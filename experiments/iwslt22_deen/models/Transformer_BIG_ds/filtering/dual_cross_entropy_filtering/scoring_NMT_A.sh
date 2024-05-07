#Warning: Work in Progress
#Setup run-specifig config
SCRIPT="$(readlink --canonicalize-existing "$0")"
SCRIPTPATH="$(dirname "$SCRIPT")"
source $SCRIPTPATH/config.sh

source $PYTHON_ENV

python -m sockeye.score -m $MODEL_OUTPUT_FOLDER/A_filter --source $NOISY_DATA_PREFIX.$SOURCE_LANG_SUFFIX --target $NOISY_DATA_PREFIX.$TARGET_LANG_SUFFIX --score-type neglogprob --length-penalty-alpha 1.0 --length-penalty-beta 0.0 --batch-size 2500 --batch-type word --device 0  --disable-device-locking > A.scores

deactivate

