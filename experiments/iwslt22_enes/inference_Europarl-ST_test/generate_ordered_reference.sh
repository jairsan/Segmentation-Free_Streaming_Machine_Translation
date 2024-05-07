reference_file_set_list=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference_Europarl-ST/data/test.de.lst
cat -n $reference_file_set_list | while read il fil;
do
    cat $fil >> reference.txt
done
