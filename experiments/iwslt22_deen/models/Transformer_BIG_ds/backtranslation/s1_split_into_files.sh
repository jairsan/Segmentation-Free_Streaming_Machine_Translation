source config_bt.sh
# Split the files for parallelization
mkdir splits_mono
split -l $SPLIT_LENGTH --suffix-length=3 --numeric-suffixes=1 $MONO_PATH splits_mono/split.
cd splits_mono
rename 's#\.0{1,}#\.#' split.*
