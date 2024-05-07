src_train_file=/scratch/translectures/data/MuST-C/v2.0/en-de/data/train/txt/train.en
tgt_train_file=/scratch/translectures/data/MuST-C/v2.0/en-de/data/train/txt/train.de

seg_free_root=/home/jiranzo/trabajo/git/my-gits/Segmentation_Free_Toolkit/

source /home/jiranzo/trabajo/env/venv_py3.8_SegmentationFree/bin/activate

features=features/

for order in 1
do
    python3 $seg_free_root/segfreetk/features/normal_regression_feature.py \
      --src_file $src_train_file \
      --tgt_file $tgt_train_file \
      --fit_intercept \
      --artefacts_output_folder $features/simple_normal_special_int/ \
      --order $order

    python3 $seg_free_root/segfreetk/features/normal_regression_feature.py \
      --src_file $src_train_file \
      --tgt_file $tgt_train_file \
      --artefacts_output_folder $features/simple_normal_special_noint/ \
      --order $order

done
