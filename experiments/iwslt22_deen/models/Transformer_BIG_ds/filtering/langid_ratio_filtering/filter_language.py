import langid,sys


sent_file = sys.argv[1]
lang = sys.argv[2]


with open(sent_file) as s, open(sent_file+".scores","w") as o:
    for line in s:
        lang_reco = langid.classify(line)[0]
        if lang_reco == lang:
            o.write("1.0\n")
        else:
            o.write("0.0\n")
            


