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

(* Individual cell in index map generated from collapsing Huffman tree  *)
(* Used in compressing ASLi semantic info outputs                       *)
type translation_block = {
  base  : char;
  rep   : string;
  len   : int;
}

(* Leaf/Node in Huffman tree generated during ASLi semantic info compression *)
type freq_pq =
  | Leaf    of int * char
  | Branch  of int * freq_pq * freq_pq

(* CONSTANTS  *)
(* Argv       *)
let binary_ind    = 1
let prelude_ind   = 2
let mra_ind       = 3
let asli_ind      = 4
let out_ind       = 5
let opcode_length = 4

(* Protobuf spelunking  *)
let ast           = "ast"
let text          = ".text"

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

(* Compression and bit twiddling  *)
let asli_base     = Char.code '"'
let asli_range    = Char.code 'z' - asli_base + 1
let padding       = '0'
let left          = "0"
let right         = "1"
let right_c       = '1'
let right_i       = 1
let left_i        = 0
let rol           = 2
let bsize         = 8

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
    | Error e -> failwith (
        Printf.sprintf "%s%s" "Could not reply request: " (Ocaml_protoc_plugin.Result.show_error e)
      )
  in
  let modules     = ir.modules                in
  let is_text (s : Section.t) = s.name = text in
  let ival_blks   =
    let all_sects = map (fun (m : Module.t) -> m.sections) modules                          in
    let all_texts = map (filter is_text) all_sects                                          in
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
        (* Display Asli outputs as they arrive *)
        print_endline s;
        s
      )
    in
    (* Set up and tear down eval environment for every single instruction *)
    let address = Some (string_of_int addr)                                     in
    let env     = Eval.build_evaluation_environment envinfo                     in
    let str     = hex ^ Hexstring.encode op                                     in 
    let res     = Dis.retrieveDisassembly ?address env str                      in
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
  let serialisable =
    let l_to_s op d cl l  = op ^ (String.concat d l) ^ cl                             in
    let jsoned asts       = map (l_to_s l_op l_dl l_cl) asts |> l_to_s l_op l_dl l_cl in
    let b64 bin   = strung ^ (Bytes.to_string bin |> Base64.encode_exn) ^ strung      in
    let json_asts = map2 (fun b -> {b with concat = jsoned b.asts}) with_asts         in
    let paired    = map2 (fun b -> (b64 b.auuid) ^ kv_pair ^ b.concat) json_asts      in
    map (String.concat l_dl) paired
  in

  (* Sandwich ASTs into the IR amongst the other auxdata *)
  let encoded =
    let pad_8 s =
      let plen = (String.length s) mod 8 in
      if plen = 0
      then ""
      else (String.make (bsize - plen) padding)
    in
    let c_to_b c      = Bytes.make 1 c                                  in
    let i_to_b i      = Char.chr i |> c_to_b                            in
    let orig_auxes    = map (fun (m : Module.t) -> m.aux_data) modules  in
    let compress ast  =
      print_endline ast;
      (* Do some Huffman compression on asli output because it's huge *)
      (* Bless me Father for I have sinned...                         *)
      let base = Array.make asli_range 0 in
      let rec freqs s a =
        (* Determine frequencies of each character  *)
        if String.length s = 0
        then a
        else
          let key = (Char.code s.[0]) - asli_base in 
          (
            Array.set a key (a.(key) + 1);
            freqs (stl s) a
          )
      in
      let ast_freqs = freqs ast base |> Array.to_list in
      let rec add_names freqs i =
        (* Map each character to a Huffman Leaf *)
        match freqs with
        | []      -> []
        | h :: t  -> Leaf(h, Char.chr (i + asli_base)) :: add_names t (i + 1)
      in
      let freq f =
        match f with
        | Leaf(r, _)      -> r
        | Branch(r, _, _) -> r
      in
      (* Order the leaves by frequency *)
      let pq_cmp a b = freq a - freq b                                                          in
      let initial  = add_names ast_freqs 0 |> filter (fun b -> freq b > 0) |> fast_sort pq_cmp  in
      let rec build_huff pq =
        (* Build the frequency tree from the ordered queue *)
        match pq with
        | []      -> []
        | h :: t  -> (
                      match t with
                      | []      -> [h]
                      | g :: u  ->
                          let joined  = Branch((freq h + freq g), h, g) in
                          let added   = fast_sort pq_cmp (joined :: u)  in
                          build_huff added
                     )
      in
      let huff_tree = build_huff initial |> hd in
      let rec collapse tree p =
        (* Collapse the tree into something more easily indexable *)
        match tree with
        | Branch(_, l, r) -> (collapse l (p ^ left)) @ (collapse r (p ^ right))
        | Leaf(_, c)      -> [{base = c; rep = p; len = String.length p}]
      in
      let huff_cmp a b = (Char.code a.base) - (Char.code b.base) in
      let binaried = collapse huff_tree "" |> fast_sort huff_cmp in
      let rec fill_map bins m =
        (* Expand the collapsed tree into an index map *)
        let rec fill_empties l s =
          if length l < s
          then fill_empties (l @ [{base = Char.chr 0; rep = ""; len = 0}]) s
          else l 
        in
        match bins with
        | []      -> m
        | h :: t  ->
          (* Insert empty cells where necessary to make indexing line up right  *)
          let mlen    = length m                      in
          let bin_ind = Char.code h.base - asli_base  in
          let padded  = if mlen < bin_ind
                        then fill_empties m bin_ind
                        else m
          in
          fill_map t (padded @ [h])
      in
      let t_map = fill_map binaried [] in
      let rec binarify compressed remaining =
        (* Using a binary string as an intermediate step because bit twiddling in ocaml is misery *)
        if String.length remaining == 0
        then compressed ^ (pad_8 compressed)
        else (
          let key = Char.code remaining.[0] - asli_base in
          let cell = nth t_map key                      in
          let add = cell.rep                            in
          let n_comp = compressed ^ add                 in
          let n_remaining = stl remaining               in
          binarify n_comp n_remaining
        )
      in
      let binarified = binarify "" ast in
      let rec byte_chunks s =
        (* Chop up intermediate binary string ino chunks of 8 for translation into real bytes *)
        let slen = String.length s in
        if slen = 0
        then []
        else String.sub s 0 bsize :: byte_chunks (String.sub s bsize (slen - bsize))
      in
      let rec byte_join l =
        (* Cat together a byte array into a huge byte string  *)
        match l with
        | []      -> empty
        | h :: t  -> Bytes.cat h (byte_join t)
      in
      let rec bs_to_ui p =
        (* Binary string -> unsigned int *)
        let slen = String.length p in
        let res i = if i.[slen - 1] = right_c
                    then right_i
                    else left_i
        in
        if slen = 1
        then res p
        else rol * bs_to_ui (String.sub p 0 (slen - 1)) + res p
      in
      let bs_to_b s = byte_chunks s |> map bs_to_ui |> map i_to_b |> byte_join in
      let compressed = bs_to_b binarified in
      let rec serialise_map m =
        (* Translate translation blocks into a standard header format *)
        (* ascii_char :: n_bits :: compressed_repr *)
        let bin_rep c = ((pad_8 c.rep) ^ c.rep) |> bs_to_b                                      in
        let serialise_cell c = Bytes.cat (Bytes.cat (c_to_b c.base) (i_to_b c.len)) (bin_rep c) in
        match m with
        | []      -> empty
        | h :: t  -> Bytes.cat (serialise_cell h) (serialise_map t)
      in
      let prefix = Bytes.cat (i_to_b (length binaried)) (serialise_map binaried) in
      Bytes.cat prefix compressed
      (* End result is (no_map_entries :: translation_map_blocks :: compressed_text) *)
    in
    (* Turn the translation map + compressed semantics into auxdata and slide it in with the rest *)
    let ast_aux j   = ({type_name = ast; data = compress j} : AuxData.t)  in
    let new_auxes   = map ast_aux serialisable |> map (fun a -> (ast, a)) in
    let aux_joins   = combine orig_auxes new_auxes                        in
    let full_auxes  = map (fun ((l : (string * AuxData.t option) list), (m, b))
        -> (m, Option.some b) :: l) aux_joins   in
    let mod_joins = combine modules full_auxes  in
    let mod_fixed = map (fun ((m : Module.t), a)
        -> {m with aux_data = a}) mod_joins in
    (* Save some space by deleting all sections except .text, not necessary*)
    let text_only = map (fun (m : Module.t)
        -> {m with sections = filter is_text m.sections}) mod_fixed in
    let new_ir      = {ir with modules = text_only}                 in
    (* Save some more space by deleting IR auxdata, only contains ddisasm version anyways *)
    let out_gtirb   = {new_ir with aux_data = []} in
    let serial      = IR.to_proto out_gtirb       in
    Runtime'.Writer.contents serial
  in

  (* And reserialise to disk *)
  let out = open_out_bin Sys.argv.(out_ind) in
  (
    Printf.fprintf out "%s" encoded;
    close_out out;
  )