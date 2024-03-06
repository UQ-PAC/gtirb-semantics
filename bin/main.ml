open Ocaml_protoc_plugin
open Gtirb_semantics.IR.Gtirb.Proto
open Gtirb_semantics.ByteInterval.Gtirb.Proto
open Gtirb_semantics.Module.Gtirb.Proto
open Gtirb_semantics.Section.Gtirb.Proto
open Gtirb_semantics.CodeBlock.Gtirb.Proto
open Gtirb_semantics.AuxData.Gtirb.Proto
open Gtirb_semantics.Symbol.Gtirb.Proto

open struct
  let (%) = CCFun.Infix.(%)
  let (%>) = CCFun.Infix.(%>)
end

open Decoder

(* TYPES  *)
type instruction_semantics = {
  address: int;
  opcode_le: string;
  opcode_be: string;
  readable: string option;
  statementlist: string list;
  pretty_statementlist: string list;
}

(** a representation of a basic block, parameterised with the information stored for each opcode. *)
type 'a block = {
  uuid     : Uuid.t;
  block    : Block.t;
  code     : CodeBlock.t;
  address  : int; 
  endian   : ByteOrder.t;
  opcodes  : 'a list;

  label    : string option;
  successors : string list;
}

type ast_block = instruction_semantics block

module StringMap = CCMap.Make(String)


type context = {
  (* symbols keyed by referent, e.g. the uuid of the block the symbol refers to. *)
  symmap_of_referent : Symbol.t UuidMap.t;
  (* symbols keyed by the uuid of the symbol. *)
  symmap   : Symbol.t UuidMap.t;

  (* auxdata keyed by function uuid. *)
  function_names     : string UuidMap.t;
  function_entries   : UuidSet.t UuidMap.t;
  function_blocks    : UuidSet.t UuidMap.t;

  (* block to function map, keyed by block uuid. *)
  function_of_block  : Uuid.t UuidMap.t;
}


(* CONSTANTS  *)
let opcode_length = 4
let json_file = ref ""
let speclist = [
  ("--json", Arg.Set_string json_file, "output json semantics to given file (default: none, use /dev/stderr for stderr)");
]
let rest_index = ref (-1)
let in_file = ref "/nowhere/input"
let out_file = ref "/nowhere/output"

let usage_string  = "GTIRB_FILE OUTPUT_FILE [--json JSON_SEMANTICS_OUTPUT]"
let usage_message = Printf.sprintf "usage: %s [--help] %s\n" Sys.argv.(0) usage_string
(* ASL specifications are from the bundled ARM semantics in libASL. *)

let handle_rest_arg arg =
  rest_index := 1 + !rest_index;
  match !rest_index with
  | 0 -> in_file := arg
  | 1 -> out_file := arg
  | _ -> output_string stderr usage_message; exit 1



(* Protobuf spelunking  *)
let ast           = "ast"
(*let text          = ".text"*)


