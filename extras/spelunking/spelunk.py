from sys import argv
import gtirb

# Usage: python spelunk.py gtirb_file search_key

# There's a LOT of duplicated code here; maybe clean it later

flatten = lambda ll: ll[0] if len(ll) == 1 else ll[0] + flatten(ll[1:])

def dump_cfg(gtirb):
    print(gtirb.cfg)

def dump_code_blocks(gtirb):
    print("LOOK FOR: IR.modules.sections.byteIntervals.blocks \"code\"\n")
    mods    = gtirb.modules
    sects   = flatten(list(map(lambda m: m.sections, mods)))
    texts   = filter(lambda s: s.name == ".text", sects)
    ivals   = flatten(list(map(lambda t: t.byte_intervals, texts)))
    blocks  = flatten(list(map(lambda i: i.blocks, ivals)))
    codes   = filter(lambda t: str(t)[:4] == "Code", blocks)
    for b in codes:
        print(str(b))

def dump_data_blocks(gtirb):
    print("LOOK FOR: IR.modules.sections.byteIntervals.blocks \"data\"\n")
    mods    = gtirb.modules
    sects   = flatten(list(map(lambda m: m.sections, mods)))
    texts   = filter(lambda s: s.name == ".text", sects)
    ivals   = flatten(list(map(lambda t: t.byte_intervals, texts)))
    blocks  = flatten(list(map(lambda i: i.blocks, ivals)))
    codes   = filter(lambda t: str(t)[:4] == "Data", blocks)
    for b in codes:
        print(str(b))

def dump_function_blocks(gtirb):
    print("LOOK FOR: IR.modules.auxData[functionBlocks]\n")
    mods    = gtirb.modules
    auxes   = [dict(m.aux_data) for m in mods]
    fblocks = [a['functionBlocks'].data for a in auxes]
    for m in fblocks:
        for k in m:
            b = m[k]
            print(k)
            for cd in b:
                print(f"\t{cd}")
            print()

def dump_instrs(gtirb):
    print("LOOK FOR: IR.modules.sections.byteIntervals.contents\n")
    mods        = gtirb.modules
    sections    = flatten([m.sections for m in mods])
    texts       = list(filter(lambda s: s.name == ".text", sections))
    sectIds     = list(map(lambda s: s.uuid, texts))
    byteIvals   = flatten(list(map(lambda t: t.byte_intervals, texts)))
    raw         = list(map(lambda i: i.contents, byteIvals))
    for u, r in zip(sectIds, raw):
        print(u)
        cuts = [r[i:i+4] for i in range(len(r) // 4)]
        for i in cuts:
            print(f"\t{i.hex()}")

def dump_symbols(gtirb):
    print("LOOK FOR: IR.modules.symbols\n")
    mods    = gtirb.modules
    symbols = [m.symbols for m in mods]
    for ss in symbols:
        for s in ss:
            print(s)
        print(s)

def dump_texts(gtirb):
    print("LOOK FOR: IR.modules.sections, .name == \".text\"\n")
    mods        = gtirb.modules
    sections    = flatten([m.sections for m in mods])
    texts       = list(filter(lambda s: s.name == ".text", sections))
    for t in texts:
        print(t)

def main():
    ir      = gtirb.IR.load_protobuf(argv[1])
    target  = argv[2]
    dumpTable = {
            "cfg"       : dump_cfg              ,
            "code"      : dump_code_blocks      ,
            "data"      : dump_data_blocks      ,
            "functions" : dump_function_blocks  ,
            "instrs"    : dump_instrs           ,
            "symbols"   : dump_symbols          ,
            "texts"     : dump_texts
    }
    dump = dumpTable.get(target, lambda _: print("That target doesn't exist."))
    dump(ir)

if __name__ == "__main__":
	main()
