HYPO_FILE=$1
TGT_REFERENCE_FILE=$2
SRC_INPUT_FILE=$3
ACTION_FILE=$4
DAL_GAMMA_SCALE=$5
DEBUG=$6

if [ -z "$6" ]
  then
    DEBUG=0
fi


cat $HYPO_FILE | sed -r 's/\@\@ //g' | sed -r 's#&lt;DOC&gt;##g' | sed -r 's#&lt;SEP&gt;##g' | sed -r 's#&lt;BRK&gt;##g' | sed -r 's#&lt;CONT&gt;##g' > $PWD/.metrics_prepro

sleep 1

/scratch/jiranzotmp/trabajo/Europarl-ST/05_experiments_ICASSP/mwerSegmenter/segmentBasedOnMWER_v2.sh kk $TGT_REFERENCE_FILE $PWD/.metrics_prepro ST_system en $PWD/.metrics_prepro_resegmented 0 0

python3 /home/jiranzo/trabajo/git/nmt-scripts/document-mt/eval_streaming_latency.py $SRC_INPUT_FILE $PWD/.metrics_prepro_resegmented $ACTION_FILE $DAL_GAMMA_SCALE $DEBUG

#python3 /home/jiranzo/trabajo/git/nmt-scripts/document-mt/eval_streaming_latency_non_recursive.py $SRC_INPUT_FILE $PWD/.metrics_prepro_resegmented $ACTION_FILE $DAL_GAMMA_SCALE $DEBUG

rm -f $PWD/.metrics_prepro_resegmented $PWD/.metrics_prepro

