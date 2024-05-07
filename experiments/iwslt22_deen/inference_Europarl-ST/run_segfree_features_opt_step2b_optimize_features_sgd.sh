src_opt_file=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_deen/data/wmt21_doc_level/infer_seg_free/MuST-C.v2.dev.prepro.de
tgt_opt_file=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_deen/data/wmt21_doc_level/infer_seg_free/MuST-C.v2.dev.prepro.en

seg_free_root=/home/jiranzo/trabajo/git/my-gits/Segmentation_Free_Toolkit/

source /home/jiranzo/trabajo/env/venv_py3.8_SegmentationFree/bin/activate

order=1

for normn in est_noint;
do

name=rev_plus_norm_order"$order"_std"$normn"

features_folder=$PWD/features

python3 $seg_free_root/segfreetk/features/feature_weight_optimization.py \
--src_file $src_opt_file \
--tgt_file $tgt_opt_file \
--features $features_folder/fairseq_reverse_scorer/reverse_model_feature.json \
$features_folder/simple_normal_order1_std$normn/feature.json \
--method sgd \
--optimizer adam \
--learning_rate 1e-3 \
--epochs 800 \
--include_next_sentence_prob 1.0 \
--json_output_file $features_folder/feature_scorer_$name.json \
--debug_file $features_folder/feature_scorer_$name.debug.txt


name=rev_plus_norm_order"$order"_std"$normn"_no_include_next

features_folder=$PWD/features

python3 $seg_free_root/segfreetk/features/feature_weight_optimization.py \
--src_file $src_opt_file \
--tgt_file $tgt_opt_file \
--features $features_folder/fairseq_reverse_scorer/reverse_model_feature.json \
$features_folder/simple_normal_order1_std$normn/feature.json \
--method sgd \
--optimizer adam \
--learning_rate 1e-3 \
--epochs 800 \
--include_next_sentence_prob 0.0 \
--json_output_file $features_folder/feature_scorer_$name.json \
--debug_file $features_folder/feature_scorer_$name.debug.txt


done
