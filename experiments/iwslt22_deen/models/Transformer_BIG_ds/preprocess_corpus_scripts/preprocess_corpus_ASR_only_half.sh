#Setup run-specifig config
source config.sh
source $PYTHON_ENV
LC_ALL=C.UTF-8

    cat $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.$SOURCE_LANG_SUFFIX | sed -n 'n;p' > $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.$SOURCE_LANG_SUFFIX.asr_even
    cat $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.$SOURCE_LANG_SUFFIX | sed -n 'p;n' > $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.$SOURCE_LANG_SUFFIX.mt_odd

    $ASR_FILE_PROCESSOR $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.$SOURCE_LANG_SUFFIX.asr_even > $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.$SOURCE_LANG_SUFFIX.asr_even
    cat $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.$SOURCE_LANG_SUFFIX.mt_odd | $moses_scripts/tokenizer/tokenizer.perl -a -l $SOURCE_LANG_SUFFIX -protected /home/jiranzo/trabajo/git/nmt-scripts/tokenizer_protected_patterns > $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.$SOURCE_LANG_SUFFIX.mt_odd

    cat $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.$TARGET_LANG_SUFFIX | $moses_scripts/tokenizer/tokenizer.perl -a -l $TARGET_LANG_SUFFIX -protected /home/jiranzo/trabajo/git/nmt-scripts/tokenizer_protected_patterns > $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.$TARGET_LANG_SUFFIX
    
    $moses_scripts/recaser/train-truecaser.perl -model $CORPUS_FOLDER/truecase-model.$SOURCE_LANG_SUFFIX -corpus $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.$SOURCE_LANG_SUFFIX.mt_odd
    $moses_scripts/recaser/train-truecaser.perl -model $CORPUS_FOLDER/truecase-model.$TARGET_LANG_SUFFIX -corpus $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.$TARGET_LANG_SUFFIX


    $moses_scripts/recaser/truecase.perl < $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.$SOURCE_LANG_SUFFIX.mt_odd > $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.true.$SOURCE_LANG_SUFFIX.mt_odd -model $CORPUS_FOLDER/truecase-model.$TARGET_LANG_SUFFIX
    $moses_scripts/recaser/truecase.perl < $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.$TARGET_LANG_SUFFIX > $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.true.$TARGET_LANG_SUFFIX -model $CORPUS_FOLDER/truecase-model.$TARGET_LANG_SUFFIX
    

    python3 asr-prepro/join_even_odd.py $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.true.$SOURCE_LANG_SUFFIX.mt_odd $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.$SOURCE_LANG_SUFFIX.asr_even  > $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.true.$SOURCE_LANG_SUFFIX

    $moses_scripts/training/clean-corpus-n.perl -ratio $SOURCE_TARGET_RATIO $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.true $SOURCE_LANG_SUFFIX $TARGET_LANG_SUFFIX $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.prepro 1 $MAX_LENGTH_PREPRO    


    ./preprocess_file_no_norm.sh -t $CORPUS_FOLDER/truecase-model.$TARGET_LANG_SUFFIX -- $CORPUS_FOLDER/$ORIG_DEV_PREFIX $TARGET_LANG_SUFFIX
    ./preprocess_file_no_norm.sh -t $CORPUS_FOLDER/truecase-model.$TARGET_LANG_SUFFIX -- $CORPUS_FOLDER/$ORIG_TEST_PREFIX $TARGET_LANG_SUFFIX
    ./preprocess_file_no_norm.sh -t $CORPUS_FOLDER/truecase-model.$SOURCE_LANG_SUFFIX -- $CORPUS_FOLDER/$ORIG_DEV_PREFIX $SOURCE_LANG_SUFFIX
    ./preprocess_file_no_norm.sh -t $CORPUS_FOLDER/truecase-model.$SOURCE_LANG_SUFFIX -- $CORPUS_FOLDER/$ORIG_TEST_PREFIX $SOURCE_LANG_SUFFIX

rm $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.$SOURCE_LANG_SUFFIX.asr_even $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.$SOURCE_LANG_SUFFIX.mt_odd $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.$SOURCE_LANG_SUFFIX.asr_even $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.$SOURCE_LANG_SUFFIX.mt_odd $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.$TARGET_LANG_SUFFIX $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.true.$SOURCE_LANG_SUFFIX.mt_odd $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.true.$TARGET_LANG_SUFFIX $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.true.$SOURCE_LANG_SUFFIX

