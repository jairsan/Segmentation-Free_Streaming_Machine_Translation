src_opt_file=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/data/wmt21_doc_level/infer_seg_free/MuST-C.v2.dev.prepro.en
tgt_opt_file=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/data/wmt21_doc_level/infer_seg_free/MuST-C.v2.dev.prepro.de

seg_free_root=/home/jiranzo/trabajo/git/my-gits/Segmentation_Free_Toolkit/

source /home/jiranzo/trabajo/env/venv_py3.8_SegmentationFree/bin/activate

features_folder=$PWD/features

python3 $seg_free_root/segfreetk/features/feature_weight_optimization.py \
--src_file $src_opt_file \
--tgt_file $tgt_opt_file \
--features $features_folder/fixed_ratio/feature.json \
$features_folder/direct_count/feature.json \
$features_folder/direct_normal/feature.json \
$features_folder/direct_normal_renorm/feature.json \
$features_folder/fairseq_reverse_scorer/reverse_model_feature.json \
--method perceptron \
--max_iterations 400 \
--json_output_file $features_folder/feature_scorer_perceptron.json \
--perceptron_a 1e-2 1e+1 1e+2 \
--perceptron_b 1e-2 1e-1 1e+1 1e+2 1e+3 1e+4

#$features_folder/fairseq_reverse_scorer/reverse_model_feature.json \
