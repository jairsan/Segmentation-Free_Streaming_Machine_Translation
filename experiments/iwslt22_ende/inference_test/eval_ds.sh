segmenter_config=$1
segmenter_max_len=$2
segmenter_future_window=$3
src_file_set_list=$4
reference_file_set_list=$5
set_name=$6
hypo_root_folder=$7


set -e 

for history_size in 50;
do

for k in 1 2 4 6 8 10; do

hypo_folder=$hypo_root_folder/$set_name.ds_"$segmenter_config"."$segmenter_max_len"."$segmenter_future_window"_hist"$history_size"_k$k

src_ref=$(cat $src_file_set_list)

tgt_ref=$(cat $reference_file_set_list)

hypo_files=$(find $hypo_folder \( -name "*.out" -and ! -name "*all.out" \) | sort -V)

hypo_RW=$( find $hypo_folder \( -name "*.actions" -and ! -name "*all.actions" \) | sort -V)

lat=$(stream_latency --hypotheses_files $hypo_files --hypotheses_RW_files $hypo_RW \
                      --reference_source_files $src_ref \
                      --reference_target_files $tgt_ref \
                      --penalty_scale_factor 0.95 \
                      --read_action_repr "0" \
                      --write_action_repr "1" \
                      --remove_tokens_from_hypo [SEP] [END] \
                      --output_format tabs)

rm -f tmp.hypo tmp.ref
cat -n $reference_file_set_list | while read il fil;
do
    sub=1
    i=$(($il-$sub))
    stream_resegment --hypo_file $hypo_folder/$i.out \
                        --reference_file $fil \
                        > $hypo_folder/$i.out.reseg
    cat $hypo_folder/$i.out.reseg | sed -r 's#\[SEP\]##g' | sed -r 's#\[END\]##g' >> tmp.hypo
    cat $ref_folder/$fil >> tmp.ref
done
scores=$(
cat tmp.hypo | sacrebleu tmp.ref --language-pair en-de | python3 -c "import sys, json; print(json.load(sys.stdin)['score'])"
)
rm -f tmp.hypo tmp.ref

avg_lat=$(echo "$lat" | awk '{ ap += $2; al += $3; dal += $4 } END { print ap/NR,al/NR,dal/NR}' -)
echo $scores $avg_lat
done
done
