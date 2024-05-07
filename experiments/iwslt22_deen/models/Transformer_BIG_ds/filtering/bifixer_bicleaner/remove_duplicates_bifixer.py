import sys


DEBUG=False

hashes = {}
keep = 0
discard = 0
for line in sys.stdin:
    columns = line.strip().split("\t")
    line_hash = columns[4]

    pres = hashes.get(line_hash,None)
    if pres == None:
        hashes[line_hash] = columns[2]
        keep += 1
        print("\t".join(columns))
    else:
        discard +=1
        if DEBUG:
            print(" [WW] Deleted duplicate sentence ", pres, ", with hash ", line_hash, file=sys.stderr)

print("Kept ", keep , " lines out of ", keep + discard, file=sys.stderr)
