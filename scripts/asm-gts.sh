#!/bin/bash

printf "This script may ask for sudo in order to install/setup various packages, or to run docker."
read

if [ -n "$(command -v aarch64-linux-gnu-as &>/dev/null)" ]; then
  echo "Installing the aarch64 binary bundle...\n"
  sudo apt install binutils-aarch64-linux-gnu 
fi
if [ -n "$(docker image inspect grammatech/ddisasm:latest &>/dev/null)" ]; then
  printf "Pulling ddisasm docker image...\n"
  docker pull grammatech/ddisasm:latest
fi

printf "Setup complete!\n"

ASM_CODE_PATH=${1:?Error: 1st argument (assembly file) missing!}
GTIRB_SEMANTICS_PATH=${2:?Error: 2nd argument (gtirb-semantics folder) missing!}
ASLP_PATH=${3:?Error: 3rd argument (aslp folder) missing!}
CUR_PWD=$PWD

printf ".globl _start\n_start:\n" > ./temp-asm-gts-code.asm
cat $1 >> ./temp-asm-gts-code.asm

aarch64-linux-gnu-as -o ./temp-asm-gts-code.out ./temp-asm-gts-code.asm
aarch64-linux-gnu-ld -s -o ./temp-asm-gts-code ./temp-asm-gts-code.out

sudo docker run -v $CUR_PWD:/examples -it -w /examples grammatech/ddisasm:latest ddisasm temp-asm-gts-code --ir temp-asm-gts-code.gtirb

cd $GTIRB_SEMANTICS_PATH
dune exec gtirb_semantics $CUR_PWD/temp-asm-gts-code.gtirb $ASLP_PATH/prelude.asl $ASLP_PATH/mra_tools $ASLP_PATH $CUR_PWD/temp-asm-gts-code.gts > $CUR_PWD/output.ast

cd $GTIRB_SEMANTICS_PATH/extras/retrieve
printf "compile; run %s/temp-asm-gts-code.gts %s/temp-asm-gts-code.ast.json.t; exit\n" $CUR_PWD $CUR_PWD | sbt

cd $CUR_PWD
python3 -mjson.tool ./temp-asm-gts-code.ast.json.t > output.ast.json
rm -f ./temp-asm-gts-code*

cat ./output.ast.json
