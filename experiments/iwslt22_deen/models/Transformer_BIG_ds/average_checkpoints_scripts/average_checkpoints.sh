source config.sh
LC_ALL=C.UTF-8
source $PYTHON_ENV
python average_checkpoints_scripts/fairseq_average_checkpoints.py --input $MODEL_OUTPUT_FOLDER --output avg.pt \
	--num-update-checkpoints 8 
deactivate


