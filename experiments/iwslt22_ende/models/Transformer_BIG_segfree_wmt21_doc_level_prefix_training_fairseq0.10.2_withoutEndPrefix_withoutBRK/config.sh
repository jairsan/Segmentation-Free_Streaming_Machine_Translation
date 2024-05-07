#####################
# User helper code  #
#####################
SCRIPTPATH=$PWD

#Fill the following fields:
CORPUS=SegFree_iwslt22_ende

#Fill the following fields:
RUN="$(basename "$SCRIPTPATH")"

####################
# Mandatory config #
####################
CLUSTER=mllp

#Fill the following fields:
CORPUS_FOLDER=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/data/wmt21_doc_level_withoutEndPrefix_withoutBRK/

#Fill the following fields:
SOURCE_LANG_SUFFIX=en
TARGET_LANG_SUFFIX=de

#This refers to the original data. Preprocessing and subword segmentation
# will be applied to these files

#Fill the following fields:
ORIG_TRAIN_PREFIX=corpus-final
ORIG_DEV_PREFIX=MuST-C.v2.dev
ORIG_TEST_PREFIX=MuST-C.v2.tst-COMMON


BPE_OPERATIONS=40000

# Sentences with more tokens will be removed at the beggining of the prepro step
MAX_LENGTH_PREPRO=200

#Either 'spm' or 'bpe'
SUBWORD_SUFFIX=spm

# Pairs where the ratio of src:tgt or tgt:src is greater will be removed
SOURCE_TARGET_RATIO=4

#Files fed to the neural network. They are supplied by the prepro/subword pipeline, or by the user if he has manually prepared them.
#Unless you are going to manually supply the files, you should leave these values unchanged.
TRAIN_PREFIX=$ORIG_TRAIN_PREFIX.prepro.$SUBWORD_SUFFIX
DEV_PREFIX=$ORIG_DEV_PREFIX.prepro.$SUBWORD_SUFFIX
TEST_PREFIX=$ORIG_TEST_PREFIX.prepro.$SUBWORD_SUFFIX

#Leftover, only support fairseq
TOOLKIT=fairseq

#Support training at artemisa cluster
if [ "$CLUSTER" == "artemisa" ]
then
    FAIRSEQ=/lhome/ext/upv064/upv0641/git/simultaneous_fairseq/
    PYTHON_ENV=/lhome/ext/upv064/upv0641/env/venv_py3.6_simultaneous_fairseq_CUDA10.0/bin/activate
    MODEL_OUTPUT_FOLDER=$PWD/"$TOOLKIT"_out/
    INFER_OUTPUT_FOLDER=$PWD/inference_out/
else
    FAIRSEQ=""
    PYTHON_ENV=/home/"$USER"/trabajo/env/venv_LATEST_fairseq/bin/activate
    MODEL_OUTPUT_FOLDER=/scratch/"$USER"/nmt-scripts-output/experiments/mt/$CORPUS/"$TOOLKIT"_out/$RUN
    INFER_OUTPUT_FOLDER=/scratch/"$USER"/nmt-scripts-output/experiments/mt/$CORPUS/inference_out/$RUN
fi

TRUECASE=true

ASR_FILE_PROCESSOR=/home/jiranzo/trabajo/git/nmt-scripts/asr-prepro/prepro_en_file.SegFree.sh

####################
# Model config     #
####################
MAX_SEQ_LEN=500
WORD_MIN_COUNT=10 #Minimum frequency of words to be included in vocabularies.

#Valid values: BASE, BIG, SIMUL-MULTIK-BASE, SIMUL-MULTIK-BIG
#Fill the following fields:
MODEL_CONFIG=BIG

if [ "$CLUSTER" == "artemisa" ]
then
        export MODELCONFIG=$MODEL_CONFIG
fi

#7.5G for base, 10.5G for BIG
GPU_MEM=10G

##########################
# Other utils config     #
##########################
moses_scripts=/scratch/jiranzo/trabajo/git/mosesdecoder/scripts
SUBWORD_FOLDER=/home/jiranzo/trabajo/git/subword-nmt

