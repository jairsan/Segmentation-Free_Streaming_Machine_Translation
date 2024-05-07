source config.sh

#Load Python environment
source $PYTHON_ENV
export LC_ALL=C.UTF-8

FT_TRAIN_PREFIX=$1
FT_DEV_PREFIX=$2
FT_NAME=$3


#Train    

    $ASR_FILE_PROCESSOR $CORPUS_FOLDER/$FT_TRAIN_PREFIX.$SOURCE_LANG_SUFFIX > $CORPUS_FOLDER/$FT_TRAIN_PREFIX.prepro.$SOURCE_LANG_SUFFIX
    $moses_scripts/recaser/truecase.perl < $CORPUS_FOLDER/$FT_TRAIN_PREFIX.$TARGET_LANG_SUFFIX > $CORPUS_FOLDER/$FT_TRAIN_PREFIX.prepro.$TARGET_LANG_SUFFIX -model $CORPUS_FOLDER/truecase-model.$TARGET_LANG_SUFFIX    

#Dev

    $ASR_FILE_PROCESSOR $CORPUS_FOLDER/$FT_DEV_PREFIX.$SOURCE_LANG_SUFFIX > $CORPUS_FOLDER/$FT_DEV_PREFIX.prepro.$SOURCE_LANG_SUFFIX
    $moses_scripts/recaser/truecase.perl < $CORPUS_FOLDER/$FT_DEV_PREFIX.$TARGET_LANG_SUFFIX > $CORPUS_FOLDER/$FT_DEV_PREFIX.prepro.$TARGET_LANG_SUFFIX -model $CORPUS_FOLDER/truecase-model.$TARGET_LANG_SUFFIX    


rm -r $CORPUS_FOLDER/fairseq_prepared_data_finetuning_"$FT_NAME"/

fairseq-preprocess --source-lang $SOURCE_LANG_SUFFIX \
--target-lang $TARGET_LANG_SUFFIX \
--trainpref $CORPUS_FOLDER/$FT_TRAIN_PREFIX.prepro.spm \
--validpref $CORPUS_FOLDER/$FT_DEV_PREFIX.prepro.spm \
--testpref $CORPUS_FOLDER/$FT_DEV_PREFIX.prepro.spm \
--destdir $CORPUS_FOLDER/fairseq_prepared_data_finetuning_"$FT_NAME" \
--srcdict $CORPUS_FOLDER/fairseq_prepared_data/dict.$SOURCE_LANG_SUFFIX.txt \
--joined-dictionary \
--workers 1
