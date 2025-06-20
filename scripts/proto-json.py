#!/usr/bin/env python3
# vim: ts=2 sts=2 et sw=2

# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "gtirb~=2.0.0",
# ]
# ///

import google.protobuf.message_factory
import google.protobuf.descriptor_pool
import google.protobuf.descriptor_pb2
import google.protobuf.json_format
import google.protobuf.descriptor
import google.protobuf.message
import subprocess
import argparse
import tempfile
import logging
import pathlib
import typing
import base64
import gtirb
import shlex
import uuid
import json
import zlib
import sys

'''
to generate GTIRB_FDSET:
  protoc --include_imports -o /dev/stdout -I lib lib/*.proto | python3 -c 'import sys,zlib,base64,pprint; d=sys.stdin.buffer.read(); pprint.pprint(base64.b64encode(zlib.compress(d)), width=160)'
'''
GTIRB_FDSET = \
(b'eJy1GMuOI0lx7fIz/MqunofXLOqhJQS0htG2Z3d2tQgJv7rb4B5b6R5mblbZle0uTdllVZVX3Wi1EhJCcOGE4MpzgQtCnHhJXLlw4P1+LSCxEgfEFxCRWeV2dddIvnDockRkRGRkRGREZMObUGosz9uGb9xb'
 b'uI7v6IWpb7ljhey+BtlgVX8X5P2LhRjNjZmoJu4k3p/nOSI8RFzXIWUiUzWJ9CKXcPMFqE2c2b2pa8xmhi8mZ/fWNI8z8uc+/CcBlZZjiqbtTJ7GmfAG5FfrtM9yaZlyf9yHYKJ51idEVUNaiktYfxUKppig'
 b'2GiGn2oKl8r12+sG3GvL9WP842Cu4I+mckmm8axhmq7wvL27AJeMegUKDdsetcWpsbR99pxegnyDH49OzpazMUtseOTP4JHJpc88chPyq/VNj3zF8A1N+TFAdXgxGzu2NemcL0jScuZxNh1BCRmHvjF52nLm'
 b'nq/fgoxzeuoJX1qW5gGm70DBkxpH0myVEaBIj5CyewhF1NRAO+MUaZsr+mQCCoEm+tNvQNqbGLYI9ChkTX0yov49UFS69pV+TeoPttynDS5Z6ooltc5Slza8kwD9ugP11wAoEKMJnVBuXKg/H0m/dRccPcfz'
 b'xsofr4BERvSRVhXq1ThR+kPJnBGevwkVw/dda7z0xejUNqYeWqxh4l/fOWTj5ZXEAQk0s5B+3bCXlE4JlsSzUsDVMfb+nVaRCyX0LGiH/RO8BnlIIzBosYQOkEGwf3DAkgHMOz2mEe+gd8JSRESAGNIkN2jR'
 b'eobIw46Es8R70huyHK0jcNhm+QDstRkQqwSPWUEvQBbhVqPXY8UAaXeGLVaSAgPSV1Yg7Vgh2bYiswAm+hbBDxWsB/Tjfptt6zlIDRqHHXaDlBNELDeJLPe8pWcg2euz2/R71GVVEj7qHh51OHueRCQ8PGE1'
 b'vQx5dEawyb+yhHcftgP8HTp08vBF9rOKBPbZzxVQZ79QwH32y4pehOyjwaDD9x+wX0ms138ssV9X8JCpXn+/zn4Tgi+z34bgS+x3EjzqIsPvA7C+z/5QQbsTQ/ZHucfgkP1JAg9b7M8VPKPWaA7ZXyS7dNlf'
 b'K3ikDIH399nfpAEnDX7YOdlnb69hdfZ3cnR62CShf0ghGbA++2doxgP2vduBcQ/Y928T+6Hc4weS3O4OB+yHEuwfoPt+RA5OHLEv7dBvj315h+w8arCv7CiFh0fsqzukhcAG+9oOmaMC0WBf38FCnQtC0WBv'
 b'ycWTfqvZGHbYN3bopIixb0oFD/sEf2tnwwr6hTTozQtfdOe+cPHqxNTO2tUGV7ta/mvPLMK7n0pAWjWCaJ1MrQrZXUhRgwqqzK3IXV9tjIVCchG37NRaDPfKKuKWPTwsB7uf1aC4fszYtrQHmTGJe2iLhtr1'
 b'iHapmQccuoAbXnDmkVgd2kO7SLIelVz373VPeZ25717wbe/6CjWRM8MbBV1RVvAcByQ1FEWvQtgyq2np1hBdNdnM2lxRgxzWQl/Mfa+alSdf4bVpXCtVtukMtKfiIggcgfrLgWeDsO1cLdFX9HDF/Vry1U2n'
 b'jC+mcHA6OIzr5QvId8yp6BljYet3oIBHMC0fdzFsaWKOr5Mo8UzLFRPVyHI8wPQPQIoGQJlK5frNyAlI/wkucsmy+/kEpIgkm7qzdCditJY9oEiy5yKDb7hT4Ue6viJJhruQtslwGa6rGbw6FldM2MY0lsJv'
 b'iqV5duw4tjDmPGthyKbC3X0CGrqIovq6cH1rIlT+YVRDXH8fpAUqDVN669p2XK0HDTNI7z0fcqELaGqk31HTNeaTMzU1SkLLsG1smTeASfQAUf/MdZbTM2yeoRQX/tKdYwdlUJSE4QUNNja20pAFKa7wWXrD'
 b'zJgCG7jO+cUz5887AJcMcTd9w43e0nBoxEyJHylrMXVz96cJyAYiz5p85QMkKR8gEtY/AuUxahpZgSq6ydq1gWt9M14ar2Ge/mEoeWrTYG7KyLnpytilOGhO4kXvEvGiSRaUD1Uw9t7EEfWSVb8JWwE6ejQ3'
 b'xak1FyYmRBFyXBimMbYF5gNij13Ll1gS5wTonIvJUuEaDRg9xzBRTiZAd47X1LBxLxMHKsqIMxdV9RzMEZbZMFD/TcjJDmtOXDp8O4GzmVyNDcmt9UqWwtahUP29UHLFqXCxOKq7TBe2iOvFkPxoPaLaWkRv'
 b'QsbwR2JuyuKb42nD78zNpg7MWaiiNFoYFza6IfB60fMd15iK0VNrvml2fjcPRXzVLW0Rl5zRV3Ht2o2pRTO7FvHf7ttpyCjdsS7DIje25oZ7gcfwz4JkBkUaIAV9V15IL7nCvHwIpHhpRZUTPz5QXDE2PDEy'
 b'hY1NPSVfOAVFaxOJXsKnlo3vAcdFX8gYXH0JH+D6gVzmcLqC9V3QLM+QESjXWUSiO2xwWlwFL7sWvA9CVnVir5qX93A7prfxkEffhywunFtYYplkjxp36Xce8ukvQi64f161KGVuxN1UvuLSPwQ5Y3k+kpPP'
 b'lpS4E5EI8iCIuZonskbwnw+MliDKaOFgianqqiVJ0oAo2MtBFiDHNYVb3ZYOu3Wt+PRplefHIVgbQHF9w/UhIa+GhL3okBA9ZSC7NhngZcixPH6BFfBbYEX8llgZv2VWwW+FMV62ZnRRpMEzY6EGPb61Gsac'
 b'hcA+ZXpcDz1Gzz/fwFLlhu2Na5PT6d4bAJepQ11MQZHKRg8leuAk6FHX6dGrEF9Kgw4WMixsXdPA+LbH9+tYzNbwBy+px+ETKZsh8LjROuqrtyFvPGa5vU8nQMM81LeghD9XN+02UGdCPjAHLQSTJPgE9cqX'
 b'aIMf44a3YfvjWDnN5tJ/NPeWi4Xj+rKKKilkljsjM4JZKrzH3cEQleVCGOn5vQ7kV+ElnSskYhP2/KY1xSpmGXM0DJt5z/J9WwSU5IZF6zsa5Lp8g4J1OfvVIlVu9ydJSHZ5bFnCmzuTrOEYvh1zSXjIo7+y'
 b'dqlUx30hWiX4My4Uztw4X9FYK6tLiYco1RzMLFlOCldqDp5Hpt3/5dokmRZ0kozssx4vzzDjR+qoI8uMuw0bhuxz2Fz78qkW11w/Bhm1qL8bQNhiRu1yFZd8QOma6JqiaXkL25hIiuq2PELbzKD/AWGON5k=')

