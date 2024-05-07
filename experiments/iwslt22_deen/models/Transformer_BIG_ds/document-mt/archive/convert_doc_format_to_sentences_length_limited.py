import sys

SOD=" <DOC> "
EOD="</DOC>"
SEP=" <SEP> "


def compute_length_buffer(buf):
    length=0
    for s in buf:
        length+= len(s.split(" "))
    return length

def filter_length(s_buf,t_buf, length_limit):
    while compute_length_buffer(s_buf) > length_limit or compute_length_buffer(t_buf) > length_limit:
        if len(s_buf) > 1:
            s_buf.pop(0)
            t_buf.pop(0)
        else:
            break

def print_buffer(s_buf, t_buf, start, i, max_len):
    if start:
        init_symbol="<DOC> "
    else:
        init_symbol="<CONT> "

    if i==max_len-1:
        end_symbol=" <END>"
    else:
        end_symbol=" <BRK>"

    s_print=init_symbol
    t_print=init_symbol
    for s in s_buf:
        s_print += s + " <SEP> " 

    for t in t_buf:
        t_print+=t + " <SEP> "

    print(s_print +  end_symbol + '\t' + t_print  + end_symbol)


def doc_to_sentences(src_filep, tgt_filep, length_limit, rolling_window=False):
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
                if rolling_window:
                    if len(s_buf) == 0:
                        continue
                    s_p_buf=[s_buf[0]]
                    t_p_buf=[t_buf[0]]
                    print_buffer(s_p_buf, t_p_buf, True, 0, len(s_buf))
                    for i in range(1,len(s_buf)):
                        s_p_buf.append(s_buf[i])
                        t_p_buf.append(t_buf[i])
                        filter_length(s_p_buf, t_p_buf, length_limit)
                        print_buffer(s_p_buf, t_p_buf, s_buf[0] == s_p_buf[0], i, len(s_buf))
                else:
                    s_sentence = ["<DOC>"]
                    t_sentence = ["<DOC>"]
                    
                    for i in range(len(s_buf)-1):
                        if len(s_sentence) + len(s_buf[i].split(" ")) < length_limit and len(t_sentence) + len(t_buf[i].split(" ")) < length_limit:
                            s_sentence += s_buf[i].split(" ")
                            t_sentence += t_buf[i].split(" ")
                            s_sentence += [" <SEP> "]
                            t_sentence += [" <SEP> "]
                        else:
                            print( " ".join(s_sentence) + " <BRK>" + '\t' + " ".join(t_sentence) + " <BRK>")
                            s_sentence = ["<CONT> "] + s_buf[i].split(" ") + [" <SEP> "]
                            t_sentence = ["<CONT> "] + t_buf[i].split(" ") + [" <SEP> "]
                    try:
                        if len(s_sentence) + len(s_buf[-1].split(" ")) < length_limit and len(t_sentence) + len(t_buf[-1].split(" ")) < length_limit:
                            s_sentence += s_buf[-1].split(" ")
                            t_sentence += t_buf[-1].split(" ")
                            s_sentence += [" <SEP> "]
                            t_sentence += [" <SEP> "]
                            print( " ".join(s_sentence) + " <END>" + '\t' + " ".join(t_sentence) + " <END>")
                        else:
                            print( " ".join(s_sentence) + " <BRK>" + '\t' + " ".join(t_sentence) + " <BRK>")
                            s_sentence = ["<CONT> "] + s_buf[-1].split(" ") + [" <SEP> "]
                            t_sentence = ["<CONT> "] + t_buf[-1].split(" ") + [" <SEP> "]
                            print( " ".join(s_sentence) + " <END>" + '\t' + " ".join(t_sentence) + " <END>")
                    except:
                        continue 
                s_buf = []
                t_buf = []

if __name__ == "__main__":
    doc_to_sentences(sys.argv[1], sys.argv[2], int(sys.argv[3]), bool(int(sys.argv[4])))  


