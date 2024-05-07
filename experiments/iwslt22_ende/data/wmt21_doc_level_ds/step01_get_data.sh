# This directory was sadly deleted
# The standard doc_level does not have SEP in the src side (see its prepro script), so we need as a starting point
# a version with full SEP tags in both src and tgt
origin=../wmt21_doc_level_with_full_tags

cat $origin/corpus-final.de | sed 's# \[EndPrefix\]##g' | sed 's# \[BRK\]##g' > corpus-final.de
cat $origin/corpus-final.en | sed 's# \[EndPrefix\]##g' | sed 's# \[BRK\]##g' > corpus-final.en

cp $origin/MuST-C.v2.dev.de .
cp $origin/MuST-C.v2.dev.en .
cp $origin/MuST-C.v2.tst-COMMON.de .
cp $origin/MuST-C.v2.tst-COMMON.en .
