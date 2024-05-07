
src_train_file=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/data/wmt21_doc_level/infer_seg_free/MuST-C.v2.train.prepro.en
tgt_train_file=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/data/wmt21_doc_level/infer_seg_free/MuST-C.v2.train.prepro.de

seg_free_root=/home/jiranzo/trabajo/git/my-gits/Segmentation_Free_Toolkit/

source /home/jiranzo/trabajo/env/venv_py3.8_SegmentationFree/bin/activate

features=features/

for iqr in 2.5
do
for mean_order in 1
do
    for std_order in 1
    do
    python3 $seg_free_root/segfreetk/features/normal_regression_linear_models_feature.py \
      --src_file $src_train_file \
      --tgt_file $tgt_train_file \
      --artefacts_output_folder $features/normal_linear_models_morder"$mean_order"_stdorder"$std_order"_iqr"$iqr"/ \
      --mean_order $mean_order \
      --std_order $std_order \
      --learning_rate 1e-5 \
      --max_positions 40 \
      --filter_outside_iqr $iqr \
      --batch_size 128 \
      --epochs 800
    done
done
done
