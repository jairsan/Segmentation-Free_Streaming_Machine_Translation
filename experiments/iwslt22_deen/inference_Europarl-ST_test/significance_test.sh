baseline_hypo=$1
comparison_hypo=$2
reference_file=$3

sacrebleu --language-pair de-en $reference_file -i $baseline_hypo $comparison_hypo --paired-bs 
