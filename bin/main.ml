open Ocaml_protoc_plugin
open Gtirb_semantics.IR.Gtirb.Proto
open Gtirb_semantics.ByteInterval.Gtirb.Proto
open Gtirb_semantics.Module.Gtirb.Proto
open Gtirb_semantics.Section.Gtirb.Proto
open Gtirb_semantics.CodeBlock.Gtirb.Proto
open Gtirb_semantics.AuxData.Gtirb.Proto
open LibASL
open Bytes
open List

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

(* ASLi semantic info for a block *)
type ast_block = {
  auuid   : bytes;
  asts    : string list list;
}

(* Wrapper for polymorphic code/data/not-set block pre-rectification  *)
type content_block = {
  block   : Block.t;
  raw     : bytes;
  address : int; 
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
let handle_rest_arg arg =
  rest_index := 1 + !rest_index;
  match !rest_index with
  | 0 -> in_file := arg
  | 1 -> out_file := arg
  | _ -> failwith "argc unexpected"


let usage_string  = "GTIRB_FILE OUTPUT_FILE [--json JSON_SEMANTICS_OUTPUT]"
let usage_message = Printf.sprintf "usage: %s [--help] %s\n" Sys.argv.(0) usage_string
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

  Printexc.record_backtrace true;
  let env =
    match Eval.aarch64_evaluation_environment () with
    | Some e -> e
    | None -> Printf.eprintf "unable to load bundled asl files. has aslp been installed correctly?"; exit 1
  in

  (* Evaluate each instruction one by one with a new environment for each *)
  let to_asli (opcode_be: bytes) (addr : int) : string list =
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
    in fst @@ do_dis ()
  in
  let rec asts opcodes addr =
    match opcodes with
    | []      -> []
    | h :: t  -> (to_asli h addr) :: (asts t (addr + opcode_length))
  in
  (* let map' f l =
    if List.length blk_orded > 10000
      then Parmap.parmap ~ncores:2 f Parmap.(L l)
      else map f l in *)
  let map' = map in
  let with_asts = map' (fun b -> {
      auuid   = b.ruuid;
      asts    = asts b.opcodes b.address;
    }) blk_orded
  in

  (* Massage asli outputs into a format which can
     be serialised and then deserialised by other tools  *)
  let serialisable: string =
    let to_list x = `List x in
    let to_string x = `String x in
    let jsoned (asts: string list list) : Yojson.Safe.t =
      to_list @@ List.map (fun x -> to_list @@ List.map to_string x) asts in
    let paired: Yojson.Safe.t =
      `Assoc (
        map
          (fun (b: ast_block) -> (Base64.encode_exn (Bytes.to_string b.auuid)), jsoned b.asts)
          with_asts) in
    Yojson.Safe.pretty_to_channel stderr paired; 

    let json_str = Yojson.Safe.pretty_to_string paired in
    if !json_file <> "" then begin
      let f = open_out !json_file in
      output_string f json_str;
      close_out f
    end;
    json_str
  in 

  (* Sandwich ASTs into the IR amongst the other auxdata *)
  let orig_auxes   = m.aux_data in
  (* Turn the translation map + compressed semantics into auxdata and slide it in with the rest *)
  let ast_aux data = AuxData.make ?type_name:(Some ast) ?data:(Some (Bytes.of_string data)) () in
  let new_aux      = ast_aux (serialisable) in
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
    let magic = really_input_string ic 8        in
    let res = really_input_string ic (len - 8)  in
    (* check for gtirb magic otherwise assume is raw protobuf *)
    let res = if (String.starts_with ~prefix:"GTIRB" magic) then res else magic ^ res in
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