log = logging.getLogger(__name__)

def debug(*args): log.debug(' ' + ' '.join(map(str, args)))

def die(*args) -> typing.NoReturn:
  log.error(' ' + ' '.join(map(str,args)))
  sys.exit(1)

def main():
  logging.basicConfig(level=logging.WARN)

  _gtirb = ['__gtirb__']
  _gtirb_ir_type = 'gtirb.proto.IR'

  argp = argparse.ArgumentParser(description='protobuf <-> json converter.')
  argp.add_argument('--seek', '-s', type=int, default=0, help='number of bytes to skip at start of input (default: 0) (note: use -s8 with .gtirb files)')
  g = argp.add_argument_group(title="input/output settings")
  g = g.add_mutually_exclusive_group()
  g.add_argument('--from', '-i', dest='fr', choices=['json', 'proto'], default=None, help='type of input (default: proto). if given, --to is set to the other type.')
  g.add_argument('--to', '-o', choices=['json', 'proto'], default=None, help='type of output (default: json). if given, --from is set to the other type.')
  g.add_argument('--idem', choices=['json', 'proto'], default=None, help='instead of converting, perform an idempotent normalisation of the given file type')
  argp.add_argument('--proto', '-p', type=str, default=_gtirb, help='directory of .proto files (default: bundled GTIRB .proto files)')
  argp.add_argument('--msgtype', '-m', type=str, default=_gtirb_ir_type, help='protobuf message type (default: gtirb.proto.IR)')
  argp.add_argument('input', nargs='?', type=argparse.FileType('rb'), default=sys.stdin.buffer, help='input file path (default: stdin)')
  argp.add_argument('output', nargs='?', type=argparse.FileType('ab+'), default=sys.stdout.buffer, help='output file path (default: stdout)')

  args = argp.parse_args()
  debug(args)

  def other(a: str):
    if a == 'json': return 'proto'
    if a == 'proto': return 'json'
    assert False, f'{a} unsup'

  if args.fr:
    args.to = other(args.fr)
  elif args.to:
    args.fr = other(args.to)
  elif args.idem:
    args.fr = args.to = args.idem
  else:
    args.fr, args.to = 'proto', 'json'

  if args.proto == _gtirb:
    fdsetdata = zlib.decompress(base64.b64decode(GTIRB_FDSET))
  else:
    args.proto = pathlib.Path(args.proto)
    if not args.proto.exists():
      die(f"protodir does not exist: {args.proto}")

    with tempfile.TemporaryDirectory(prefix='proto_to_json.') as tmpdir:
      tmpdir = pathlib.Path(tmpdir)
      fdsetfile = tmpdir / 'fdset'
      debug('tmpdir:', tmpdir)
      cmd = \
        ['protoc',  '--include_imports', '-I', args.proto, '-o', fdsetfile] + \
        list(map(str,args.proto.glob('**/*.proto')))
      debug('subprocess:', *(shlex.quote(str(x)) for x in cmd))
      subprocess.check_call(cmd, stdout=subprocess.DEVNULL)

      with open(fdsetfile, 'rb') as f:
        fdsetdata = f.read()

  fds = google.protobuf.descriptor_pb2.FileDescriptorSet.FromString(fdsetdata)

  msgclasses = google.protobuf.message_factory.GetMessages(fds.file)

  ProtoMessage = msgclasses.get(args.msgtype)
  debug('proto message type:', ProtoMessage)
  if not ProtoMessage:
    die(f"message type '{args.msgtype}' not found.")

  prefix = args.input.read(args.seek)
  data = args.input.read()
  args.input.close()
  message = None
  if args.fr == 'proto':
    try:
      message = ProtoMessage().FromString(data)
    except Exception as e:
      if (args.proto, args.msgtype, args.seek) == (_gtirb, _gtirb_ir_type, 0):
        hint = 'failed to decode gtirb.  NOTE: .gtirb files have a magic prefix and need --seek 8 to decode properly.'
        if args.proto == _gtirb and args.seek == 0: raise UserWarning(hint) from e
      raise
  elif args.fr == 'json':
    message = ProtoMessage()
    message = google.protobuf.json_format.Parse(data, message)

  assert message
  if args.output.fileno() not in (0, 1):  # not stdin or stdout
    args.output.truncate(0)

  if args.idem:
    args.output.write(prefix)

  if args.to == 'proto':
    data = message.SerializeToString(deterministic=True)
    args.output.write(data)
  elif args.to == 'json':
    # see: https://github.com/protocolbuffers/protobuf/blob/main/python/google/protobuf/json_format.py
    # and: https://protobuf.dev/programming-guides/proto3/#json
    msgdict = google.protobuf.json_format.MessageToDict(
      message,
including_default_value_fields=True,

      # always_print_fields_with_no_presence=True,
      preserving_proto_field_name=True
    )

    if args.proto == _gtirb:
      ser = gtirb.serialization.Serialization()

      def process_keys(x):
        if isinstance(x, tuple):
          return str(tuple(process_keys(y) for y in x))
        else:
          return process_auxdata(x)

      def process_auxdata(x):
        if isinstance(x, bytes):
          try:
            return json.loads(x.decode('ascii'))
          except Exception:
            return str(x)
        elif isinstance(x, list):
          return [process_auxdata(y) for y in x]
        elif isinstance(x, dict):
          if set(x.keys()) == {'type_name', 'data'}:
            data = base64.b64decode(x['data'])
            return process_auxdata({
              'type_name': x['type_name'],
              '_decoded': ser.decode(data, x['type_name'])
            })
          return dict((process_keys(k), process_auxdata(v)) for k,v in x.items())
        elif isinstance(x, uuid.UUID):
          return base64.b64encode(x.bytes).decode('ascii')
        elif isinstance(x, gtirb.offset.Offset):
          return str(x)
        elif x is None or isinstance(x, (str, int, float, bool, bytes)):
          return x
        elif isinstance(x, tuple):
          return tuple(process_auxdata(y) for y in x)
        elif isinstance(x, set):
          return [process_auxdata(y) for y in x]
        else:
          assert False, "unsup type " + repr(x)

      msgdict = process_auxdata(msgdict)
      # print(msgdict)

    data = json.dumps(msgdict, indent=2, sort_keys=True, default=str)
    args.output.write(data.encode('utf-8'))


if __name__ == '__main__':
  main()
