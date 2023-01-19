# gtirb-semantics

## Introduction

This codebase serves to tie several verification tools together.
The [GTIRB](https://github.com/grammatech/gtirb) intermediate representation produced by the [Datalog Disassembler](https://github.com/GrammaTech/ddisasm) is deserialised using [Google Protocol Buffers](https://developers.google.com/protocol-buffers). This is then dismantled and the [ASLi ASL Interpreter](https://github.com/UQ-PAC/asl-interpreter) is used to add instruction semantics for each instruction opcode. These are then reserialised back into the original IR protobufs alongside the original data produced by DDisasm.

## Requirements
To build and run this you will need:
* ddisasm and dependencies thereof
* asl-interpreter and dependencies thereof
* mra_tools
* protoc
* The following OPAM packages:
	* ocaml-protoc-plugin
	* hexstring
	* base64

## Usage
```
dune exec gtirb_semantics input_path prelude_path mra_dir asli_dir output_path
```
