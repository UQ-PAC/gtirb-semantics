(** decoding support for GTIRB's sanctioned auxdata formats. *)

(*
see: https://github.com/UQ-PAC/bil-to-boogie-translator/blob/main/src/main/scala/gtirb/MapDecoder.scala
https://grammatech.github.io/gtirb/python/_modules/gtirb/serialization.html#MappingCodec.decode
*)

(** full string and current position in byte string. *)
type input = {
  bytes: bytes;
  offset: int;
}

type 'a result = 'a * input
type 'a parser = input -> 'a result

let read (size: int) (x: input) : bytes result =
  let data = Bytes.sub x.bytes x.offset size in
  (* Printf.printf "offset=%d\n" x.offset;
  let bt = Printexc.get_callstack 3 in
  Printexc.print_raw_backtrace stdout bt; *)
  (data, {x with offset = x.offset + size})

let ref_decoder (f: 'a parser) (x: input ref) : 'a =
  let (k,x') = f !x in
  x := x';
  k


let uuid_decoder = read 16

let int64_decoder (x: input) : Int64.t result =
  let (b, x) = read 8 x in
  (Bytes.get_int64_le b 0, x)

let set_decoder (value: 'a parser) (x: input) : 'a list result =
  let (n, x) = int64_decoder x in
  let x = ref x in (* XXX no monads *)
  (* Printf.printf "offset=%d, %Lu\n" !x.offset n; *)
  let ret = List.init (Int64.to_int n) (fun _ -> ref_decoder value x) in
  ret, !x
  (* WARNING! tuple construction does not introduce a sequence point. *)

let map_decoder (key: 'k parser) (value: 'v parser) (x: input) : ('k * 'v) list result =
  let (n, x) = int64_decoder x in
  let x = ref x in (* XXX no monads *)
  (* Printf.printf "offset=%d, %Lu\n" !x.offset n; *)
  let ret = List.init (Int64.to_int n)
    (fun _ ->
      let k = ref_decoder key x in
      let v = ref_decoder value x in
      (k, v)) in
  ret, !x

let decode (f: 'a parser) bytes : 'a =
  print_endline "boop";
  let (result, inp) = f { bytes; offset = 0; } in
  assert (inp.offset == Bytes.length bytes);
  (* Printf.printf "%d -- %d\n" (inp.offset) (Bytes.length bytes); *)
  result

let decode_map_uuid_uuid : bytes -> (bytes * bytes) list =
  decode (map_decoder uuid_decoder uuid_decoder)

let decode_map_uuid_uuid_set : bytes -> (bytes * bytes list) list =
  decode (map_decoder uuid_decoder (set_decoder uuid_decoder))


