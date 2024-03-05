(* from: https://ocaml.org/p/decompress/1.4.0/doc/Gz/Higher/index.html#val-compress *)
let deflate_string ?(level= 4) str =
  let i = De.bigstring_create De.io_buffer_size in
  let o = De.bigstring_create De.io_buffer_size in
  let w = De.Lz77.make_window ~bits:15 in
  let q = De.Queue.create 0x1000 in
  let r = Buffer.create 0x1000 in
  let p = ref 0 in

  let time () = Int32.zero in
  let cfg = Gz.Higher.configuration Gz.Unix time in

  let refill buf =
    let len = min (String.length str - !p) De.io_buffer_size in
    Bigstringaf.blit_from_string str ~src_off:!p buf ~dst_off:0 ~len ;
    p := !p + len ; len in
  let flush buf len =
    let str = Bigstringaf.substring buf ~off:0 ~len in
    Buffer.add_string r str in

  Gz.Higher.compress ~w ~q ~level ~refill ~flush () cfg i o;
  Buffer.contents r