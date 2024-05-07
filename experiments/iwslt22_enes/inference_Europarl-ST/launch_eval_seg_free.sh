mkdir -p segfree_logs/

SRC_REFERENCE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference_Europarl-ST/data/dev.prepro.en.lst
TGT_REFERENCE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference_Europarl-ST/data/dev.de.lst

SET_NAME=Europarl-ST.dev
OUTPUT_FOLDER_ROOT=$PWD/inference_out

mkdir -p segfree_eval_results/

#for fname in reverse norm_order1_std1 ratio rev_plus_norm_order1_std1 rev_plus_norm_order1_std2 rev_plus_norm_order1_std4 rev_plus_normal_hf_xlm-roberta-base_iqr1.5_lr1e-6 rev_plus_normal_hf_xlm-roberta-base_iqr1.5_lr2e-5 rev_plus_normal_hf_xlm-roberta-base_iqr2.5_lr1e-6 rev_plus_normal_hf_xlm-roberta-base_iqr2.5_lr2e-5 rev_plus_linear_models_morder1_stdorder1_iqr2.5 rev_plus_linear_models_morder1_stdorder1 rev_plus_linear_models_morder2_stdorder1;
for fname in rev_plus_norm_order1_stdest_int rev_plus_norm_order1_stdest_noint rev_plus_norm_order1_stdest_int_no_include_next rev_plus_norm_order1_stdest_noint_no_include_next;
do
    ./eval_seg_free.sh $SRC_REFERENCE_SET_LIST $TGT_REFERENCE_SET_LIST $SET_NAME $OUTPUT_FOLDER_ROOT $fname > segfree_eval_results/$fname.dat
done

