src=en
tgt=de

for set in dev test;
do
    src_file=/scratch/translectures/data/Europarl-ST/RELEASES/v1.1/$src/$tgt/$set/segments.$src
    tgt_file=/scratch/translectures/data/Europarl-ST/RELEASES/v1.1/$src/$tgt/$set/segments.$tgt
    segments=/scratch/translectures/data/Europarl-ST/RELEASES/v1.1/$src/$tgt/$set/segments.lst
    output_folder=$PWD/split_$set
    cp $src_file $set.$src
    cp $tgt_file $set.$tgt
    python3 split_Europarl-ST.py $src_file $segments $output_folder
    python3 split_Europarl-ST.py $tgt_file $segments $output_folder
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
