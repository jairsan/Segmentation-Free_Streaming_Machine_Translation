ASR_FILE_PROCESSOR=/home/jiranzo/trabajo/git/nmt-scripts/asr-prepro/prepro_en_file.SegFree.sh

$ASR_FILE_PROCESSOR MuST-C.v2.dev.en > MuST-C.v2.dev.prepro.en 
$ASR_FILE_PROCESSOR corpus.en > corpus.prepro.en
ln -s MuST-C.v2.dev.de MuST-C.v2.dev.prepro.de
ln -s corpus.de corpus.prepro.de
