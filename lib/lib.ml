open Lifter
open Gtirb_modules.All

let opcode_length = 4

type content_block = { block : Block.t; raw : bytes; address : int }
(** Block containing raw byte interval, with address adjusted to absolute
    address *)

type rectified_block = {
  ruuid : bytes;
  contents : bytes;
  opcodes : bytes list;
  address : int;
  size : int;
}
(** A block / byte interval split into discrete i32 opcodes. *)

let b64_of_uuid uuid = Base64.encode_exn (Bytes.to_string uuid)

let fold_opcode_list_with_address address ops lift =
  snd
  @@ List.fold_left_map
       (fun i op ->
         (i + opcode_length, lift i (Opcode.of_be_bytes (String.of_bytes op))))
       address ops

let fold_rectified_block_with_address (r : rectified_block) lift =
  fold_opcode_list_with_address r.address r.opcodes lift

let rectify_block ~(byte_order : [> `LittleEndian | `BigEndian ])
    (content_block : content_block) (code_block : CodeBlock.t) : rectified_block
    =
  let endian_reverse (opcode : bytes) : bytes =
    let len = Bytes.length opcode in
    let getrev i = Bytes.get opcode (len - 1 - i) in
    Bytes.init len getrev
  in

  let need_flip =
    match byte_order with `LittleEndian -> true | `BigEndian -> false
  in
  let cut_op contents i =
    let bytes = Bytes.sub contents (i * opcode_length) opcode_length in
    if need_flip then endian_reverse bytes else bytes
  in

  let size = code_block.size in
  let ruuid = code_block.uuid in
  let address = content_block.address in
  let num_opcodes = code_block.size / opcode_length in
  if size <> num_opcodes * opcode_length then
    Printf.eprintf "block size is not a multiple of opcode size (size %d): %s\n"
      size (b64_of_uuid ruuid);

  let contents = Bytes.sub content_block.raw content_block.block.offset size in
  let opcodes = List.init num_opcodes (cut_op contents) in

  { size; ruuid; contents; opcodes; address }

(** Extrect the code blocks from a module and convert them to rectified_blocks
    of absolute-addressed opcode sequences. *)
let code_blocks_of_module (m : Module.t) =
  let content_block (i : ByteInterval.t) (b : Block.t) : content_block =
    { block = b; raw = i.contents; address = i.address + b.offset }
  in
  let byte_order =
    match m.byte_order with
    | ByteOrder.LittleEndian -> `LittleEndian
    | ByteOrder.BigEndian -> `BigEndian
    | ByteOrder.ByteOrder_Undefined -> `BigEndian
  in
  m.sections
  |> List.concat_map (fun (s : Section.t) -> s.byte_intervals)
  |> List.concat_map (fun i ->
         List.filter_map
           (fun (b : Block.t) ->
             match b.value with
             | `Code c -> Some (content_block i b, c)
             | _ -> None)
           i.blocks)
  |> List.map (fun (cb, cod) -> rectify_block ~byte_order cb cod)
