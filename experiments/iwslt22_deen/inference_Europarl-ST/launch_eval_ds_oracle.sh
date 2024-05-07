mkdir -p ds_oracle_eval_results/

SRC_REFERENCE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_deen/inference_Europarl-ST/data/dev.prepro.de.lst
TGT_REFERENCE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_deen/inference_Europarl-ST/data/dev.en.lst

SET_NAME=Europarl-ST.dev
OUTPUT_FOLDER_ROOT=$PWD/inference_out

for FUTURE_WINDOW in 0;
do
    MAX_LEN=$(( $FUTURE_WINDOW + 11 ))

    ./eval_ds_oracle.sh $FUTURE_WINDOW $SRC_REFERENCE_SET_LIST $TGT_REFERENCE_SET_LIST $SET_NAME $OUTPUT_FOLDER_ROOT > ds_oracle_eval_results/$FUTURE_WINDOW.dat
done
