import sys

#Special symbols used internally
SOD="[DOC]"
SEP="[SEP]"
CONT="[CONT]"
END="[END]"
BRK="[BRK]"

#Symbol used in input parallel corpus to denote end of document
EOD="</DOC>"

"""
This script takes a parallel corpus as input,  whose docs are denoted by the EOD(</DOC>) tag,
and produces a corpus as a result of applying a sliding window over the history.
However, when having to pop sentences to clip history, popping either the src or
tgt pops the whole sentence pair, so as to keep consistency.

This V2 (which is a development of seg-free version) adds hardcoded tags, and always outputs
SEP in both src and tgt. This is important to later do alignments, re-translation samples, etc.

Then, if one wishes to do seg-free, on should symply remove all [SEP] instances from the src side of the corpus.
"""

def compute_length_buffer(buf):
    length=0
    for s in buf:
        length+= len(s.split(" "))
    return length

def filter_length(s_buf,t_buf, length_limit_src, length_limit_tgt):
    while compute_length_buffer(s_buf) > length_limit_src or compute_length_buffer(t_buf) > length_limit_tgt:
        if len(s_buf) > 1:
            s_buf.pop(0)
            t_buf.pop(0)
        else:
            break

    return s_buf, t_buf

def print_buffer(s_buf, t_buf, start, i, max_len):
    if start:
        init_symbol=SOD
    else:
        init_symbol=CONT

    if i==max_len-1:
        end_symbol=" " + END
    else:
        end_symbol=" " + BRK

    s_print=init_symbol
    t_print=init_symbol
    for s in s_buf:
        s_print += " " + s + " " + SEP

    for t in t_buf:
        t_print+=  " " + t + " " + SEP

    print(s_print +  end_symbol + '\t' + t_print  + end_symbol)


def doc_to_sentences(src_filep, tgt_filep, length_limit_src, length_limit_tgt):
    with open(src_filep) as src_file, open(tgt_filep) as tgt_file:
        s_buf=[]
        t_buf=[]
        for s, t in zip(src_file, tgt_file):
            if s.strip() != EOD:
                s_s = s.strip()
                t_s = t.strip()
                s_buf.append(s_s)
                t_buf.append(t_s)

            else:
                if len(s_buf) == 0:
                    continue
                s_p_buf=[s_buf[0]]
                t_p_buf=[t_buf[0]]
                print_buffer(s_p_buf, t_p_buf, True, 0, len(s_buf))
                for i in range(1,len(s_buf)):
                    s_p_buf, t_p_buf = filter_length(s_p_buf, t_p_buf, length_limit_src, length_limit_tgt)
                    s_p_buf.append(s_buf[i])
                    t_p_buf.append(t_buf[i])
                    print_buffer(s_p_buf, t_p_buf, s_buf[0] == s_p_buf[0], i, len(s_buf))

                s_buf = []
                t_buf = []

if __name__ == "__main__":
    doc_to_sentences(sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]))


