# original code by agimenez
# fairseq vocab is of format
#        ```
#        <symbol0> <count0>
#        <symbol1> <count1>
#        ...
#echo "<s>" 1
#echo "<pad>" 1
#echo "</s>" 1
#echo "<unk>" 1
cat $1 | awk '{for (i=1;i<=NF;i++) t[$i]++} END{for (v in t) print v,t[v] }'
