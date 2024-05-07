source config.sh

mkdir filtered

for s in 100000 2000000 5000000; do
python3 select_sentences.py total.scores $ORIG_NOISY_DATA_PREFIX.prepro.$SOURCE_LANG_SUFFIX $ORIG_NOISY_DATA_PREFIX.prepro.$TARGET_LANG_SUFFIX filtered/corpus.$s.prepro.$SOURCE_LANG_SUFFIX  filtered/corpus.$s.prepro.$TARGET_LANG_SUFFIX $s

done
