#!/bin/bash

source config.sh

#Load Python environment
source $PYTHON_ENV

mkdir -p $INFER_OUTPUT_FOLDER
LC_ALL=C.UTF-8
INFER_FILE_PREFIX=$1
FT_NAME=$2
    
fairseq-interactive --path $MODEL_OUTPUT_FOLDER.finetuned_"$FT_NAME"/checkpoint_best.pt \
                       --beam 6 \
                       --batch-size 8 \
                       --log-format none \
                       --buffer-size 8 \
                       --quiet \
                       $CORPUS_FOLDER/fairseq_prepared_data/ \
                       --input $CORPUS_FOLDER/$INFER_FILE_PREFIX.$SOURCE_LANG_SUFFIX  | grep -P '^H' | cut -f3- > $INFER_OUTPUT_FOLDER/$CORPUS.$RUN.$INFER_FILE_PREFIX.hyp_"$FT_NAME".$TARGET_LANG_SUFFIX

deactivate

