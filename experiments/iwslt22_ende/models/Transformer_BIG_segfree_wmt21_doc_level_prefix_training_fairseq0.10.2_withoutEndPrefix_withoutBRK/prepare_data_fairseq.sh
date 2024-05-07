source config.sh

#Load Python environment
source $PYTHON_ENV
export LC_ALL=C.UTF-8

rm -r $CORPUS_FOLDER/fairseq_prepared_data/

fairseq-preprocess --source-lang $SOURCE_LANG_SUFFIX \
--target-lang $TARGET_LANG_SUFFIX \
--trainpref $CORPUS_FOLDER/$TRAIN_PREFIX \
--validpref $CORPUS_FOLDER/$DEV_PREFIX \
--testpref $CORPUS_FOLDER/$TEST_PREFIX \
--destdir $CORPUS_FOLDER/fairseq_prepared_data/ \
--thresholdsrc $WORD_MIN_COUNT \
--thresholdtgt $WORD_MIN_COUNT \
--workers 16 \
--joined-dictionary

deactivate
