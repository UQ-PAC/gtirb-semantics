module OcamlResult = Result
open Ocaml_protoc_plugin
open Gtirb_semantics.Lib
open Gtirb_modules.All
module Result = OcamlResult
open Lifter
open Aslp_common.Common

(* TYPES  *)

let () = Printexc.record_backtrace true

(* ASLi semantic info for a block *)
type ast_block = { auuid : bytes; asts : opcode_sem list }

(* flags *)
let json_file = ref ""
let serve = ref false
let no_timer = ref false
let client = ref false
let offline = ref false
let shutdown_server = ref false

let speclist =
  [
    ( "--json",
      Arg.Set_string json_file,
      "output json semantics to given file (default: none, use /dev/stderr for \
       stderr)" );
    ("--serve", Arg.Set serve, "Start server process (in foreground)");
    ("--client", Arg.Set client, "Use client to server");
    ("--offline", Arg.Set offline, "Use offline lifter (implies --local)");
    ("--shutdown-server", Arg.Set shutdown_server, "Stop server process");
    ("--no-time", Arg.Set no_timer, "Don't show time elapsed on termination.");
  ]

let count_pos_args = ref 0
let in_file = ref "/nowhere/input"
let out_file = ref "/nowhere/output"

let handle_rest_arg arg =
  count_pos_args := 1 + !count_pos_args;
  match !count_pos_args with
  | 1 -> in_file := arg
  | 2 -> out_file := arg
  | _ -> ()

let usage_string = "[options] [input.gtirb output.gts]"
let usage_message = Printf.sprintf "usage: %s %s\n" Sys.argv.(0) usage_string

