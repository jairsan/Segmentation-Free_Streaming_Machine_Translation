mkdir -p ds_logs/

SRC_FILE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference_Europarl-ST/data/test.prepro.en.lst
SET_NAME=Europarl-ST.test
OUTPUT_FOLDER_ROOT=$PWD/inference_out

for config in roberta_large_v2;
do
    for FUTURE_WINDOW in 1;
    do
        MAX_LEN=$(( $FUTURE_WINDOW + 11 ))

        qsubmit -gmem 10G -gcards 1 -Q cuda11.q -m 16 -o ds_logs/$config.$MAX_LEN.$FUTURE_WINDOW ./infer_ds.sh $config $MAX_LEN $FUTURE_WINDOW $SRC_FILE_SET_LIST $SET_NAME $OUTPUT_FOLDER_ROOT
    done
done
