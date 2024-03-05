open Ocaml_protoc_plugin
open Gtirb_semantics.IR.Gtirb.Proto
open Gtirb_semantics.ByteInterval.Gtirb.Proto
open Gtirb_semantics.Module.Gtirb.Proto
open Gtirb_semantics.Section.Gtirb.Proto
open Gtirb_semantics.CodeBlock.Gtirb.Proto
open Gtirb_semantics.AuxData.Gtirb.Proto
open Gtirb_semantics.Symbol.Gtirb.Proto
open LibASL
open Bytes
open List
open Llvm_disas

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
  uuid     : bytes;
  uuid_b64 : string;
  block    : Block.t;
  code     : CodeBlock.t;
  address  : int; 
  endian   : ByteOrder.t;
  opcodes  : 'a list;

  label    : string option;
  successors : string list;
}

type ast_block = instruction_semantics block

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
let _mapmap (f: 'a -> 'b) (l: 'a list list) = map (map f) l


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
  Printexc.record_backtrace true;
  let env =
    match Eval.aarch64_evaluation_environment () with
    | Some e -> e
    | None -> Printf.eprintf "unable to load bundled asl files. has aslp been installed correctly?"; exit 1
  in env
)

(* MAIN FUNCTIONALITY *)

(** Populates a basic block block with semantics. *)
let run_asli_for_block (b: bytes block) : instruction_semantics block =

  (* Evaluate each instruction one by one with a new environment for each *)
  let to_asli (opcode_be: bytes) (addr : int) : instruction_semantics =
    let p_raw a = Utils.to_string (Asl_parser_pp.pp_raw_stmt a) |> String.trim   in
    let p_pretty a = Asl_utils.pp_stmt a |> String.trim                          in
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
      (match Dis.retrieveDisassembly ?address env (Dis.build_env env) opnum_str with
      | res -> (map p_raw res, map p_pretty res)
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
      readable = assembly_of_bytes_opt opcode;
      statementlist = insns_raw;
      pretty_statementlist = insns_pretty;
    }
  in

  let opcodes' = mapi
    (fun i op -> to_asli op (b.address + i * opcode_length)) b.opcodes in
  {b with opcodes = opcodes'}


(** Adds debug-relevant information to each block, returning a new block list.
    For example, successors and function names. *)
let debug_info_for_blocks (m: Module.t) (blocks: bytes block list) : bytes block list = 
  blocks

(** Locates and extracts basic blocks from a Module. *)
let locate_blocks (m: Module.t) : bytes block list =
  let symmap = Hashtbl.create (List.length m.symbols) in
  List.iter 
    (fun (s: Symbol.t) -> 
      match s.optional_payload with 
      | `Referent_uuid b -> Hashtbl.add symmap b s
      | _ -> ())
    m.symbols;


  let blocks : bytes block list =
    let all_sects = m.sections in
    let all_texts = all_sects in
    let intervals = map (fun (s : Section.t) -> s.byte_intervals) all_texts |> flatten in

    let make_block (i: ByteInterval.t) (b: Block.t): bytes block option =
      match b.value with
      | `Code (c : CodeBlock.t) -> 
        Some {
          uuid = c.uuid;
          uuid_b64 = Base64.encode_exn (Bytes.to_string c.uuid);
          block = b;
          code = c;
          address = i.address;
          endian = m.byte_order;

          opcodes = cut_opcodes @@ Bytes.sub i.contents b.offset c.size;

          label = Option.map (fun (s: Symbol.t) -> s.name) @@ Hashtbl.find_opt symmap c.uuid;
          successors = [];
        }
      | _ -> None in
    flatten @@ map (fun i -> filter_map (fun b -> make_block i b) i.blocks) intervals
  in

  (* Convert every opcode to big endianness *)
  let to_big_endian b = 
    if b.endian == ByteOrder.LittleEndian
      then { b with opcodes = map b_rev b.opcodes; endian = ByteOrder.BigEndian }
      else b in
  let blocks = map to_big_endian blocks in

  (* sort by address to approximate a (intra-procedural) topological order. *)
  List.sort (fun a b -> Int.compare a.address b.address) blocks


(** Adds semantics information to a single Module, returning a new Module. *)
let do_module (m: Module.t) : Module.t = 

  let blocks = locate_blocks m in

  let blocks = map run_asli_for_block blocks in

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
    let jsoned (asts: instruction_semantics list ) : Yojson.Safe.t = map (yojson_instsem) asts |> to_list in

    let make_entry (b: ast_block): string * Yojson.Safe.t = 
      let label_maybe =
        match b.label with 
        | Some l -> [("label", `String l)]
        | None -> [] in
      (
        b.uuid_b64,
        `Assoc (label_maybe @ [ ("addr", `Int b.address); ("instructions", (jsoned b.opcodes)) ])
      )
    in

    let paired: Yojson.Safe.t = `Assoc (map make_entry blocks) in
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
  (*let convert (k: string list): bytes list = map Bytes.of_string k in *)
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

  let modules'    = map do_module ir.modules     in
  let new_ir      = {ir with modules = modules'} in
  let serial      = IR.to_proto new_ir           in
  let encoded     = Writer.contents serial       in

  (* Reserialise to disk *)
  let out = open_out_bin !out_file in
  output_string out encoded;
  close_out out;
