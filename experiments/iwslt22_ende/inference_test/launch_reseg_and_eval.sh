SRC_REFERENCE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference/data/tst-COMMON.prepro.en.lst
TGT_REFERENCE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference/data/tst-COMMON.de.lst

SET_NAME=MuST-C.tst-COMMON
OUTPUT_FOLDER_ROOT=$PWD/inference_out

mkdir -p eval_results/

#for fname in ds_oracle.0 ds_roberta_large_v2.12.1 segfree_ratio segfree_rev_plus_norm_order1_stdest_noint_no_include_next;
for fname in ds_oracle.0;
do
    ./reseg_and_eval.sh $SRC_REFERENCE_SET_LIST $TGT_REFERENCE_SET_LIST $fname $SET_NAME $OUTPUT_FOLDER_ROOT > eval_results/$fname.dat
done

