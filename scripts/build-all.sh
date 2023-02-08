#!/bin/bash

echo This must be run as root and may take several hours. Press enter to continue or ctrl-c to abort.
read
wget -O key https://download.grammatech.com/gtirb/files/apt-repo/conf/apt.gpg.key
sudo apt-key add key
rm key
echo "deb https://download.grammatech.com/gtirb/files/apt-repo focal stable"| tee -a /etc/apt/sources.list
apt-get update -y
apt-get install -yqq apt-transport-https curl gnupg gcc-aarch64-linux-gnu git make libgtirb gtirb-pprinter ddisasm libgmp-dev libprotobuf-dev protobuf-compiler default-jdk scala
echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list
echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | sudo tee /etc/apt/sources.list.d/sbt_old.list
curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo -H gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/scalasbt-release.gpg --import
sudo chmod 644 /etc/apt/trusted.gpg.d/scalasbt-release.gpg
sudo apt-get update -y
sudo apt-get install -y sbt
git clone https://github.com/alastairreid/mra_tools
cd mra_tools
mkdir -p v8.6
cd v8.6
wget https://developer.arm.com/-/media/developer/products/architecture/armv8-a-architecture/2019-12/SysReg_xml_v86A-2019-12.tar.gz
wget https://developer.arm.com/-/media/developer/products/architecture/armv8-a-architecture/2019-12/A64_ISA_xml_v86A-2019-12.tar.gz
wget https://developer.arm.com/-/media/developer/products/architecture/armv8-a-architecture/2019-12/AArch32_ISA_xml_v86A-2019-12.tar.gz
tar zxf A64_ISA_xml_v86A-2019-12.tar.gz
tar zxf AArch32_ISA_xml_v86A-2019-12.tar.gz
tar zxf SysReg_xml_v86A-2019-12.tar.gz
cd ..
make all
cd ..
git clone https://github.com/UQ-PAC/asl-interpreter
apt-get install -y opam
opam init
opam switch create 5.0.0
eval $(opam env)
apt install -y libgmp-dev libprotobuf-dev protobuf-compiler default-jdk scala
opam install -y ocaml dune menhir ott linenoise pprint z3 zarith odoc ocamlformat hexstring base64 ocaml-protoc-plugin
eval `opam config env`
cd asl-interpreter
make install
make -C ../mra_tools clean
make -C ../mra_tools
make install
cd ..
git clone https://github.com/UQ-PAC/gtirb-semantics
git clone https://github.com/GNUNotUsername/basil-protobufs
