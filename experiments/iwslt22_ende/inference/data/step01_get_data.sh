src=en
tgt=de

for set in dev tst-COMMON;
do
    src_file=/scratch/translectures/data/MuST-C/v2.0/$src-$tgt/data/$set/txt/$set.$src
    tgt_file=/scratch/translectures/data/MuST-C/v2.0/$src-$tgt/data/$set/txt/$set.$tgt
    segments=/scratch/translectures/data/MuST-C/v2.0/$src-$tgt/data/$set/txt/$set.yaml
    output_folder=$PWD/split_$set
    rm -r $output_folder/
    cp $src_file $set.$src
    cp $tgt_file $set.$tgt
    python3 split_MuST-C.py $src_file $segments $output_folder
    python3 split_MuST-C.py $tgt_file $segments $output_folder
    mkdir -p split_"$set"_prepro
    rm $set.$src.lst $set.$tgt.lst $set.prepro.$src.lst
    for FILE in $(ls $output_folder/*.$src);
    do
        filename=$(basename -- "$FILE")
        bsn="${filename%.*}"
        /home/jiranzo/trabajo/git/nmt-scripts/asr-prepro/prepro_en_file.SegFree.sh $output_folder/$bsn.$src > split_"$set"_prepro/$bsn.$src
        echo "$output_folder/$bsn.$src" >> $set.$src.lst
        echo "$output_folder/$bsn.$tgt" >> $set.$tgt.lst
        echo "$PWD/split_"$set"_prepro/$bsn.$src" >> $set.prepro.$src.lst
    done
    
done
