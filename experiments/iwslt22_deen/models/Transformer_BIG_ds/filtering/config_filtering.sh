####################
# Filtering config #
####################
# Clean refers to a subset of data to be used for training filtering models. It is assumed this data is of a good enough quality. 
ORIG_CLEAN_DATA_TRAIN_PREFIX=clean_data
ORIG_CLEAN_DATA_DEV_PREFIX=clean_data_dev

CLEAN_DATA_TRAIN_PREFIX=$ORIG_CLEAN_DATA_TRAIN_PREFIX.prepro.bpe
CLEAN_DATA_DEV_PREFIX=$ORIG_CLEAN_DATA_DEV_PREFIX.prepro.bpe

# The corpus to be filtered
ORIG_NOISY_DATA_PREFIX=noisy_data
NOISY_DATA_PREFIX=$ORIG_NOISY_DATA_PREFIX.prepro.bpe

