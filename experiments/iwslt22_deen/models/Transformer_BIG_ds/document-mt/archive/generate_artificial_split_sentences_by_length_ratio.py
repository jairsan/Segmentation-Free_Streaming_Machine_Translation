import sys
import random

EOD="<\DOC>"

def split(src_file_fp, tgt_file_fp, seed, split_probs=[0.25,0.25,0.5]):
        if seed is not None:
            random.seed(seed)
        with open(src_file_fp) as src_file, open(tgt_file_fp) as tgt_file:
            buf = None
            for source_line, target_line in zip(src_file, tgt_file):
                source_line = source_line.strip()
                target_line = target_line.strip()

                src_len=len(source_line.split(" "))
                tgt_len=len(target_line.split(" "))

                p = random.random()

                #If sentence is too short, we  just print whatever we have
                if src_len < 3:
                    if source_line == EOD:
                        if buf is not None:
                            print(buf[0] +  "\t" + buf[1])
                        print(EOD + "\t" + EOD) 
                    else:
                        if buf is not None:                    
                            print(buf[0] + " " + source_line + "\t" + buf[1] + " " +target_line)
                        else:
                            print(source_line + "\t" + target_line)
                else:
                
                    # If we already have some leftovers, we will always emit /s
                    if buf is not None:
                        if p < split_probs[0] + split_probs[1]:
                            print(buf[0] + " " + source_line + "\t" + buf[1] + " " +target_line)
                            buf=None
                        else:
                            split_pos=random.randint(0, src_len - 2) + 1
                            target_split_pos = split_pos *  ( int(tgt_len / src_len) )

                            n_s = source_line.split(" ")[:split_pos]
                            n_t = target_line.split(" ")[:target_split_pos]
                            
                            print(buf[0] + " " + " ".join(n_s) + "\t" + buf[1] + " " + " ".join(n_t))
                            buf = (" ".join(source_line.split(" ")[split_pos:]), " ".join(target_line.split(" ")[target_split_pos:]))

                    else:
                            
                        # -1: This sentence has no /s
                        if p < split_probs[0]:
                            buf = (source_line, target_line)  
                        # 0: Same /s as original              
                        elif p < split_probs[0] + split_probs[1]:
                            print(source_line + "\t" + target_line)
                        # 1: We make a split, and store the rest for later
                        else:
                            split_pos=random.randint(0, src_len - 2) + 1
                            target_split_pos = split_pos *  ( int(tgt_len / src_len) )

                            n_s = source_line.split(" ")[:split_pos]
                            n_t = target_line.split(" ")[:target_split_pos]
                            
                            print(" ".join(n_s) + "\t" + " ".join(n_t))                            
                            buf = (" ".join(source_line.split(" ")[split_pos:]), " ".join(target_line.split(" ")[target_split_pos:]))

if __name__ == "__main__":
    
    if len(sys.argv) > 3:
        seed=int(sys.argv[3])
    else:
        seed=None

split(sys.argv[1], sys.argv[2], seed)
