import IR_pb2
from sys import argv

ir = IR_pb2.IR()
f = open(argv[1], "rb")
ir.ParseFromString(f.read())
ast = (ir.modules[0]).aux_data[b'ast'].data.decode("utf-8")
print(ast)
