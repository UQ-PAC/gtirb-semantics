module OcamlResult = Result

open Ocaml_protoc_plugin
open Gtirb_semantics.IR.Gtirb.Proto
open Gtirb_semantics.ByteInterval.Gtirb.Proto
open Gtirb_semantics.Module.Gtirb.Proto
open Gtirb_semantics.Section.Gtirb.Proto
open Gtirb_semantics.CodeBlock.Gtirb.Proto
open Gtirb_semantics.AuxData.Gtirb.Proto
open Aslp_common.Common

module Result = OcamlResult

(* TYPES  *)

let () = Printexc.record_backtrace true
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
  asts    : opcode_sem list;
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
let serve = ref false
let client = ref false
let offline = ref false
let shutdown_server = ref false
let speclist = [
  ("--json", Arg.Set_string json_file, "output json semantics to given file (default: none, use /dev/stderr for stderr)");
  ("--serve", Arg.Set serve, "Start server process (in foreground)"); 
  ("--client", Arg.Set client, "Use client to server"); 
  ("--offline", Arg.Set offline, "Use offline lifter (implies --local)"); 
  ("--shutdown-server", Arg.Set shutdown_server, "Stop server process"); 
]
let count_pos_args = ref (0)
let in_file = ref "/nowhere/input"
let out_file = ref "/nowhere/output"
let handle_rest_arg arg =
  count_pos_args := 1 + !count_pos_args;
  match !count_pos_args with
  | 1 -> in_file := arg
  | 2 -> out_file := arg
  | _ -> ()

let usage_string  = "[options] [input.gtirb output.gts]"
let usage_message = Printf.sprintf "usage: %s %s\n" Sys.argv.(0) usage_string

