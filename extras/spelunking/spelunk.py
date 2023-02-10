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

def dump_symbols(gtirb):
    mods    = gtirb.modules
    symbols = [m.symbols for m in mods]
    for ss in symbols:
        for s in ss:
            print(s)
        print(s)

def main():
    ir = gtirb.IR.load_protobuf(argv[1])
    targets = list(set(argv[2:]))
    for target in targets:
        if target == "functions":
            dump_function_blocks(ir)
        elif target == "symbols":
            dump_symbols(ir) 
        else:
            print(f"Target {target} doesn't exist")

if __name__ == "__main__":
	main()
