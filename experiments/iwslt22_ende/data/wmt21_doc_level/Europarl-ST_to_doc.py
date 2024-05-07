import sys

last_session = None
for line in sys.stdin:
    src, tgt, segment = line.strip().split("\t")
    session=segment.split()[0]
    if last_session == None:
        last_session = session
    elif session != last_session:
        print("</DOC>","</DOC>",sep="\t")
        last_session=session
    print(src,tgt,sep="\t")
print("</DOC>","</DOC>",sep="\t")
