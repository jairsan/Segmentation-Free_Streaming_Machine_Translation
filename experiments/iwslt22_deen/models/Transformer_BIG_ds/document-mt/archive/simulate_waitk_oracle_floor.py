import math,json
import sys

def simulate(src_file_fp, tgt_file_fp, delays_out_file_fp, k):
    with open(src_file_fp) as src_file, open(tgt_file_fp) as tgt_file, open(delays_out_file_fp,"w") as delays_file:
        for s_l, t_l in zip(src_file, tgt_file):
            
            s_len = len(s_l.strip().split())
            
            delays = []
            target_words = t_l.strip().split()
            gamma = len(target_words) / s_len
           
            t_words = t_l.strip().split()

            for i,t_w in enumerate(t_words, start=1):
                delays.append(min( math.floor(k + (i -1) / gamma) , s_len))

            # Simulate EOS
            s_len = s_len + 1

            line = { "src_len":s_len, "delays":delays}

            print(json.dumps(line),file=delays_file)

if __name__ == "__main__":
    simulate(sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]))
