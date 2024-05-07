mkdir -p segfree_logs/

SRC_FILE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_deen/inference_Europarl-ST/data/test.prepro.de.lst
SET_NAME=Europarl-ST.test

OUTPUT_FOLDER_ROOT=$PWD/inference_out
#ratio
for fsystem in ratio rev_plus_norm_order1_stdest_noint rev_plus_norm_order1_stdest_noint_no_include_next;
do
    qsubmit -gmem 10G -gcards 1 -m 16 -o segfree_logs/segfree.$SET_NAME.$fsystem.log ./infer_seg_free.sh $SRC_FILE_SET_LIST $SET_NAME $OUTPUT_FOLDER_ROOT $fsystem
done

