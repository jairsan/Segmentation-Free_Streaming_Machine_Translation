import sys

SOD=" <DOC> "
EOD="</DOC>"
SEP=" <SEP> "


"""
Takes doc format as input. Then, produces sentences with history,
whose context consists on a fixed number of previous source
and target sentences.
"""

def doc_to_prev_curr_next(src_filep, tgt_filep, n_prev_context=0, n_prev_target_context=0, n_prev_target=0):
    with open(src_filep) as src_file, open(tgt_filep) as tgt_file:
        buf=[]
        for s, t in zip(src_file, tgt_file):
            if s.strip() != EOD:
                buf.append((s.strip(),t.strip()))
            else:
                if len(buf) > 1:
                    print(SOD + buf[0][0] + "\t" + buf[0][1])
                
                for i in range(1,len(buf)):
                    if n_prev_context > 0:
                        previous_context=' <SEP> '.join([ x[0] for x in buf[i - n_prev_context:i]])
                    else:
                        previous_context=' <SEP> '.join([ x[1] for x in buf[i - n_prev_target_context:i]])
                    
                                
                    target = ' <SEP> '.join([ x[1] for x in buf[i - n_prev_target_context:i+1]])
                    
                    print(previous_context + ' <SEP> ' + buf[i][0] + '\t' + target)
                buf=[]

if __name__ == "__main__":
    doc_to_prev_curr_next(sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]))    