let mode () = match (!client, !offline) with
    | _, true -> `LocalOffline
    | true, false -> `Client
    | false, false -> `LocalOnline

(* ASL specifications are from the bundled ARM semantics in libASL. *)

(* Protobuf spelunking  *)
(*let text          = ".text"*)

(* Byte & array manipulation convenience functions *)
let _b_tl op n   = Bytes.sub op n (Bytes.length op - n)
let _b_hd op n   = Bytes.sub op 0 n

let b64_of_uuid uuid = Base64.encode_exn (Bytes.to_string uuid)

let endian_reverse (opcode: bytes): bytes = 
  let len = Bytes.length opcode in
  let getrev i = Bytes.get opcode (len - 1 - i) in
  Bytes.init len getrev


let do_block ~(need_flip: bool) (b, c : content_block * CodeBlock.t): rectified_block =
  let cut_op contents i =
    let bytes = Bytes.sub contents (i * opcode_length) opcode_length in
    if need_flip then endian_reverse bytes else bytes in

  let size = c.size in
  let offset = b.block.offset in
  let ruuid = c.uuid in
  let address = b.address in
  let num_opcodes = c.size / opcode_length in
  if (size <> num_opcodes * opcode_length) then
    Printf.eprintf "block size is not a multiple of opcode size (size %d): %s\n" size (b64_of_uuid ruuid);

  let contents = Bytes.sub b.raw offset size in
  let opcodes = List.init num_opcodes (cut_op contents) in

  { size; offset; ruuid; contents; opcodes; address }
  
let (let*) = Lwt.bind

let do_module (m: Module.t): Module.t Lwt.t = 

  let all_sects = m.sections in
  let intervals = List.flatten @@ List.map (fun (s : Section.t) -> s.byte_intervals) all_sects in

  let content_block (i: ByteInterval.t) (b: Block.t) =
    {block = b; raw = i.contents; address = i.address} in

  let ival_blks : content_block list =
    List.flatten @@ List.map (fun i -> List.map (fun b -> content_block i b) i.blocks) intervals in

  (* Resolve polymorphic block variants to filter only code blocks *)
  let extract_code (b : content_block) = match b.block.value with
      | `Code (c : CodeBlock.t) -> Some (b, c)
      | _                       -> None in

  let cblocks = List.filter_map extract_code ival_blks in

  let need_flip = m.byte_order = ByteOrder.LittleEndian in
  let rblocks = List.map (do_block ~need_flip) cblocks in 


  (* Evaluate each instruction one by one with a new environment for each *)

  let rec lift_online_local (opcodes : bytes list) (addr : int) =
    match opcodes with
    | []      -> []
    | h :: t  -> (Server.lift_opcode ~cache:true ~opcode_be:(String.of_bytes h) addr) :: (lift_online_local t (addr + opcode_length))
  in 

  let lift_offline_local (opcodes:bytes list) (addr: int) = 
    let lift_one_offline (op: bytes) (addr: int) = 
      Server.lift_opcode_offline_lifter ~opcode_be:(String.of_bytes op) addr
    in
    let with_addrs = List.mapi (fun i op -> (op, addr + (i * opcode_length))) opcodes in
    let res = List.map (fun (opcode,addr) -> lift_one_offline opcode addr) with_addrs in
    res
  in
  let rec ops opcodes addr =
    match opcodes with
    | []      -> []
    | h :: t  -> ((String.of_bytes h), addr) :: (ops t (addr + opcode_length))
  in
  let asts opcodes addr = match (mode()) with 
    | `Client -> (Client.lift_multi ~opcodes:(ops opcodes addr))
    | `LocalOnline -> Lwt.return @@ lift_online_local opcodes addr
    | `LocalOffline -> Lwt.return @@ lift_offline_local opcodes addr
  in

  (*
   let map' f l =
    if List.length blk_orded > 10000
      then Parmap.parmap ~ncores:2 f Parmap.(L l)
      else map f l in *)
  let* with_asts = Lwt_list.map_p (fun b -> 
    let* asts = asts b.opcodes b.address in
    Lwt.return {
      auuid   = b.ruuid;
      asts    = asts; 
    }) rblocks
  in

  (* Massage asli outputs into a format which can
     be serialised and then deserialised by other tools  *)
  let serialisable: string =
    let to_list x = `List x in
    let to_string x = `String x in
    let jsoned (asts: (string list, dis_error) result list) : Yojson.Safe.t =
      let toj (x: (string list, dis_error) result) : Yojson.Safe.t = match x with
        | Ok sl -> to_list @@ List.map to_string sl
        | Error err -> 
          (match mode () with 
          | `Client -> Printf.eprintf "Decode error on op %s: %s\n" err.opcode err.error
          | _ -> ());
          `Assoc [
          ("decode_error", `Assoc [("opcode", (`String err.opcode)); ("error", `String err.error)] )
        ]
      in
      to_list @@ List.map toj asts in 

    let paired: Yojson.Safe.t =
      `Assoc (
        List.map
          (fun (b: ast_block) -> (b64_of_uuid b.auuid, jsoned b.asts))
          with_asts) in

    let json_str = Yojson.Safe.to_string paired in
    if !json_file <> "" then begin
      let f = open_out !json_file in
      output_string f json_str;
      close_out f
    end;
    json_str
  in 

  (* Sandwich ASTs into the IR amongst the other auxdata *)
  let aux_key      = "ast" in
  (* Omit ast auxdata if it already exists. *)
  let orig_auxes   = List.filter (fun (k, _) -> k <> aux_key) m.aux_data in
  (* Turn the translation map + compressed semantics into auxdata and slide it in with the rest *)
  let ast_aux data = AuxData.make ?type_name:(Some aux_key) ?data:(Some (Bytes.of_string data)) () in
  let new_aux      = ast_aux serialisable in
  let full_auxes   = (aux_key, Some new_aux) :: orig_auxes in
  let mod_fixed    = {m with aux_data = full_auxes} in
  Lwt.return mod_fixed


let gtirb_to_gts () : unit = 
  let bt = Sys.time() in
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

  let modules'    = Lwt_main.run @@ Lwt_list.map_p do_module ir.modules in
  let new_ir      = {ir with modules = modules'}  in
  let serial      = IR.to_proto new_ir            in
  let encoded     = Writer.contents serial        in

  (* Reserialise to disk *)
  let out = open_out_bin !out_file in
    output_string out encoded;
    close_out out;
    let et = Sys.time () in
    let usr_time_delta = et -. bt in
    let time_delta = Float.div (Mtime.Span.to_float_ns (Mtime_clock.elapsed ())) (1000000000.0) in
    if (not !client) then 
      let stats = Server.get_local_lifter_stats () in
      let oc = if (stats.fail > 0) then stderr else stdout in
      Printf.fprintf oc "Lifted %d instructions in %f sec (%f user time) (%d failure) (%f cache hit rate)\n"
      stats.success time_delta usr_time_delta (stats.fail) (stats.cache_hit_rate)


(*  MAIN  *)
let () =
  (* BEGINNING *)
  Arg.parse speclist handle_rest_arg usage_message;
  (* Printf.eprintf "gtirb-semantics: %s -> %s\n" !in_file !out_file; *)
  if (not !serve) && (not !shutdown_server) && !count_pos_args <> 2 then
    (output_string stderr usage_message; exit 1);

  if (!shutdown_server) then begin
    Lwt_main.run @@ Client.shutdown_server ()
  end
  else 
  if (!serve) then begin
    Server.start_server ()
  end else begin
    output_string stdout "Lifting\n" ;
    gtirb_to_gts ()
  end



