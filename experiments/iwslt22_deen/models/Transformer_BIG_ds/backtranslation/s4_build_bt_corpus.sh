source config_bt.sh

for i in $(seq 1 $max_split_suffix); do
a=$(wc -l splits_mono_prepro/split.$i.prepro.bpe | cut -d" " -f 1)
b=$(cat synthetic_source/backtrans.$i | grep -P '^H' | cut -f3- | wc -l)

#cut -d" " -f 1

if [ "$a" -eq "$b" ]
then
    cat splits_mono_prepro/split.$i.prepro.bpe >> backtrans.bpe.$TARGET_LANG_SUFFIX
    cat synthetic_source/backtrans.$i | grep -P '^H' | cut -f3- >> backtrans.bpe.$SOURCE_LANG_SUFFIX
else
    echo "WARN: Detected problem in file $i"
fi

done

cat backtrans.bpe.$SOURCE_LANG_SUFFIX | sed -r 's/\@\@ //g' | $moses_scripts/recaser/detruecase.perl | $moses_scripts/tokenizer/detokenizer.perl -l $SOURCE_LANG_SUFFIX > backtrans.$SOURCE_LANG_SUFFIX
cat backtrans.bpe.$TARGET_LANG_SUFFIX | sed -r 's/\@\@ //g' | $moses_scripts/recaser/detruecase.perl | $moses_scripts/tokenizer/detokenizer.perl -l $TARGET_LANG_SUFFIX > backtrans.$TARGET_LANG_SUFFIX

