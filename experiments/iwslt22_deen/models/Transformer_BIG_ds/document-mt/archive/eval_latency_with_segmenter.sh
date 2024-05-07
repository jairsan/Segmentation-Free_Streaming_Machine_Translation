file=$1
segmenter_delay=$2

set -x

python3 ~/trabajo/git/nmt-scripts/document-mt/add_segmenter_delay_and_generate_actions.py $1 $2 > "$file"_with_initR_$2

python3 ~/trabajo/git/fairseq/fairseq-0.9.0-efficient-simultaneous/examples/simultaneous_translation/eval/eval_latency.py --input "$file"_with_initR_$2

