# USAGE ./bpe_file FILE_PREFIX LANG
truecase=false

source config.sh
source $PYTHON_ENV
NAME=bpe
FOLDER=$CORPUS_FOLDER




file_prefix=$1
lang=$2


cat $file_prefix.$lang | $SUBWORD_FOLDER/apply_bpe.py -c $FOLDER/$NAME.codes --vocabulary $FOLDER/$NAME.vocab.$lang --vocabulary-threshold 50 > $file_prefix.bpe.$lang


