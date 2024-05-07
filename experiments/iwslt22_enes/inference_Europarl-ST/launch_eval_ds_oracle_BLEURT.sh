mkdir -p ds_oracle_eval_results_BLEURT/

SRC_REFERENCE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference_Europarl-ST/data/dev.prepro.en.lst
TGT_REFERENCE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference_Europarl-ST/data/dev.de.lst

SET_NAME=Europarl-ST.dev
OUTPUT_FOLDER_ROOT=$PWD/inference_out

for FUTURE_WINDOW in 0;
do
    MAX_LEN=$(( $FUTURE_WINDOW + 11 ))

    ./eval_ds_oracle_BLEURT.sh $FUTURE_WINDOW $SRC_REFERENCE_SET_LIST $TGT_REFERENCE_SET_LIST $SET_NAME $OUTPUT_FOLDER_ROOT > ds_oracle_eval_results_BLEURT/$FUTURE_WINDOW.dat
done
