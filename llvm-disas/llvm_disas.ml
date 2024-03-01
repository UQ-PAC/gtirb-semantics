open Ctypes
open Foreign


let llvm_initialize_all_target_infos = foreign "LLVMInitializeAArch64TargetInfo" (void @-> returning void)
let llvm_initialize_all_target_mcs = foreign "LLVMInitializeAArch64TargetMC" (void @-> returning void)
let llvm_initialize_all_disassemblers = foreign "LLVMInitializeAArch64Disassembler" (void @-> returning void)
let llvm_create_disasm = foreign  "LLVMCreateDisasm" ( string @-> ptr void  @-> int @-> ptr void @-> ptr void @-> returning (ptr void))
let llvm_disasm_instruction = foreign "LLVMDisasmInstruction" (ptr void @-> ptr char @-> size_t @-> size_t @-> ptr char @-> size_t @-> returning int)


let () = 
  llvm_initialize_all_target_infos ();
  llvm_initialize_all_target_mcs ();
  llvm_initialize_all_disassemblers ()

let disassembler : unit ptr = 
  let triple = "aarch64-unknown-linux-gnu" in
  let dc : unit ptr = llvm_create_disasm triple null 0 null null in
  if (dc == null) then 
    failwith ("Error creating disassembler for " ^ triple);
  dc

let byte_list (i: int) : char list = 
  let b = Bytes.create 4 in
  Bytes.set_int32_le b 0 (Int32.of_int i);
  List.init 4 (Bytes.get b)

let hexstring_to_opcode (s: string) = 
  byte_list (int_of_string s)

let assembly_of_bytelist (opcode : char list) : string = 
  let oc = CArray.of_list char opcode in
  let array_len = 500 in
  let out = CArray.make char array_len in
  let outb = llvm_disasm_instruction disassembler (CArray.start oc) (Unsigned.Size_t.of_int 4) (Unsigned.Size_t.of_int 0) (CArray.start out) (Unsigned.Size_t.of_int array_len) in
  if (outb == 0) then raise (Failure "Error disassembling instruction.") else
  let takeWhile (p: 'a -> bool) (ar:('a list)) : 'a list = 
      let rec _take (c: 'a list) (a: 'a list) = match a with 
        | h :: tl -> if (p h) then (_take (c @ [h]) tl) else c
        | _ -> c  
      in
      _take [] ar
    in
  let strout = (String.concat "" (List.map (fun c -> String.make 1 c) (takeWhile (fun c -> c != '\000') (CArray.to_list out))))
  in String.trim @@ String.map (fun f -> if f == '\t' then ' ' else f) strout
  
(* Get disassembly of a little-endian aarch64 opcode as a hexstring*)
let assembly_of_hexstring (opcode : string) : string = 
  assembly_of_bytelist (hexstring_to_opcode opcode)

(* Get disassembly of a little-endian aarch64 opcode as bytes*)
let assembly_of_bytes (opcode: bytes) : string = 
  assembly_of_bytelist (List.of_seq (Bytes.to_seq opcode))

(* Get disassembly of a little-endian aarch64 opcode as an int*)
let assembly_of_int (opcode : int) : string = 
  assembly_of_bytelist (byte_list opcode)

let assembly_of_int_opt (opcode : int) : string option = 
  match assembly_of_int opcode with 
    | exception Failure _ -> None 
    | x -> Some x

let assembly_of_hexstring_opt (opcode : string) : string option = 
  match assembly_of_hexstring opcode with 
    | exception Failure _ -> None 
    | x -> Some x

let assembly_of_bytes_opt (opcode: bytes) : string option = 
  match assembly_of_bytelist (List.of_seq (Bytes.to_seq opcode)) with 
    | exception Failure _ -> None 
    | x -> Some x

