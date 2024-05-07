SRC_REFERENCE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference_Europarl-ST/data/dev.prepro.en.lst
TGT_REFERENCE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference_Europarl-ST/data/dev.de.lst

SET_NAME=Europarl-ST.dev
OUTPUT_FOLDER_ROOT=$PWD/inference_out

mkdir -p segfree_eval_results_BLEURT/

for fname in rev_plus_norm_order1_std1;
do
    ./eval_seg_free_BLEURT.sh $SRC_REFERENCE_SET_LIST $TGT_REFERENCE_SET_LIST $SET_NAME $OUTPUT_FOLDER_ROOT $fname > segfree_eval_results_BLEURT/$fname.dat
done

