mkdir -p ds_logs/

SRC_FILE_SET_LIST=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/inference_Europarl-ST/data/dev.prepro.en.lst
SET_NAME=Europarl-ST.dev
OUTPUT_FOLDER_ROOT=$PWD/inference_out

for FUTURE_WINDOW in 0;
do
    qsubmit -gmem 20G -gcards 1 -Q cuda11.q -m 16 -o ds_logs/oracle.$FUTURE_WINDOW ./infer_ds_oracle.sh $FUTURE_WINDOW $SRC_FILE_SET_LIST $SET_NAME $OUTPUT_FOLDER_ROOT
done

