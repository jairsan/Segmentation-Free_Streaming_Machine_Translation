#!/bin/bash

source config.sh

#Load Python environment
source $PYTHON_ENV

mkdir -p $INFER_OUTPUT_FOLDER
export LC_ALL=C.UTF-8
INFER_FILE_PREFIX=$1    
fairseq-interactive --path $MODEL_OUTPUT_FOLDER/checkpoint_best.pt \
                       --beam 6 \
                       --batch-size 8 \
                       --log-format none \
                       --buffer-size 8 \
                       --quiet \
                       $CORPUS_FOLDER/fairseq_prepared_data/ \
                       --input $CORPUS_FOLDER/$INFER_FILE_PREFIX.$SOURCE_LANG_SUFFIX  | grep -P '^H' | cut -f3- > $INFER_OUTPUT_FOLDER/$CORPUS.$RUN.$INFER_FILE_PREFIX.hyp.$TARGET_LANG_SUFFIX
deactivate

