#Setup run-specifig config
SCRIPT="$(readlink --canonicalize-existing "$0")"
SCRIPTPATH="$(dirname "$SCRIPT")"
source $SCRIPTPATH/config.sh

source $PYTHON_ENV

cat $CORPUS_FOLDER/$NOISY_DATA_PREFIX.$SOURCE_LANG_SUFFIX | sed -r 's/\@\@ //g' | $moses_scripts/recaser/detruecase.perl | $moses_scripts/tokenizer/detokenizer.perl -l $SOURCE_LANG_SUFFIX > $CORPUS_FOLDER/$NOISY_DATA_PREFIX.detok.$SOURCE_LANG_SUFFIX
cat $CORPUS_FOLDER/$NOISY_DATA_PREFIX.$TARGET_LANG_SUFFIX | sed -r 's/\@\@ //g' | $moses_scripts/recaser/detruecase.perl | $moses_scripts/tokenizer/detokenizer.perl -l $TARGET_LANG_SUFFIX > $CORPUS_FOLDER/$NOISY_DATA_PREFIX.detok.$TARGET_LANG_SUFFIX

python filter_language.py $SOURCE_LANG_SUFFIX $TARGET_LANG_SUFFIX $CORPUS_FOLDER/$NOISY_DATA_PREFIX.detok.$SOURCE_LANG_SUFFIX $CORPUS_FOLDER/$NOISY_DATA_PREFIX.detok.$TARGET_LANG_SUFFIX
