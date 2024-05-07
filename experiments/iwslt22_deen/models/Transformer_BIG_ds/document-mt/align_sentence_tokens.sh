INPUT_SUFFIX=$1
SRC_LANG=$2
TGT_LANG=$3
OUTPUT_SUFFIX=$4

cat $INPUT_SUFFIX.$SRC_LANG | ~/trabajo/git/mosesdecoder/scripts/tokenizer/tokenizer.perl -l $SRC_LANG -no-escape -protected /home/jiranzo/trabajo/git/nmt-scripts/tokenizer_protected_patterns > $OUTPUT_SUFFIX.$SRC_LANG.input.tok
cat $INPUT_SUFFIX.$TGT_LANG | ~/trabajo/git/mosesdecoder/scripts/tokenizer/tokenizer.perl -l $TGT_LANG -no-escape -protected /home/jiranzo/trabajo/git/nmt-scripts/tokenizer_protected_patterns > $OUTPUT_SUFFIX.$TGT_LANG.input.tok

#Quite hacky. One delimiter character per fil. See https://unix.stackexchange.com/questions/115754/paste-command-setting-multiple-delimiters
paste $OUTPUT_SUFFIX.$SRC_LANG.input.tok /dev/null /dev/null /dev/null /dev/null $OUTPUT_SUFFIX.$TGT_LANG.input.tok -d ' ||| ' > $OUTPUT_SUFFIX."$SRC_LANG"-"$TGT_LANG".input.tok

#Forward alignment: i-j. Means that target word j is aligned with input word i.
/home/jiranzo/trabajo/git/fast_align/build/fast_align -i $OUTPUT_SUFFIX."$SRC_LANG"-"$TGT_LANG".input.tok -d -o -v > $OUTPUT_SUFFIX.forward.align

#So maybe we need reverse alignment
/home/jiranzo/trabajo/git/fast_align/build/fast_align -i $OUTPUT_SUFFIX."$SRC_LANG"-"$TGT_LANG".input.tok -d -o -v -r > $OUTPUT_SUFFIX.reverse.align

/home/jiranzo/trabajo/git/fast_align/build/atools -i $OUTPUT_SUFFIX.forward.align -j $OUTPUT_SUFFIX.reverse.align -c grow-diag-final-and > $OUTPUT_SUFFIX.grow-diag-final.align

rm $OUTPUT_SUFFIX.$SRC_LANG.input.tok $OUTPUT_SUFFIX.$TGT_LANG.input.tok $OUTPUT_SUFFIX."$SRC_LANG"-"$TGT_LANG".input.tok
