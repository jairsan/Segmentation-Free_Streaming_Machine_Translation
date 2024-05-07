import json
import sys


def fix(fil, delay):
    with open(fil) as fp:
        a = fp.readlines()
        a = a[0].strip()
        a = a.split(" ")
        
        for i in range(delay):
            a.insert(0,"R")    

        a.reverse()
        for i in range(delay):
            a.remove("R")
        a.reverse()
    
        counter = 0
        delays_a = []

        for action in a:
            if action == "R":
                counter+=1
            else:
                delays_a.append(counter)

        print("x_len ", counter, file=sys.stderr)
        print("y_len ", len(delays_a), file=sys.stderr)

        print(json.dumps(
                {
                    "src_len": counter,
                    "delays": delays_a
                }
                ))

if __name__ == "__main__":
    fix(sys.argv[1], int(sys.argv[2]))
