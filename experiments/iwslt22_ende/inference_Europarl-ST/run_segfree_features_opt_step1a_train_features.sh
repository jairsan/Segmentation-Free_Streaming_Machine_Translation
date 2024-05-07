src_train_file=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/data/wmt21_doc_level/infer_seg_free/MuST-C.v2.train.prepro.en
tgt_train_file=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/data/wmt21_doc_level/infer_seg_free/MuST-C.v2.train.prepro.de

seg_free_root=/home/jiranzo/trabajo/git/my-gits/Segmentation_Free_Toolkit/

source /home/jiranzo/trabajo/env/venv_py3.8_SegmentationFree/bin/activate

features=features/

python3 $seg_free_root/segfreetk/features/direct_normal_feature.py \
  --src_file $src_train_file \
  --tgt_file $tgt_train_file \
  --artefacts_output_folder $features/direct_normal/

python3 $seg_free_root/segfreetk/features/direct_count_feature.py \
  --src_file $src_train_file \
  --tgt_file $tgt_train_file \
  --artefacts_output_folder $features/direct_count/

python3 $seg_free_root/segfreetk/features/fixed_ratio_feature.py \
  --src_file $src_train_file \
  --tgt_file $tgt_train_file \
  --artefacts_output_folder $features/fixed_ratio/

python3 $seg_free_root/segfreetk/features/direct_normal_feature.py \
  --src_file $src_train_file \
  --tgt_file $tgt_train_file \
  --json_store_renorm_probs \
  --artefacts_output_folder $features/direct_normal_renorm/

mkdir -p $features/length_src
echo '{"MODEL_TYPE": "LENGTH", "length_of": "src"}' > $features/length_src/feature.json

mkdir -p $features/length_src2tgt
echo '{"MODEL_TYPE": "LENGTH", "length_of": "src2tgt"}' > $features/length_src2tgt/feature.json

mkdir -p $features/length_tgt2src
echo '{"MODEL_TYPE": "LENGTH", "length_of": "tgt2src"}' > $features/length_tgt2src/feature.json

mkdir -p $features/length_src_noexp
echo '{"MODEL_TYPE": "LENGTH", "length_of": "src", "do_exp": false}' > $features/length_src_noexp/feature.json

mkdir -p $features/length_src2tgt_noexp
echo '{"MODEL_TYPE": "LENGTH", "length_of": "src2tgt", "do_exp": false}' > $features/length_src2tgt_noexp/feature.json

mkdir -p $features/length_tgt2src_noexp
echo '{"MODEL_TYPE": "LENGTH", "length_of": "tgt2src", "do_exp": false}' > $features/length_tgt2src_noexp/feature.json
