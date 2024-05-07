export PATH=$PATH:/scratch/translectures/bin/srilm/1.7.2/bin/i686-m64/

source config.sh

TRAIN_N_tgt=lm_N_tgt.data
TRAIN_I_tgt=lm_I_tgt.data


ngram-count -order 4 -lm modelN_tgt -kndiscount -interpolate -text $TRAIN_N_tgt   
ngram-count -order 4 -lm modelI_tgt -kndiscount -interpolate -text $TRAIN_I_tgt

ngram -order 4 -lm modelN_tgt -ppl $ORIG_NOISY_DATA_PREFIX.prepro.$TARGET_LANG_SUFFIX -unk -debug 1 | grep "zeroprobs" | awk 'NR>1{print buf}{buf = $0}' | awk '{print $6}'> lm_N_tgt.scores
ngram -order 4 -lm modelI_tgt -ppl $ORIG_NOISY_DATA_PREFIX.prepro.$TARGET_LANG_SUFFIX -unk -debug 1 | grep "zeroprobs" | awk 'NR>1{print buf}{buf = $0}' | awk '{print $6}'> lm_I_tgt.scores



TRAIN_N_src=lm_N_src.data
TRAIN_I_src=lm_I_src.data

ngram-count -order 4 -lm modelN_src -kndiscount -interpolate -text $TRAIN_N_src 
ngram-count -order 4 -lm modelI_src -kndiscount -interpolate -text $TRAIN_I_src

ngram -order 4 -lm modelN_src -ppl $ORIG_NOISY_DATA_PREFIX.prepro.$SOURCE_LANG_SUFFIX -unk -debug 1 | grep "zeroprobs" | awk 'NR>1{print buf}{buf = $0}' | awk '{print $6}'> lm_N_src.scores
ngram -order 4 -lm modelI_src -ppl $ORIG_NOISY_DATA_PREFIX.prepro.$SOURCE_LANG_SUFFIX -unk -debug 1 | grep "zeroprobs" | awk 'NR>1{print buf}{buf = $0}' | awk '{print $6}'> lm_I_src.scores
