mkdir -p ds_eval_results/

SRC_REFERENCE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference/data/dev.prepro.en.lst
TGT_REFERENCE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference/data/dev.de.lst

SET_NAME=MuST-C.dev
OUTPUT_FOLDER_ROOT=$PWD/inference_out

for config in simple_rnn_base roberta_base;
do
    for FUTURE_WINDOW in 0 1 2 3 4;
    do
        MAX_LEN=$(( $FUTURE_WINDOW + 11 ))

        ./eval_ds.sh $config $MAX_LEN $FUTURE_WINDOW $SRC_REFERENCE_SET_LIST $TGT_REFERENCE_SET_LIST $SET_NAME $OUTPUT_FOLDER_ROOT > ds_eval_results/$config.$FUTURE_WINDOW.dat
    done
done

for config in roberta_large_v2;
do
    for FUTURE_WINDOW in 1;
    do
        MAX_LEN=$(( $FUTURE_WINDOW + 11 ))

        ./eval_ds.sh $config $MAX_LEN $FUTURE_WINDOW $SRC_REFERENCE_SET_LIST $TGT_REFERENCE_SET_LIST $SET_NAME $OUTPUT_FOLDER_ROOT > ds_eval_results/$config.$FUTURE_WINDOW.dat
    done
done
