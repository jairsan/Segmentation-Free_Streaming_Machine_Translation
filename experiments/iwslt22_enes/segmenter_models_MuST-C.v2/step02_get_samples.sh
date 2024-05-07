#!/bin/bash

mkdir -p prepared_data

segmenter_root=/home/jiranzo/PycharmProjects/ST-Segmenter

for SET in train dev;
do
    for FUTURE_WINDOW in 0 1 2 3 4;
    do
        MAX_LEN=$(( $FUTURE_WINDOW + 11 ))

        for i in split_$SET/*.en
        do
            $segmenter_root/scripts/get_samples_without_vocab.py $MAX_LEN $FUTURE_WINDOW < $i
        done > prepared_data/$SET.ML${MAX_LEN}.WS${FUTURE_WINDOW}.txt
    done
done

cat prepared_data/train.ML15.WS4.txt | awk '{for (i=1;i<=NF;i++) t[$i]++} END{for (v in t) print v,t[v] }' > prepared_data/train.vocab.txt
