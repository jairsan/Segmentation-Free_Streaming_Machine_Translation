source config_bt.sh
source $PYTHON_ENV

LC_ALL=C.UTF-8

fairseq-interactive --path $BT_MODEL/checkpoint_best.pt \
                       --beam 4 \
                       --batch-size 32 \
                       --log-format none \
                       --buffer-size 32 \
                       --quiet \
                       $BT_MODEL \
                       --input splits_mono_prepro/split.$SGE_TASK_ID.prepro.bpe --source-lang $TARGET_LANG_SUFFIX --target-lang $SOURCE_LANG_SUFFIX > synthetic_source/backtrans.$SGE_TASK_ID
                                       
deactivate
