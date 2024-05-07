import sys
def remove(src_fp, tgt_fp, out_src_fp, out_tgt_fp):
    with open(src_fp) as src_file, open(tgt_fp) as tgt_file, open(out_src_fp,"w") as out_src, open(out_tgt_fp,"w") as out_tgt:
        for src_line, tgt_line in zip(src_file, tgt_file):
            if src_line.strip() == "</DOC>" and tgt_line.strip() == "</DOC>":
                continue
            else:
                out_src.write(src_line)
                out_tgt.write(tgt_line)

remove(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
