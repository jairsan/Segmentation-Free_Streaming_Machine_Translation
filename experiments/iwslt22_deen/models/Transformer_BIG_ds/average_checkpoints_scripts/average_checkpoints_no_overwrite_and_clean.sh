source config.sh
LC_ALL=C.UTF-8
source $PYTHON_ENV

set -e


python average_checkpoints_scripts/fairseq_average_checkpoints.py --input $MODEL_OUTPUT_FOLDER --output $MODEL_OUTPUT_FOLDER/checkpoint_averaged.pt \
	--num-update-checkpoints 8 

cd $MODEL_OUTPUT_FOLDER
ls | grep -E -v 'checkpoint_best.pt|checkpoint_last.pt|checkpoint_averaged.pt' | xargs rm

deactivate


