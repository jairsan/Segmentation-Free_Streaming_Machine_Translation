from numpy import random
import numpy as np
import sys

K=3
DROP_PROB=0.1
MASK_PROB=0.1


a = ['this', 'is', 'a', 'test', 'sentence' , 'to', 'check','the','effects','of','applying','noise']

def noisify_sentence(sentence):
    drop = random.random(len(sentence))
    sentence = [sentence[i] for i in range(len(sentence)) if drop[i] >= DROP_PROB]
    mask = random.random(len(sentence))
    sentence = [sentence[i] if mask[i] >= MASK_PROB else "BLANK" for i in range(len(sentence))]
    
    i = np.array(range(len(sentence)))
    q = i + random.randint(0,K+1,len(sentence))
    arr = [ (q[i],i) for i in range(len(sentence))] 
    arr.sort(key=lambda t: t[0])
    sentence = [sentence[arr[i][1]] for i in range(len(sentence)) ]
    return sentence
    
def noisify_file(path):
    with open(path) as input_file, open(path+".noisified","w") as output_file:
        for line in input_file:
            sentence = noisify_sentence(line.rstrip().split(" "))
            print(" ".join(sentence),file=output_file)
            
            
if __name__ == "__main__":
    noisify_file(sys.argv[1])




