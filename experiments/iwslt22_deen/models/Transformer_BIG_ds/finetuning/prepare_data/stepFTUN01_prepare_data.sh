source config.sh

#Load Python environment
source $PYTHON_ENV
export LC_ALL=C.UTF-8

FT_TRAIN_PREFIX=$1
FT_DEV_PREFIX=$2
FT_NAME=$3


NAME=bpe
FOLDER=$CORPUS_FOLDER


#Train    
    #Prepare tgt
    ./preprocess_and_bpe_file_v2.sh -t truecase-model -- $FT_TRAIN_PREFIX $TARGET_LANG_SUFFIX > $CORPUS_FOLDER/$FT_TRAIN_PREFIX.prepro.bpe.$TARGET_LANG_SUFFIX
    ./preprocess_and_bpe_file_v2.sh -t truecase-model -- $FT_TRAIN_PREFIX $SOURCE_LANG_SUFFIX > $CORPUS_FOLDER/$FT_TRAIN_PREFIX.prepro.bpe.$SOURCE_LANG_SUFFIX

#Dev
    #Prepare tgt
    ./preprocess_and_bpe_file_v2.sh -t truecase-model -- $FT_DEV_PREFIX $TARGET_LANG_SUFFIX > $CORPUS_FOLDER/$FT_DEV_PREFIX.prepro.bpe.$TARGET_LANG_SUFFIX
    ./preprocess_and_bpe_file_v2.sh -t truecase-model -- $FT_DEV_PREFIX $SOURCE_LANG_SUFFIX > $CORPUS_FOLDER/$FT_DEV_PREFIX.prepro.bpe.$SOURCE_LANG_SUFFIX

rm -r $CORPUS_FOLDER/fairseq_prepared_data_finetuning_"$FT_NAME"/

fairseq-preprocess --source-lang $SOURCE_LANG_SUFFIX \
--target-lang $TARGET_LANG_SUFFIX \
--trainpref $CORPUS_FOLDER/$FT_TRAIN_PREFIX.prepro.bpe \
--validpref $CORPUS_FOLDER/$FT_DEV_PREFIX.prepro.bpe \
--testpref $CORPUS_FOLDER/$FT_DEV_PREFIX.prepro.bpe \
--destdir $CORPUS_FOLDER/fairseq_prepared_data_finetuning_"$FT_NAME" \
--srcdict $CORPUS_FOLDER/fairseq_prepared_data/dict.$SOURCE_LANG_SUFFIX.txt \
--joined-dictionary \
--workers 1 


