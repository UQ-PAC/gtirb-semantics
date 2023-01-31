#!/bin/bash

echo "This no longer works due to compression of ASTs"
echo "Deserialisation checker will be updated to decompress AST soon"

#clear;

#INARY=$1;
#PRELUDE=$2;
#MRADIR=$3;
#ASLI=$4;

#protoc -I=../lib --python_out=py ../lib/*proto

#OIFS=$IFS;
#IFS='/';
#read -ra BINPATH <<< $BINARY;
#NBIN=${BINPATH[-1]};
#IFS=$OIFS;
#rm -rf temp 2> /dev/null;
#mkdir temp;
#cp $BINARY temp;
#cd temp;
#ddisasm --ir $NBIN.gtirb $NBIN;
#dune exec gtirb_semantics $NBIN.gtirb ../$PRELUDE ../$MRADIR ../$ASLI $NBIN.gtsem;
#cd ../py;
#python3 showasts.py ../temp/$NBIN.gtsem | less;
#rm *pb2*;
#cd ../..;
#rm temp
