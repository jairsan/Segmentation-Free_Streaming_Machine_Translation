#Warning: Work in Progress
#Setup run-specifig config
SCRIPT="$(readlink --canonicalize-existing "$0")"
SCRIPTPATH="$(dirname "$SCRIPT")"
source $SCRIPTPATH/config.sh

source $PYTHON_ENV
CUTOFF=0.25

paste A.scores B.scores | awk '{print exp (- ( sqrt(($1 - $2) *($1 - $2)) + 0.5 * ($1 + $2) ) )}' > adq.scores

paste lm_N_src.scores lm_I_src.scores | awk '{print $1 / $2}' | awk '{if ($1 > 1 ) print "1.0"; else print $1;}' |
 awk -v cutoff=$CUTOFF '{if ($1 >= cutoff ) print $1; else print "0.0"; }' > dom_src.scores
 
paste lm_N_tgt.scores lm_I_tgt.scores | awk '{print $1 / $2}' | awk '{if ($1 > 1 ) print "1.0"; else print $1;}' |
 awk -v cutoff=$CUTOFF '{if ($1 >= cutoff ) print $1; else print "0.0"; }' > dom_tgt.scores

paste src_lang.scores tgt_lang.scores | awk '{print ($1 * $2)  }' > lang.scores

paste adq.scores dom_src.scores dom_tgt.scores lang.scores | awk  '{print ($1 * $2 * $3 * $4)  }' > total.scores

deactivate
