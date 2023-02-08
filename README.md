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

To massively simplify this, simply copy ```scripts/build-all.sh``` to your desired install directory and run as root. This script assumes a completely fresh Ubuntu 20.04.5 installation. It is advised to run this script within a fresh VM but it should work on established installations.

## Usage
```
dune exec gtirb_semantics input_path prelude_path mra_dir asli_dir output_path
```

## Disassembly Pipeline
An example pipeline of disassembly -> instruction lifting -> semantic info is located in scripts/pipeline.sh.
This will disassemble an ARM64 binary and produce both the initial GTIRB IR and the GTIRB IR + semantics.
These will be located in temp/(binary_name).gtirb and temp/(binary_name).gtsem respectively.
The semantics will also be produced in a JSON-like format to stdout.
This can be run from the scripts subdirectory with ```./pipeline.sh binary_path prelude_path mra_dir asli_dir```
