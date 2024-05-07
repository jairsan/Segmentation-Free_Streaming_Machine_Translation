config_name=$1
gpu_mem=$2
queue=$3

corpus_path=/scratch/jiranzotmp/trabajo/SegmentationFree/iwslt22_ende/segmenter_models_MuST-C.v2/prepared_data
segmenter_root=/home/jiranzo/PycharmProjects/ST-Segmenter
python_env=/home/jiranzo/trabajo/env/venv_py3.8_SegmentationFree/bin/activate

mkdir -p logs/

for FUTURE_WINDOW in 2 3 4;
do
    MAX_LEN=$(( $FUTURE_WINDOW + 11 ))

    qsubmit -gcards 1 -gmem $gpu_mem -Q $queue -o logs/$config_name.$MAX_LEN.$FUTURE_WINDOW -m 16 ./train_config_scripts/$config_name.sh $corpus_path $MAX_LEN $FUTURE_WINDOW $config_name.$MAX_LEN.$FUTURE_WINDOW $segmenter_root $python_env

done
