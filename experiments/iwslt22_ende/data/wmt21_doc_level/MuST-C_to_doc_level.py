import re
import sys

with open(sys.argv[1]) as yaml, open(sys.argv[2]) as src, open(sys.argv[3]) as tgt:
    last_id = None
    for yaml_line, src_line , tgt_line in zip(yaml, src, tgt):
        curr_id = re.search( 'wav.*\}', yaml_line).group(0)

        #Only for init
        if last_id == None:
            last_id = curr_id
        
        if last_id != curr_id:
            last_id = curr_id
            print('</DOC>', '\t' ,'</DOC>')

        print(src_line[:-1], '\t', tgt_line[:-1])
