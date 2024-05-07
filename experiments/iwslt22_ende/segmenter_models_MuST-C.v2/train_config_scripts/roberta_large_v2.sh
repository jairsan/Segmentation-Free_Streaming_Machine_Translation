corpus_folder=$1
len=$2
window=$3
output_folder=$4
segmenter_root=$5
python_env=$6

rm -r $output_folder

source $python_env 

python $segmenter_root/train_model.py \
--model_architecture xlm-roberta \
--transformer_model_name xlm-roberta-large \
--train_corpus $corpus_folder/train.ML$len.WS$window.txt \
--dev_corpus $corpus_folder/dev.ML$len.WS$window.txt \
--output_folder $output_folder \
--vocabulary $corpus_folder/train.vocab.txt \
--sampling_temperature 100 \
--batch_size 64 \
--epochs 10 \
--adam_b1 0.9 \
--adam_b2 0.98 \
--adam_eps 1e-8 \
--lr 1e-5 \
--lr_schedule reduce_on_plateau \
--lr_reduce_patience 1 \
--amp \
--sample_max_len $len \
--sample_window_size $window
