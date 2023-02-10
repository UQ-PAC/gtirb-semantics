from sys import argv
import gtirb

def dump_function_blocks(gtirb):
	mods	= gtirb.modules
	auxes	= [dict(m.aux_data) for m in mods			]
	fblocks	= [a['functionBlocks'].data for a in auxes	]
	for m in fblocks:
		for k in m:
			b = m[k]
			print(k)
			for cd in b:
				print(f"\t{cd}")
			print()

def main():
	ir = gtirb.IR.load_protobuf(argv[1])
	print("loaded")
	#src = open(argv[1], "rb")
	targets = list(set(argv[2:]))
	#gtirb = IR()
	#gtirb.ParseFromString(src.read()[8:])
	#src.close()
	for target in targets:
		if target == "functions":
			dump_function_blocks(ir)
		else:
			print(f"Target {target} doesn't exist")
		print("\n")


if __name__ == "__main__":
	main()
