#!/usr/bin/env python3
# vim: ts=2 sts=2 et sw=2

"""
debug-gts.py [GTS FILE]

Given a .gts file, prints its semantics to stdout but augmented with
an instruction mnemonic alongside each instruction's statement list.

example output:
{
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
}
"""

import sys
import json
import base64
import shutil
import typing
import pathlib
import argparse
import tempfile
import warnings
import functools
import subprocess
import collections
import collections.abc
import multiprocessing.pool

proto_json = pathlib.Path(__file__).parent / 'proto-json.py'
assert proto_json.exists(), f'\'{proto_json}\' not found.  keep this debug-gts.py in the same folder as proto-json.py'
llvm_mc = shutil.which('llvm-mc')
assert llvm_mc, "could not find llvm-mc in PATH, check that llvm is installed."

def chunks(lst, n):
    """Yield successive n-sized chunks from lst."""
    for i in range(0, len(lst), n):
        yield lst[i:i + n]


def _decode_isns(isns: collections.abc.Iterable[bytes]):
  hex = ' '.join(f'0x{x:02x}' for opcode_bytes in isns for x in opcode_bytes)
  out = subprocess.check_output([llvm_mc, '--disassemble', '--arch=arm64'],
                                input=hex, encoding='ascii')
  out = out.replace('.text', '', 1).strip()  # discard first .text
  outs = (x.strip().replace('\t', ' ') for x in out.split('\n'))
  return dict(zip(isns, outs))

def decode_isns(isns: collections.abc.Iterable[bytes]):
  out = {}
  for x in chunks(isns, 1000):
    out |= _decode_isns(x)
  return out 

def do_block(uuid, blk, contents: bytes, sem, isn_names: dict[bytes, str]):
  blksize = int(blk['code']['size'])
  off = int(blk['offset'])

  isize = 32 // 8  # == 4 bytes per instruction
  def slice(i: int):
    i *= isize
    assert 0 <= i and i + isize <= blksize
    i += off
    assert 0 <= i and i + isize <= len(contents)
    return contents[i:i+isize]

  if len(sem) * isize != blksize:
    warnings.warn(f"semantics and gtirb instruction counts differ in block {uuid!r}. "
                  f"semantics: {len(sem)}, gtirb: {blksize / isize}")

  return [
    { isn_names[slice(i)]: sem }
    for i, sem in enumerate(sem)
  ]

def do_module(mod, isn_names: dict[bytes, str]):
  sems = mod['aux_data']['ast']['data']
  sems = base64.b64decode(sems)
  sems = json.loads(sems)
  # print(sems)

  gtirb_ids = set()
  sem_ids = set(sems.keys())
  out = {}
  for sec in mod['sections']:
    for ival in sec['byte_intervals']:
      contents = base64.b64decode(ival['contents'])
      for blk in ival['blocks']:
        if 'code' not in blk: continue
        uuid = blk['code']['uuid']
        out[uuid] = do_block(uuid, blk, contents, sems[uuid], isn_names)
        gtirb_ids.add(uuid)

  if gtirb_ids != sem_ids:
    warnings.warn(f'semantics and gtirb block uuids differ.\n'
                  f'  in gtirb but not semantics: {gtirb_ids - sem_ids}.\n'
                  f'  in semantics but not gtirb: {sem_ids - gtirb_ids}')

  return out

def main():
  argp = argparse.ArgumentParser()
  argp.add_argument('gts_input', help='.gts input file')
  argp.add_argument('json_output', nargs='?', type=argparse.FileType('w'),
                    help='.json output file (default: stdout)',
                    default=sys.stdout)
  args = argp.parse_args()

  gts_file = args.gts_input
  with tempfile.TemporaryFile() as f:
    subprocess.check_call(
      [proto_json, gts_file],
      stdout=f)
    f.seek(0)
    data = json.load(f)

  out = []
  # traverse protobuf twice. first, to find all isn bytes, then to apply them.
  isns = collections.defaultdict(str)
  for mod in data['modules']:
    do_module(mod, isns)

  print('decoding', len(isns), 'opcodes...', file=sys.stderr, end=' ', flush=True)
  isn_names = decode_isns(tuple(isns.keys()))
  print('done', file=sys.stderr)
  assert len(isn_names) == len(isns), f"llvm-mc instruction count mismatch {len(isn_names)=} {len(isns)=}"

  for mod in data['modules']:
    out.append(do_module(mod, isn_names))

  json.dump(out, args.json_output, indent=2)
  args.json_output.write('\n')

  return 0

if __name__ == '__main__':
  sys.exit(main())
