source config.sh
#Load Python environment
source $PYTHON_ENV

export PYTHONUNBUFFERED=1
export LC_ALL=C.UTF-8
fairseq-train $CORPUS_FOLDER/fairseq_prepared_data/ \
  -s $SOURCE_LANG_SUFFIX \
  -t $TARGET_LANG_SUFFIX \
  --arch transformer_vaswani_wmt_en_fr_big \
  --share-all-embeddings \
  --optimizer adam \
  --adam-betas '(0.9, 0.98)' \
  --clip-norm 0.0 \
  --lr-scheduler inverse_sqrt \
  --warmup-init-lr 1e-07 \
  --warmup-updates 4000 \
  --lr 0.0005 \
  --min-lr 1e-09 \
  --dropout 0.1 \
  --weight-decay 0.0 \
  --criterion label_smoothed_cross_entropy \
  --label-smoothing 0.1 \
  --max-tokens 2000 \
  --update-freq 8 \
  --save-dir $MODEL_OUTPUT_FOLDER \
  --no-progress-bar \
  --log-interval 100 \
  --save-interval-updates 10000 \
  --keep-interval-updates 10 \
  --ddp-backend=no_c10d \
  --max-update 1000000 \
  --max-source-positions $MAX_SEQ_LEN \
  --max-target-positions $MAX_SEQ_LEN \
  --fp16

deactivate
