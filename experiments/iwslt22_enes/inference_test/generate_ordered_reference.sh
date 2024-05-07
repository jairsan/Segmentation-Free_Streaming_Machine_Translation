reference_file_set_list=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference/data/tst-COMMON.de.lst
cat -n $reference_file_set_list | while read il fil;
do
    cat $fil >> reference.txt
done
