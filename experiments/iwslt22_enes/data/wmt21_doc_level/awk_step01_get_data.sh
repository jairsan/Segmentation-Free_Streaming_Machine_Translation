#This block is commented because there were multiple iterations to get the rest of the script correct.
#Rest assure that all lines have actually been used

#wget https://www.statmt.org/wmt13/training-parallel-commoncrawl.tgz
#tar -xzvf training-parallel-commoncrawl.tgz
#paste 2017-01-trnted/texts/de/en/de-en/train.tags.de-en.de 2017-01-trnted/texts/de/en/de-en/train.tags.de-en.en | grep -v '^[[:space:]]<' > ted.de-en
#wget https://data.statmt.org/wikititles/v3/wikititles-v3.de-en.tsv
#wget https://data.statmt.org/news-commentary/v16/training/news-commentary-v16.de-en.tsv.gz
#wget https://data.statmt.org/wmt20/translation-task/WikiMatrix/WikiMatrix.v1.de-en.langid.tsv.gz
#unzip -d $PWD /scratch/translectures/data/wmt/wmt19/bilingual_corpora/en-de/rapid2019.de-en.zip

#The order of indices of tgt and src are inconsistant across the orginal script. These nuances are mainted on this script
src=$1
tgt=$2
STAGE=$3
STOP_STAGE=$4
MustC_ver=$5 # v1.0 v2.0
out=corpus
out_doc="$out"-doc

N_REPIT=1 #How much times do we upsample the document level datasets
SRC_LEN=60
TGT_LEN=75

#===============================================
#rm corpus-doc.* MuST-C.* tmp*
#rm corpus-doc.* MuST-C.* tmp* corpus-doc-final.*

get_MUSTC_dev_test () {
	MustC_ver_abv="${MustC_ver%.*}"
	MustC_path=/scratch/translectures/data/MuST-C/"$MustC_ver"/"$src"-"$tgt"/data
	cp "$MustC_path"/dev/txt/dev."$src" MuST-C."$MustC_ver_abv".dev."$src"
	cp "$MustC_path"/dev/txt/dev."$tgt" MuST-C."$MustC_ver_abv".dev."$tgt"
	cp "$MustC_path"/tst-COMMON/txt/tst-COMMON."$src" MuST-C."$MustC_ver_abv".tst-COMMON."$src"
	cp "$MustC_path"/tst-COMMON/txt/tst-COMMON."$tgt" MuST-C."$MustC_ver_abv".tst-COMMON."$tgt"
}

extract_MUSTC_doc () {
	MustC_path_train=/scratch/translectures/data/MuST-C/"$MustC_ver"/"$src"-"$tgt"/data/train/txt/train
	python3 MuST-C_to_doc_level.py "$MustC_path_train".yaml "$MustC_path_train"."$src" "$MustC_path_train"."$tgt" \
	| awk -F'\t' -v out_doc=$out_doc -v src=$src -v tgt=$tgt '{print $1 >> out_doc "." src} {print $2 >> out_doc "." tgt}'

}

extract_EUROPARLST_doc () {
	dir_src=$1
	dir_tgt=$2
        segments_path=/scratch/translectures/data/Europarl-ST/RELEASES/v1.1/"$dir_src"/"$dir_tgt"/train/segments

	paste "$segments_path"."$src" "$segments_path"."$tgt" "$segments_path".lst \
		| python3 Europarl-ST_to_doc.py \
		| awk -F'\t' -v out_doc=$out_doc -v src=$src -v tgt=$tgt '{print $1 >> out_doc "." src} {print $2 >> out_doc "." tgt}'
}


#===============================================
test_a () {
	wc -l <(sed -e '/<\/DOC>/d' "$out_doc".en)
}

if [ ${STAGE} -le 0 ] && [ ${STOP_STAGE} -ge 0 ]; then
	get_MUSTC_dev_test 

	extract_EUROPARLST_doc "$src" "$tgt"
	extract_EUROPARLST_doc "$tgt" "$src"

	extract_MUSTC_doc
        
	sed -Ei "s/^ //g" "$out_doc"."$src"
	sed -Ei "s/^ //g" "$out_doc"."$tgt"
fi

echo "0->1"

if [ ${STAGE} -le 1 ] && [ ${STOP_STAGE} -ge 1 ]; then
	for i in $(seq $N_REPIT);
	do
	    cat "$out_doc"."$tgt" >> tmp."$out_doc"."$tgt"
	    cat "$out_doc"."$src" >> tmp."$out_doc"."$src"
	done

	echo Generating to doc limited..
	#OJO cambia el ordern del reg en el awk respcto los anteriores.
	python3 ~/trabajo/git/nmt-scripts/document-mt/convert_doc_format_to_sentences_history_length_limited_V2.py tmp."$out_doc"."$tgt" tmp."$out_doc"."$src" $SRC_LEN $TGT_LEN  | awk -F'\t' -v out_doc=$out_doc-final -v src=$src -v tgt=$tgt '{print $1 >> out_doc "." tgt} {print $2 >> out_doc "." src}'
	
	cat "$out_doc"-final."$tgt" > tmp."$out_doc"-final."$tgt"
	cat "$out_doc"-final."$src" > tmp."$out_doc"-final."$src"

	echo Generating prefix training...
	python3 ~/trabajo/git/nmt-scripts/document-mt/generate_prefix_training_corpus_doc_level.py tmp."$out_doc"-final."$tgt" tmp."$out_doc"-final."$src" tmp2."$out_doc"-final."$tgt" tmp2."$out_doc"-final."$src"

	cat tmp."$out_doc"-final."$tgt" tmp2."$out_doc"-final."$tgt" > "$out_doc"-final."$tgt"
	#Bug javier corchetes preguntar
	cat tmp."$out_doc"-final."$src" tmp2."$out_doc"-final."$src" | sed -r 's/ \[SEP\]//g' | sed -r 's/ \[BRK\]//g' > "$out_doc"-final."$src"
fi

