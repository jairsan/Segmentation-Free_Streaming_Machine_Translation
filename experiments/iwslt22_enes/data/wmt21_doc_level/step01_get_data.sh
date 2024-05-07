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
MustC_ver="v1.0"
out_name=corpus

N_REPIT=1 #How much times do we upsample the document level datasets
SRC_LEN=60
TGT_LEN=75

#===============================================

get_MUSTC_dev_test () {
	MustC_ver_abv="${MustC_ver%.*}"
	MustC_path=/scratch/translectures/data/MuST-C/"$MustC_ver"/en-"$tgt"/data
	cp "$MustC_path"/dev/txt/dev.en MuST-C."$MustC_ver_abv".dev.en
	cp "$MustC_path"/dev/txt/dev."$tgt" MuST-C."$MustC_ver_abv".dev."$tgt"
	cp "$MustC_path"/tst-COMMON/txt/tst-COMMON.en MuST-C."$MustC_ver_abv".tst-COMMON.en
	cp "$MustC_path"/tst-COMMON/txt/tst-COMMON."$tgt" MuST-C."$MustC_ver_abv".tst-COMMON."$tgt"
}

extract_MUSTC_doc () {
	src_or_tgt_field=$1
	out=$2
	MustC_path_train=/scratch/translectures/data/MuST-C/"$MustC_ver"/en-"$tgt"/data/train/txt/train
	python3 MuST-C_to_doc_level.py "$MustC_path_train".yaml "$MustC_path_train".en "$MustC_path_train"."$tgt" \
	| cut -f "$src_or_tgt_field" >> "$out_name"-doc."$out"

}

extract_EUROPARLST_doc () {
	dir_src=$1
	dir_tgt=$2
        segments_path=/scratch/translectures/data/Europarl-ST/RELEASES/v1.1/"$dir_src"/"$dir_tgt"/train/segments

	paste "$segments_path"."$src" "$segments_path"."$tgt" "$segments_path".lst | python3 Europarl-ST_to_doc.py | cut -f 1 >> "$out_name"-doc.en
	paste "$segments_path"."$src" "$segments_path"."$tgt" "$segments_path".lst | python3 Europarl-ST_to_doc.py | cut -f 2 >> "$out_name"-doc."$tgt"
}


#===============================================

if [ ${STAGE} -le 0 ] && [ ${STOP_STAGE} -ge 0 ]; then
	get_MUSTC_dev_test 

	extract_MUSTC_doc 1 en
	extract_MUSTC_doc 2 "$tgt"

	extract_EUROPARLST_doc en "$tgt"
	extract_EUROPARLST_doc "$tgt" en
fi

echo "0->1"

if [ ${STAGE} -le 1 ] && [ ${STOP_STAGE} -ge 1 ]; then
	for i in $(seq $N_REPIT);
	do
	    cat "$out_name"-doc."$tgt" >> tmp."$out_name"-doc."$tgt"
	    cat "$out_name"-doc.en >> tmp."$out_name"-doc.en
	done

	echo Generating to doc limited..
	python3 ~/trabajo/git/nmt-scripts/document-mt/convert_doc_format_to_sentences_history_length_limited_V2.py tmp."$out_name"-doc."$tgt" tmp."$out_name"-doc.en $SRC_LEN $TGT_LEN > "$out_name"-doc."$tgt"en
	cut -f 1 "$out_name"-doc."$tgt"en > "$out_name"-doc-final."$tgt"
	cut -f 2 "$out_name"-doc."$tgt"en > "$out_name"-doc-final.en

	cp "$out_name"-doc-final."$tgt" tmp."$out_name"-doc-final."$tgt"
	cp "$out_name"-doc-final.en     tmp."$out_name"-doc-final.en

	echo Generating prefix training...
	python3 ~/trabajo/git/nmt-scripts/document-mt/generate_prefix_training_corpus_doc_level.py tmp."$out_name"-doc-final."$tgt" tmp."$out_name"-doc-final.en tmp2."$out_name"-doc-final."$tgt" tmp2."$out_name"-doc-final.en

	cat tmp."$out_name"-doc-final."$tgt" tmp2."$out_name"-doc-final."$tgt" > "$out_name"-doc-final."$tgt"
	cat tmp."$out_name"-doc-final.en tmp2."$out_name"-doc-final.en | sed -r 's/ \[SEP]//g' | sed -r 's/ \[BRK]//g' > "$out_name"-doc-final.en
fi


