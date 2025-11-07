#!/usr/bin/env python3
# vim: ts=2 sts=2 et sw=2

from collections import defaultdict
import sys
import json

def print_instruction(asm):
  yield 'AsmInstruction'
  yield '{ asmAddress = ' + hex(asm['address'])
  yield ', asmProcedure = ' + json.dumps(asm['procedure'])
  yield ', asmBlock = ' + json.dumps(asm['block'])
  yield ', asmSemantics = ' + json.dumps(asm['semantics'])
  yield '}'

if __name__ == '__main__':
  data = json.load(sys.stdin)

  procedures = defaultdict(list)

  for mod in data:
    for _, block in mod.items():
      for asm in block['code']:
        procedures[block['procedure']].append(
          asm | {
            'address': int(asm['address'].split()[0], 16),
            'procedure': block['procedure'],
            'block': block['name'],
            'section': block['section']
          }
        )

  for asms in procedures.values():
    asms.sort(key=lambda asm: asm['address'])


  print('[')
  for procname, asms in procedures.items():
    print('AsmProcedure')
    print('{ procName =', json.dumps(procname))
    print(', procSection =', json.dumps(asms[0]['section'])) # XXX: assumes asms nonempty
    print(', procInstructions =')
    print('  [ ', end='')
    print('\n  , '.join(
      ('\n    '.join(print_instruction(asm))
      for asm in asms)
    ))
    print('  ],')
    print('},')
  print(']')





