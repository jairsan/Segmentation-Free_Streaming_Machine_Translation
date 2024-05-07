SCRIPT="$(readlink --canonicalize-existing "$0")"
SCRIPTPATH="$(dirname "$SCRIPT")"
source $SCRIPTPATH/config.sh
source $PYTHON_ENV
SUBWORD_FOLDER=/home/jiranzo/trabajo/git/subword-nmt
moses_scripts=/scratch/jiranzo/trabajo/git/mosesdecoder/scripts

TRAIN_FILE_PREFIX=$CORPUS_FOLDER/$ORIG_CLEAN_DATA_TRAIN_PREFIX.prepro
DEV_FILE_PREFIX=$CORPUS_FOLDER/$ORIG_CLEAN_DATA_DEV_PREFIX.prepro
L1=$SOURCE_LANG_SUFFIX
L2=$TARGET_LANG_SUFFIX
NAME=bpe_clean
FOLDER=$CORPUS_FOLDER

$SUBWORD_FOLDER/learn_joint_bpe_and_vocab.py --input $TRAIN_FILE_PREFIX.$L1 $TRAIN_FILE_PREFIX.$L2 -s $BPE_OPERATIONS -o $FOLDER/$NAME.codes --write-vocabulary $FOLDER/$NAME.vocab.$L1 $FOLDER/$NAME.vocab.$L2

$SUBWORD_FOLDER/apply_bpe.py -c $FOLDER/$NAME.codes --vocabulary $FOLDER/$NAME.vocab.$L1 --vocabulary-threshold 50 < $TRAIN_FILE_PREFIX.$L1 > $FOLDER/`basename $TRAIN_FILE_PREFIX.bpe.$L1`
$SUBWORD_FOLDER/apply_bpe.py -c $FOLDER/$NAME.codes --vocabulary $FOLDER/$NAME.vocab.$L2 --vocabulary-threshold 50 < $TRAIN_FILE_PREFIX.$L2 > $FOLDER/`basename $TRAIN_FILE_PREFIX.bpe.$L2`
 
$SUBWORD_FOLDER/apply_bpe.py -c $FOLDER/$NAME.codes --vocabulary $FOLDER/$NAME.vocab.$L1 --vocabulary-threshold 50 < $DEV_FILE_PREFIX.$L1 > $FOLDER/`basename $DEV_FILE_PREFIX.bpe.$L1`
$SUBWORD_FOLDER/apply_bpe.py -c $FOLDER/$NAME.codes --vocabulary $FOLDER/$NAME.vocab.$L2 --vocabulary-threshold 50 < $DEV_FILE_PREFIX.$L2 > $FOLDER/`basename $DEV_FILE_PREFIX.bpe.$L2`
