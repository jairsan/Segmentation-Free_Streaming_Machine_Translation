source config.sh

echo "This script is provided as an example"
echo "Please make sure that you have first edited this file in order to extract the correct data"

cat /scratch/translectures/data/news-crawl/cleaned/news-crawl.2017.filtered.cleaned_subset.de | shuf | head -n 1000000 | $moses_scripts/tokenizer/tokenizer.perl  -l $SOURCE_LANG_SUFFIX > lm_I_src.data
cat noisy_data.de | shuf | head -n 1000000 | $moses_scripts/tokenizer/tokenizer.perl  -l $SOURCE_LANG_SUFFIX > lm_N_src.data


zcat /scratch/translectures/data/news-crawl/raw/news.2018.fr.shuffled.deduped.gz | shuf | head -n 1000000 | $moses_scripts/tokenizer/tokenizer.perl  -l $TARGET_LANG_SUFFIX > lm_I_tgt.data
cat noisy_data.fr | shuf | head -n 1000000 | $moses_scripts/tokenizer/tokenizer.perl  -l $TARGET_LANG_SUFFIX > lm_N_tgt.data





