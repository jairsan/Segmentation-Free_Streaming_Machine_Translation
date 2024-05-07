mkdir -p segfree_logs/

SRC_FILE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference/data/dev.prepro.en.lst
SET_NAME=MuST-C.dev
OUTPUT_FOLDER_ROOT=$PWD/inference_out

#for fsystem in reverse ratio;
for fsystem in rev_plus_norm_order1_stdest_noint_no_include_next;
do
    qsubmit -gmem 10G -gcards 1 -m 16 -Q cuda11.q -o segfree_logs/segfree.$SET_NAME.$fsystem.log ./infer_seg_free.sh $SRC_FILE_SET_LIST $SET_NAME $OUTPUT_FOLDER_ROOT $fsystem
done


