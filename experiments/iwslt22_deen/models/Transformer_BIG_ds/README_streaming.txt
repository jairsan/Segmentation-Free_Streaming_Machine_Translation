(Sentence-level simul system, works only for custom fairseq, CUDA 10.0)

Custom Fairseq repo:
    https://mllp.upv.es/git/jiranzo/simultaneous_fairseq

Train multi-k:
    train_model_scripts/train_model_fairseq_SIMUL-MULTIK-BASE_FP16.sh , BASE->BIG, etc

Inference:
    $SIMUL_FAIRSEQ/examples/simultaneous_translation/eval/multi_k_translation_wrapper.py

Evaluate:
    eval_latency.py  with the delays file produced by the inference step

Production inference:
    Use mt_server and model type: FAIRSEQ_SIMUL_IWSLT22 

