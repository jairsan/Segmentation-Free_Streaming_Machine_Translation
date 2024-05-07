SCRIPT="$(readlink --canonicalize-existing "$0")"
SCRIPTPATH="$(dirname "$SCRIPT")"
source $SCRIPTPATH/config.sh
moses_scripts=/scratch/jiranzo/trabajo/git/mosesdecoder/scripts


cat $ORIG_CLEAN_DATA_TRAIN_PREFIX.$SOURCE_LANG_SUFFIX | $moses_scripts/tokenizer/normalize-punctuation.perl -l $SOURCE_LANG_SUFFIX | $moses_scripts/tokenizer/tokenizer.perl -a -l $SOURCE_LANG_SUFFIX > $ORIG_CLEAN_DATA_TRAIN_PREFIX.tmp.$SOURCE_LANG_SUFFIX
cat $ORIG_CLEAN_DATA_TRAIN_PREFIX.$TARGET_LANG_SUFFIX | $moses_scripts/tokenizer/normalize-punctuation.perl -l $TARGET_LANG_SUFFIX | $moses_scripts/tokenizer/tokenizer.perl -a -l $TARGET_LANG_SUFFIX > $ORIG_CLEAN_DATA_TRAIN_PREFIX.tmp.$TARGET_LANG_SUFFIX

$moses_scripts/training/clean-corpus-n.perl $ORIG_CLEAN_DATA_TRAIN_PREFIX.tmp $SOURCE_LANG_SUFFIX $TARGET_LANG_SUFFIX $ORIG_CLEAN_DATA_TRAIN_PREFIX.tmp.clean 1 85

$moses_scripts/recaser/train-truecaser.perl -model $SCRIPTPATH/truecase-model.$SOURCE_LANG_SUFFIX -corpus $ORIG_CLEAN_DATA_TRAIN_PREFIX.tmp.clean.$SOURCE_LANG_SUFFIX
$moses_scripts/recaser/truecase.perl < $ORIG_CLEAN_DATA_TRAIN_PREFIX.tmp.clean.$SOURCE_LANG_SUFFIX > $ORIG_CLEAN_DATA_TRAIN_PREFIX.prepro.$SOURCE_LANG_SUFFIX -model $SCRIPTPATH/truecase-model.$SOURCE_LANG_SUFFIX

$moses_scripts/recaser/train-truecaser.perl -model $SCRIPTPATH/truecase-model.$TARGET_LANG_SUFFIX -corpus $ORIG_CLEAN_DATA_TRAIN_PREFIX.tmp.clean.$TARGET_LANG_SUFFIX
$moses_scripts/recaser/truecase.perl < $ORIG_CLEAN_DATA_TRAIN_PREFIX.tmp.clean.$TARGET_LANG_SUFFIX > $ORIG_CLEAN_DATA_TRAIN_PREFIX.prepro.$TARGET_LANG_SUFFIX -model $SCRIPTPATH/truecase-model.$TARGET_LANG_SUFFIX

./preprocess_file.sh -t $SCRIPTPATH/truecase-model.$SOURCE_LANG_SUFFIX -- $ORIG_CLEAN_DATA_DEV_PREFIX $SOURCE_LANG_SUFFIX
./preprocess_file.sh -t $SCRIPTPATH/truecase-model.$TARGET_LANG_SUFFIX -- $ORIG_CLEAN_DATA_DEV_PREFIX $TARGET_LANG_SUFFIX

rm $ORIG_CLEAN_DATA_TRAIN_PREFIX.tmp.$TARGET_LANG_SUFFIX
rm $ORIG_CLEAN_DATA_TRAIN_PREFIX.tmp.$SOURCE_LANG_SUFFIX
rm $ORIG_CLEAN_DATA_TRAIN_PREFIX.tmp.clean.$TARGET_LANG_SUFFIX
rm $ORIG_CLEAN_DATA_TRAIN_PREFIX.tmp.clean.$SOURCE_LANG_SUFFIX
