#Warning: Work in Progress
#Setup run-specifig config
SCRIPT="$(readlink --canonicalize-existing "$0")"
SCRIPTPATH="$(dirname "$SCRIPT")"

SUBWORD_FOLDER=/home/jiranzo/trabajo/git/subword-nmt
moses_scripts=/scratch/jiranzo/trabajo/git/mosesdecoder/scripts

source $SCRIPTPATH/config.sh
source $PYTHON_ENV


cat $ORIG_NOISY_DATA_PREFIX.$SOURCE_LANG_SUFFIX | $moses_scripts/tokenizer/normalize-punctuation.perl -l $SOURCE_LANG_SUFFIX | $moses_scripts/tokenizer/tokenizer.perl -a -l $SOURCE_LANG_SUFFIX > $ORIG_NOISY_DATA_PREFIX.tmp.$SOURCE_LANG_SUFFIX
cat $ORIG_NOISY_DATA_PREFIX.$TARGET_LANG_SUFFIX | $moses_scripts/tokenizer/normalize-punctuation.perl -l $TARGET_LANG_SUFFIX | $moses_scripts/tokenizer/tokenizer.perl -a -l $TARGET_LANG_SUFFIX > $ORIG_NOISY_DATA_PREFIX.tmp.$TARGET_LANG_SUFFIX

$moses_scripts/recaser/truecase.perl < $ORIG_NOISY_DATA_PREFIX.tmp.$SOURCE_LANG_SUFFIX > $ORIG_NOISY_DATA_PREFIX.prepro.$SOURCE_LANG_SUFFIX -model $SCRIPTPATH/truecase-model.$SOURCE_LANG_SUFFIX
$moses_scripts/recaser/truecase.perl < $ORIG_NOISY_DATA_PREFIX.tmp.$TARGET_LANG_SUFFIX > $ORIG_NOISY_DATA_PREFIX.prepro.$TARGET_LANG_SUFFIX -model $SCRIPTPATH/truecase-model.$TARGET_LANG_SUFFIX

L1=$SOURCE_LANG_SUFFIX
L2=$TARGET_LANG_SUFFIX
NAME=bpe_clean
FOLDER=$CORPUS_FOLDER

$SUBWORD_FOLDER/apply_bpe.py -c $FOLDER/$NAME.codes --vocabulary $FOLDER/$NAME.vocab.$L1 --vocabulary-threshold 50 < $ORIG_NOISY_DATA_PREFIX.prepro.$L1 > $FOLDER/`basename $ORIG_NOISY_DATA_PREFIX.prepro.bpe.tmp.$L1`
$SUBWORD_FOLDER/apply_bpe.py -c $FOLDER/$NAME.codes --vocabulary $FOLDER/$NAME.vocab.$L2 --vocabulary-threshold 50 < $ORIG_NOISY_DATA_PREFIX.prepro.$L2 > $FOLDER/`basename $ORIG_NOISY_DATA_PREFIX.prepro.bpe.tmp.$L2`

#We clean with upper limit set to the system max_length, otherwise there will be problems in scoring.
$moses_scripts/training/clean-corpus-n.perl $ORIG_NOISY_DATA_PREFIX.prepro.bpe.tmp $SOURCE_LANG_SUFFIX $TARGET_LANG_SUFFIX $ORIG_NOISY_DATA_PREFIX.prepro.bpe 1 $MAX_SEQ_LEN

rm $ORIG_NOISY_DATA_PREFIX.prepro.bpe.tmp.$SOURCE_LANG_SUFFIX
rm $ORIG_NOISY_DATA_PREFIX.prepro.bpe.tmp.$TARGET_LANG_SUFFIX





