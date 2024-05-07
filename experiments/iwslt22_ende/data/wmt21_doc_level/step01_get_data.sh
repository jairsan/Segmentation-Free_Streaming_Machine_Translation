#This block is commented because there were multiple iterations to get the rest of the script correct.
#Rest assure that all lines have actually been used

#wget https://www.statmt.org/wmt13/training-parallel-commoncrawl.tgz
#tar -xzvf training-parallel-commoncrawl.tgz
#paste 2017-01-trnted/texts/de/en/de-en/train.tags.de-en.de 2017-01-trnted/texts/de/en/de-en/train.tags.de-en.en | grep -v '^[[:space:]]<' > ted.de-en
#wget https://data.statmt.org/wikititles/v3/wikititles-v3.de-en.tsv
#wget https://data.statmt.org/news-commentary/v16/training/news-commentary-v16.de-en.tsv.gz
#wget https://data.statmt.org/wmt20/translation-task/WikiMatrix/WikiMatrix.v1.de-en.langid.tsv.gz
#unzip -d $PWD /scratch/translectures/data/wmt/wmt19/bilingual_corpora/en-de/rapid2019.de-en.zip

cut -f 1 ted.de-en > corpus-doc.de
zcat news-commentary-v16.de-en.tsv.gz | cut -f 1 | sed -e 's#^$#</DOC>#' >> corpus-doc.de
zcat /scratch/translectures/data/ParaCrawl/v7.1/en-de.txt.gz | cut -f 2 > corpus.de
cat commoncrawl.de-en.de >> corpus.de
cut -f 1 wikititles-v3.de-en.tsv >> corpus.de
cat rapid2019.de-en.de | sed -e 's#^$#</DOC>#' >> corpus-doc.de
zcat WikiMatrix.v1.de-en.langid.tsv.gz | cut -f 2 >> corpus.de
tail -n +2 /scratch/translectures/data/LibriVoxDeEn/text2text.tsv | cut -f 5 >> corpus.de

python3 MuST-C_to_doc_level.py /scratch/translectures/data/MuST-C/v2.0/en-de/data/train/txt/train.yaml /scratch/translectures/data/MuST-C/v2.0/en-de/data/train/txt/train.en /scratch/translectures/data/MuST-C/v2.0/en-de/data/train/txt/train.de | cut -f 2 >> corpus-doc.de

paste /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/de/en/train/segments.de /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/de/en/train/segments.en /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/de/en/train/segments.lst | python3 Europarl-ST_to_doc.py | cut -f 1 >> corpus-doc.de
paste /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/en/de/train/segments.de /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/en/de/train/segments.en /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/en/de/train/segments.lst | python3 Europarl-ST_to_doc.py | cut -f 1 >> corpus-doc.de
#Removed due to noise
#paste /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/de/en/train-noisy/segments.de /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/de/en/train-noisy/segments.en /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/de/en/train-noisy/segments.lst | python3 Europarl-ST_to_doc.py | cut -f 1 >> corpus-doc.de
#paste /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/en/de/train-noisy/segments.de /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/en/de/train-noisy/segments.en /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/en/de/train-noisy/segments.lst | python3 Europarl-ST_to_doc.py | cut -f 1 >> corpus-doc.de

cut -f 2 ted.de-en > corpus-doc.en
zcat news-commentary-v16.de-en.tsv.gz | cut -f 2 | sed -e 's#^$#</DOC>#' >> corpus-doc.en
zcat /scratch/translectures/data/ParaCrawl/v7.1/en-de.txt.gz | cut -f 1 > corpus.en
cat commoncrawl.de-en.en >> corpus.en
cut -f 2 wikititles-v3.de-en.tsv >> corpus.en
cat rapid2019.de-en.en | sed -e 's#^$#</DOC>#' >> corpus-doc.en
zcat WikiMatrix.v1.de-en.langid.tsv.gz | cut -f 3 >> corpus.en
tail -n +2 /scratch/translectures/data/LibriVoxDeEn/text2text.tsv | cut -f 6 >> corpus.en

python3 MuST-C_to_doc_level.py /scratch/translectures/data/MuST-C/v2.0/en-de/data/train/txt/train.yaml /scratch/translectures/data/MuST-C/v2.0/en-de/data/train/txt/train.en /scratch/translectures/data/MuST-C/v2.0/en-de/data/train/txt/train.de | cut -f 1 >> corpus-doc.en

paste /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/de/en/train/segments.de /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/de/en/train/segments.en /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/de/en/train/segments.lst | python3 Europarl-ST_to_doc.py | cut -f 2 >> corpus-doc.en
paste /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/en/de/train/segments.de /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/en/de/train/segments.en /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/en/de/train/segments.lst | python3 Europarl-ST_to_doc.py | cut -f 2 >> corpus-doc.en
#Removed due to noise
#paste /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/de/en/train-noisy/segments.de /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/de/en/train-noisy/segments.en /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/de/en/train-noisy/segments.lst | python3 Europarl-ST_to_doc.py | cut -f 2 >> corpus-doc.en
#paste /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/en/de/train-noisy/segments.de /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/en/de/train-noisy/segments.en /scratch/translectures/data/Europarl-ST/RELEASES/v1.1/en/de/train-noisy/segments.lst | python3 Europarl-ST_to_doc.py | cut -f 2 >> corpus-doc.en


cp /scratch/translectures/data/MuST-C/v2.0/en-de/data/dev/txt/dev.en MuST-C.v2.dev.en
cp /scratch/translectures/data/MuST-C/v2.0/en-de/data/tst-COMMON/txt/tst-COMMON.en MuST-C.v2.tst-COMMON.en
cp /scratch/translectures/data/MuST-C/v2.0/en-de/data/dev/txt/dev.de MuST-C.v2.dev.de
cp /scratch/translectures/data/MuST-C/v2.0/en-de/data/tst-COMMON/txt/tst-COMMON.de MuST-C.v2.tst-COMMON.de
