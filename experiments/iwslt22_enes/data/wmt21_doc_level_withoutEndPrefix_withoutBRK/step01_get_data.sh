origin=../wmt21_doc_level

cat $origin/corpus-final.de | sed 's#\[EndPrefix\]##g' | sed 's#\[BRK\]##g' > corpus-final.de
cat $origin/corpus-final.en | sed 's#\[EndPrefix\]##g' > corpus-final.en

ln -s $origin/MuST-C.v2.dev.de .
ln -s $origin/MuST-C.v2.dev.en .
ln -s $origin/MuST-C.v2.tst-COMMON.de .
ln -s $origin/MuST-C.v2.tst-COMMON.en .
