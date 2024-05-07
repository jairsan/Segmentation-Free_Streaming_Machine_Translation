IN_FIL_PREFIX=$1
OUTPUT_F=$2
src=$3
tgt=$4

rm -f $OUTPUT_F
for i in $(seq 1 50);
do
    cat $IN_FIL_PREFIX.bicleaned.$i | awk -F'\t' '{if ($7 >= 0.5) print $0 }' >> $OUTPUT_F
done

cut -f 3 $OUTPUT_F > $OUTPUT_F.$src
cut -f 4 $OUTPUT_F > $OUTPUT_F.$tgt
rm $OUTPUT_F
