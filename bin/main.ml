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

(* JSON parsing/building  *)
let hex           = "0x"


(*  MAIN  *)
let () = 
  (* Convenience *)
  let mapmap f l = map (map f) l                      in

  (* Record convenience *)
  let rblock sz id = {
    ruuid     = id;
    contents  = empty;
    opcodes   = [];
    address   = 0;
    offset    = 0;
    size      = sz;
  } in
  
  (* Byte & array manipulation convenience functions *)
  let len         = Bytes.length                in
  let b_tl op n   = Bytes.sub op n (len op - n) in
  let b_hd op n   = Bytes.sub op 0 n            in

  (* BEGINNING *)
  let usage () =
    (Printf.eprintf "usage: %s [--help] %s\n" Sys.argv.(0) usage_string) in
  if (Array.mem "--help" Sys.argv) then
    (usage (); exit 0);
  if (Array.length Sys.argv != expected_argc) then
    (usage (); raise (Invalid_argument "invalid command line arguments"));

  (* Read bytes from the file, skip first 8 *) 
  let bytes = 
    let ic  = open_in Sys.argv.(binary_ind)     in 
    let len = in_channel_length ic              in
    let _   = really_input_string ic 8          in
    let res = really_input_string ic (len - 8)  in
    close_in ic; 
    res
  in
  (* Pull out interesting code bits *)
  let gtirb = 
    let raw = Reader.create bytes in
    IR.from_proto raw
  in
  let ir =
    match gtirb with
    | Ok a    -> a
    | Error e -> failwith (
        Printf.sprintf "%s%s" "Could not reply request: " (Ocaml_protoc_plugin.Result.show_error e)
      )
  in
  let modules     = ir.modules                in
  let ival_blks : content_block list list  =
    let all_sects = map (fun (m : Module.t) -> m.sections) modules                          in
    let all_texts = all_sects                                          in
    let intervals = mapmap (fun (s : Section.t) -> s.byte_intervals) all_texts |> map flatten in
    mapmap (fun (i : ByteInterval.t)
      -> map (fun b -> {block = b; raw = i.contents; address = i.address}) i.blocks) intervals
      |> map flatten
  in

  (* Resolve polymorphic block variants to isolate only useful info *)
  let codes_only : rectified_block list list = 
    let rectify = function
      | `Code (c : CodeBlock.t) -> rblock c.size c.uuid
      | _                       -> rblock 0 empty
    in
    let poly_blks   = mapmap (fun b -> {{{(rectify b.block.value)
      with offset   = b.block.offset}
      with contents = b.raw}
      with address  = b.address + b.block.offset}) ival_blks
    in 
    map (filter (fun b -> b.size > 0)) poly_blks in
  
  (* Section up byte interval contents to their respective blocks and take individual opcodes *)
  let op_cuts : rectified_block list list  =
    let trimmed = mapmap (fun b -> 
        {b with contents = Bytes.sub b.contents b.offset b.size}) codes_only in
    let rec cut_ops contents =
      if len contents <= opcode_length then [contents]
      else ((b_hd contents opcode_length) :: cut_ops (b_tl contents opcode_length))
    in
    mapmap (fun b -> {b with opcodes = cut_ops b.contents}) trimmed
  in

  (* Convert every opcode to big endianness *)
  let blk_orded : rectified_block list list =
    let need_flip = map (fun (m : Module.t)
        -> m.byte_order = ByteOrder.LittleEndian) modules in
    let rec endian_reverse opcode: bytes = 
      if len opcode = 1
      then opcode
      else cat (endian_reverse (b_tl opcode 1)) (b_hd opcode 1)                       in
    let flip_opcodes block = {block with opcodes = map endian_reverse block.opcodes}  in
    let pairs = combine need_flip op_cuts in
    let fix_mod p =
      match p with
      | (true,  o)  -> map flip_opcodes o
      | (false, o)  -> o
    in
    map fix_mod pairs
  in

  (* hashtable for memoising disassembly results by opcode. *)
  let tbl : (bytes, string list) Hashtbl.t = Hashtbl.create 10000 in
  List.iter
    (fun op -> Hashtbl.replace tbl op [])
    List.(concat_map (fun x -> x.opcodes) @@ flatten blk_orded);
  let tbl_update k f =
    match Hashtbl.find_opt tbl k with
    | Some x -> x
    | None -> let x = f () in (Hashtbl.replace tbl k x; x)
  in
  (* Printf.printf "%d unique ops\n" Hashtbl.(length tbl); *)
  (* flush stdout; *)

  Printexc.record_backtrace true;
  let env =
    match Eval.aarch64_evaluation_environment () with
    | Some e -> e
    | None -> Printf.eprintf "unable to load bundled asl files. has aslp been installed correctly?"; exit 1
  in

  (* Evaluate each instruction one by one with a new environment for each *)
  let to_asli (op: bytes) (addr : int) : string list =
    let p_raw a = Utils.to_string (Asl_parser_pp.pp_raw_stmt a) |> String.trim in
    let address = Some (string_of_int addr)                                    in
    let str     = hex ^ Hexstring.encode op                                    in
    let str_bytes = Printf.sprintf "%08lX" (Bytes.get_int32_le op 0)           in
    let do_dis () =
      (match (Dis.retrieveDisassembly ?address env (Dis.build_env env) str) with
      | res -> map (fun x -> p_raw x) res
      | exception exc ->
        Printf.eprintf
          "error during aslp disassembly (opcode %s, bytes %s):\n\nFatal error: exception %s\n"
          str str_bytes (Printexc.to_string exc);
        Printexc.print_backtrace stderr;
        exit 1)
    in tbl_update op (do_dis)
  in
  let rec asts opcodes addr =
    match opcodes with
    | []      -> []
    | h :: t  -> (to_asli h addr) :: (asts t (addr + opcode_length))
  in
  let with_asts = mapmap (fun b 
    -> {
      auuid   = b.ruuid;
      asts    = (asts b.opcodes b.address);
    }) blk_orded
  in

  (* Massage asli outputs into a format which can
     be serialised and then deserialised by other tools  *)
  let serialisable: string list =
      let to_list x = `List x  in
    let jsoned (asts: string list list )  : Yojson.Safe.t = mapmap (fun s -> `String s) asts |> map to_list |> to_list in
    (*let quote bin = strung ^ (Bytes.to_string bin) ^ strung      in *)
    let paired: Yojson.Safe.t  list = (map (fun l -> `Assoc (map (fun b -> (((Base64.encode_exn (Bytes.to_string  b.auuid))), (jsoned b.asts))) l)) with_asts) in
      map (fun j -> Yojson.Safe.to_string j) paired
  in 

  (* Sandwich ASTs into the IR amongst the other auxdata *)
  let encoded =
    let orig_auxes    = map (fun (m : Module.t) -> m.aux_data) modules  in
    (* Turn the translation map + compressed semantics into auxdata and slide it in with the rest *)
    (*let convert (k: string list): bytes list = map Bytes.of_string k in *)
    let ast_aux (j: string) : AuxData.t = ({type_name = ast; data = Bytes.of_string j} : AuxData.t)  in
    let new_auxes   = map ast_aux (serialisable) |> map (fun a -> (ast, a)) in
    let aux_joins   = combine orig_auxes new_auxes                        in
    let full_auxes  = map (fun ((l : (string * AuxData.t option) list), (m, b))
        -> (m, Option.some b) :: l) aux_joins     in
    let mod_joins   = combine modules full_auxes  in
    let mod_fixed   = map (fun ((m : Module.t), a)
        -> {m with aux_data = a}) mod_joins in
    (* Save some space by deleting all sections except .text, not necessary *)
    let text_only   = map (fun (m : Module.t)
        -> {m with sections = m.sections}) mod_fixed in
    let new_ir      = {ir with modules = text_only}                 in
    (* Save some more space by deleting IR auxdata, only contains ddisasm version anyways *)
    let out_gtirb   = {new_ir with aux_data = []} in
    let serial      = IR.to_proto out_gtirb       in
    Writer.contents serial
  in

  (* Reserialise to disk *)
  let out = open_out_bin Sys.argv.(out_ind) in
  (
    Printf.fprintf out "%s" encoded;
    close_out out;
  )
