segmenter_config=$1
segmenter_max_len=$2
segmenter_future_window=$3
src_file_set_list=$4
set_name=$5
output_root_folder=$6

seg_free_root=/home/jiranzo/trabajo/git/my-gits/Segmentation_Free_Toolkit/
source /home/jiranzo/trabajo/env/venv_py3.8_SegmentationFree/bin/activate

for history_size in 50;
do
    for k in 1 2 4 6 8 10;
    do

        out=$output_root_folder/"$set_name".ds_"$segmenter_config"."$segmenter_max_len"."$segmenter_future_window"_hist"$history_size"_k$k
        rm -r $out

        python3 $seg_free_root/segfreetk/common/translator.py \
        --agent_type ds_segmenter_agent \
        --segmenter_checkpoint /scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/segmenter_models_MuST-C.v2/"$segmenter_config"."$segmenter_max_len"."$segmenter_future_window"/model.best.pt \
        --translator_checkpoint "/scratch/jiranzo/nmt-scripts-output/experiments/mt/SegFree_iwslt22_ende/fairseq_out/Transformer_BIG_ds/checkpoint_best.pt" \
        --translator_dict_folder "/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/data/wmt21_doc_level_ds/fairseq_prepared_data/" \
        --translator_splitter "/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/data/wmt21_doc_level_ds/spm.model" \
        --translator_splitter_type "str" \
        --input_files $(cat $src_file_set_list) \
        --search_length_penalty_alpha 1.0 \
        --k $k \
        --catchup 0.9 \
        --model_special_token_src_end_prefix "" \
        --model_special_token_src_brk "" \
        --model_special_token_src_sep "[SEP]" \
        --src_history_max_len $history_size \
        --tgt_history_max_len $history_size \
        --max_forced_read_actions_before_fallback 5 \
        --block_repeated_ngrams_order 6 \
        --output_folder $out
    done
done
