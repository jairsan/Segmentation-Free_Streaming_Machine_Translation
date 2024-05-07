source config.sh
LC_ALL=C.UTF-8

file_prefix=$1
lang=$2


$moses_scripts/recaser/truecase.perl < $CORPUS_FOLDER/$file_prefix.$lang > $CORPUS_FOLDER/$file_prefix.prepro.$lang -model $CORPUS_FOLDER/truecase-model.$lang

spm_encode --model=$CORPUS_FOLDER/spm.model --vocabulary $CORPUS_FOLDER/spm.vocab.$lang --vocabulary_threshold=50 --output_format=id < $CORPUS_FOLDER/$file_prefix.prepro.$lang > $CORPUS_FOLDER/$file_prefix.prepro.spm.$lang


