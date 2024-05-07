import langid,sys

src = sys.argv[1]
tgt = sys.argv[2]
src_file = sys.argv[3]
tgt_file = sys.argv[4]

with open(src_file) as s, open("src_lang.scores","w") as o:
    for line in s:
        lang = langid.classify(line)[0]
        if lang == src:
            o.write("1.0\n")
        else:
            o.write("0.0\n")
            
with open(tgt_file) as t, open("tgt_lang.scores","w") as o: 
    for line in t:
        lang = langid.classify(line)[0]
        if lang == tgt:
            o.write("1.0\n")
        else:
            o.write("0.0\n") 
            


