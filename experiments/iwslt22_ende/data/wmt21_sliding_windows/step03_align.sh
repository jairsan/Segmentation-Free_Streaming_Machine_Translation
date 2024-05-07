fabuild=/home/jiranzo/trabajo/git/fast_align/build
moses_scripts=/scratch/jiranzo/trabajo/git/mosesdecoder/scripts

function align () {
    set -e
    rm -f $3
    python3 prepare_corpus_for_align.py $1 $2 > tmp_align
    split -a 1 -d -n l/10 tmp_align tmp_align.split.
    for i in {0..9};
    do
        $fabuild/fast_align -i tmp_align.split.$i -d -o -v > forward_align.split.$i
        $fabuild/fast_align -i tmp_align.split.$i -d -o -v -r > reverse_align.split.$i
        $fabuild/atools -i forward_align.split.$i -j reverse_align.split.$i -c grow-diag-final-and >> $3
        rm forward_align.split.$i reverse_align.split.$i tmp_align.split.$i
    done
    rm tmp_align
    }

$moses_scripts/training/clean-corpus-n.perl -ratio 4 corpus.prepro en de corpus.prepro.clean 1 200
$moses_scripts/training/clean-corpus-n.perl -ratio 4 MuST-C.v2.dev.prepro en de MuST-C.v2.dev.prepro.clean 1 200
cat corpus.prepro.clean.en MuST-C.v2.dev.prepro.clean.en > tmp.en
cat corpus.prepro.clean.de MuST-C.v2.dev.prepro.clean.de > tmp.de

align tmp.en tmp.de tmp.align
