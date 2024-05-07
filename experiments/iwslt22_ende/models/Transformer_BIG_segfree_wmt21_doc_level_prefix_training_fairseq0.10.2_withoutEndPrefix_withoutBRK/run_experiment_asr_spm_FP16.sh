#Setup run-specifig config
source config.sh


#./preprocess_corpus_ASR_only_clean_truecase.sh
#./learn_and_apply_spm.sh

#./prepare_data_$TOOLKIT.sh

#qsubmit -n t$RUN$CORPUS -w bin$RUN$CORPUS -gmem $GPU_MEM -gcards 4 -m 100 -a punxo ./train_model_"$TOOLKIT"_"$MODEL_CONFIG"_FP16.sh
qsubmit -n t$RUN$CORPUS -w bin$RUN$CORPUS -gmem $GPU_MEM -gcards 1 -m 50 -Q cuda11.q ./train_model_"$TOOLKIT"_"$MODEL_CONFIG"_sangonera_FP16.sh
