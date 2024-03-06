(** decoding support for GTIRB's sanctioned auxdata formats. *)

(*
see: https://github.com/UQ-PAC/bil-to-boogie-translator/blob/main/src/main/scala/gtirb/MapDecoder.scala
https://grammatech.github.io/gtirb/python/_modules/gtirb/serialization.html#MappingCodec.decode
*)


module Slice = CCParse.Slice

module CCParse = struct
  include CCParse

  let rec count (n: int) (p: 'a t) : 'a list t =
    if n < 0 then
      raise (Invalid_argument "count parser negative counts");
    if n == 0 then pure []
    else
      let* x = p in
      map (CCList.cons x) (count (n-1) p)
end

open CCFun.Infix
open CCParse.Infix
type 'a parser = 'a CCParse.t


module Uuid = struct
  type t = UuidInternal of string

  let compare (UuidInternal a) (UuidInternal b) = String.compare a b
  let equal (UuidInternal a) (UuidInternal b) = String.equal a b

  (** Constructs a Uuid from a string of bytes. Note: the string should contain raw bytes, not encoded into base64. *)
  let of_string : string -> t = fun x -> UuidInternal x

  (** Constructs a Uuid from bytes. *)
  let of_bytes : bytes -> t = fun x -> UuidInternal (Bytes.to_string x)
  let to_string (UuidInternal x) = x
  let to_bytes (UuidInternal x) = Bytes.of_string x
  let to_base64 (UuidInternal x) = Base64.encode_exn x

  let pp p x = Format.pp_print_string p (to_base64 x)
end

module UuidSet = struct 
  include CCSet.Make(Uuid)
  (* let pp ?(pp_start:unit CCSet.printer option) ?(pp_stop:unit CCSet.printer option) ?(pp_sep:unit CCSet.printer option) : Uuid.t CCSet.printer -> t CCSet.printer = 
    let l = CCFormat.const_string "{" in
    let r = CCFormat.const_string "}" in
    fun p -> pp ~pp_start:Option.(value pp_start ~default:l) ~pp_stop:Option.(value pp_stop ~default:r) ?pp_sep p *)
end
module UuidMap = CCMap.Make(Uuid)


(* let read (size: int) (x: input) : bytes result =
  let data = Bytes.sub x.bytes x.offset size in
  (* Printf.printf "offset=%d\n" x.offset;
  let bt = Printexc.get_callstack 3 in
  Printexc.print_raw_backtrace stdout bt; *)
  (data, {x with offset = x.offset + size})

let ref_decoder (f: 'a parser) (x: input ref) : 'a =
  let (k,x') = f !x in
  x := x';
  k *)


let uuid_decoder =
  let+ slice = CCParse.take 16 in
  let str = Slice.to_string slice in
  Uuid.of_string str

let int64_decoder : Int64.t parser =
  let+ b = CCParse.take 8 in
  CCString.get_int64_le (Slice.to_string b) 0

let set_decoder (value: 'a parser)  : 'a list parser =
  let* n = int64_decoder in
  CCParse.count (Int64.to_int n) value

let map_decoder (key: 'k parser) (value: 'v parser) : ('k * 'v) list parser =
  let* n = int64_decoder in
  CCParse.count (Int64.to_int n) (CCParse.both key value)

let decode (f: 'a parser) bytes : 'a =
  match CCParse.parse_string_e (f <* CCParse.eoi) (Bytes.to_string bytes) with
  | Ok x -> x
  | Error e ->
    let open CCParse.Error in
    let (line,col) = line_and_column e in
    failwith (Printf.sprintf "%s @ line %d, col %d" (msg e) line col)

let decode_map_uuid_uuid : bytes -> Uuid.t UuidMap.t =
  UuidMap.of_list % decode (map_decoder uuid_decoder uuid_decoder)

let decode_map_uuid_uuid_set : bytes -> UuidSet.t UuidMap.t =
  let make = UuidMap.map UuidSet.of_list % UuidMap.of_list in
  make % decode (map_decoder uuid_decoder (set_decoder uuid_decoder))


