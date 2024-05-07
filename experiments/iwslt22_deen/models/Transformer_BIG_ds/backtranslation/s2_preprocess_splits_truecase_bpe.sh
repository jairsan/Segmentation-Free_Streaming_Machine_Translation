source config_bt.sh
source $PYTHON_ENV 
lang=$TARGET_LANG_SUFFIX # Language of the mono data

mkdir splits_mono_prepro

# Tokenize and truecase using the truecasing model trained on the general domain corpora
for file in splits_mono/split.*; do
    name=$(basename $file)
    cat $file | $moses_scripts/tokenizer/tokenizer.perl -a -l $lang -no-escape -protected /home/jiranzo/trabajo/git/nmt-scripts/tokenizer_protected_patterns | $moses_scripts/recaser/truecase.perl > splits_mono_prepro/$name.prepro -model $PREPRO_MODELS_PATH/truecase-model.$lang

done

# Apply BPE using BPE models trained on the general domain corpora
for file in splits_mono_prepro/*.prepro; do
    cat $file | $SUBWORD_FOLDER/apply_bpe.py -c $PREPRO_MODELS_PATH/bpe.codes --vocabulary $PREPRO_MODELS_PATH/bpe.vocab.$lang  --vocabulary-threshold 50 > $file.bpe
done

rm splits_mono_prepro/*.prepro

deactivate