let mode =
  lazy
    (match (!client, !offline) with
    | _, true -> `LocalOffline
    | true, false -> `Client (Client.connect ())
    | false, false -> `LocalOnline)

(* ASL specifications are from the bundled ARM semantics in libASL. *)

(* Protobuf spelunking  *)
(*let text          = ".text"*)

(* Byte & array manipulation convenience functions *)
let _b_tl op n = Bytes.sub op n (Bytes.length op - n)
let _b_hd op n = Bytes.sub op 0 n
let ( let* ) = Lwt.bind

let do_module (m : Module.t) : Module.t Lwt.t =
  let rectified = code_blocks_of_module m in

  let to_result opcode x : opcode_sem =
    x
    |> Result.map (List.map asl_stmt_to_string)
    |> Result.map_error (fun error -> { opcode; error })
  in

  (* Evaluate each instruction one by one with a new environment for each *)
  let asts (b : rectified_block) =
    let lift_local
        (lifter :
          ?address:int -> int32 -> (LibASL.Asl_ast.stmt list, string) result) =
      function
      | address, opcode ->
          lifter ~address opcode |> to_result (Opcode.to_hex_string opcode)
    in
    match Lazy.force mode with
    | `Client c ->
        let ops =
          opcodes_zipped_with_address b
          |> List.map (function addr, op -> (Opcode.to_be_bytes op, addr))
        in
        Lwt.bind c (fun c -> Client.lift_multi c ~opcodes:ops)
    | `LocalOnline ->
        Lwt.return
        @@ (opcodes_zipped_with_address b
           |> List.map (lift_local CachedOnlineLifter.lift))
    | `LocalOffline ->
        Lwt.return
        @@ (opcodes_zipped_with_address b
           |> List.map (lift_local OfflineLifter.lift))
  in

  let* with_asts =
    Lwt_list.map_p
      (fun b ->
        let* asts = asts b in
        Lwt.return { auuid = b.ruuid; asts })
      rectified
  in

  (* Massage asli outputs into a format which can
     be serialised and then deserialised by other tools  *)
  let serialisable : string =
    let to_list x = `List x in
    let to_string x = `String x in
    let jsoned (asts : (string list, dis_error) result list) : Yojson.Safe.t =
      let toj (x : (string list, dis_error) result) : Yojson.Safe.t =
        match x with
        | Ok sl -> to_list @@ List.map to_string sl
        | Error err ->
            (match Lazy.force mode with
            | `Client _ ->
                Printf.eprintf "Decode error on op %s: %s\n" err.opcode
                  err.error
            | _ -> ());
            `Assoc
              [
                ( "decode_error",
                  `Assoc
                    [
                      ("opcode", `String err.opcode);
                      ("error", `String err.error);
                    ] );
              ]
      in
      to_list @@ List.map toj asts
    in

    let paired : Yojson.Safe.t =
      `Assoc
        (List.map
           (fun (b : ast_block) -> (b64_of_uuid b.auuid, jsoned b.asts))
           with_asts)
    in

    let json_str = Yojson.Safe.pretty_to_string paired in
    if !json_file <> "" then (
      let f = open_out !json_file in
      output_string f json_str;
      close_out f);
    json_str
  in

  (* Sandwich ASTs into the IR amongst the other auxdata *)
  let aux_key = "ast" in
  (* Omit ast auxdata if it already exists. *)
  let orig_auxes = List.filter (fun (k, _) -> k <> aux_key) m.aux_data in
  (* Turn the translation map + compressed semantics into auxdata and slide it in with the rest *)
  let ast_aux data =
    AuxData.make ?type_name:(Some aux_key)
      ?data:(Some (Bytes.of_string data))
      ()
  in
  let new_aux = ast_aux serialisable in
  let full_auxes = (aux_key, Some new_aux) :: orig_auxes in
  let mod_fixed = { m with aux_data = full_auxes } in
  Lwt.return mod_fixed

let gtirb_to_gts () : unit =
  let bt = Sys.time () in
  (* Read bytes from the file, skip first 8 *)
  let bytes =
    let ic = open_in_bin !in_file in
    let len = in_channel_length ic in
    let magic = really_input_string ic 8 in
    let res = really_input_string ic (len - 8) in
    (* check for gtirb magic otherwise assume is raw protobuf *)
    let res =
      if String.starts_with ~prefix:"GTIRB" magic then res else magic ^ res
    in
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
    | Ok a -> a
    | Error e ->
        failwith
          (Printf.sprintf "%s%s" "Could not reply request: "
             (Ocaml_protoc_plugin.Result.show_error e))
  in

  let modules' = Lwt_main.run @@ Lwt_list.map_p do_module ir.modules in
  let new_ir = { ir with modules = modules' } in
  let serial = IR.to_proto new_ir in
  let encoded = Writer.contents serial in

  (* Reserialise to disk *)
  let out = open_out_bin !out_file in
  output_string out encoded;
  close_out out;
  let et = Sys.time () in
  let usr_time_delta = et -. bt in
  let time_delta =
    Float.div (Mtime.Span.to_float_ns (Mtime_clock.elapsed ())) 1000000000.0
  in
  if not !client then
    let stats = Server.get_local_lifter_stats () in
    let oc = if stats.fail > 0 then stderr else stdout in
    let cache =
      match Lazy.force mode with
      | `LocalOffline -> ""
      | _ -> Printf.sprintf " (%f cache hit rate)" stats.cache_hit_rate
    in
    let time  = if (!no_timer) then "" else (Printf.sprintf "in %f sec (%f user time) " time_delta usr_time_delta ) in
    Printf.fprintf oc
      "Successfully lifted %d instructions %s(%d \
       failure: %d unique opcodes)%s\n"
      stats.success time stats.fail
      (List.length stats.unique_failing_opcodes_le)
      cache

(*  MAIN  *)
let () =
  (* BEGINNING *)
  Arg.parse speclist handle_rest_arg usage_message;
  (* Printf.eprintf "gtirb-semantics: %s -> %s\n" !in_file !out_file; *)
  if (not !serve) && (not !shutdown_server) && !count_pos_args <> 2 then (
    output_string stderr usage_message;
    exit 1);

  if !shutdown_server then
    Lwt_main.run
    @@
    let* c = Client.connect () in
    Client.shutdown_server c
  else if !serve then Server.run_server ()
  else (
    output_string stdout "Lifting\n";
    gtirb_to_gts ())
