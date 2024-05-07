source config.sh

export LC_ALL=C.UTF-8

$moses_scripts/training/clean-corpus-n.perl -ratio $SOURCE_TARGET_RATIO $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX $SOURCE_LANG_SUFFIX $TARGET_LANG_SUFFIX $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.clean 1 $MAX_LENGTH_PREPRO
cat $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.clean.$SOURCE_LANG_SUFFIX | $moses_scripts/tokenizer/tokenizer.perl -a -l $SOURCE_LANG_SUFFIX -no-escape -protected /home/jiranzo/trabajo/git/nmt-scripts/tokenizer_protected_patterns > $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.clean2.$SOURCE_LANG_SUFFIX
cat $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.clean.$TARGET_LANG_SUFFIX | $moses_scripts/tokenizer/tokenizer.perl -a -l $TARGET_LANG_SUFFIX -no-escape -protected /home/jiranzo/trabajo/git/nmt-scripts/tokenizer_protected_patterns > $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.clean2.$TARGET_LANG_SUFFIX

$moses_scripts/recaser/train-truecaser.perl -model $CORPUS_FOLDER/truecase-model.$SOURCE_LANG_SUFFIX -corpus $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.clean2.$SOURCE_LANG_SUFFIX
$moses_scripts/recaser/train-truecaser.perl -model $CORPUS_FOLDER/truecase-model.$TARGET_LANG_SUFFIX -corpus $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.clean2.$TARGET_LANG_SUFFIX

$moses_scripts/recaser/truecase.perl < $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.clean2.$SOURCE_LANG_SUFFIX > $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.prepro.$SOURCE_LANG_SUFFIX -model $CORPUS_FOLDER/truecase-model.$SOURCE_LANG_SUFFIX
$moses_scripts/recaser/truecase.perl < $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.clean2.$TARGET_LANG_SUFFIX > $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.prepro.$TARGET_LANG_SUFFIX -model $CORPUS_FOLDER/truecase-model.$TARGET_LANG_SUFFIX

rm $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.clean.$SOURCE_LANG_SUFFIX $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.clean.$TARGET_LANG_SUFFIX $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.clean2.$SOURCE_LANG_SUFFIX $CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.tmp.clean2.$TARGET_LANG_SUFFIX


cat $CORPUS_FOLDER/$ORIG_DEV_PREFIX.$SOURCE_LANG_SUFFIX | $moses_scripts/tokenizer/tokenizer.perl -a -l $SOURCE_LANG_SUFFIX -no-escape -protected /home/jiranzo/trabajo/git/nmt-scripts/tokenizer_protected_patterns | $moses_scripts/recaser/truecase.perl > $CORPUS_FOLDER/$ORIG_DEV_PREFIX.prepro.$SOURCE_LANG_SUFFIX -model $CORPUS_FOLDER/truecase-model.$SOURCE_LANG_SUFFIX
cat $CORPUS_FOLDER/$ORIG_DEV_PREFIX.$TARGET_LANG_SUFFIX | $moses_scripts/tokenizer/tokenizer.perl -a -l $TARGET_LANG_SUFFIX -no-escape -protected /home/jiranzo/trabajo/git/nmt-scripts/tokenizer_protected_patterns | $moses_scripts/recaser/truecase.perl > $CORPUS_FOLDER/$ORIG_DEV_PREFIX.prepro.$TARGET_LANG_SUFFIX -model $CORPUS_FOLDER/truecase-model.$TARGET_LANG_SUFFIX

cat $CORPUS_FOLDER/$ORIG_TEST_PREFIX.$SOURCE_LANG_SUFFIX | $moses_scripts/tokenizer/tokenizer.perl -a -l $SOURCE_LANG_SUFFIX -no-escape -protected /home/jiranzo/trabajo/git/nmt-scripts/tokenizer_protected_patterns | $moses_scripts/recaser/truecase.perl > $CORPUS_FOLDER/$ORIG_TEST_PREFIX.prepro.$SOURCE_LANG_SUFFIX -model $CORPUS_FOLDER/truecase-model.$SOURCE_LANG_SUFFIX
cat $CORPUS_FOLDER/$ORIG_TEST_PREFIX.$TARGET_LANG_SUFFIX | $moses_scripts/tokenizer/tokenizer.perl -a -l $TARGET_LANG_SUFFIX -no-escape -protected /home/jiranzo/trabajo/git/nmt-scripts/tokenizer_protected_patterns | $moses_scripts/recaser/truecase.perl > $CORPUS_FOLDER/$ORIG_TEST_PREFIX.prepro.$TARGET_LANG_SUFFIX -model $CORPUS_FOLDER/truecase-model.$TARGET_LANG_SUFFIX


