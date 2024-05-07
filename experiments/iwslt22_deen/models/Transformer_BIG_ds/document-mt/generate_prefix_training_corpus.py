import sys
import random
import math

def generate_prefixes(src_file, tgt_file, prefix_src_out, prefix_tgt_out,
                 special_symbol_src='[EndPrefix]', special_symbol_tgt='[EndPrefix]'):
    """
    Given two parallel files, generates a prefix training version of each sentence.
    The standard recipe is to take the baseline corpus, extract a prefix training version,
    and then train using both versions (standard + prefix), so 2x the original amount of sentences.
    i.e.
    python3 ~/trabajo/git/nmt-scripts/document-mt/generate_prefix_training_corpus.py ../enes/corpus.es ../enes/corpus.en corpus.es corpus.en
    cat ../enes/corpus.es >> corpus.es
    cat ../enes/corpus.en >> corpus.en
    """
    with open(src_file) as src, open(tgt_file) as tgt,\
    open(prefix_src_out, "w") as out_src, open(prefix_tgt_out, "w") as out_tgt:
        for src_line, tgt_line in zip(src, tgt):
            src_line = src_line.strip().split()
            tgt_line = tgt_line.strip().split()
            keep_ratio = random.random()
            src_line = " ".join(src_line[: math.ceil(len(src_line)*keep_ratio) ] + [special_symbol_src])
            tgt_line = " ".join(tgt_line[: math.ceil(len(tgt_line)*keep_ratio) ] + [special_symbol_tgt])
            out_src.write(src_line + "\n")
            out_tgt.write(tgt_line + "\n")

if __name__ == "__main__":
    generate_prefixes(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
