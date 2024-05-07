source config.sh
source /home/jiranzo/trabajo/env/venv_py3.6_PyTorch1.0_CUDA10.0/bin/activate
moses_scripts=/scratch/jiranzo/trabajo/git/mosesdecoder/scripts

$moses_scripts/training/clean-corpus-n.perl -ratio 1.5 $ORIG_NOISY_DATA_PREFIX $SOURCE_LANG_SUFFIX $TARGET_LANG_SUFFIX corpus.f1 1 100

qsubmit -m 8 python filter_language.py corpus.f1.$TARGET_LANG_SUFFIX $TARGET_LANG_SUFFIX
qsubmit -m 8 python filter_language.py corpus.f1.$SOURCE_LANG_SUFFIX $SOURCE_LANG_SUFFIX


