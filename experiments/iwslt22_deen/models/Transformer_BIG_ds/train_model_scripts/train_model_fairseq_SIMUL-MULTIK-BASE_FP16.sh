source config.sh

#Load Python environment
source $PYTHON_ENV
export LC_ALL=C.UTF-8
export PYTHONUNBUFFERED=1

#By default, waitk for eval=1024
fairseq-train $CORPUS_FOLDER/fairseq_prepared_data/ \
  -s $SOURCE_LANG_SUFFIX \
  -t $TARGET_LANG_SUFFIX \
    --user-dir $FAIRSEQ/examples/simultaneous_translation \
    --arch waitk_transformer_base \
    --share-all-embeddings \
    --left-pad-source False \
    --multi-waitk \
  --optimizer adam \
  --adam-betas '(0.9, 0.98)' \
  --clip-norm 0.0 \
  --lr-scheduler inverse_sqrt \
  --warmup-init-lr 1e-07 \
  --warmup-updates 4000 \
  --lr 0.0005 \
  --min-lr 1e-09 \
  --dropout 0.3 \
  --weight-decay 0.0 \
  --criterion label_smoothed_cross_entropy \
  --label-smoothing 0.1 \
  --max-tokens 4000 \
  --update-freq 8 \
  --save-dir $MODEL_OUTPUT_FOLDER \
  --no-progress-bar \
  --log-interval 100 \
  --save-interval-updates 10000 \
  --keep-interval-updates 20 \
  --ddp-backend=no_c10d \
  --max-update 1000000 \
  --max-source-positions $MAX_SEQ_LEN \
  --max-target-positions $MAX_SEQ_LEN \
  --fp16
deactivate
