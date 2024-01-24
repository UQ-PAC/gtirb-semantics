#!/usr/bin/env python3
# vim: ts=2 sts=2 et sw=2

"""
debug-gts.py [GTS FILE]

Given a .gts file, prints its semantics to stdout but augmented with
an instruction mnemonic alongside each instruction's statement list.

example output: 
[
  "GBb7LATIS92OQzoZaJodlg==": [
    {
      "mov w0, #0                          // =0x0": [
        "Stmt_Assign(LExpr_Array(LExpr_Var(_R),Expr_LitInt(\"0\")),Expr_LitBits(\"0000000000000000000000000000000000000000000000000000000000000000\"))"
      ]
    },
    {
      "ret": [
        "Stmt_Assign(LExpr_Var(BTypeNext),Expr_LitBits(\"00\"))",
        "Stmt_Assign(LExpr_Var(__BranchTaken),Expr_Var(TRUE))",
        "Stmt_Assign(LExpr_Var(_PC),Expr_Array(Expr_Var(_R),Expr_LitInt(\"30\")))"
      ]
    }
  ],
]
"""

import os
import sys
import json
import base64
import shutil
import argparse
import tempfile
import functools
import subprocess

dirname = os.path.dirname(__file__)
llvm_mc = shutil.which('llvm-mc')
assert llvm_mc, "could not find llvm-mc in PATH, check that llvm is installed."

@functools.lru_cache
def decode_isn(opcode_bytes):
  hex = ' '.join(f'0x{x:02x}' for x in opcode_bytes).encode('ascii')
  out = subprocess.check_output(
      [llvm_mc, '--disassemble', '--arch=arm64'], input=hex)
  return out.decode('ascii').strip().split('\n')[-1].strip().replace('\t', ' ')

def do_block(blk, contents: bytes, sems):
  uuid = blk['code']['uuid']
  size = int(blk['code']['size'])
  off = int(blk['offset'])

  def slice(i: int):
    isize = 32 // 8  # = 4 bytes per instruction
    i *= isize
    assert 0 <= i and i + isize <= size
    i += off
    assert 0 <= i and i + isize <= len(contents)
    return contents[i:i+isize]

  return {
    uuid: [
      { decode_isn(slice(i)): sem }
      for i, sem in enumerate(sems[uuid])
    ]
  }

def do_module(mod):
  sems = mod['aux_data']['ast']['data']
  sems = base64.b64decode(sems)
  sems = json.loads(sems)
  # print(sems)

  out = {}
  for sec in mod['sections']:
    for ival in sec['byte_intervals']:
      contents = base64.b64decode(ival['contents'])
      for blk in ival['blocks']:
        if 'code' not in blk: continue
        out |= do_block(blk, contents, sems)

  return out

def main():
  argp = argparse.ArgumentParser()
  argp.add_argument('input', help='.gts file')
  argp.add_argument('output', nargs='?', type=argparse.FileType('w'), 
                    help='.json output file (default: stdout)',
                    default=sys.stdout)
  args = argp.parse_args()

  gts_file = args.input
  with tempfile.TemporaryFile() as f:
    subprocess.check_call(
      [f'{dirname}/proto-json.py', gts_file], 
      stdout=f)
    f.seek(0)
    data = json.load(f)

  # nb: flattens all blocks in the gts file into one dict 
  out = {}
  for mod in data['modules']:
    out |= do_module(mod)

  json.dump(out, args.output, indent=2)

  return 0

if __name__ == '__main__':
  sys.exit(main())
