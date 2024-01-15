#!/usr/bin/env python3
# vim: ts=2 sts=2 et sw=2

import google.protobuf.message_factory
import google.protobuf.descriptor_pool
import google.protobuf.descriptor_pb2
import google.protobuf.json_format
import google.protobuf.descriptor
import subprocess
import argparse
import tempfile
import logging
import pathlib
import typing
import shlex
import json
import sys

log = logging.getLogger(__name__)

def debug(*args): log.debug(' ' + ' '.join(map(str, args)))

def die(*args) -> typing.NoReturn:
  log.error(' ' + ' '.join(map(str,args)))
  sys.exit(1)

def main():
  logging.basicConfig(level=logging.WARN)

  argp = argparse.ArgumentParser(description='protobuf <-> json converter.')
  argp.add_argument('--seek', '-s', type=int, default=0, help='number of bytes to skip at start of input (default: 0)')
  argp.add_argument('--to', '-o', choices=['json', 'proto'], default='json', help='type of output to produce, input should be the other type.')
  argp.add_argument('protodir', type=str, help='directory of .proto files')
  argp.add_argument('msgtype', type=str, help='fully-qualified protobuf message type')
  argp.add_argument('input', nargs='?', type=argparse.FileType('rb'), default=sys.stdin.buffer, help='input file path (default: stdin)')
  argp.add_argument('output', nargs='?', type=argparse.FileType('wb'), default=sys.stdout.buffer, help='output file path (default: stdout)')

  args = argp.parse_args()
  debug(args)

  args.protodir = pathlib.Path(args.protodir)
  if not args.protodir.exists():
    die(f"protodir not found: {args.protodir}")

  with tempfile.TemporaryDirectory(prefix='proto_to_json.') as tmpdir:
    tmpdir = pathlib.Path(tmpdir)
    fdsetfile = tmpdir / 'fdset'
    debug('tmpdir:', tmpdir)
    cmd = \
      ['protoc',  '--include_imports', '-I', args.protodir, '-o', fdsetfile] + \
      list(map(str,args.protodir.glob('**/*.proto')))
    debug('subprocess:', *(shlex.quote(str(x)) for x in cmd))
    subprocess.check_call(cmd, stdout=subprocess.DEVNULL)

    with open(fdsetfile, 'rb') as f:
      fds = google.protobuf.descriptor_pb2.FileDescriptorSet.FromString(f.read())

  msgclasses = google.protobuf.message_factory.GetMessages(fds.file)

  ProtoMessage = msgclasses.get(args.msgtype)
  debug('proto message type:', ProtoMessage)
  if not ProtoMessage:
    die(f"message type '{args.msgtype}' not found.")

  args.input.read(args.seek)
  if args.to == 'json':
    message = ProtoMessage().FromString(args.input.read())

    # see: https://github.com/protocolbuffers/protobuf/blob/main/python/google/protobuf/json_format.py
    # and: https://protobuf.dev/programming-guides/proto3/#json
    msgdict = google.protobuf.json_format.MessageToDict(
      message, 
      including_default_value_fields=True, 
      preserving_proto_field_name=True
    )

    data = json.dumps(msgdict, sort_keys=True)
    args.output.write(data.encode('utf-8'))
  else:
    message = ProtoMessage()
    message = google.protobuf.json_format.Parse(args.input.read(), message)

    data = message.SerializeToString(deterministic=True)
    args.output.write(data)

if __name__ == '__main__':
  main()
