
src_train_file=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/data/wmt21_doc_level/infer_seg_free/MuST-C.v2.train.prepro.en
tgt_train_file=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/data/wmt21_doc_level/infer_seg_free/MuST-C.v2.train.prepro.de

seg_free_root=/home/jiranzo/trabajo/git/my-gits/Segmentation_Free_Toolkit/

source /home/jiranzo/trabajo/env/venv_py3.8_SegmentationFree/bin/activate

features=features/

for order in 1 2
do
    for std in 1 2 4 8
    do
    python3 $seg_free_root/segfreetk/features/normal_regression_feature.py \
      --src_file $src_train_file \
      --tgt_file $tgt_train_file \
      --fit_intercept \
      --artefacts_output_folder $features/simple_normal_order"$order"_std"$std"/ \
      --order $order \
      --std $std
    done
done
