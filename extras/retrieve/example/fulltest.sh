#!/bin/bash

PACARGS="../basil-protobufs/example/example.gtirb ../asl-interpreter/prelude.asl ../mra_tools ../asl-interpreter ../basil-protobufs/example/example.gts"

echo "This script assumes the directory layout created by gtirb_semantics/scripts/build-all.sh."
echo "Press enter to continue or ctrl-c if this requirement is not met."
read
clear
rm example example.ast example.ast.json example.gtirb example.gts
aarch64-linux-gnu-gcc example -o example
ddisasm example --ir example.gtirb
cd ../gtirb_semantics
dune exec gtirb_semantics $PACARGS > ../basil-protobufs/example/example.ast
cd ../basil-protobufs
echo 'compile; run example/example.gts example/example.ast.json.t; exit' | sbt
cd example
python3 -mjson.tool hw.ast.json.t > hw.ast.json
rm hw.ast.json.t
less hw.ast.json
