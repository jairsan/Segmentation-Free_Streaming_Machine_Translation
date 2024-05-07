# USAGE [SCORES_FILE] [SRC_FILE] [TGT_FILE] [FILTERED_SRC_FILE] [FILTERED_TGT_FILE] [N_SENTENCES]
# Assumes that higher scores are better
# Based on code from J.Iranzo and P.Baquero
import sys
n_pairs = sys.argv[6]

with open(sys.argv[1], 'r') as score_file:
    thresholds = list(sorted(map(float, score_file),reverse=True))
threshold = thresholds[int(n_pairs)]


with open(sys.argv[1], 'r') as score_file, \
open(sys.argv[2], 'r') as src_file, \
open(sys.argv[3], 'r') as tgt_file, \
open(sys.argv[4], 'w') as filtered_src, open(sys.argv[5], 'w') as filtered_tgt, open("trash","w") as trash:
    lines = zip(score_file,src_file,tgt_file)

    for score,src_s, tgt_s in lines:
        if float(score) >= threshold:
            filtered_src.write(src_s)
            filtered_tgt.write(tgt_s)
        else:
            trash.write(src_s +"\t" + tgt_s)

