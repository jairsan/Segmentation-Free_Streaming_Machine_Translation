INPUT_SUFFIX=corpus
SRC_LANG=en
TGT_LANG=de
OUTPUT_SUFFIX=corpus

SRC_PREPRO=/home/jiranzo/trabajo/git/nmt-scripts/asr-prepro/prepro_en_file.TTP-Jun19.sh
TGT_PREPRO=/home/jiranzo/trabajo/git/nmt-scripts/asr-prepro/prepro_de_file.sh

$SRC_PREPRO $INPUT_SUFFIX.$SRC_LANG > $OUTPUT_SUFFIX.input.tok.dirty.$SRC_LANG 
$TGT_PREPRO $INPUT_SUFFIX.$TGT_LANG > $OUTPUT_SUFFIX.input.tok.dirty.$TGT_LANG

~/trabajo/git/mosesdecoder/scripts/training/clean-corpus-n.perl $OUTPUT_SUFFIX.input.tok.dirty $SRC_LANG $TGT_LANG $OUTPUT_SUFFIX.input.tok 1 80

#Quite hacky. One delimiter character per fil. See https://unix.stackexchange.com/questions/115754/paste-command-setting-multiple-delimiters
paste $OUTPUT_SUFFIX.input.tok.$SRC_LANG /dev/null /dev/null /dev/null /dev/null $OUTPUT_SUFFIX.input.tok.$TGT_LANG -d ' ||| ' > $OUTPUT_SUFFIX."$SRC_LANG"-"$TGT_LANG".input.tok

#Forward alignment: i-j. Means that target word j is aligned with input word i.
/home/jiranzo/trabajo/git/fast_align/build/fast_align -i $OUTPUT_SUFFIX."$SRC_LANG"-"$TGT_LANG".input.tok -d -o -v > $OUTPUT_SUFFIX.forward.align

#So maybe we need reverse alignment
/home/jiranzo/trabajo/git/fast_align/build/fast_align -i $OUTPUT_SUFFIX."$SRC_LANG"-"$TGT_LANG".input.tok -d -o -v -r > $OUTPUT_SUFFIX.reverse.align

# As a result, get alignments i-j. There might be multiple words aligned with a single target word, that is len(alignments) > len(tgt_tokens)
/home/jiranzo/trabajo/git/fast_align/build/atools -i $OUTPUT_SUFFIX.forward.align -j $OUTPUT_SUFFIX.reverse.align -c grow-diag-final-and > $OUTPUT_SUFFIX.grow-diag-final.align

rm $OUTPUT_SUFFIX."$SRC_LANG"-"$TGT_LANG".input.tok $OUTPUT_SUFFIX.input.tok.dirty.$SRC_LANG $OUTPUT_SUFFIX.input.tok.dirty.$TGT_LANG
#Optionally
#rm $OUTPUT_SUFFIX.forward.align $OUTPUT_SUFFIX.reverse.align

