import sys

# These two are sadly unused
#SOD=" [DOC] "
#SEP=" [SEP] "


EOD="</DOC>"

"""
This script takes a parallel corpus as input,  whose docs are denoted by the EOD(</DOC>) tag,
and produces a corpus as a result of applying a sliding window over the history.
"""

def compute_length_buffer(buf):
    length=0
    for s in buf:
        length+= len(s.split(" "))
    return length

def filter_length(s_buf,t_buf, length_limit_src, length_limit_tgt, mode):
    assert mode in ["whole_sentence", "words"]
    len_s = compute_length_buffer(s_buf)
    while len_s > length_limit_src:
        if len(s_buf) > 1 and len_s - len(s_buf[0].split(" ")) >= length_limit_src:
            len_s -= len(s_buf[0].split(" "))
            s_buf.pop(0)
        elif len(s_buf) > 1:
            len_current = len(s_buf[0].split(" "))
            keep = length_limit_src - (len_s - len_current)
            list_to_keep = s_buf[0].split(" ")[-keep:]
            assert len(list_to_keep) + (len_s - len_current) == length_limit_src
            s_buf[0] = " ".join(list_to_keep)
            break
        else:
            words = s_buf[0].split(" ")
            list_to_keep = words[-length_limit_src:]
            s_buf[0] = " ".join(list_to_keep)
            break
    
    len_t = compute_length_buffer(t_buf)
    while len_t > length_limit_tgt:
        if len(t_buf) > 1 and len_t - len(t_buf[0].split(" ")) >= length_limit_tgt:
            len_t -= len(t_buf[0].split(" "))
            t_buf.pop(0)
        elif len(t_buf) > 1 and mode == "words":
            len_current = len(t_buf[0].split(" "))
            keep = length_limit_tgt - (len_t - len_current)
            list_to_keep = t_buf[0].split(" ")[-keep:]
            assert len(list_to_keep) + (len_t - len_current) == length_limit_tgt
            t_buf[0] = " ".join(list_to_keep)
            break

        elif len(t_buf) > 1 and mode == "whole_sentence":
            t_buf.pop(0)
            break
        elif mode == "words":
            words = t_buf[0].split(" ")
            list_to_keep = words[-length_limit_tgt:]
            t_buf[0] = " ".join(list_to_keep)
            break
        elif mode == "whole_sentence":
            break
        else:
            raise Exception

    return s_buf, t_buf

def print_buffer(s_buf, t_buf, start, i, max_len):
    if start:
        init_symbol="[DOC]"
    else:
        init_symbol="[CONT]"

    if i==max_len-1:
        end_symbol=" [END]"
    else:
        end_symbol=""

    s_print=init_symbol
    t_print=init_symbol
    for s in s_buf:
        s_print += " " + s 

    for t in t_buf:
        t_print+=  " " + t + " [SEP]"

    print(s_print +  end_symbol + '\t' + t_print  + end_symbol)


def doc_to_sentences(src_filep, tgt_filep, length_limit_src, length_limit_tgt, mode):
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
                    s_p_buf, t_p_buf = filter_length(s_p_buf, t_p_buf, length_limit_src, length_limit_tgt, mode)
                    s_p_buf.append(s_buf[i])
                    t_p_buf.append(t_buf[i])
                    print_buffer(s_p_buf, t_p_buf, s_buf[0] == s_p_buf[0], i, len(s_buf))

                s_buf = []
                t_buf = []

if __name__ == "__main__":
    doc_to_sentences(sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), sys.argv[5])


