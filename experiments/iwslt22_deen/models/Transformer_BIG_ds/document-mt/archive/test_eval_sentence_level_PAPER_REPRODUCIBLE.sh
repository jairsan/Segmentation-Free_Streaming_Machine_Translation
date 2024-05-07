set -e


rm -rf REPRODUCIBLE/

mkdir -p REPRODUCIBLE/REAL
mkdir -p REPRODUCIBLE/INSEG
mkdir -p REPRODUCIBLE/OUTSEG_INSEG
mkdir -p REPRODUCIBLE/POLICY_OUTSEG_INSEG

for k in 1 2 3 4 5 6 7 8 9 10;
do
    echo "###########################"
    echo $k

    echo "Model segmentation - Model realignment"
    python3 convert_delays_to_streamRW.py /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen_BACKUP/inference_out/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.segmented_IWSLT20_rnn_15_4.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/delay tmp_file /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen_BACKUP/inference_out/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.segmented_IWSLT20_rnn_15_4.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text
    

    ./align_and_eval_streaming_latency_KEEP.sh /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen_BACKUP/inference_out/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.segmented_IWSLT20_rnn_15_4.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de tmp_file 1.0 0

    RUN=REAL
    cp tmp_file REPRODUCIBLE/$RUN/$k.RW
    cat /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen_BACKUP/inference_out/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.segmented_IWSLT20_rnn_15_4.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text | sed -r 's/\@\@ //g' | sed -r 's#&lt;DOC&gt;##g' | sed -r 's#&lt;SEP&gt;##g' | sed -r 's#&lt;BRK&gt;##g' | sed -r 's#&lt;CONT&gt;##g' > REPRODUCIBLE/$RUN/$k.orig_h
    cp $PWD/.metrics_prepro_resegmented REPRODUCIBLE/$RUN/$k.reseg_h 

    rm -f tmp_file $PWD/.metrics_prepro_resegmented $PWD/.metrics_prepro

   echo "Reference segmentation - Real alignment"
    python3 convert_delays_to_streamRW.py /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen_BACKUP/inference_out/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/delay tmp_file /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen_BACKUP/inference_out/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text 1

    ./align_and_eval_streaming_latency_KEEP.sh /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen_BACKUP/inference_out/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de tmp_file 1.0 0 

    RUN=INSEG
    cp tmp_file REPRODUCIBLE/$RUN/$k.RW
    cat /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen_BACKUP/inference_out/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text | sed -r 's/\@\@ //g' | sed -r 's#&lt;DOC&gt;##g' | sed -r 's#&lt;SEP&gt;##g' | sed -r 's#&lt;BRK&gt;##g' | sed -r 's#&lt;CONT&gt;##g' > REPRODUCIBLE/$RUN/$k.orig_h
    cp $PWD/.metrics_prepro_resegmented REPRODUCIBLE/$RUN/$k.reseg_h 
    rm -f tmp_file $PWD/.metrics_prepro_resegmented $PWD/.metrics_prepro


 
    echo "Reference segmentation - Oracle alignment"
    python3 convert_delays_to_streamRW.py /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen_BACKUP/inference_out/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/delay tmp_file /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen_BACKUP/inference_out/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text

    #python3 /home/jiranzo/trabajo/git/nmt-scripts/document-mt/eval_streaming_latency.py /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen_BACKUP/inference_out/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text tmp_file 1.0 0) >> RESULTS_PAPER_REFERENCE_SEGMENTATION_REFERENCE_ALIGNMENT
   
    RUN=OUTSEG_INSEG
    cp tmp_file REPRODUCIBLE/$RUN/$k.RW
    cat /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen_BACKUP/inference_out/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text | sed -r 's/\@\@ //g' | sed -r 's#&lt;DOC&gt;##g' | sed -r 's#&lt;SEP&gt;##g' | sed -r 's#&lt;BRK&gt;##g' | sed -r 's#&lt;CONT&gt;##g' > REPRODUCIBLE/$RUN/$k.orig_h
    cp REPRODUCIBLE/$RUN/$k.orig_h REPRODUCIBLE/$RUN/$k.reseg_h 
    rm -f tmp_file $PWD/.metrics_prepro_resegmented $PWD/.metrics_prepro


    echo "Reference segmentation - Oracle system - Oracle alignment"
    python3 simulate_waitk_oracle.py  /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en tmp_file_delays $k

    python3 convert_delays_to_streamRW.py tmp_file_delays tmp_file /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en
    
    echo $k $(python3 /home/jiranzo/trabajo/git/nmt-scripts/document-mt/eval_streaming_latency.py /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en tmp_file 1.0 0) >> RESULTS_PAPER_REFERENCE_SEGMENTATION_ORACLE_SYSTEM_ORACLE_ALIGNMENT

    
    RUN=POLICY_OUTSEG_INSEG
    cp tmp_file REPRODUCIBLE/$RUN/$k.RW
    cp /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en REPRODUCIBLE/$RUN/$k.orig_h
    cp REPRODUCIBLE/$RUN/$k.orig_h REPRODUCIBLE/$RUN/$k.reseg_h 
    rm -f tmp_file $PWD/.metrics_prepro_resegmented $PWD/.metrics_prepro




done
