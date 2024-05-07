import sys


def do(src_f, tgt_f):
    with open(src_f) as sf, open(tgt_f) as tf:
        for s_l, t_l in zip(sf, tf):
            print( len(t_l.strip().split()) / len(s_l.strip().split()) )


if __name__ == "__main__":
    do(sys.argv[1], sys.argv[2])
