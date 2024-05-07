import json
import sys

def convert(delay_file_p, output_file_fp, hypo_file_fp):
   with open(delay_file_p) as delay_file, open(output_file_fp, "w") as output_file, open(hypo_file_fp) as hypo_file:
        actions = []
        for line, written_words in zip(delay_file, hypo_file):
            sentence_actions = []
            a = json.loads(line.strip())
            #Ignore EOS
            src_len= a["src_len"] - 1
            
            read_words = 0
           
            #Limit to ignore EOS 
            limit = len(written_words.strip().split())
            for tgt_word_gt in a["delays"][:limit]:
                while read_words < min(tgt_word_gt, src_len):
                    sentence_actions.append("R")
                    read_words += 1

                sentence_actions.append("W")

            while read_words < src_len:
                sentence_actions.append("R")
                read_words += 1
            actions.extend(sentence_actions)

            assert sentence_actions.count("W") == len(written_words.strip().split()), sentence_actions.count("W") + " " + written_words.strip().split()

        output_file.write( " ".join(actions))
if __name__ == "__main__":
    convert(sys.argv[1], sys.argv[2], sys.argv[3])
