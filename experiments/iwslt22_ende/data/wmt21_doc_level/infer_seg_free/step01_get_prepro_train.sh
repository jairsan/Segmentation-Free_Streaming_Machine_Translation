moses_scripts=/scratch/jiranzo/trabajo/git/mosesdecoder/scripts
/home/jiranzo/trabajo/git/nmt-scripts/asr-prepro/prepro_en_file.SegFree.sh /scratch/translectures/data/MuST-C/v2.0/en-de/data/train/txt/train.en > MuST-C.v2.train.prepro.en
$moses_scripts/recaser/truecase.perl < /scratch/translectures/data/MuST-C/v2.0/en-de/data/train/txt/train.de > MuST-C.v2.train.prepro.de -model ../truecase-model.de

