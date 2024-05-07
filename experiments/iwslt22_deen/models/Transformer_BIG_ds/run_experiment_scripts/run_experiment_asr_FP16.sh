#Setup run-specifig config
source config.sh

qsubmit -n p$RUN$CORPUS -m 24 ./preprocess_corpus_ASR.sh
qsubmit -n b$RUN$CORPUS -w p$RUN$CORPUS -m 24 ./learn_and_apply_bpe.sh
qsubmit -n bin$RUN$CORPUS -w b$RUN$CORPUS -m 24 ./prepare_data_$TOOLKIT.sh

qsubmit -n t$RUN$CORPUS -w bin$RUN$CORPUS -gmem $GPU_MEM -gcards 1 -m 24 -a pinxo,panxo.dsic.upv.es,riddler.dsic.upv.es,sephiroth,gozer1,gozer2,estelles ./train_model_"$TOOLKIT"_"$MODEL_CONFIG"_FP16.sh

qsubmit -n idev$RUN$CORPUS -w t$RUN$CORPUS -gmem 6G -m 16 ./infer_$TOOLKIT.sh $DEV_PREFIX
qsubmit -n itest$RUN$CORPUS -w t$RUN$CORPUS -gmem 6G -m 16 ./infer_$TOOLKIT.sh $TEST_PREFIX

