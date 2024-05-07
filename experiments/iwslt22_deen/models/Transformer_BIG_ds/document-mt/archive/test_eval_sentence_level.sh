set -e
rm -f RESULTS_PAPER_R*

for k in 1 2 3 4 5 6 7 8 9 10;
do
    echo "###########################"
    echo $k

    echo "Model segmentation - Model realignment"
    python3 convert_delays_to_streamRW.py /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.segmented_IWSLT20_rnn_15_4.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/delay tmp_file /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.segmented_IWSLT20_rnn_15_4.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text

    echo $k $( ./align_and_eval_streaming_latency.sh /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.segmented_IWSLT20_rnn_15_4.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de tmp_file 1.0 0) >> RESULTS_PAPER_REAL

    rm -f tmp_file

    echo "Model segmentation - Model realignment - DAL scale 0.95 "
    python3 convert_delays_to_streamRW.py /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.segmented_IWSLT20_rnn_15_4.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/delay tmp_file /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.segmented_IWSLT20_rnn_15_4.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text

    echo $k $(./align_and_eval_streaming_latency.sh /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.segmented_IWSLT20_rnn_15_4.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de tmp_file 0.95 0) >> RESULTS_PAPER_REAL_0.95

    rm -f tmp_file
    
    echo "Model segmentation - Model realignment - DAL scale 0.9 "
    python3 convert_delays_to_streamRW.py /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.segmented_IWSLT20_rnn_15_4.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/delay tmp_file /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.segmented_IWSLT20_rnn_15_4.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text

    echo $k $(./align_and_eval_streaming_latency.sh /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.segmented_IWSLT20_rnn_15_4.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de tmp_file 0.9 0) >> RESULTS_PAPER_REAL_0.9

    rm -f tmp_file


    echo "Model segmentation - Model realignment - DAL scale 0.75 "
    #python3 convert_delays_to_streamRW.py /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.segmented_IWSLT20_rnn_15_4.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/delay tmp_file /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.segmented_IWSLT20_rnn_15_4.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text

    #./align_and_eval_streaming_latency.sh /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.segmented_IWSLT20_rnn_15_4.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de tmp_file 0.75 0

    rm -f tmp_file

    echo "Model segmentation - Model realignment - DAL scale 0.5 "
    #python3 convert_delays_to_streamRW.py /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.segmented_IWSLT20_rnn_15_4.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/delay tmp_file /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.segmented_IWSLT20_rnn_15_4.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text

    #./align_and_eval_streaming_latency.sh /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.segmented_IWSLT20_rnn_15_4.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de tmp_file 0.5 0

    rm -f tmp_file

    echo "Reference segmentation - Reference alignment"
    python3 convert_delays_to_streamRW.py /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/delay tmp_file /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text

    echo $k $(python3 /home/jiranzo/trabajo/git/nmt-scripts/document-mt/eval_streaming_latency.py /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text tmp_file 1.0 0) >> RESULTS_PAPER_REFERENCE_SEGMENTATION_REFERENCE_ALIGNMENT

    rm -f tmp_file


    echo "Reference segmentation - Reference alignment - DAL scale 0.95"
    python3 convert_delays_to_streamRW.py /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/delay tmp_file /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text

    echo $k $(python3 /home/jiranzo/trabajo/git/nmt-scripts/document-mt/eval_streaming_latency.py /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text tmp_file 0.95 0) >> RESULTS_PAPER_REFERENCE_SEGMENTATION_REFERENCE_ALIGNMENT_0.95


    rm -f tmp_file
 
    echo "Reference segmentation - Reference alignment - DAL scale 0.9"
    python3 convert_delays_to_streamRW.py /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/delay tmp_file /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text

    echo $k $(python3 /home/jiranzo/trabajo/git/nmt-scripts/document-mt/eval_streaming_latency.py /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text tmp_file 0.9 0) >> RESULTS_PAPER_REFERENCE_SEGMENTATION_REFERENCE_ALIGNMENT_0.9


    rm -f tmp_file

    echo "Reference segmentation - Real alignment"
    python3 convert_delays_to_streamRW.py /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/delay tmp_file /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text 1

    echo $k $(./align_and_eval_streaming_latency.sh /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de tmp_file 1.0 0)  >> RESULTS_PAPER_REFERENCE_SEGMENTATION_REAL_ALIGNMENT 
    
    rm -f tmp_file

    echo "Reference segmentation - Real alignment - DAL scale 0.95"
    python3 convert_delays_to_streamRW.py /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/delay tmp_file /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text 1

    echo $k $(./align_and_eval_streaming_latency.sh /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de tmp_file 0.95 0)  >> RESULTS_PAPER_REFERENCE_SEGMENTATION_REAL_ALIGNMENT_0.95 
    
    rm -f tmp_file

 
    echo "Reference segmentation - Real alignment - DAL scale 0.9"
    python3 convert_delays_to_streamRW.py /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/delay tmp_file /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text 1

    echo $k $(./align_and_eval_streaming_latency.sh /scratch/jiranzotmp/experiments/mt/StreamTranslation_deen/inference_out/Transformer_BASE_waitk_baseline/StreamTranslation_deen.Transformer_BASE_waitk_baseline.norm.iwslt17.dev2010.results_MuST-C_2_catchup1.24_wait$k/text /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de tmp_file 0.9 0)  >> RESULTS_PAPER_REFERENCE_SEGMENTATION_REAL_ALIGNMENT_0.9 
    
    rm -f tmp_file

    echo "Reference segmentation - Oracle system - Oracle alignment"
    python3 simulate_waitk_oracle.py  /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en tmp_file_delays $k

    python3 convert_delays_to_streamRW.py tmp_file_delays tmp_file /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en
    
    echo $k $(python3 /home/jiranzo/trabajo/git/nmt-scripts/document-mt/eval_streaming_latency.py /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en tmp_file 1.0 0) >> RESULTS_PAPER_REFERENCE_SEGMENTATION_ORACLE_SYSTEM_ORACLE_ALIGNMENT

    rm -f tmp_file tmp_file_delays

    echo "Reference segmentation - Oracle system - Real alignment"
    python3 simulate_waitk_oracle.py  /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en tmp_file_delays $k
    
    python3 convert_delays_to_streamRW.py tmp_file_delays tmp_file /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en
    
    echo $k $(./align_and_eval_streaming_latency.sh /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/iwslt17.dev2010.prepro.en /scratch/jiranzotmp/trabajo/StreamTranslation_deen/eval/norm.iwslt17.dev2010.de tmp_file 1.0 0) >> RESULTS_PAPER_REFERENCE_SEGMENTATION_ORACLE_SYSTEM_REAL_ALIGNMENT


    rm -f tmp_file tmp_file_delays




done
