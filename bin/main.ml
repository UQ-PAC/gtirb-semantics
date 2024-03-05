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

(* These could probably be simplified *)
(* OCaml representation of mid-evaluation code block  *)
type rectified_block = {
  ruuid     : bytes;
  contents  : bytes;
  opcodes   : bytes list;
  address   : int;
  offset    : int;
  size      : int;
}

type instruction_semantics = {
  address: int;
  opcode_le: string;
  opcode_be: string;
  readable: string option;
  statementlist: string list;
  pretty_statementlist: string list;
}

(* ASLi semantic info for a block *)
type ast_block = {
  auuid   : bytes;
  label: string option;
  address : int;
  asts    : instruction_semantics list;
}


(* Wrapper for polymorphic code/data/not-set block pre-rectification  *)
type content_block = {
  block   : Block.t;
  raw     : bytes;
  address : int; 
}

(* CONSTANTS  *)
(* Argv       *)
let binary_ind    = 1
let out_ind       = 2
let opcode_length = 4


let expected_argc = 3  (* including arg0 *)
let usage_string  = "GTIRB_FILE OUTPUT_FILE"
(* ASL specifications are from the bundled ARM semantics in libASL. *)

(* Protobuf spelunking  *)
let ast           = "ast"
(*let text          = ".text"*)


(* Convenience *)
let _mapmap (f: 'a -> 'b) (l: 'a list list) = map (map f) l

(* Record convenience *)
let rblock sz id = {
  ruuid     = id;
  contents  = empty;
  opcodes   = [];
  address   = 0;
  offset    = 0;
  size      = sz;
}

(* Byte & array manipulation convenience functions *)
let b_tl op n   = Bytes.sub op n (Bytes.length op - n)
let b_hd op n   = Bytes.sub op 0 n

  
let do_module (m: Module.t): Module.t = 

  let ival_blks : content_block list =
    let all_sects = m.sections in
    let all_texts = all_sects in
    let intervals = map (fun (s : Section.t) -> s.byte_intervals) all_texts |> flatten in

    let content_block (i: ByteInterval.t) (b: Block.t) =
      {block = b; raw = i.contents; address = i.address} in
      
    flatten @@ map (fun i -> map (fun b -> content_block i b) i.blocks) intervals
  in

  (* Resolve polymorphic block variants to isolate only useful info *)
  let codes_only : rectified_block list = 
    let rectify = function
      | `Code (c : CodeBlock.t) -> rblock c.size c.uuid
      | _                       -> rblock 0 empty
    in
    let poly_blks   = map (fun b -> {(rectify b.block.value)
      with offset   = b.block.offset;
      contents = b.raw;
      address  = b.address + b.block.offset}) ival_blks
    in 
    filter (fun b -> b.size > 0) poly_blks in
  
  (* Section up byte interval contents to their respective blocks and take individual opcodes *)
  let op_cuts : rectified_block list  =
    let trimmed = map (fun b -> 
        {b with contents = Bytes.sub b.contents b.offset b.size}) codes_only in
    let rec cut_ops contents =
      if Bytes.length contents <= opcode_length then [contents]
      else (b_hd contents opcode_length) :: cut_ops (b_tl contents opcode_length)
    in
    map (fun b -> {b with opcodes = cut_ops b.contents}) trimmed
  in

  let symmap = Hashtbl.create (List.length m.symbols) in
  List.iter 
    (fun (s: Symbol.t) -> 
      match s.optional_payload with 
      | `Referent_uuid b -> Hashtbl.add symmap b s
      | _ -> ())
    m.symbols;

  let need_flip = m.byte_order = ByteOrder.LittleEndian in

  (* Convert every opcode to big endianness *)
  let blk_orded : rectified_block list =
    let endian_reverse (opcode: bytes): bytes = 
      let len = Bytes.length opcode in
      let getrev i = Bytes.get opcode (len - 1 - i) in
      Bytes.(init len getrev) in
    let flip_opcodes block = {block with opcodes = map endian_reverse block.opcodes}  in
    let fix_mod : rectified_block list -> rectified_block list = if need_flip then map flip_opcodes else Fun.id
    in
    fix_mod op_cuts
  in

  (* hashtable for memoising disassembly results by opcode. *)
  let tbl : (bytes, (string list) * (string list)) Hashtbl.t = Hashtbl.create 10000 in
  let tbl_update k f =
    match Hashtbl.find_opt tbl k with
    | Some x -> x
    | None -> let x = f () in (Hashtbl.replace tbl k x; x)
  in

  Printexc.record_backtrace true;
  let env =
    match Eval.aarch64_evaluation_environment () with
    | Some e -> e
    | None -> Printf.eprintf "unable to load bundled asl files. has aslp been installed correctly?"; exit 1
  in

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
      (match Dis.retrieveDisassembly ?address env (Dis.build_env env) opnum_str with
      | res -> (map p_raw res, map p_pretty res)
      | exception exc ->
        Printf.eprintf
          "error during aslp disassembly (opcode %s, bytes %s):\n\nFatal error: exception %s\n"
          opnum_str opcode_str (Printexc.to_string exc);
        Printexc.print_backtrace stderr;
        exit 1)
    in
    let insns_raw, insns_pretty = tbl_update opcode_be (do_dis) in
    {
      address = addr;
      opcode_be = opnum_str;
      opcode_le = opcode_str;
      readable = assembly_of_bytes_opt opcode;
      statementlist = insns_raw;
      pretty_statementlist = insns_pretty;
    }
  in
  let rec asts opcodes addr =
    match opcodes with
    | []      -> []
    | h :: t  -> (to_asli h addr) :: (asts t (addr + opcode_length))
  in
  let with_asts = map (fun b 
    -> {
      auuid   = b.ruuid;
      address = b.address;
      asts    = (asts b.opcodes b.address);
      label   = Option.map (fun (s: Symbol.t) -> s.name) (Hashtbl.find_opt symmap b.ruuid)
    }) blk_orded
  in

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
        Base64.encode_exn (Bytes.to_string b.auuid),
        `Assoc (label_maybe @ [ ("addr", `Int b.address); ("instructions", (jsoned b.asts)) ])
      )
    in

    let paired: Yojson.Safe.t = `Assoc (map make_entry with_asts) in
    Yojson.Safe.pretty_to_channel stderr paired; 
    Yojson.Safe.to_string paired
  in 

  (* Sandwich ASTs into the IR amongst the other auxdata *)
  let orig_auxes   = m.aux_data in
  (* Turn the translation map + compressed semantics into auxdata and slide it in with the rest *)
  (*let convert (k: string list): bytes list = map Bytes.of_string k in *)
  let ast_aux data = AuxData.make ?type_name:(Some ast) ?data:(Some (Bytes.of_string data)) () in
  let new_aux      = ast_aux (serialisable) in
  let full_auxes   = ("ast", Some new_aux) :: orig_auxes in
  let mod_fixed    = {m with aux_data = full_auxes} in
  mod_fixed


(*  MAIN  *)
let () = 
  (* BEGINNING *)
  let usage () =
    (Printf.eprintf "usage: %s [--help] %s\n" Sys.argv.(0) usage_string) in
  if (Array.mem "--help" Sys.argv) then
    (usage (); exit 0);
  if (Array.length Sys.argv != expected_argc) then
    (usage (); raise (Invalid_argument "invalid command line arguments"));

  (* Read bytes from the file, skip first 8 *) 
  let bytes = 
    let ic  = open_in_bin Sys.argv.(binary_ind)     in 
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
  let out = open_out_bin Sys.argv.(out_ind) in
  output_string out encoded;
  close_out out;
