
src_train_file=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/data/wmt21_doc_level/infer_seg_free/MuST-C.v2.train.prepro.en
tgt_train_file=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/data/wmt21_doc_level/infer_seg_free/MuST-C.v2.train.prepro.de

seg_free_root=/home/jiranzo/trabajo/git/my-gits/Segmentation_Free_Toolkit/

source /home/jiranzo/trabajo/env/venv_py3.8_SegmentationFree/bin/activate

features=features/

for lr in 2e-5 1e-6
do
for iqr in 1.5 2.5
do
for model in xlm-roberta-base
do
    python3 $seg_free_root/segfreetk/features/normal_regression_xlm_roberta_feature.py \
      --src_file $src_train_file \
      --tgt_file $tgt_train_file \
      --artefacts_output_folder $features/normal_hf_"$model"_iqr"$iqr"_lr$lr/ \
      --model_name $model \
      --learning_rate $lr \
      --max_positions 60 \
      --filter_outside_iqr $iqr \
      --batch_size 16 \
      --epochs 10
    done
done 
done
