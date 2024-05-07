#Setup run-specifig config
source config.sh
source $PYTHON_ENV

export SACREBLEU_FORMAT=text

hyp=$INFER_OUTPUT_FOLDER/$CORPUS.$RUN.$DEV_PREFIX.hyp.$TARGET_LANG_SUFFIX
ref=$CORPUS_FOLDER/$ORIG_DEV_PREFIX.$TARGET_LANG_SUFFIX

echo "Computing BLEU for dev set"
cat $hyp |  spm_decode --model=$CORPUS_FOLDER/spm.model --input_format=id | $moses_scripts/recaser/detruecase.perl | $moses_scripts/tokenizer/detokenizer.perl -l $TARGET_LANG_SUFFIX | sacrebleu $ref -l $SOURCE_LANG_SUFFIX-$TARGET_LANG_SUFFIX

hyp=$INFER_OUTPUT_FOLDER/$CORPUS.$RUN.$TEST_PREFIX.hyp.$TARGET_LANG_SUFFIX
ref=$CORPUS_FOLDER/$ORIG_TEST_PREFIX.$TARGET_LANG_SUFFIX

echo "Computing BLEU for test set"
cat $hyp | spm_decode --model=$CORPUS_FOLDER/spm.model --input_format=id | $moses_scripts/recaser/detruecase.perl | $moses_scripts/tokenizer/detokenizer.perl -l $TARGET_LANG_SUFFIX | sacrebleu $ref -l $SOURCE_LANG_SUFFIX-$TARGET_LANG_SUFFIX

deactivate
