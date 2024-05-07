# USAGE ./preprocess_file [-t MODEL_PREFIX] -- FILE_PREFIX LANG
source config.sh
LC_ALL=C.UTF-8
truecase=false

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
    cat $file_prefix.$lang | $moses_scripts/tokenizer/tokenizer.perl -a -l $lang -protected /home/jiranzo/trabajo/git/nmt-scripts/tokenizer_protected_patterns | $moses_scripts/recaser/truecase.perl -model $tc_model > $file_prefix.prepro.$lang
else
    cat $file_prefix.$lang | $moses_scripts/tokenizer/tokenizer.perl -a -l $lang -protected /home/jiranzo/trabajo/git/nmt-scripts/tokenizer_protected_patterns | $moses_scripts/tokenizer/lowercase.perl > $file_prefix.prepro.$lang

fi
