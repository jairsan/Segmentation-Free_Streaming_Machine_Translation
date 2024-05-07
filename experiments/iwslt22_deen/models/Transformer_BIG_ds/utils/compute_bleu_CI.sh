#Setup run-specifig config
source config.sh

hyp=$INFER_OUTPUT_FOLDER/$CORPUS.$RUN.$DEV_PREFIX.hyp.$TARGET_LANG_SUFFIX
ref=$CORPUS_FOLDER/$DEV_PREFIX.$TARGET_LANG_SUFFIX
echo "#########################################################"
echo "                         WARNING                         "
echo "This script takes as reference the .prepro.bpe files     "
echo "after undoig BPE. Make sure that this is what you want.  "
echo "#########################################################"
echo "Computing BLEU for dev set"
cat $hyp | sed -r 's/\@\@ //g' > $hyp.tmp_compute_bleu
cat $ref | sed -r 's/\@\@ //g' > $ref.tmp_compute_bleu
/scratch/jiranzo/trabajo/git/phd_jiranzo/bsc_jiranzo/utils/mt-confidence-intervals.sh -r $ref.tmp_compute_bleu -t $hyp.tmp_compute_bleu -n 10000

hyp=$INFER_OUTPUT_FOLDER/$CORPUS.$RUN.$TEST_PREFIX.hyp.$TARGET_LANG_SUFFIX
ref=$CORPUS_FOLDER/$TEST_PREFIX.$TARGET_LANG_SUFFIX

echo "Computing BLEU for test set"
cat $hyp | sed -r 's/\@\@ //g' > $hyp.tmp_compute_bleu
cat $ref | sed -r 's/\@\@ //g' > $ref.tmp_compute_bleu
/scratch/jiranzo/trabajo/git/phd_jiranzo/bsc_jiranzo/utils/mt-confidence-intervals.sh -r $ref.tmp_compute_bleu -t $hyp.tmp_compute_bleu -n 10000
