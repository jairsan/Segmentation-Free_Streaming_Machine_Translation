import sys

with open(sys.argv[1]) as src_fp, open(sys.argv[2]) as tgt_fp:
    for src_line, tgt_line in zip(src_fp, tgt_fp):
        s = src_line.strip()
        t = tgt_line.strip()
        print(s + " ||| " + t)
