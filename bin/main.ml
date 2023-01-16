open Ocaml_protoc_plugin.Runtime
open Gtirb_semantics.IR.Gtirb.Proto
open Gtirb_semantics.ByteInterval.Gtirb.Proto
open Gtirb_semantics.Module.Gtirb.Proto
open Gtirb_semantics.Section.Gtirb.Proto
open Gtirb_semantics.CodeBlock.Gtirb.Proto
open Gtirb_semantics.AuxData.Gtirb.Proto
open LibASL
open Bytes
open List

type rectified_block = {
  ruuid     : bytes;
  contents  : bytes;
  opcodes   : bytes list;
  address   : int;
  offset    : int;
  size      : int;
}

type ast_block = {
  auuid   : bytes;
  asts    : string list list;
  concat  : string;
}

type content_block = {
  block   : Block.t;
  raw     : bytes;
  address : int; 
}

let binary_ind    = 1
let out_ind       = 2
let prelude_ind   = 3
let specs_start   = 4
let noplen        = 4
let opcode_length = 4

let ast           = "ast"
let text          = ".text"
let hex           = "0x"
let l_op          = "["
let l_dl          = ","
let l_cl          = "]"
let newline       = "\n"
let space         = " "
let strung        = "\""
let kv_pair       = ":"
let j_op          = "{"
let j_cl          = "}"

let () = 

  (* List manipulation convenience *)
  let map2 f l = map (map f) l in

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
  let len         = Bytes.length                                        in
  let b_tl op n   = Bytes.sub op n (len op - n)                         in
  let b_hd op n   = Bytes.sub op 0 n                                    in
  let asbtol a i  = Array.to_list (Array.sub a i (Array.length a - i))  in 

  (* Main *)
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
    let raw = Runtime'.Reader.create bytes in
    IR.from_proto raw
  in
  let ir =
    match gtirb with
    | Ok a    -> a
    | Error e -> failwith (Printf.sprintf "%s%s" "Could not reply request: " (Ocaml_protoc_plugin.Result.show_error e))
  in
  let modules = ir.modules in
  let ival_blks =
    let all_sects = map (fun (m : Module.t) -> m.sections) modules                          in
    let all_texts = map (filter (fun (s : Section.t) -> s.name = text)) all_sects           in
    let intervals = map2 (fun (s : Section.t) -> s.byte_intervals) all_texts |> map flatten in
    map2 (fun (i : ByteInterval.t)
      -> map (fun b -> {block = b; raw = i.contents; address = i.address}) i.blocks) intervals
      |> map flatten
  in

  (* Resolve polymorphic block variants to isolate info we actually care about *)
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
  
  (* Section up byte interval contents to their respective blocks and slice out individual opcodes *)
  let op_cuts   =
    let trimmed = map2 (fun b -> {b with contents = Bytes.sub b.contents b.offset b.size}) codes_only in
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
      if len opcode = 1 then opcode
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
    let prel    = Sys.argv.(prelude_ind)                                in
    let specs   = asbtol Sys.argv specs_start                           in
    let prelude = LoadASL.read_file prel true false                     in
    let mra     = map (fun t -> LoadASL.read_file t false false) specs  in
    concat (prelude :: mra)
  in

  (* Evaluate each opcode one by one with a new environment for each *)
  let to_asli op addr =
    let address = Some (string_of_int addr)                                     in
    let env     = Eval.build_evaluation_environment envinfo                     in
    let str     = hex ^ Hexstring.encode op                                     in 
    let res     = Dis.retrieveDisassembly ?address env str                      in
    let ascii   = map Asl_utils.pp_stmt res                                     in
    let indiv s = init (String.length s) (String.get s) |> map (String.make 1)  in
    let no_nl s = map (fun l -> if l = newline then space else l) s             in
    let trimmed = map String.trim ascii                                         in
    let joined  = map indiv trimmed |> map no_nl |> map (String.concat "")      in
    map (fun s -> strung ^ s ^ strung) joined
  in
  let rec asts opcodes addr envinfo =
    match opcodes with
    | []      -> []
    | h :: t  -> (to_asli h addr) :: (asts t (addr + opcode_length) envinfo)
  in
  let with_asts = map2 (fun b -> {auuid = b.ruuid; asts = (asts b.opcodes b.address envinfo); concat = ""}) blk_orded in

  (* Now massage asli outputs into a format which can be serialised and then deserialised by other tools *)
  let serialisable =
    let l_to_s op d cl l  = op ^ (String.concat d l) ^ cl                                   in
    let jsoned asts       = map (l_to_s l_op l_dl l_cl) asts |> l_to_s l_op l_dl l_cl       in
    let json_asts = map2 (fun b -> {b with concat = jsoned b.asts}) with_asts               in
    let no_nops   = map (filter (fun b -> String.length b.concat > noplen)) json_asts       in  (* Comparing to [[]] not working?               *)
    let paired    = map2 (fun b -> (Hexstring.encode b.auuid) ^ kv_pair ^ b.concat) no_nops in  (* Ideally this should be base64 instad of hex  *)
    map (l_to_s j_op l_dl j_cl) paired
  in

  (* Finally, sandwich ASTs into the IR amongst the other auxdata *)
  let encoded   =
    let orig_auxes  = map (fun (m : Module.t) -> m.aux_data) modules            in
    let ast_aux j   = ({type_name = ast; data = Bytes.of_string j} : AuxData.t) in
    let new_auxes   = map ast_aux serialisable |> map (fun a -> (ast, a))       in
    let aux_joins   = combine orig_auxes new_auxes                              in
    let full_auxes  = map (fun ((l : (string * AuxData.t option) list), (m, b))
        -> (m, Option.some b) :: l) aux_joins     in
    let mod_joins   = combine modules full_auxes  in
    let mod_fixed   = map (fun ((m : Module.t), a)
        -> {m with aux_data = a}) mod_joins       in
    let out_gtirb = {ir with modules = mod_fixed} in
    let serial    = IR.to_proto out_gtirb         in
  Runtime'.Writer.contents serial
  in

  (* And reserialise to disk *)
  let out = open_out_bin Sys.argv.(out_ind) in
  (
    Printf.fprintf out "%s" encoded;
    close_out out;
  )