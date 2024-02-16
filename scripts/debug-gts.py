#!/usr/bin/env python3
# vim: ts=2 sts=2 et sw=2

# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "gtirb~=2.0.0",
# ]
# ///

# Requirements:
#  gtirb

"""
debug-gts.py [GTS FILE]

Given a .gts file, prints its semantics to stdout but augmented with
an instruction mnemonic alongside each instruction's statement list.

example output:
{
  "XPbERKxyS8CPh9nu9/oe8A==": {
    "name": "main [entry] [  1/675]",
    "address": 4204032,
    "code": [
      {
        "adrp x2, #184320": [
          "Stmt_Assign(LExpr_Array(LExpr_Var(_R),Expr_LitInt(\"2\")),Expr_LitBits(\"0000000000000000000000000000000000000000010000101111000000000000\"))"
        ]
      },
    ]
  },
}
"""


import io
import sys
import uuid
import json
try:
  import gtirb
except ImportError:
  print('ERROR: `gtirb` python package not found! to run this script and automatically download dependencies, you can use `pipx`:', file=sys.stderr)
  print('', file=sys.stderr)
  print('    pipx run', sys.argv[0], file=sys.stderr)
  print('', file=sys.stderr)
  print('or, alternatively, create a virtual environment and install gtirb there:', file=sys.stderr)
  print('', file=sys.stderr)
  print('    python3 -m venv path/to/venv', file=sys.stderr)
  print('    source path/to/venv/bin/activate', file=sys.stderr)
  print('    pip install gtirb', file=sys.stderr)
  print('', file=sys.stderr)
  print('If you are seeing this error within a Nix package, this has been incorrectly packaged.', file=sys.stderr)
  print('', file=sys.stderr)
  raise
import base64
import shutil
import gtirb.ir
import argparse
import warnings
import subprocess
import collections
import collections.abc

PROTO_VERSION = gtirb.version.PROTOBUF_VERSION

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

def do_block(uuid: str, blk: gtirb.CodeBlock, contents: bytes, sem, isn_names: dict[bytes, str]):
  blksize = blk.size
  off = blk.offset

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

def b64_uuid(uuid: uuid.UUID) -> str:
  return base64.b64encode(uuid.bytes).decode('ascii')

def compute_friendly_names(mod: gtirb.Module) -> dict[uuid.UUID, str]:
  funnames = mod.aux_data['functionNames'].data
  funentries = mod.aux_data['functionEntries'].data
  funblocks = mod.aux_data['functionBlocks'].data

  out = {}
  for func, blks in funblocks.items():
    l = str(len(blks))

    blks = sorted(blks, key=lambda blk: blk.address) # type: ignore
    for i, blk in enumerate(blks, 1):
      entry = ' [entry]' if blk in funentries[func] else ''
      outgoingEdges = next(blk.outgoing_edges, None)
      proxyName= '' 
      if outgoingEdges is not None:
        proxy = next(blk.outgoing_edges).target
        proxyRef = next(proxy.references, None) if isinstance(proxy, gtirb.ProxyBlock) else None
        proxyName = f" ({proxyRef.name})" if proxyRef is not None else ''
      out[blk.uuid] = funnames[func].name + proxyName + entry + ' [{i:>{w}}/{l}]'.format(i=i, l=l, w=len(l))

  return out

def friendly_block(mod: gtirb.Module, blk: gtirb.Block, with_uuid=False, *, _block_to_func: dict[uuid.UUID, str] = {}):
  if not _block_to_func:
    _block_to_func |= compute_friendly_names(mod)

  uuid = blk.uuid
  prefix = '' if not with_uuid else b64_uuid(uuid) + ' / '
  if isinstance(blk, gtirb.CodeBlock):
    return prefix + _block_to_func[uuid]
  elif isinstance(blk, gtirb.ProxyBlock):
    ref = next(blk.references, None)
    if ref is not None: 
      return prefix + f'({type(blk).__name__})' + ' / ' + ref.name
    else :
      return prefix + "Unresolved " + f'{type(blk).__name__}' 

  return prefix + f'({type(blk).__name__})'

def do_module(mod: gtirb.Module, isn_names: dict[bytes, str]):
  sems = mod.aux_data['ast'].data
  sems = json.loads(sems)


  gtirb_ids = set()
  sem_ids = set(sems.keys())
  out = {}
  for sec in mod.sections:
    for blk in sec.code_blocks:
        if not isinstance(blk, gtirb.CodeBlock): continue

        uuid = blk.uuid

        b64 = b64_uuid(uuid)
        friendly = friendly_block(mod, blk)
        out[b64] = {
          'name': friendly,
          'address': blk.address,
          'code': do_block(friendly, blk, bytes(blk.byte_interval.contents), sems[b64], isn_names), # type: ignore
          'successors': {
            friendly_block(mod, x.target, True) : str(x.label) for x in blk.outgoing_edges
          },
        }
        gtirb_ids.add(b64)

  out = list(out.items())
  out.sort(key=lambda x: x[1]['address'])
  out = dict(out)

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

  # make a .gtirb file with appropriate magic number
  bio = io.BytesIO()
  bio.write(b'GTIRB\0\0' + bytes([PROTO_VERSION]))
  with open(args.gts_input, 'rb') as f:
    bio.write(f.read())
  bio.seek(0)

  ir = gtirb.IR.load_protobuf_file(bio)
  del bio

  out = []
  # traverse protobuf twice. first, to find all isn bytes, then to apply them.
  isns = collections.defaultdict(str)
  for mod in ir.modules:
    do_module(mod, isns)

  print('decoding', len(isns), 'opcodes...', file=sys.stderr, end=' ', flush=True)
  isn_names = decode_isns(tuple(isns.keys()))
  print('done', file=sys.stderr)
  assert len(isn_names) == len(isns), f"llvm-mc instruction count mismatch {len(isn_names)=} {len(isns)=}"

  for mod in ir.modules:
    out.append(do_module(mod, isn_names))

  json.dump(out, args.json_output, indent=2)
  args.json_output.write('\n')

  return 0

if __name__ == '__main__':
  sys.exit(main())
