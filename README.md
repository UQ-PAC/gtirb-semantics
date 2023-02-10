# gtirb-semantics

## Introduction

This codebase serves to tie several verification tools together.
The [GTIRB](https://github.com/grammatech/gtirb) intermediate representation produced by the [Datalog Disassembler](https://github.com/GrammaTech/ddisasm) is deserialised using [Google Protocol Buffers](https://developers.google.com/protocol-buffers). This is then dismantled and the [ASLi ASL Interpreter](https://github.com/UQ-PAC/asl-interpreter) is used to add instruction semantics for each instruction opcode. These are then reserialised back into the original IR protobufs alongside the original data produced by DDisasm (.gts file).
The semantic information itself is printed to stdout.

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

To massively simplify this, simply run ```scripts/build-all.sh``` in your preferred install directory. This script assumes a completely fresh Ubuntu 20.04.5 installation. It is advised to run this script within a fresh VM but it should work on established installations. A complete installation can take several hours and will prompt for the sudo password at least once.

```
wget https://raw.githubusercontent.com/UQ-PAC/gtirb-semantics/main/scripts/build-all.sh
chmod 744 build-all.sh
./build-all.sh
```
Partway through, opam will ask if it can modify ```~/.profile``` and if it can add a hook to its init scripts. Answer ```N``` to both.

## Usage
```
dune exec gtirb_semantics input_path prelude_path mra_dir asli_dir output_path
```

## GTIRB Specifics
The serialised output is almost identical to that produced by ddisasm except with a few differences:
* All Sections except ".text" have been removed from each compilation module. This is as they are not useful for analysis purposes, and take up a lot of effectively dead space.
* The auxdata attached to the top-level IR has been removed. It contained only the ddisasm version number and is not useful.
* The semantic information provided by ASLi has been added as an auxdata record for each compilation module. As these outputs are verbose and quite large when formatted as readable text, they have been compressed. The compression scheme is as below:

| Item     | no_blocks | Compression Map                   | Compressed Text |
|----------|-----------|-----------------------------------|-----------------|
| Size (B) | 1         | (3 * no_blocks) - (4 * no_blocks) | Remainder       |

The no_blocks field contains the number of blocks in the compression map.
Each block in the compression map follows the below format:

| Item     | Ascii | no_bits | Compressed |
|----------|-------|---------|------------|
| Size (B) | 1     | 1       | 1-2        |

The Ascii field contains the original character pre-compression. The no_bits field contains the number of bits in the compressed representation of the character in question. The compressed field contains the compressed representation of that character aligned to the right. The resulting decompressed text output needs only to be wrapped in curly braces before being parsed as JSON with your favourite JSON library.
The semantic information JSON data is structured as so:
```
{
    uuid : [
            [
                opcode_0_semantics
            ], [
                opcode_1_semantics
        ], ...
    ]
}
```
Where ```uuid``` is the base64 string of a UUID corresponding to a code block within the GTIRB structure.
Each ```opcode_n_semantics``` are readable strings.

## Use with other tools
Some boilerplate Scala code has been provided in ```extras/retreive```. This minimal solution deserialises a .gts file and retrieves the IPCFG, text sections for each module, and semantic information for each module.

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

This has been provided to make it easier to extract relevant information from the GTIRB IR when developing future tools. Alternatively, see the ```--json``` option in ```ddisdasm``` for producing a readable JSON representation of the GTIRB IR, although this will be extremely verbose.

This tool is easily extendable to accommodate any increased spelunking needs in the future.
It is important to note that the spelunker will not recognise .gts files due to the structural differences.

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
