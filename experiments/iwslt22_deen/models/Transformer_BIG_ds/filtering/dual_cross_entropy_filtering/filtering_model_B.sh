#Warning: Work in Progress
#Setup run-specifig config
SCRIPT="$(readlink --canonicalize-existing "$0")"
SCRIPTPATH="$(dirname "$SCRIPT")"
source $SCRIPTPATH/config.sh

source $PYTHON_ENV
            
sockeye-train --source $CORPUS_FOLDER/$CLEAN_DATA_TRAIN_PREFIX.$TARGET_LANG_SUFFIX \
                       --target $CORPUS_FOLDER/$CLEAN_DATA_TRAIN_PREFIX.$SOURCE_LANG_SUFFIX \
                       --validation-source $CORPUS_FOLDER/$CLEAN_DATA_DEV_PREFIX.$TARGET_LANG_SUFFIX \
                       --validation-target $CORPUS_FOLDER/$CLEAN_DATA_DEV_PREFIX.$SOURCE_LANG_SUFFIX \
                       --output $MODEL_OUTPUT_FOLDER/B_filter \
                       --encoder transformer \
                       --decoder transformer \
                       --num-layers 6 \
                       --batch-type=word \
                       --batch-size=3000 \
                       --embed-dropout=0:0 \
                       --num-layers=6:6 \
                       --transformer-model-size=512 \
                       --transformer-attention-heads=8 \
                       --transformer-feed-forward-num-hidden=2048 \
                       --transformer-preprocess=n \
                       --transformer-postprocess=dr \
                       --transformer-dropout-attention=0.1 \
                       --transformer-dropout-act=0.1 \
                       --transformer-dropout-prepost=0.1 \
                       --transformer-positional-embedding-type fixed \
                       --fill-up=replicate \
                       --max-seq-len=$MAX_SEQ_LEN:$MAX_SEQ_LEN \
                       --label-smoothing 0.1 \
                       --weight-tying \
                       --weight-tying-type=src_trg_softmax \
                       --num-embed 512:512 \
                       --optimizer=adam \
                       --gradient-clipping-threshold=-1 \
                       --initial-learning-rate=0.0001 \
                       --learning-rate-reduce-num-not-improved=8 \
                       --learning-rate-reduce-factor=0.7 \
                       --learning-rate-scheduler-type=plateau-reduce \
                       --max-updates 10000000 \
                       --weight-init xavier \
                       --weight-init-scale 3.0 \
                       --weight-init-xavier-factor-type avg \
                       --max-num-checkpoint-not-improved 15 \
                       --keep-last-params 25 \
                       --decode-and-evaluate 0 \
                       --disable-device-locking 

                       
deactivate
                       






