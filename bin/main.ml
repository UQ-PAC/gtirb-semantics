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
  concat  : string;
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
let prelude_ind   = 2
let mra_ind       = 3
let asli_ind      = 4
let out_ind       = 5
let opcode_length = 4

let expected_argc = 6
let usage_string  = " GTIRB_FILE ASLI_PRELUDE MRA_TOOLS_DIR ASLI_DIR OUTPUT_FILE"

(* Protobuf spelunking  *)
let ast           = "ast"
(*let text          = ".text"*)

(* JSON parsing/building  *)
let hex           = "0x"
let l_op          = "["
let l_dl          = ","
let l_cl          = "]"
let strung        = "\""
let alt_str       = "'"
let kv_pair       = ":"
let newline       = "\n"

(* ASL Spec pathing *)
(* Hardcoding this as it's unlikely to change for a while and adding 200000 cmdline args is pain  *)
let arch          = "regs-arch-arch_instrs-arch_decode"
let support       = "aes-barriers-debug-feature-hints-interrupts-memory-stubs-fetchdecode"
let test          = "override-test"
let types         = "types"
let spec_d        = '-'
let path_d        = "/"
let asl           = ".asl"

(*  MAIN  *)
let () = 
  (* Convenience *)
  let map2 f l = map (map f) l                      in
  let stl s = String.sub s 1 (String.length s - 1)  in

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
  if (Array.length Sys.argv != expected_argc) then
    (Printf.eprintf "usage: %s%s\n" Sys.argv.(0) usage_string;
    raise (Invalid_argument "invalid command line arguments"))
  else 
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
  let ival_blks   =
    let all_sects = map (fun (m : Module.t) -> m.sections) modules                          in
    let all_texts = all_sects                                          in
    let intervals = map2 (fun (s : Section.t) -> s.byte_intervals) all_texts |> map flatten in
    map2 (fun (i : ByteInterval.t)
      -> map (fun b -> {block = b; raw = i.contents; address = i.address}) i.blocks) intervals
      |> map flatten
  in

  (* Resolve polymorphic block variants to isolate only useful info *)
  let codes_only  = 
    let rectify   = function
      | `Code (c : CodeBlock.t) -> rblock c.size c.uuid
      | _                       -> rblock 0 empty
    in
    let poly_blks   = map2 (fun b -> {{{(rectify b.block.value)
      with offset   = b.block.offset}
      with contents = b.raw}
      with address  = b.address + b.block.offset}) ival_blks
    in 
    map (filter (fun b -> b.size > 0)) poly_blks in
  
  (* Section up byte interval contents to their respective blocks and take individual opcodes *)
  let op_cuts   =
    let trimmed = map2 (fun b -> 
        {b with contents = Bytes.sub b.contents b.offset b.size}) codes_only in
    let rec cut_ops contents =
      if len contents <= opcode_length then [contents]
      else ((b_hd contents opcode_length) :: cut_ops (b_tl contents opcode_length))
    in
    map2 (fun b -> {b with opcodes = cut_ops b.contents}) trimmed
  in

  (* Convert every opcode to big endianness *)
  let blk_orded =
    let need_flip = map (fun (m : Module.t)
        -> m.byte_order = ByteOrder.LittleEndian) modules in
    let rec endian_reverse opcode = 
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

  (* Organise specs to allow for ASLi evaluation environment setup *)
  let envinfo =
    let spc_dir = Sys.argv.(mra_ind)                                        in
    let take_paths p sdir fs = String.split_on_char spec_d fs |> 
        map (fun f -> p ^ path_d ^ sdir ^ path_d ^ f ^ asl)                 in
    let add_types l = (hd l) :: (spc_dir ^ path_d ^ types ^ asl) :: (tl l)  in
    let arches  = take_paths spc_dir "arch" arch                            in
    let support = take_paths spc_dir "support" support                      in
    let tests   = take_paths Sys.argv.(asli_ind) "tests" test               in
    let prel    = Sys.argv.(prelude_ind)                                    in
    let w_types = add_types arches                                          in
    let specs   = w_types @ support @ tests                                 in
    let prelude = LoadASL.read_file prel true false                         in
    let mra     = map (fun t -> LoadASL.read_file t false false) specs      in
    concat (prelude :: mra)
  in

  (* Evaluate each instruction one by one with a new environment for each *)
  let to_asli op addr =
    let p_raw a = 
      let rec fix_json s =
        if String.length s = 0
        then s
        else (
          let p = String.sub s 0 1 in
          let q =
            (* '"' needs to become '\'' to make json parsing less painful on the basil side *)
            (* and \n needs to become , to make lists format correctly *)
              if p = strung
              then alt_str
              else (
                if p = newline
                then l_dl
                else p
              )
          in 
          q ^ fix_json (stl s)
        )
      in 
      let s = Utils.to_string (Asl_parser_pp.pp_raw_stmt a) |> String.trim |> fix_json in
      (
        (* Display Asli outputs as they arrive 
        print_endline s;*)
        s
      )
    in
    (* Set up and tear down eval environment for every single instruction *)
    let address = Some (string_of_int addr)                                     in
    let env     = Eval.build_evaluation_environment envinfo                     in
    let str     = hex ^ Hexstring.encode op                                     in
    let res     = Dis.retrieveDisassembly ?address env (Dis.build_env env) str  in
    let ascii   = map p_raw res                                                 in
    let indiv s = init (String.length s) (String.get s) |> map (String.make 1)  in
    let joined  = map indiv ascii |>  map (String.concat "")                    in
    map (fun s -> strung ^ s ^ strung) joined
  in
  let rec asts opcodes addr envinfo =
    match opcodes with
    | []      -> []
    | h :: t  -> (to_asli h addr) :: (asts t (addr + opcode_length) envinfo)
  in
  let with_asts = map2 (fun b 
    -> {
      auuid   = b.ruuid;
      asts    = (asts b.opcodes b.address envinfo);
      concat  = ""
    }) blk_orded
  in

  (* Massage asli outputs into a format which can
     be serialised and then deserialised by other tools *)
  let serialisable: string list =
    let l_to_s op d cl l  = op ^ (String.concat d l) ^ cl                             in
    let jsoned asts       = map (l_to_s l_op l_dl l_cl) asts |> l_to_s l_op l_dl l_cl in
    (*let quote bin = strung ^ (Bytes.to_string bin) ^ strung      in *)
    let b64 bin   = strung ^ (Bytes.to_string bin |> Base64.encode_exn) ^ strung      in 
    let json_asts = map2 (fun b -> {b with concat = jsoned b.asts}) with_asts         in
    let paired    = map2 (fun b -> (b64 b.auuid) ^ kv_pair ^ b.concat) json_asts      in
    map (String.concat l_dl) paired
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
