source /home/jiranzo/trabajo/env/venv_py3.7.12_bitextor_filtering_tools/bin/activate

fil=$1
config_fil=$2

IN_F=$fil.$SGE_TASK_ID
OUT_F=$fil.bicleaned.$SGE_TASK_ID

export LC_ALL=C.UTF-8
LC_ALL=C.UTF-8
bicleaner-classify-lite --debug --disable_lm_filter $IN_F $OUT_F $config_fil

a=$(cat $IN_F | wc -l )
b=$(cat $OUT_F | wc -l)

if [ "$a" -eq "$b" ]
then
    exit 0
else
    echo "Incorrect number of output lines" $a $b
    exit 1
fi
