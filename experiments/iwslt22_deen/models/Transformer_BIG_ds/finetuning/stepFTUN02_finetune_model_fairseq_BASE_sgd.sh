source config.sh
source $PYTHON_ENV

FT_NAME=$1
LR=$2
#You could use 0.00005, but ideal is to get the actual value when training finished

FAIRSEQ=/home/jiranzo/trabajo/git/fairseq/fairseq-0.9.0-efficient-simultaneous/

fairseq-train $CORPUS_FOLDER/fairseq_prepared_data_finetuning_"$FT_NAME"/ \
  -s $SOURCE_LANG_SUFFIX \
  -t $TARGET_LANG_SUFFIX \
  --arch transformer \
  --share-all-embeddings \
  --task translation \
  --criterion label_smoothed_cross_entropy \
  --optimizer sgd \
  --lr-scheduler fixed \
  --clip-norm 0.0 \
  --lr $LR \
  --dropout 0.3 \
  --weight-decay 0.0 \
  --label-smoothing 0.1 \
  --max-tokens 4000 \
  --update-freq 8 \
  --restore-file $MODEL_OUTPUT_FOLDER/checkpoint_best.pt \
  --reset-optimizer \
  --save-dir $MODEL_OUTPUT_FOLDER.finetuned_"$FT_NAME" \
  --max-update 5000 \
  --save-interval-updates 500 \
  --keep-interval-updates 10 \
  --save-interval 100 \
  --no-progress-bar \
  --log-interval 10 \
  --ddp-backend=no_c10d

