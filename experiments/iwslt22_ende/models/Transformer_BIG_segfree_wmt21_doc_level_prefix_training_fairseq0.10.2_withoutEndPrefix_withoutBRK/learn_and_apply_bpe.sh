source config.sh
source $PYTHON_ENV
export LC_ALL=C.UTF-8

TRAIN_FILE_PREFIX=$CORPUS_FOLDER/$ORIG_TRAIN_PREFIX.prepro
DEV_FILE_PREFIX=$CORPUS_FOLDER/$ORIG_DEV_PREFIX.prepro
TEST_FILE_PREFIX=$CORPUS_FOLDER/$ORIG_TEST_PREFIX.prepro
L1=$SOURCE_LANG_SUFFIX
L2=$TARGET_LANG_SUFFIX
NAME=bpe
FOLDER=$CORPUS_FOLDER

echo "Learning BPE..."
$SUBWORD_FOLDER/learn_joint_bpe_and_vocab.py --input $TRAIN_FILE_PREFIX.$L1 $TRAIN_FILE_PREFIX.$L2 -s $BPE_OPERATIONS -o $FOLDER/$NAME.codes --write-vocabulary $FOLDER/$NAME.vocab.$L1 $FOLDER/$NAME.vocab.$L2

echo "Applying BPE..."
$SUBWORD_FOLDER/apply_bpe.py -c $FOLDER/$NAME.codes --vocabulary $FOLDER/$NAME.vocab.$L1 --vocabulary-threshold 50 < $TRAIN_FILE_PREFIX.$L1 > $FOLDER/`basename $TRAIN_FILE_PREFIX.bpe.$L1`
$SUBWORD_FOLDER/apply_bpe.py -c $FOLDER/$NAME.codes --vocabulary $FOLDER/$NAME.vocab.$L2 --vocabulary-threshold 50 < $TRAIN_FILE_PREFIX.$L2 > $FOLDER/`basename $TRAIN_FILE_PREFIX.bpe.$L2`
 
$SUBWORD_FOLDER/apply_bpe.py -c $FOLDER/$NAME.codes --vocabulary $FOLDER/$NAME.vocab.$L1 --vocabulary-threshold 50 < $DEV_FILE_PREFIX.$L1 > $FOLDER/`basename $DEV_FILE_PREFIX.bpe.$L1`
$SUBWORD_FOLDER/apply_bpe.py -c $FOLDER/$NAME.codes --vocabulary $FOLDER/$NAME.vocab.$L2 --vocabulary-threshold 50 < $DEV_FILE_PREFIX.$L2 > $FOLDER/`basename $DEV_FILE_PREFIX.bpe.$L2`
 
$SUBWORD_FOLDER/apply_bpe.py -c $FOLDER/$NAME.codes --vocabulary $FOLDER/$NAME.vocab.$L1 --vocabulary-threshold 50 < $TEST_FILE_PREFIX.$L1 > $FOLDER/`basename $TEST_FILE_PREFIX.bpe.$L1`
$SUBWORD_FOLDER/apply_bpe.py -c $FOLDER/$NAME.codes --vocabulary $FOLDER/$NAME.vocab.$L2 --vocabulary-threshold 50 < $TEST_FILE_PREFIX.$L2 > $FOLDER/`basename $TEST_FILE_PREFIX.bpe.$L2`

deactivate

