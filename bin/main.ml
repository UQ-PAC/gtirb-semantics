module OcamlResult = Result

open Ocaml_protoc_plugin
open Gtirb_semantics.IR.Gtirb.Proto
open Gtirb_semantics.ByteInterval.Gtirb.Proto
open Gtirb_semantics.Module.Gtirb.Proto
open Gtirb_semantics.Section.Gtirb.Proto
open Gtirb_semantics.CodeBlock.Gtirb.Proto
open Gtirb_semantics.AuxData.Gtirb.Proto
open LibASL

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


type dis_error = {
  opcode: string;
  error: string
}


type opcode_sem = ((string list, dis_error) result)

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
let client = ref true
let shutdown_server = ref false
let speclist = [
  ("--json", Arg.Set_string json_file, "output json semantics to given file (default: none, use /dev/stderr for stderr)");
  ("--serve", Arg.Set serve, "Start server process (in foreground)"); 
  ("--local", Arg.Clear client, "Do not use client to server"); 
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

module Rpc = struct

  let message_count = ref 0

  let sockfpath = match (Sys.getenv_opt "GTIRB_SEM_SOCKET") with 
      | Some x -> (x)
      | None -> ("gtirb_semantics_socket")


  let sockaddr = Lwt_unix.ADDR_UNIX sockfpath

  type msg_call = 
    | Shutdown 
    | Lift of {addr: int; opcode_be: string}
    | LiftAll of (string * int) list

  type msg_resp = 
    | Ok of opcode_sem
    | All of opcode_sem list

end


module InsnLifter = struct 

  module DisCache = Lru_cache.Make (struct
    open! Core.Bytes
    open Core
    open! Lru_cache
    type t = (string * int) [@@deriving compare, hash, sexp_of]
        let invariant = ignore
    end)


  let disas_cache : ((string list, dis_error) result) DisCache.t = DisCache.create ~max_size:5000 ()

  (* number of cache misses *)
  let decode_instr_success = ref 0
  (* number of serviced decode requests*)
  let decode_instr_total = ref 0
  (* number of errors *)
  let decode_instr_fail = ref 0



  let env = lazy begin
    match Arm_env.aarch64_evaluation_environment () with
    | Some e -> e
    | None -> Printf.eprintf "unable to load bundled asl files. has aslp been installed correctly?"; exit 1
  end


  let to_asli_impl (opcode_be: string) (addr : int) : ((string list, dis_error) result) =
    let p_raw a = Utils.to_string (Asl_parser_pp.pp_raw_stmt a) |> String.trim    in
    let p_pretty a = Asl_utils.pp_stmt a |> String.trim                           in
    let p_byte (b: char) = Printf.sprintf "%02X" (Char.code b)                    in
    let address = Some (string_of_int addr)                                       in

    (* below, opnum is the numeric opcode (necessarily BE) and opcode_* are always LE. *)
    (* TODO: change argument of to_asli to follow this convention. *)
    let opnum = Int32.to_int String.(get_int32_be opcode_be 0)                    in
    let opnum_str = Printf.sprintf "0x%08lx" Int32.(of_int opnum)                 in

    let opcode_list : char list = List.(rev @@ of_seq @@ String.to_seq opcode_be) in
    let opcode_str = String.concat " " List.(map p_byte opcode_list)              in
    let _opcode : bytes = Bytes.of_seq List.(to_seq opcode_list)                  in

    let do_dis () : ((string list * string list), dis_error) result =
      (match Dis.retrieveDisassembly ?address (Lazy.force env) (Dis.build_env (Lazy.force env)) opnum_str with
      | res -> 
          decode_instr_success := !decode_instr_success + 1 ; 
          Ok (List.map p_raw res, List.map p_pretty res)
      | exception exc ->
        Printf.eprintf
          "error during aslp disassembly (unsupported opcode %s, bytes %s):\n\nException : %s\n"
          opnum_str opcode_str (Printexc.to_string exc);
          decode_instr_fail := !decode_instr_fail + 1 ; 
          (* Printexc.print_backtrace stderr; *)
          Error {
            opcode =  opnum_str;
            error = (Printexc.to_string exc)
          }
      )
    in Result.map fst (do_dis ())

  let to_asli ?(cache=true) (opcode_be: string) (addr : int) : ((string list, dis_error) result) =
    if cache then (
    let k : (string * int) = (opcode_be, addr) in 
    DisCache.find_or_add disas_cache k ~default:(fun () -> to_asli_impl opcode_be addr)
    ) else (to_asli_impl opcode_be addr)

end


module Server = struct 

  let shutdown = ref false

  let rec respond (ic: Lwt_io.input_channel)  (oc:Lwt_io.output_channel) : unit Lwt.t = 

    let stop () = 
      let* () = Lwt_io.close ic in
      let* () = Lwt_io.close oc in
      Lwt.return ()
    in
    if (Lwt_io.is_closed ic || Lwt_io.is_closed oc || !shutdown) 
    then stop ()
    else 
      let* r: Rpc.msg_call = Lwt.catch (fun () -> Lwt_io.read_value ic) (function
      | exn -> 
          let* () = stop () in
          Lwt.fail exn 
      )
      in
      Rpc.message_count := !Rpc.message_count + 1 ;
      let* () = match r with
        | Shutdown ->
          shutdown := true ;
          stop () 
        | Lift {addr; opcode_be} ->  
          let lifted : opcode_sem = InsnLifter.to_asli opcode_be addr  in
          let resp : Rpc.msg_resp = Ok lifted in
          Lwt_io.write_value oc resp
        | LiftAll (ops) -> 
          let lifted = List.map (fun (op, addr) -> InsnLifter.to_asli op addr) ops in
          let resp : Rpc.msg_resp = All lifted in
          Lwt_io.write_value oc resp
      in 
      respond ic oc

  and handle_conn (addr: Lwt_unix.sockaddr) ((ic: Lwt_io.input_channel) , (oc:Lwt_io.output_channel)) = 
    Lwt.catch (fun () -> respond ic oc) (function 
      | End_of_file -> (let* () = Lwt_io.close ic in let* () = Lwt_io.close oc; in Lwt.return ())
      | x -> Lwt_io.printf "%s" (Printexc.to_string x)
      )


  let server = lazy (Lwt_io.establish_server_with_client_address Rpc.sockaddr handle_conn)


  let rec run_server () = 
    if !shutdown 
    then 
      Lwt.return () 
    else 
      let* () = Lwt_io.printf "Decoded %d instructions  (%d failure) (%f cache hit rate) (%d messages)\n"
      !InsnLifter.decode_instr_success !InsnLifter.decode_instr_fail (InsnLifter.DisCache.hit_rate InsnLifter.disas_cache) !Rpc.message_count
      in
      let* () = Lwt_unix.sleep 5.0 in
      run_server ()

  let start_server () = 
    let start = 
      let* _ = Lwt.return (
        let* r  = Lwt.return (Lazy.force InsnLifter.env) in
        let* m = Lwt.return ((Mtime.Span.to_float_ns (Mtime_clock.elapsed ())) /. 1000000000.0) in
        Lwt_io.printf "Initialiesd lifter environment in %f seconds\n" m
        ) in
      let* s = Lazy.force server in
      let* _ = Lwt_io.printf "Serving on domain socket GTIRB_SEM_SOCKET=%s\n" Rpc.sockfpath in

      Lwt_unix.on_signal
      Sys.sigint
        (fun _ ->  exit 0)
      |> ignore;

      Lwt_main.at_exit (fun () -> begin
      print_endline "shutdown server" ;
        (Lwt_io.shutdown_server s)
      end
      );
      (run_server ())
    in Lwt_main.run start

end

module Client = struct
  open Lwt

  let connection = lazy ( Lwt_io.open_connection Rpc.sockaddr )

  let cin () = let* (ic,oc) = Lazy.force connection in 
      if (Lwt_io.is_closed ic) then (failwith "connection (in) closed") ;
      return ic
  let cout () = let* (ic,oc) = Lazy.force connection in 
      if (Lwt_io.is_closed oc) then (failwith "connection (out) closed") ;
      return oc

  let shutdown_server () = 
    let* cout = cout () in
    let m : Rpc.msg_call = Shutdown in
    Lwt_io.write_value cout m

  let lift (opcode_be: string) (addr : int) = 
    let* cout = cout()  in
    let* cin = cin() in
    let cm : Rpc.msg_call = Lift {opcode_be; addr} in
    let*() = Lwt_io.write_value cout cm in
    let* resp : Rpc.msg_resp = Lwt_io.read_value cin  in
    match resp with 
      | Ok x -> return x
      | All x -> Lwt.fail_with "did not expect multi response"

  let lift_one (opcode_be: string) (addr : int) = 
    Lwt_main.run (lift opcode_be addr)

  let lift_multi (opcodes: (string * int) list) : opcode_sem list Lwt.t = 
    let* lift_m = 
      let* cout = cout() in let* cin = cin() in
      let cm : Rpc.msg_call = LiftAll opcodes in
      let*() = Lwt_io.write_value cout cm in
      let* resp : Rpc.msg_resp = Lwt_io.read_value cin  in
      match resp with 
        | All x -> return x
        | Ok x -> return [x]
      in 
    let* _ = Lwt_list.iter_s (function 
      | Ok x -> InsnLifter.decode_instr_success := !InsnLifter.decode_instr_success + 1; Lwt.return () ;
      | Error ({opcode; error}) -> (
        InsnLifter.decode_instr_fail := !InsnLifter.decode_instr_fail + 1; 
        Lwt_io.printf "Lift error : %s :: %s\n"  opcode error;
      )
      ) lift_m
    in
    return lift_m
end

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

  let rec ops opcodes addr =
    match opcodes with
    | []      -> []
    | h :: t  -> ((String.of_bytes h), addr) :: (ops t (addr + opcode_length))
  in
  let asts opcodes addr = if (!client) then (Client.lift_multi (ops opcodes addr))
  else begin
    let rec getasts opcodes addr =
      match opcodes with
      | []      -> []
      | h :: t  -> (InsnLifter.to_asli (String.of_bytes h) addr) :: (getasts t (addr + opcode_length))
    in Lwt.return @@ getasts opcodes addr
  end
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
        | Error err -> `Assoc [
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
    Printf.printf "Lifted %d instructions in %f sec (%f user time) (%d failure) (%f cache hit rate)\n"
      !InsnLifter.decode_instr_success time_delta usr_time_delta !InsnLifter.decode_instr_fail (InsnLifter.DisCache.hit_rate InsnLifter.disas_cache)


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



