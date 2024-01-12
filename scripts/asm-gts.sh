#!/bin/bash -u

printf "This script may ask for sudo in order to install/setup various packages, or to run docker.\n"
read -t 1 || true

if command -v aarch64-linux-gnu-as &>/dev/null; then
  CROSS="aarch64-linux-gnu"
elif command -v aarch64-suse-linux-as &>/dev/null; then
  CROSS="aarch64-suse-linux"
else
  echo "Installing the aarch64 binary bundle (for Ubuntu)...\n"
  sudo apt install binutils-aarch64-linux-gnu 
fi

if ! which sbt &>/dev/null; then
  echo "sbt is required. check extras/retrieve/project/build.properties and be aware of Java version (in)compatibilities."
  exit 1
fi

CUR_PWD=$PWD

if which ddisasm &>/dev/null; then
  DDISASM=( "$(which ddisasm)" )
else
  DDISASM=(sudo docker run -v $CUR_PWD:/examples -it -w /examples grammatech/ddisasm:latest ddisasm)
  if [ -n "$(docker image inspect grammatech/ddisasm:latest &>/dev/null)" ]; then
    printf "Pulling ddisasm docker image...\n"
    docker pull grammatech/ddisasm:latest
  fi
fi
echo "ddisasm: " "${DDISASM[@]}"

if which gtirb_semantics &>/dev/null; then
  GTIRB_SEMANTICS=( $(which gtirb_semantics) )
else
  GTIRB_SEMANTICS=(dune exec gtirb_semantics)
fi
echo "gtirb_semantics: " "${GTIRB_SEMANTICS[@]}"

printf "Setup complete!\n"


ASM_CODE_PATH=${1:?Error: 1st argument (assembly file) missing!}
GTIRB_SEMANTICS_PATH=${2:?Error: 2nd argument (gtirb-semantics folder) missing!}
ASLP_PATH=${3:?Error: 3rd argument (aslp folder) missing!}

printf ".globl _start\n_start:\n" > ./temp-asm-gts-code.asm
cat $1 >> ./temp-asm-gts-code.asm

$CROSS-as -o ./temp-asm-gts-code.out ./temp-asm-gts-code.asm
$CROSS-ld -s -o ./temp-asm-gts-code ./temp-asm-gts-code.out

"${DDISASM[@]}" temp-asm-gts-code --ir temp-asm-gts-code.gtirb

cd $GTIRB_SEMANTICS_PATH
"${GTIRB_SEMANTICS[@]}" $CUR_PWD/temp-asm-gts-code.gtirb $ASLP_PATH/prelude.asl $ASLP_PATH/mra_tools $ASLP_PATH $CUR_PWD/temp-asm-gts-code.gts > $CUR_PWD/output.ast

cd $GTIRB_SEMANTICS_PATH/extras/retrieve
sbt "compile; run $CUR_PWD/temp-asm-gts-code.gts $CUR_PWD/temp-asm-gts-code.ast.json.t; exit" 

cd $CUR_PWD
python3 -mjson.tool ./temp-asm-gts-code.ast.json.t > output.ast.json
rm -f ./temp-asm-gts-code*

cat ./output.ast.json
