mkdir -p ds_eval_results/

SRC_REFERENCE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference_Europarl-ST/data/dev.prepro.en.lst
TGT_REFERENCE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference_Europarl-ST/data/dev.de.lst

SET_NAME=Europarl-ST.dev
OUTPUT_FOLDER_ROOT=$PWD/inference_out

#for config in simple_rnn_base rnn_ff_text_base roberta_base roberta_large_v2;
for config in roberta_large_v2;
do
    for FUTURE_WINDOW in 0 1 2 3 4;
    do
        MAX_LEN=$(( $FUTURE_WINDOW + 11 ))

        ./eval_ds.sh $config $MAX_LEN $FUTURE_WINDOW $SRC_REFERENCE_SET_LIST $TGT_REFERENCE_SET_LIST $SET_NAME $OUTPUT_FOLDER_ROOT > ds_eval_results/$config.$FUTURE_WINDOW.dat
    done
done
