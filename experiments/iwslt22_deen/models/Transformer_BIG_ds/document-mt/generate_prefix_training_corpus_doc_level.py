import sys
import random
import math

SEP="[SEP]"

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

            if SEP in src_line:
                end_symbol_src=src_line[-1]
                end_symbol_tgt=tgt_line[-1]

                tmp_src = " ".join(src_line[:-1])
                tmp_tgt = " ".join(tgt_line[:-1])
                
                sl = tmp_src.split(SEP)
                tl = tmp_tgt.split(SEP)
            
                assert len(sl[-1]) == 0 and len(tl[-1]) == 0
                sl = sl[:-1]
                tl = tl[:-1]

                ssl = sl[-1].split()
                stl = tl[-1].split()

                sl[-1] = " ".join( ssl[: max(math.ceil(len(ssl)*keep_ratio),1) ] + [special_symbol_src] )
                tl[-1] = " ".join( stl[: max(math.ceil(len(stl)*keep_ratio),1) ] + [special_symbol_tgt] )


                final_s=""
                final_t=""
                
                i=0
            
                for s,t in zip(sl, tl):
                    final_s += s
                    final_t += t 
                    i+=1
                    if i < len(sl):
                        final_s += SEP + " "
                        final_t += SEP + " "
                #print("[II]", " ".join(src_line), " ".join(tgt_line), final_s, final_t, sep="\t")
                out_src.write(final_s + "\n")
                out_tgt.write(final_t + "\n")
            else:
                src_line = " ".join(src_line[: max(math.ceil(len(src_line)*keep_ratio),1) ] + [special_symbol_src])
                tgt_line = " ".join(tgt_line[: max(math.ceil(len(tgt_line)*keep_ratio),1) ] + [special_symbol_tgt])
                out_src.write(src_line + "\n")
                out_tgt.write(tgt_line + "\n")

if __name__ == "__main__":
    generate_prefixes(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
