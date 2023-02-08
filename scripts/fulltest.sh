#!/bin/bash

PACARGS="extras/example-bin/example.gtirb ../asl-interpreter/prelude.asl ../mra_tools ../asl-interpreter extras/example-bin/example.gts"

echo "This script assumes the directory layout created by gtirb_semantics/scripts/build-all.sh."
echo "Press enter to continue or ctrl-c if this requirement is not met."
read
clear
cd ../extras/example-bin
rm example example.ast example.ast.json example.gtirb example.gts
aarch64-linux-gnu-gcc example.c -o example
ddisasm example --ir example.gtirb
cd ../..
dune exec gtirb_semantics $PACARGS > ../basli/example/example.ast
cd ../basli
echo 'compile; run ../gtirb_semantics/extras/example-bin/example.gts ../gtirb_semantics/extras/example-bin/example.ast.json.t; exit' | sbt
cd ../gtirb_semantics/extras/example-bin
python3 -mjson.tool hw.ast.json.t > hw.ast.json
rm hw.ast.json.t
less hw.ast.json
