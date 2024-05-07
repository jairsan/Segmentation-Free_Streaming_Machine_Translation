#Setup run-specifig config
source config.sh


./preprocess_corpus_only_clean_truecase.sh
./learn_and_apply_spm_str.sh

qsubmit -n bin$RUN$CORPUS -w b$RUN$CORPUS -m 24 ./prepare_data_$TOOLKIT.sh

qsubmit -n t$RUN$CORPUS -w bin$RUN$CORPUS -gmem $GPU_MEM -gcards 1 -m 30 -a punxo,pinxo,panxo.dsic.upv.es,riddler.dsic.upv.es,sephiroth,gozer1,gozer2,estelles ./train_model_"$TOOLKIT"_"$MODEL_CONFIG"_FP16.sh

qsubmit -n idev$RUN$CORPUS -w t$RUN$CORPUS -gmem 6G -m 16 ./infer_$TOOLKIT.sh $DEV_PREFIX
qsubmit -n itest$RUN$CORPUS -w t$RUN$CORPUS -gmem 6G -m 16 ./infer_$TOOLKIT.sh $TEST_PREFIX

