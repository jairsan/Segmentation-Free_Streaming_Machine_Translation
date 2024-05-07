#Setup run-specifig config
source config.sh


#./preprocess_corpus_ASR_only_clean_truecase.sh
#./learn_and_apply_spm.sh

#qsubmit -n bin$RUN$CORPUS -w b$RUN$CORPUS -m 24 ./prepare_data_$TOOLKIT.sh

qsubmit -n t$RUN$CORPUS -w bin$RUN$CORPUS -gmem $GPU_MEM -gcards 1 -m 20 -a raimonet,estelles,cassalla,gozer2,punxo,pinxo,panxo.dsic.upv.es ./train_model_"$TOOLKIT"_"$MODEL_CONFIG"_FP16.sh
