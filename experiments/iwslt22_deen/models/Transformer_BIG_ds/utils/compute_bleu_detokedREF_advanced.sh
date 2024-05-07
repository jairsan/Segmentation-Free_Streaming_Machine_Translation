#Setup run-specifig config
source config.sh
source $PYTHON_ENV

hyp=$INFER_OUTPUT_FOLDER/$CORPUS.$RUN.$DEV_PREFIX.hyp.$TARGET_LANG_SUFFIX
ref=$CORPUS_FOLDER/$ORIG_DEV_PREFIX.$TARGET_LANG_SUFFIX

echo "Computing BLEU for dev set"
cat $hyp | sed -r 's/\@\@ //g' | $moses_scripts/recaser/detruecase.perl | $moses_scripts/tokenizer/detokenizer.perl -l $TARGET_LANG_SUFFIX | sacrebleu $ref -l $SOURCE_LANG_SUFFIX-$TARGET_LANG_SUFFIX

hyp=$INFER_OUTPUT_FOLDER/$CORPUS.$RUN.$TEST_PREFIX.hyp.$TARGET_LANG_SUFFIX
ref=$CORPUS_FOLDER/$ORIG_TEST_PREFIX.$TARGET_LANG_SUFFIX

echo "Computing BLEU for test set"
cat $hyp | sed -r 's/\@\@ //g' | $moses_scripts/recaser/detruecase.perl | $moses_scripts/tokenizer/detokenizer.perl -l $TARGET_LANG_SUFFIX | sacrebleu $ref -l $SOURCE_LANG_SUFFIX-$TARGET_LANG_SUFFIX


echo "Now checking if there exists inference using AVG checkpoint"

hyp=$INFER_OUTPUT_FOLDER/$CORPUS.$RUN.$DEV_PREFIX.hyp.AVG.$TARGET_LANG_SUFFIX
ref=$CORPUS_FOLDER/$ORIG_DEV_PREFIX.$TARGET_LANG_SUFFIX

echo "AVG: Computing BLEU for dev set"
cat $hyp | sed -r 's/\@\@ //g' | $moses_scripts/recaser/detruecase.perl | $moses_scripts/tokenizer/detokenizer.perl -l $TARGET_LANG_SUFFIX | sacrebleu $ref -l $SOURCE_LANG_SUFFIX-$TARGET_LANG_SUFFIX

hyp=$INFER_OUTPUT_FOLDER/$CORPUS.$RUN.$TEST_PREFIX.hyp.AVG.$TARGET_LANG_SUFFIX
ref=$CORPUS_FOLDER/$ORIG_TEST_PREFIX.$TARGET_LANG_SUFFIX

echo "AVG: Computing BLEU for test set"
cat $hyp | sed -r 's/\@\@ //g' | $moses_scripts/recaser/detruecase.perl | $moses_scripts/tokenizer/detokenizer.perl -l $TARGET_LANG_SUFFIX | sacrebleu $ref -l $SOURCE_LANG_SUFFIX-$TARGET_LANG_SUFFIX


deactivate
