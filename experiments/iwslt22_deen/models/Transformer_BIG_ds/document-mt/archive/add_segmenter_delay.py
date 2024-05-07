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
    
        print(" ".join(a))

if __name__ == "__main__":
    fix(sys.argv[1], int(sys.argv[2]))
