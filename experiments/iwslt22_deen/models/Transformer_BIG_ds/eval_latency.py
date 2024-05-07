import sys
import json


def compute_measures(source_sentence_fp: str, target_sentence_fp: str, delays_fp: str,
                     eos_included_in_delays: bool = True):
    """
    """
    with open(source_sentence_fp) as source_file, open(target_sentence_fp) as target_file, open(delays_fp) as delays_file:
        src_lens = []
        tgt_lens = []
        src_sentences = []
        tgt_sentences = []
        gammas = []

        sentence_delays = []

        for s_l, t_l, delays_l in zip(source_file, target_file, delays_file):
            s = s_l.strip().split()
            src_sentences.append(s)
            src_lens.append(len(s) + int(eos_included_in_delays))
            t = t_l.strip().split()
            tgt_sentences.append(t)
            tgt_lens.append(len(t) + int(eos_included_in_delays))
            gammas.append((len(t) + int(eos_included_in_delays)) / (len(s) + int(eos_included_in_delays)))
            
            a = json.loads(delays_l.strip())

            assert len(s) + int(eos_included_in_delays) == a["src_len"]

            sentence_delays.append(a["delays"])

        # Compute AP
        AP = 0
        for i in range(len(tgt_sentences)):
            partial_score = 0
            for t in range(len(sentence_delays[i])):
                partial_score += sentence_delays[i][t]
            if tgt_lens[i] > 0:
                partial_score = partial_score / (src_lens[i] * tgt_lens[i])
            AP += partial_score

        AP = AP / len(tgt_sentences)

        # Compute AL
        AL = 0
        for i in range(len(tgt_sentences)):
            partial_score = 0
            tau = 0
            for t in range(1, tgt_lens[i]+1):
                tau += 1
                if sentence_delays[i][t-1] >= src_lens[i]:
                    break
            
            for t in range(1, tau+1):
                partial_score += sentence_delays[i][t-1] - (t - 1)/gammas[i]
            if tau > 0:
                partial_score = partial_score / tau
            
            AL += partial_score
        
        AL = AL / len(tgt_sentences)

        #Compute DAL
        DAL = 0
        for i in range(len(tgt_sentences)):
            partial_score = 0
            for t in range(1, tgt_lens[i] +1):
                if t == 1:
                    gt_prime = sentence_delays[i][t-1] 
                else:
                    gt_prime = max(sentence_delays[i][t-1], last_gt_prime + (1/ gammas[i]))
                
                last_gt_prime = gt_prime

                partial_score += gt_prime - (t - 1)/gammas[i]

            if tgt_lens[i] > 0:

                partial_score = partial_score / tgt_lens[i]
            DAL += partial_score
        DAL = DAL / len(tgt_sentences)

        print(f"{AP:4.1f} {AL:4.1f} {DAL:4.1f}")




if __name__ == "__main__":
    compute_measures(sys.argv[1], sys.argv[2], sys.argv[3], bool(int(sys.argv[4])))
