#./train_wrapper.sh rnn_ff_text_base 10G all.q
#./train_wrapper.sh simple_rnn_base 10G all.q
#./train_wrapper.sh roberta_base 10G all.q
#./train_wrapper.sh roberta_large_v2 20G cuda11.q
# This is just a special version because previous one was interrupted, delete when done
./train_wrapper_int.sh roberta_large_v2 20G cuda11.q
