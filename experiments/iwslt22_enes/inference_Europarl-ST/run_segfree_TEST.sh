src_opt_file=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/data/wmt21_doc_level/infer_seg_free/MuST-C.v2.dev.prepro.en
tgt_opt_file=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/data/wmt21_doc_level/infer_seg_free/MuST-C.v2.dev.prepro.de

seg_free_root=/home/jiranzo/trabajo/git/my-gits/Segmentation_Free_Toolkit/

source /home/jiranzo/trabajo/env/venv_py3.8_SegmentationFree/bin/activate

for morder in 1
do

for stdorder in 1
do

name=TEST

features_folder=$PWD/features

python3 $seg_free_root/segfreetk/features/feature_weight_optimization.py \
--src_file $src_opt_file \
--tgt_file $tgt_opt_file \
--features $features_folder/normal_linear_models_morder"$morder"_stdorder"$stdorder"/feature.json \
$features_folder/length_src2tgt/feature.json $features_folder/length_tgt2src/feature.json \
--method sgd \
--optimizer adam \
--learning_rate 1e-3 \
--epochs 800 \
--json_output_file $features_folder/feature_scorer_$name.json \

done
done
