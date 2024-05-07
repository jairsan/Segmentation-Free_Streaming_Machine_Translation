import os,sys

def extract_MUs(out_name, align_file, src_file, tgt_file):
    #Extract 0 indexed MUs from the source side, in the form of labels
    with open(out_name, "w") as MU_f, open(align_file) as align_f, open(src_file) as src_f, open(tgt_file) as tgt_f:
        for align_l, src_text, tgt_text in zip (align_f, src_f, tgt_f):
            alignments = [ (int(alig.split("-")[0]) , int(alig.split("-")[1])) for alig  in  align_l.strip().split()  ]
            src_toks = src_text.strip().split()
            src_len = len(src_toks)
            tgt_toks = tgt_text.strip().split()
            tgt_len = len(tgt_toks)

            valid_indices = []
            ind_tgt = []
            for i in range(1, src_len + 1):
             for j in range(1, tgt_len + 1):
                invalid_src_tgt = [ True for alig in alignments if alig[1] >= j and alig[0] < i ]
                invalid_tgt_src = [ True for alig in alignments if  alig[0] >= i and alig[1] < j ]
                if len(invalid_src_tgt) == 0 and len(invalid_tgt_src) == 0:
                    valid_indices.append(i)
                    ind_tgt.append(j)
                    break

            old_index = 0
            old_tgt = 0
            MUs = []


            #For visually showing MUs

            #What each MU has been aligned too
            MUs_tgt = []
            for ind, tgt in zip(valid_indices, ind_tgt):
                MUs.append(" ".join(src_toks[old_index:ind]))
                old_index = ind
            
                MUs_tgt.append(" ".join(tgt_toks[old_tgt:tgt]))
                old_tgt = tgt
 
            #print(" | ".join(MUs))
            #print(" ||| ".join( [  x + " # " + y for x,y in zip(MUs, MUs_tgt) ] ))
            

            labels = ["0"] * src_len
            for ind in valid_indices:
                #print(labels, ind, src_len)
                labels[min(ind, src_len - 1)] = "1"
            
            print(" ".join(labels), file=MU_f)
           
            

if __name__ == "__main__":
    extract_MUs(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
