#cat ../wmt21_doc_level/corpus.en ../wmt21_doc_level/corpus-doc.en > corpus.tmp.en
#cat ../wmt21_doc_level/corpus.de ../wmt21_doc_level/corpus-doc.de > corpus.tmp.de
python3 remove_doc_markers.py corpus.tmp.en corpus.tmp.de corpus.en corpus.de
cp /scratch/translectures/data/MuST-C/v2.0/en-de/data/dev/txt/dev.en MuST-C.v2.dev.en
cp /scratch/translectures/data/MuST-C/v2.0/en-de/data/dev/txt/dev.de MuST-C.v2.dev.de
