mkdir -p segfree_logs/

SRC_FILE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference/data/tst-COMMON.prepro.en.lst
SET_NAME=MuST-C.tst-COMMON
OUTPUT_FOLDER_ROOT=$PWD/inference_out

for fsystem in rev_plus_norm_order1_stdest_noint rev_plus_norm_order1_stdest_noint_no_include_next;
do
    qsubmit -gmem 20G -gcards 1 -m 16 -o segfree_logs/segfree.$SET_NAME.$fsystem.log ./infer_seg_free.sh $SRC_FILE_SET_LIST $SET_NAME $OUTPUT_FOLDER_ROOT $fsystem
done


