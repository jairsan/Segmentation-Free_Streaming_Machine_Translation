src_file_set_list=$1
set_name=$2
output_root_folder=$3
feature_name=$4

seg_free_root=/home/jiranzo/trabajo/git/my-gits/Segmentation_Free_Toolkit/
source /home/jiranzo/trabajo/env/venv_py3.8_SegmentationFree/bin/activate

for history_size in 50;
do
    for k in 1 2 3 4 5 6 7 8 9 10;
    do
        out=$output_root_folder/"$set_name".segfree_"$feature_name"_hist"$history_size"_k$k
        rm -r $out

        python3 $seg_free_root/segfreetk/common/translator.py \
        --feature_scorer /scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_deen/inference_Europarl-ST/features/feature_scorer_"$feature_name".json \
        --translator_checkpoint "/scratch/jiranzotmp/experiments/mt/SegFree_iwslt22_deen/fairseq_out/Transformer_BIG_segfree_prefix_training/checkpoint_best.pt" \
        --translator_dict_folder "/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_deen/data/wmt21_doc_level/fairseq_prepared_data/" \
        --translator_splitter "/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_deen/data/wmt21_doc_level/spm.model" \
        --translator_splitter_type "str" \
        --input_files $(cat $src_file_set_list) \
        --search_length_penalty_alpha 1.0 \
        --k $k \
        --catchup 1.08 \
        --model_special_token_src_end_prefix "" \
        --model_special_token_src_brk "" \
        --model_special_token_src_end "[end]" \
        --src_history_max_len $history_size \
        --tgt_history_max_len $history_size \
        --max_forced_read_actions_before_fallback 5 \
        --block_repeated_ngrams_order 6 \
        --output_folder $out
    done
done
