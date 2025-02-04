# gtirb-semantics

## Introduction

This codebase serves to tie several verification tools together.
The [GTIRB](https://github.com/grammatech/gtirb) intermediate representation produced by the [Datalog Disassembler](https://github.com/GrammaTech/ddisasm) is deserialised using [Google Protocol Buffers](https://developers.google.com/protocol-buffers). This is then dismantled and the [ASLi ASL Interpreter](https://github.com/UQ-PAC/asl-interpreter) is used to add instruction semantics for each instruction opcode. These are then reserialised back into the original IR protobufs alongside the original data produced by DDisasm (.gts file).
The semantic information itself is also printed to stdout.

## Installation


### For use

Through the nix package 

1. (First time only) setup nix repo [nix package](https://github.com/katrinafyi/pac-nix)
2. `nix profile install github:katrinafyi/pac-nix#gtirb-semantics`

Through opam

1. (First time only) Set up [opam repository](https://github.com/ailrst/opam-repository)

```sh
opam repository add pac https://github.com/ailrst/opam-repository.git
```

2. `opam install gtirb_semantics`

### For development

1. (First time only) install [ASLp](https://github.com/UQ-PAC/aslp?tab=readme-ov-file#installing-dependencies)

(Through opam repository or opam pin)

```shell
opam pin asli git+https://github.com/UQ-PAC/aslp
```

2. Clone and install

```
git clone git@github.com:UQ-PAC/gtirb-semantics.git && cd gtirb-semantics
opam install --deps-only .
dune build  --profile=release
dune install
```

- If the build fails finding `protoc`, it can be installed through the system package manager.
- Lift binaries with `ddisasm` ([install using nix](https://github.com/katrinafyi/pac-nix?tab=readme-ov-file))

## Usage

To save on the initialisation time (2s which can dominate execution time when lifting many programs)
and keep the in-memory instruction cache warm, it is possible to use `gtirb_semantics` as a
client-server. 

For example:

```
gtirb_semantics --serve & > /dev/null
gtirb_semantics --client input.gtirb output.gts
gtirb_semantics --client input2.gtirb output2.gts
gtirb_semantics --stop-server
```
The client and server communicate via domain socket which can be specified by setting the
`GTIRB_SEM_SOCKET` environment variable.

Full usage description:

```
usage: gtirb_semantics [options] [input.gtirb output.gts]

  --json output json semantics to given file (default: none, use /dev/stderr for stderr)
  --serve Start server process (in foreground)
  --client Use client to server
  --shutdown-server Stop server process
  --help  Display this list of options
```

GTIRB files can be obtained with:
```
ddisasm ./a.out --ir a.gtirb
```

## GTIRB Specifics
The serialised output is almost identical to that produced by ddisasm except with a few differences:
* The file does not have the 8-byte magic prefix used by GTIRB.
* The semantic information provided by ASLi has been added as an auxdata record for each compilation module. 
  The semantic information JSON data is structured as so:
  ```js
  {
      uuid : [
          [
              opcode_0_semantics
          ],
          [
              opcode_1_semantics
          ],
          ...
      ]
  }
  ```
  Where ```uuid``` is the base64 string of a UUID corresponding to a code block within the GTIRB structure.
  Each ```opcode_n_semantics``` are readable strings of the ASL AST.

## Use with other tools
Some boilerplate Scala code has been provided in ```extras/retrieve```. This minimal solution deserialises a .gts file and retrieves the IPCFG, text sections for each module, and semantic information for each module.

A GTIRB spelunking tool has been provided in ```extras/spelunking```. It is runnable with ```python3 spelunk.py gtirb_file search_key``` where ```search_key``` is any of the below:

| Search Key | Target                                                                          |
|------------|---------------------------------------------------------------------------------|
| cfg        | Interprocess control flow graph for the entire binary                           |
| code       | Code blocks from each compilation module                                        |
| data       | Data blocks from each compilation module                                        |
| functions  | Function blocks from each compilation module's auxdata                          |
| instrs     | Dumps instructions as they appear in each texct section, may be endian-inverted |
| symbols    | Symbols from each compilation module                                            |
| texts      | Text sections from each compilation module                                      |

This has been provided to make it easier to extract relevant information from the GTIRB IR when developing future tools. Alternatively, see the ```--json``` option in ```ddisasm``` for producing a readable JSON representation of the GTIRB IR, although this will be extremely verbose.

This tool is easily extendable to accommodate any increased spelunking needs in the future.
It is important to note that the spelunker will not recognise .gts files due to the structural differences.

`scripts/debug-gts.py` is a tool for converting the .gts into a human-readable JSON format, with instruction names and opcode alongside each block of semantics.

`scripts/proto-json.py` converts to/from GTIRB/gts and a JSON format. This can be useful for exploring the GTIRB output with tools such as jq.

## Disassembly Pipeline
An example pipeline of disassembly -> instruction lifting -> semantic info -> compression -> serialisation -> deserialisation -> decompression is located in scripts/pipeline.sh.
This will disassemble an example ARM64 binary and produce:
* The initial GTIRB IR.
* The GTIRB IR with compressed semantic information.
* The raw semantic information without context.
* The semantic information in the aforementioned JSON structure.

These will be located in example.gtirb, example.gts, example.ast and example.ast.json respectively within ```extras/example-bin```.
This can be run from the scripts subdirectory with ```./fulltest.sh```. This script assumes the directory layout as produced by ```build-all.sh```.
As such, if the scala code located in ```extras/retrieve``` is modified, then it must be copied to a directory ```basli``` adjacent to ```gtirb-semantics```, as per the layout created by ```scripts/build-all.sh``` in order to avoid modifying ```fulltest.sh``` itself.
