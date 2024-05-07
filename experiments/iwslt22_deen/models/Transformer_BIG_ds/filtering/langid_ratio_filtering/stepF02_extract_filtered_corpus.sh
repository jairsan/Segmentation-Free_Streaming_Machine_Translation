source config.sh

paste corpus.f1.$SOURCE_LANG_SUFFIX corpus.f1.$TARGET_LANG_SUFFIX corpus.f1.$SOURCE_LANG_SUFFIX.scores corpus.f1.$TARGET_LANG_SUFFIX.scores | awk -F $'\t' 'BEGIN {OFS = FS} {if ($3 == 1.0 && $4 == 1.0) print $1,$2}' > corpus.f2."$SOURCE_LANG_SUFFIX""$TARGET_LANG_SUFFIX"

cut -f 1 corpus.f2."$SOURCE_LANG_SUFFIX""$TARGET_LANG_SUFFIX" > corpus.f2.$SOURCE_LANG_SUFFIX
cut -f 2 corpus.f2."$SOURCE_LANG_SUFFIX""$TARGET_LANG_SUFFIX" > corpus.f2.$TARGET_LANG_SUFFIX
