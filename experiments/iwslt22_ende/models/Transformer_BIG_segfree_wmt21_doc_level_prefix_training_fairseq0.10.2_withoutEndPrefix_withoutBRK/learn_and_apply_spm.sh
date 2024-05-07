source config.sh

export LC_ALL=C.UTF-8

echo "WARNING: Remember to launch locally on a machine with spm installed" 


function apply_spm {
    prefix=$1
    lang=$2
    spm_encode --model=$CORPUS_FOLDER/spm.model --vocabulary $CORPUS_FOLDER/spm.vocab.$lang --vocabulary_threshold=50 --output_format=id < $CORPUS_FOLDER/$prefix.prepro.$lang > $CORPUS_FOLDER/$prefix.prepro.spm.$lang

}

spm_train --input $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.prepro.$SOURCE_LANG_SUFFIX,$CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.prepro.$TARGET_LANG_SUFFIX --input_format=text --input_sentence_size=10000000 --shuffle_input_sentence=true --model_prefix=$CORPUS_FOLDER/spm --pad_id=3 --treat_whitespace_as_suffix=true --vocab_size=50000 --model_type=bpe --character_coverage=0.9995 --user_defined_symbols=[BRK]▁,[CONT]▁,[END]▁,[DOC]▁,[BT]▁,[SEP]▁,[EndPrefix]▁

spm_encode --model=$CORPUS_FOLDER/spm.model --generate_vocabulary < $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.prepro.$SOURCE_LANG_SUFFIX > $CORPUS_FOLDER/spm.vocab.$SOURCE_LANG_SUFFIX
spm_encode --model=$CORPUS_FOLDER/spm.model --generate_vocabulary < $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.prepro.$TARGET_LANG_SUFFIX > $CORPUS_FOLDER/spm.vocab.$TARGET_LANG_SUFFIX

apply_spm $ORIG_TRAIN_PREFIX $SOURCE_LANG_SUFFIX
apply_spm $ORIG_TRAIN_PREFIX $TARGET_LANG_SUFFIX
apply_spm $ORIG_DEV_PREFIX $SOURCE_LANG_SUFFIX
apply_spm $ORIG_DEV_PREFIX $TARGET_LANG_SUFFIX
apply_spm $ORIG_TEST_PREFIX $SOURCE_LANG_SUFFIX
apply_spm $ORIG_TEST_PREFIX $TARGET_LANG_SUFFIX
