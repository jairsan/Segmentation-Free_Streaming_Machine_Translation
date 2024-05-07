SRC_REFERENCE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference/data/dev.prepro.en.lst
TGT_REFERENCE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference/data/dev.de.lst

SET_NAME=MuST-C.dev

OUTPUT_FOLDER_ROOT=$PWD/inference_out

mkdir -p segfree_eval_results_BLEURT/

for fname in reverse norm_order1_std1 ratio rev_plus_norm_order1_std1 rev_plus_norm_order1_std2 rev_plus_norm_order1_std4;
do
    ./eval_seg_free_BLEURT.sh $SRC_REFERENCE_SET_LIST $TGT_REFERENCE_SET_LIST $SET_NAME $OUTPUT_FOLDER_ROOT $fname > segfree_eval_results_BLEURT/$fname.dat
done

