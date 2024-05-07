corpus_folder=$1
len=$2
window=$3
output_folder=$4
segmenter_root=$5
python_env=$6

rm -r $output_folder

source $python_env 

python $segmenter_root/train_model.py \
--model_architecture simple-rnn \
--train_corpus $corpus_folder/train.ML$len.WS$window.txt \
--dev_corpus $corpus_folder/dev.ML$len.WS$window.txt \
--output_folder $output_folder \
--vocabulary $corpus_folder/train.vocab.txt \
--sampling_temperature 100 \
--batch_size 256 \
--sample_max_len $len \
--sample_window_size $window
