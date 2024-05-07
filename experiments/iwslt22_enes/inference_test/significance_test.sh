baseline_hypo=$1
comparison_hypo=$2
reference_file=$3

sacrebleu --language-pair en-de $reference_file -i $baseline_hypo $comparison_hypo --paired-bs 
