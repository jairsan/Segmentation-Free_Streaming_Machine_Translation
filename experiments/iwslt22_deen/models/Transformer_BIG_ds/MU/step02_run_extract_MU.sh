SRC_LANG=en
TGT_LANG=de
OUTPUT_SUFFIX=corpus
python3 extract_MU.py $OUTPUT_SUFFIX.input.tok.$SRC_LANG.MU_indices $OUTPUT_SUFFIX.grow-diag-final.align $OUTPUT_SUFFIX.input.tok.$SRC_LANG $OUTPUT_SUFFIX.input.tok.$TGT_LANG
