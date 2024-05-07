source config_bt.sh
# Obtain max suffix from splits_mono_prepro 
mkdir synthetic_source
qsubmit -gmem 8G -m 8 -j 1:$max_split_suffix ./do_backtrans.sh
