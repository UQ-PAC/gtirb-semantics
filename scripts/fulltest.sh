#!/bin/bash

EXBIN="gtirb-semantics/extras/example-bin"
GTSARGS="extras/example-bin/example.gtirb ../asl-interpreter/prelude.asl ../mra_tools ../asl-interpreter extras/example-bin/example.gts"
BASLIARGS="compile; run example.gts example.ast.json.t; exit"

echo "This script assumes the directory layout created by build-all.sh."
echo "Press enter to continue or ctrl-c if this requirement is not met."
read
cd ../extras/example-bin
rm example example.ast example.ast.json example.gtirb example.gts
aarch64-linux-gnu-gcc example.c -o example
ddisasm example --ir example.gtirb
cd ../..
dune exec gtirb_semantics $GTSARGS > extras/example-bin/example.ast
cp extras/example-bin/example.gts ../basli
cd ../basli
echo
echo $BASLIARGS | sbt
mv example.ast.json.t ../$EXBIN
cd ../$EXBIN
python3 -mjson.tool example.ast.json.t > example.ast.json
rm example.ast.json.t
cat example.ast.json
