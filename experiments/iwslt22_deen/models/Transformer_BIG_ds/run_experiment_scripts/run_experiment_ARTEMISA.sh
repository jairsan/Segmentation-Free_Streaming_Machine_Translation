source config.sh

for s in {1..5};
do
export TRAINSTEP=0$s
condor_submit train_model_fairseq_HTCONDOR.sub
sleep 3600
condor_wait -debug -num 1 -wait 604800 logs.train_step."$TRAINSTEP".out
done