(* Convenience *)
let _mapmap (f: 'a -> 'b) (l: 'a list list) = List.map (List.map f) l

let pp_base64 p = Format.pp_print_string p % Uuid.to_base64
let pp_block p = pp_base64 p % fun b -> b.uuid


(* Byte & array manipulation convenience functions *)
let b_tl op n   = Bytes.sub op n (Bytes.length op - n)
let b_hd op n   = Bytes.sub op 0 n
let b_rev (opcode: bytes): bytes = 
  let len = Bytes.length opcode in
  let getrev i = Bytes.get opcode (len - 1 - i) in
  Bytes.(init len getrev)

let cut_opcodes (b: bytes): bytes list =
  let len = Bytes.length b in
  let count = len / opcode_length in
  assert (0 == len mod opcode_length);
  List.init count
    (fun i -> Bytes.sub b (i * opcode_length) opcode_length)


(* ASLP initialisation (lazy, use with Lazy.force) *)
let asl_env = lazy (
  let env =
    match LibASL.Eval.aarch64_evaluation_environment () with
    | Some e -> e
    | None -> Printf.eprintf "unable to load bundled asl files. has aslp been installed correctly?"; exit 1
  in env
)

(* MAIN FUNCTIONALITY *)

(** Populates a basic block block with semantics. *)
let run_asli_for_block (b: bytes block) : instruction_semantics block =

  (* Evaluate each instruction one by one with a new environment for each *)
  let to_asli (opcode_be: bytes) (addr : int) : instruction_semantics =
    let p_raw a = LibASL.Utils.to_string (LibASL.Asl_parser_pp.pp_raw_stmt a) |> String.trim   in
    let p_pretty a = LibASL.Asl_utils.pp_stmt a |> String.trim                          in
    let p_byte (b: char) = Printf.sprintf "%02X" (Char.code b)                   in
    let address = Some (string_of_int addr)                                      in

    (* below, opnum is the numeric opcode (necessarily BE) and opcode_* are always LE. *)
    (* TODO: change argument of to_asli to follow this convention. *)
    let opnum = Int32.to_int Bytes.(get_int32_be opcode_be 0)                    in
    let opnum_str = Printf.sprintf "0x%08lx" Int32.(of_int opnum)                in

    let opcode_list : char list = List.(rev @@ of_seq @@ Bytes.to_seq opcode_be) in
    let opcode_str = String.concat " " List.(map p_byte opcode_list)             in
    let opcode : bytes = Bytes.of_seq List.(to_seq opcode_list)                  in

    let do_dis () =
      let env = Lazy.force asl_env in
      let denv = LibASL.Dis.build_env env in
      (match LibASL.Dis.retrieveDisassembly ?address env denv opnum_str with
      | res -> (List.map p_raw res, List.map p_pretty res)
      | exception exc ->
        Printf.eprintf
          "error during aslp disassembly (opcode %s, bytes %s):\n\nFatal error: exception %s\n"
          opnum_str opcode_str (Printexc.to_string exc);
        Printexc.print_backtrace stderr;
        exit 1)
    in
    let insns_raw, insns_pretty = do_dis () in
    {
      address = addr;
      opcode_be = opnum_str;
      opcode_le = opcode_str;
      readable = Llvm_disas.assembly_of_bytes_opt opcode;
      statementlist = insns_raw;
      pretty_statementlist = insns_pretty;
    }
  in

  let opcodes' = List.mapi
    (fun i op -> to_asli op (b.address + i * opcode_length)) b.opcodes in
  {b with opcodes = opcodes'}


(** Adds debug-relevant information to each block, returning a new block list.
    For example, successors and function names. *)
let debug_info_for_blocks (m: Module.t) (blocks: bytes block list) : bytes block list = 
  let symmap = Hashtbl.create (List.length m.symbols) in
  List.iter 
    (fun (s: Symbol.t) -> 
      match s.optional_payload with 
      | `Referent_uuid b -> Hashtbl.add symmap b s
      | _ -> ())
    m.symbols;

  let get_aux name = (Option.get @@ List.assoc name m.aux_data).data in
  let x = decode_map_uuid_uuid @@ get_aux "functionNames" in
  (* let a = UuidMap.of_list x in
  let a2 = UuidMap.map (fun v -> )
  List.iter (fun (k, v) -> 
    let a = Option.fold ~none:("none for " ^ Base64.encode_exn (Bytes.to_string v)) ~some:(fun (a : Symbol.t) -> a.name) @@ Hashtbl.find_opt symmap v in
    Printf.printf "k: %s\n" a
    ) x; *)
  let _ = decode_map_uuid_uuid_set @@ get_aux "functionEntries" in
  let _ = decode_map_uuid_uuid_set @@ get_aux "functionBlocks" in
    blocks


(** Locates basic blocks from a Module and extracts their opcodes. *)
let locate_blocks (context: context) (m: Module.t) : bytes block list =
  let blocks : bytes block list =
    let all_sects = m.sections in
    let all_texts = all_sects in
    let intervals = List.map (fun (s : Section.t) -> s.byte_intervals) all_texts |> List.flatten in

    let make_block (i: ByteInterval.t) (b: Block.t): bytes block option =
      match b.value with
      | `Code (c : CodeBlock.t) -> 
        let uuid = Uuid.of_bytes c.uuid in
        Some {
          uuid;
          block = b;
          code = c;
          address = i.address;
          endian = m.byte_order;

          opcodes = cut_opcodes @@ Bytes.sub i.contents b.offset c.size;

          label = Option.map (fun (s: Symbol.t) -> s.name) @@ UuidMap.find_opt uuid context.symmap_of_referent;
          successors = [];
        }
      | _ -> None in
    List.flatten @@ List.map (fun i -> List.filter_map (fun b -> make_block i b) i.blocks) intervals
  in

  (* Convert every opcode to big endianness *)
  let to_big_endian b = 
    if b.endian == ByteOrder.LittleEndian
      then { b with opcodes = List.map b_rev b.opcodes; endian = ByteOrder.BigEndian }
      else b in
  let blocks = List.map to_big_endian blocks in

  (* sort by address to approximate a (intra-procedural) topological order. *)
  let blocks = List.sort (fun a b -> Int.compare a.address b.address) blocks in

  let blocks = debug_info_for_blocks m blocks in

  blocks

let build_module_context (m: Module.t) : context =
  let symmap_of_referent =
    UuidMap.of_list @@ List.filter_map
      (fun (s: Symbol.t) -> match s.optional_payload with 
       | `Referent_uuid b -> Some (Uuid.of_bytes b, s)
       | _ -> None)
      m.symbols in

  let symmap =
    UuidMap.of_list @@ List.map
      (fun (s: Symbol.t) -> (Uuid.of_bytes s.uuid, s))
      m.symbols in

  let auxdata = 
    m.aux_data 
    |> StringMap.of_list
    |> StringMap.filter_map Fun.(const id)
    |> StringMap.map (fun (x : AuxData.t) -> x.data) in

  let get_aux s = StringMap.get s auxdata in
  let get_or_empty f name = Option.fold ~none:UuidMap.empty ~some:f @@ get_aux name in

  let function_names =
    get_or_empty decode_map_uuid_uuid "functionNames"
    |> UuidMap.filter_map (fun _k v -> UuidMap.find_opt v symmap)
    |> UuidMap.map (fun (s: Symbol.t) -> s.name) in

  let function_entries = get_or_empty decode_map_uuid_uuid_set "functionEntries" in
  let function_blocks = get_or_empty decode_map_uuid_uuid_set "functionBlocks" in

  let function_of_block =
    function_blocks
    |> UuidMap.map UuidSet.to_list
    |> UuidMap.to_list
    |> CCList.concat_map (fun (f,bs) -> List.map (fun b -> (b,f)) bs)
    |> UuidMap.of_list in

  UuidMap.pp (CCFormat.within "[" "]" Uuid.pp) (CCFormat.hbox @@ UuidSet.pp Uuid.pp) Format.err_formatter function_entries;
  Format.pp_force_newline Format.err_formatter ();
  Format.pp_force_newline Format.err_formatter ();
  UuidMap.pp (CCFormat.within "[" "]" Uuid.pp) (CCFormat.hbox @@ UuidSet.pp Uuid.pp) Format.err_formatter function_blocks;

  { symmap_of_referent; symmap; function_names; function_entries; function_blocks; function_of_block; }


(** Adds semantics information to a single Module, returning a new Module. *)
let do_module (m: Module.t) : Module.t = 

  let context = build_module_context m in

  let blocks = locate_blocks context m in

  let blocks = List.map run_asli_for_block blocks in

  (* Massage asli outputs into a format which can
     be serialised and then deserialised by other tools  *)
  let yojson_instsem (s: instruction_semantics) = 
    let assembly_maybe = 
      match s.readable with 
      | Some x -> [("assembly", `String x)]
      | None -> [] in
    `Assoc 
      (assembly_maybe @
        [ ("addr", `Int s.address);
          ("opcode_le", `String s.opcode_le); ("opcode_be", `String s.opcode_be);
          ("semantics", `List (List.map (fun s -> `String s) s.statementlist));
          ("pretty_semantics", `List (List.map (fun s -> `String s) s.pretty_statementlist)); ])
  in

  let serialisable: string =
    let to_list x = `List x in
    let jsoned (asts: instruction_semantics list ) : Yojson.Safe.t = List.map (yojson_instsem) asts |> to_list in

    let make_entry (b: ast_block): string * Yojson.Safe.t = 
      let label_maybe =
        match b.label with 
        | Some l -> [("label", `String l)]
        | None -> [] in
      (
        Uuid.to_base64 b.uuid,
        `Assoc (label_maybe @ [ ("addr", `Int b.address); ("instructions", (jsoned b.opcodes)) ])
      )
    in

    let paired: Yojson.Safe.t = `Assoc (List.map make_entry blocks) in
    let json_str = Yojson.Safe.pretty_to_string paired in
    if !json_file != "" then begin
      let f = open_out !json_file in
      output_string f json_str;
      close_out f
    end;
    json_str
  in 

  (* Sandwich ASTs into the IR amongst the other auxdata *)
  let orig_auxes   = m.aux_data in
  (* Turn the translation map + compressed semantics into auxdata and slide it in with the rest *)
  (*let convert (k: string list): bytes list = List.map Bytes.of_string k in *)
  let ast_aux data = AuxData.make ?type_name:(Some ast) ?data:(Some (Bytes.of_string data)) () in
  let new_aux      = ast_aux (Compress.deflate_string serialisable) in
  let full_auxes   = ("ast", Some new_aux) :: orig_auxes in
  let mod_fixed    = {m with aux_data = full_auxes} in

  mod_fixed


(*  MAIN  *)
let () = 
  (* BEGINNING *)
  Arg.parse speclist handle_rest_arg usage_message;
  (* Printf.eprintf "gtirb-semantics: %s -> %s\n" !in_file !out_file; *)

  Printexc.record_backtrace true;
  (* Read bytes from the file, skip first 8 *) 
  let bytes = 
    let ic  = open_in_bin !in_file              in 
    let len = in_channel_length ic              in
    let _   = really_input_string ic 8          in
    let res = really_input_string ic (len - 8)  in
    close_in ic; 
    res
  in

  (* Pull out interesting code bits *)
  let gtirb = 
    let raw = Reader.create bytes in
    IR.from_proto raw in

  let ir =
    match gtirb with
    | Ok a    -> a
    | Error e -> failwith (
        Printf.sprintf "%s%s" "Could not reply request: " (Ocaml_protoc_plugin.Result.show_error e)
      ) in

  let modules'    = List.map do_module ir.modules     in
  let new_ir      = {ir with modules = modules'} in
  let serial      = IR.to_proto new_ir           in
  let encoded     = Writer.contents serial       in

  (* Reserialise to disk *)
  let out = open_out_bin !out_file in
  output_string out encoded;
  close_out out;
