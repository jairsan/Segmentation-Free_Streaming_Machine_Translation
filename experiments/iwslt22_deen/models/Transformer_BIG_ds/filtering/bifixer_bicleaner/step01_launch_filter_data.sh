source /home/jiranzo/trabajo/env/venv_py3.7.12_bitextor_filtering_tools/bin/activate

filter (){
    name=$1
    src=$2
    tgt=$3
    out=$4

    paste $name.$src $name.$tgt $name.$src $name.$tgt > $name."$src"-"$tgt"-fake

    echo "Starting bifixer" #Output now has 6 columns -- orig[1-4] + hash[5] + ranking[6]
    bifixer --ignore_characters --ignore_orthography $name."$src"-"$tgt"-fake $name."$src"-"$tgt".bifixed $src $tgt
    
    cat $name."$src"-"$tgt".bifixed | python /home/jiranzo/trabajo/git/nmt-scripts/filtering/bifixer_bicleaner/remove_duplicates_bifixer.py > $name."$src"-"$tgt".bifixed.dedup
   
    dir=tmp-filtering-$(basename $name)-split-files

    rm -rf $dir
    mkdir -p $dir
 
    split -n l/50 --suffix-length=2 --numeric-suffixes=1 $name."$src"-"$tgt".bifixed.dedup $dir/chunk.
    cd $dir
    rename 's/\.0+/./' chunk.0?
    cd ../
   
    rm -f $name."$src"-"$tgt"-fake $name."$src"-"$tgt".bifixed $name."$src"-"$tgt".bifixed.dedup 

    qsubmit -m 16 -j 1:50 -n biclean-$(basename $name) ./aux_filter_file.sh $dir/chunk /home/jiranzo/trabajo/git/other-gits/bicleaner/models/"$src"-"$tgt"/"$src"-"$tgt".yaml
    qsubmit -m 4 -w biclean-$(basename $name) ./aux_join_files.sh $dir/chunk $out $src $tgt
}


#Usage
#mkdir filtered

#We can manually define how to apply
#filter tmp-check/Wikipedia.en-es en es filtered/Wikipedia.en-es

#or read from command line
filter $1 $2 $3 $4
