from sys import argv
import gtirb

def failure(_):
    print("That target doesn't exist")

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

def dump_texts(gtirb):
    pass

def main():
    ir      = gtirb.IR.load_protobuf(argv[1])
    target  = argv[2]
    dumpTable = {
            "functions" : dump_function_blocks,
            "symbols"   : dump_symbols,
            "texts"     : dump_texts
    }
    dump = dumpTable.get(target, failure)
    dump(ir)

if __name__ == "__main__":
	main()
