# USAGE ./preprocess_and_bpe_file.sh [-t MODEL_PREFIX] -- FILE_PREFIX LANG
truecase=false
source config.sh
source $PYTHON_ENV
NAME=bpe
FOLDER=$CORPUS_FOLDER


while [ -n "$1" ]; do 
 
    case "$1" in
 
    -t) truecase=true
        tc_model="$2"
        shift
        ;;
    --) shift
    	break
    	;; 
 
    esac
    shift
done

file_prefix=$1
lang=$2

if [ "$truecase" = true ]; then
    cat $file_prefix.$lang | $moses_scripts/tokenizer/tokenizer.perl -a -l $lang -no-escape -protected /home/jiranzo/trabajo/git/nmt-scripts/tokenizer_protected_patterns | $moses_scripts/recaser/truecase.perl -model $CORPUS_FOLDER/$tc_model.$lang | $SUBWORD_FOLDER/apply_bpe.py -c $FOLDER/$NAME.codes --vocabulary $FOLDER/$NAME.vocab.$lang --vocabulary-threshold 50 
else
    cat $file_prefix.$lang | $moses_scripts/tokenizer/tokenizer.perl -a -l $lang -no-escape -protected /home/jiranzo/trabajo/git/nmt-scripts/tokenizer_protected_patterns | $moses_scripts/tokenizer/lowercase.perl | $SUBWORD_FOLDER/apply_bpe.py -c $FOLDER/$NAME.codes --vocabulary $FOLDER/$NAME.vocab.$lang --vocabulary-threshold 50 

fi
