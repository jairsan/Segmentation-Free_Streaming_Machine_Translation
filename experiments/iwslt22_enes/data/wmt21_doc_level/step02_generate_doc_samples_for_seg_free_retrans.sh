N_REPIT=1
SRC_LEN=60
TGT_LEN=75

rm -f corpus-doc.tmp.de corpus-doc.tmp.en

for i in $(seq $N_REPIT);
do
    cat corpus-doc.de >> corpus-doc.tmp.de
    cat corpus-doc.en >> corpus-doc.tmp.en
done

python3 MuST-C_to_doc_level.py /scratch/translectures/data/MuST-C/v2.0/en-de/data/train/txt/train.yaml /scratch/translectures/data/MuST-C/v2.0/en-de/data/train/txt/train.en /scratch/translectures/data/MuST-C/v2.0/en-de/data/train/txt/train.de | cut -f 1 > MuST-C.v2.train-doc.en
python3 MuST-C_to_doc_level.py /scratch/translectures/data/MuST-C/v2.0/en-de/data/train/txt/train.yaml /scratch/translectures/data/MuST-C/v2.0/en-de/data/train/txt/train.en /scratch/translectures/data/MuST-C/v2.0/en-de/data/train/txt/train.de | cut -f 2 > MuST-C.v2.train-doc.de

python3 MuST-C_to_doc_level.py /scratch/translectures/data/MuST-C/v2.0/en-de/data/dev/txt/dev.yaml /scratch/translectures/data/MuST-C/v2.0/en-de/data/dev/txt/dev.en /scratch/translectures/data/MuST-C/v2.0/en-de/data/dev/txt/dev.de | cut -f 1 > MuST-C.v2.dev-doc.en
python3 MuST-C_to_doc_level.py /scratch/translectures/data/MuST-C/v2.0/en-de/data/dev/txt/dev.yaml /scratch/translectures/data/MuST-C/v2.0/en-de/data/dev/txt/dev.en /scratch/translectures/data/MuST-C/v2.0/en-de/data/dev/txt/dev.de | cut -f 2 > MuST-C.v2.dev-doc.de

python3 ~/trabajo/git/nmt-scripts/document-mt/convert_doc_format_to_sentences_history_length_limited_V2.py corpus-doc.tmp.de corpus-doc.tmp.en $SRC_LEN $TGT_LEN > corpus-doc.deen
python3 ~/trabajo/git/nmt-scripts/document-mt/convert_doc_format_to_sentences_history_length_limited_V2.py MuST-C.v2.train-doc.de MuST-C.v2.train-doc.en $SRC_LEN $TGT_LEN > MuST-C.v2.train-doc.deen
python3 ~/trabajo/git/nmt-scripts/document-mt/convert_doc_format_to_sentences_history_length_limited_V2.py MuST-C.v2.dev-doc.de MuST-C.v2.dev-doc.en $SRC_LEN $TGT_LEN > MuST-C.v2.dev-doc.deen

cut -f 1 corpus-doc.deen > corpus-doc-final.de
cut -f 2 corpus-doc.deen > corpus-doc-final.en
cut -f 1 MuST-C.v2.train-doc.deen > MuST-C.v2.train-doc.de
cut -f 2 MuST-C.v2.train-doc.deen > MuST-C.v2.train-doc.en
cut -f 1 MuST-C.v2.dev-doc.deen > MuST-C.v2.dev-doc.de
cut -f 2 MuST-C.v2.dev-doc.deen > MuST-C.v2.dev-doc.en


# TODO
# start rerun from here
#

cat corpus-doc-final.de corpus.de > tmp.corpus-final.de
cat corpus-doc-final.en corpus.en > tmp.corpus-final.en



python3 ~/trabajo/git/nmt-scripts/document-mt/generate_prefix_training_corpus_doc_level.py tmp.corpus-final.de tmp.corpus-final.en tmp2.corpus-final.de tmp2.corpus-final.en
cat tmp.corpus-final.de tmp2.corpus-final.de > corpus-final.de
cat tmp.corpus-final.en tmp2.corpus-final.en | sed -r 's/ \[SEP]//g' | sed -r 's/ \[BRK]//g' > corpus-final.en


###FIXME
#rm corpus-doc.deen corpus-doc.tmp.de corpus-doc.tmp.en
#rm tmp.corpus-final.de tmp.corpus-final.en tmp2.corpus-final.de tmp2.corpus-final.en
