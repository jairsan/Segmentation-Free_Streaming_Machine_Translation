reference_file_set_list=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_deen/inference_Europarl-ST/data/test.en.lst
cat -n $reference_file_set_list | while read il fil;
do
    cat $fil >> reference.txt
done
