import random
import sys
from dataclasses import dataclass
from typing import List, Tuple


@dataclass
class Alignment:
    src_idx: int
    tgt_idx: int

def collapse_alignment(src_sentences: List[List[str]], tgt_sentences: List[List[str]], alignments: List[List[str]])\
        -> Tuple[List[str], List[str], List[Alignment]]:
    s: List[str] = []
    t: List[str] = []
    A: List[Alignment] = []
    for sk, tk, ak in zip(src_sentences, tgt_sentences, alignments):
        for a in ak:
            i, j = a.split("-")
            ig = int(i) + len(s)
            jg = int(j) + len(t)
            A.append(Alignment(src_idx=ig, tgt_idx=jg))
        s.extend(sk)
        t.extend(tk)

    return s, t, A


def get_p_q(idx: int, tq:int, A: List[Alignment]) -> Tuple[int, int]:
    selected_a: List[Alignment] = [ a for a in A if idx <= a.tgt_idx < tq]
    p = min([a.src_idx for a in selected_a])
    q = max([a.src_idx for a in selected_a])
    return p, q


def generate_windows(src_file_fp, tgt_file_fp, align_file_fp):
    random.seed(10)
    k=0
    with open(src_file_fp) as src_file, open(tgt_file_fp) as tgt_file, open(align_file_fp) as align_file:
        negative_idx = 0
        remaining_words = random.randint(10, 25)
        s_history: List[List[str]] = []
        t_history: List[List[str]] = []
        a_history: List[List[str]] = []
        for s_l, t_l, align_l in zip(src_file, tgt_file, align_file):
            s = s_l.strip().split()
            t = t_l.strip().split()
            negative_idx += len(t)
            a = align_l.strip().split()
            s_history.append(s)
            t_history.append(t)
            a_history.append(a)

            if len(s_history) > 30:
                s_history.pop(0)
                t_history.pop(0)
                a_history.pop(0)

            if remaining_words > len(t):
                remaining_words -= len(t)
            else:
                while remaining_words <= len(t):
                    new_s, new_t, new_a = collapse_alignment(src_sentences=s_history, tgt_sentences=t_history, alignments=a_history)
                    tq = remaining_words + sum([len(tt) for tt in t_history[:-1]])
        
                    try:
                        idx = len(new_t) - negative_idx
                        wt = new_t[idx:tq]
                        p, q = get_p_q(idx=idx, tq=tq, A=new_a)
                        ws = new_s[p:q]
                        print(" ".join(ws), " ".join(wt), sep="\t")
                    except:
                        pass
                    negative_idx = len(new_t) - tq
                    remaining_words += random.randint(10, 25)


if __name__ == "__main__":
    generate_windows(sys.argv[1], sys.argv[2], sys.argv[3])
