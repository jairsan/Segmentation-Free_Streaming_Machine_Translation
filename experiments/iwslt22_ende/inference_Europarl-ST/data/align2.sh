#!/bin/bash -e
# Joan Albert Silvestre
# set -x
export LC_ALL="C.UTF-8"

function log {
  echo -e "[LL] [${HOSTNAME%%.*}] [$(date "+%F %T")] $1"
}

function time_stats {
  begin=$1; end=$2; ref=$3
  diff=$(echo "$end - $begin" | bc -l | awk -F'.' '{print $1}') 
  time=$(date -u -d @${diff} +"%T")
  if [ $diff -ge 86400 ]; then
    time="$time(+$[diff/86400]days)"
  fi
  if [ "$ref" != "0" ]; then
    rtf=$(printf %.2f $(echo "$diff/$ref" | bc -l))
  else
    rtf="N/A"
  fi
}

function error {
  echo -e "[EE] [${HOSTNAME%%.*}] $1" >&2
  exit 1
}

function warn {
  echo -e "[WW] [${HOSTNAME%%.*}] $1" >&2
}

PRGNAME=$(basename $0)
NARGS=4

# Show help
function print_help {
    TO=$1
    SHOWHELP=$2
    echo "$PRGNAME [options] <CONFIG_FILE> <IN_MEDIA> <SEGMENTS_LIST> <OUT_DIR>" > $TO
    echo "" > $TO
    [ $SHOWHELP -eq 0 ] && return
    cat <<EOF > $TO

  Options:

    -h: Shows this help
    -S <dir>: Scripts dir. Default: dirname of this script.
    -t <dir>: Set tmp directory. Default: /home/tmp/ttp/\$USER.\${JOB_ID}.\$JOB_NAME
    -p <dir>: Set tmp directory prefix. Default: /home/tmp/ttp
    -N      : Do not remove tmp dir at exit.
    -b <dir>: Set TLK bin directory. Default: extracted from \$PATH env variable.
    -n <str>: Job name. Default: basename of input media file.
    -T      : Generate alignment for training purposes.
    -R      : Do not re-segment; use recognition segmentation instead.
    -m      : Deal with MTP notation ([music], [lang:Foreign] ... [/lang:Foreign], etc.)
    -s      : Put acoustic silences at the beggining and at the end of the end of each segment to be aligned.
    -P <str>: Override prune options from config file. Example: "-p '-m 5000:-m 10000:-m 20000'"
 
EOF
}

echo "*******************************************************************"
echo "*"
echo "* $USER@${HOSTNAME%%.*}"
echo "*"
echo "* $0 $@"
echo "*"
echo "*******************************************************************"

set +e
ffmpeg=$(which ffmpeg)
[ -z $ffmpeg ] && ffmpeg=$(which avconv)
[ -z $ffmpeg ] && error "ffmpeg/avconv not found in PATH"
ffprobe=$(which ffprobe)
[ -z $ffprobe ] && ffmpeg=$(which probe)
[ -z $ffprobe ] && error "ffprobe/avprobe not found in PATH"
[ "$(which tLtranscribe)" != "" ] && TLK_BIN_DIR=$(dirname $(which tLtranscribe)) || TLK_BIN_DIR=""
set -e
SCRIPTS_DIR="$(readlink -f $(dirname $0))"
TMP="NULL"
MY_JOB_NAME="NULL"
DELETE_TMP=1
TRAIN=0
RESEG=1
TMP_PREF="/home/tmp/ttp"
MAX_OOVS_PERCENT=60
MTP=0
SPS=0
PRUNE_OVR_OPTS="NULL"
RECOVER_TEXT_FORMAT=1

ARGS=`getopt -o "ThNt:b:n:p:S:c:RsP:m" -n $PRGNAME -- "$@"`
eval set -- "$ARGS"
while true
do
    case $1 in
	-h) print_help /dev/stdout 1; exit 0;;
        -S) SCRIPTS_DIR="$(readlink -f $2)";;
        -t) TMP="$2";;
        -p) TMP_PREF="$2";;
        -N) DELETE_TMP=0;;
        -b) TLK_BIN_DIR="$(readlink -f $2)";;
        -n) MY_JOB_NAME="$2";;
        -T) TRAIN=1;;
        -R) RESEG=0;;
        -s) SPS=1;;
        -m) MTP=1;;
        -P) PRUNE_OVR_OPTS="$2";;
	--) shift; break;;
    esac
    shift
done
[ $# != $NARGS ] && { print_help /dev/stderr 0; error "wrong number of arguments"; }

log "$(date)"
ts_g_s=$(date +%s)

CONFIG="$(readlink -f $1)"
IN_MEDIA="$(readlink -f $2)"
SEGMENTS_LIST="$(readlink -f $3)"
OUTDIR="$4"

mkdir -p "$OUTDIR"

[ "$MY_JOB_NAME" = "NULL" ] && [ ! -z "$JOB_NAME" ] && MY_JOB_NAME="$JOB_NAME" || MY_JOB_NAME="$(basename $IN_MEDIA)"
[ ! -z "$JOB_ID" ] && MY_JOB_ID="$JOB_ID" || MY_JOB_ID=$$
[ "$TMP" = "NULL" ] && TMP="$TMP_PREF/$USER.${MY_JOB_ID}.$MY_JOB_NAME"

TLK_TLTRECO_SCRIPTS="$TLK_BIN_DIR/../share/tlk/tLtask-recognise/scripts"
export PATH=$TLK_TLTRECO_SCRIPTS:$TLK_BIN_DIR:$PATH

source "$CONFIG"
[ ! -z "$LANGUAGE" ] && [ ! -z "$TIED_LIST" ] && [ ! -z "$AM" ] && 
   [ ! -z "$DNN" ] && [ ! -z "$TLEXTRACT_OPTS" ] && 
   [ ! -z "$W2P" ] && [ ! -z "$TLRECOGNISE_OPTS" ] ||
   error "Missing required variables in the Config File"

if [ $SPS -eq 1 ]; then
  [ ! -z "$SP_TOKEN" ] || error "Missing \$SP_TOKEN variable in config file"
fi

if [ $PRUNE_OVR_OPTS != "NULL" ]; then
  PRUNE_1=$(echo $PRUNE_OVR_OPTS | cut -d ':' -f 1) 
  PRUNE_2=$(echo $PRUNE_OVR_OPTS | cut -d ':' -f 2) 
  PRUNE_3=$(echo $PRUNE_OVR_OPTS | cut -d ':' -f 3) 
fi

lexmono2tri=$(which lexmono2tri.py)
wgraph=$(which wgraph.py)

if [ ! -z "$GET_CACHE" ]; then
  log "Caching files..."
  log "$(date)"
  ts_ca_s=$(date +%s)
  TIED_LIST=$($GET_CACHE "$TIED_LIST")
  DNN=$($GET_CACHE "$DNN")
  AM=$($GET_CACHE "$AM")
  ts_ca_e=$(date +%s)
else
  ts_ca_s=0
  ts_ca_e=0
fi

mkdir -p "$TMP"
#cd "$TMP"

function finish {
   log "Removing TMP dir ($TMP)"
   rm -rf "$TMP"
}

if [ $DELETE_TMP -eq 1 ]; then
  trap finish 0 1 2 3 6 9 14 15
#  trap finish EXIT
fi

set -e

echo "**** TMP dir: $TMP ****"

ts_pr_s=$(date +%s)
# Extract audio
mkdir -p "$TMP/wav"

rm -f "$TMP/wavs.lst"
rm -f "$TMP/trans.txt"

if [ ! -z "$(which $ffprobe)" ]; then
  vlen=$($ffprobe "$IN_MEDIA" -show_format_entry duration | grep "[0-9]\.[0-9]" | sed -e 's|duration=||g')
  [ $? -ne 0 ] && vlen=0
else
  vlen=0 
fi

n=0
cat $SEGMENTS_LIST | while read st et txt; do
  n=$[n+1]
  if [ $st = "0" -a $et = "<END>" ]; then
    id="${st}_${vlen}-${n}"
    log "Processing Sample ID $id"
    wavf="$TMP/wav/$id.wav"
    $ffmpeg -i "$IN_MEDIA" "$wavf" < /dev/null #&> /dev/null
  else
    id="${st}_${et}-${n}"
    log "Processing Sample ID $id"
    len=$(echo "$et - $st" | bc -l | awk '{printf "%f", $0}')
    wavf="$TMP/wav/$id.wav"
    $ffmpeg -i "$IN_MEDIA" -ss "$st" -t "$len" "$wavf" < /dev/null #&> /dev/null
  fi
  echo $wavf >> "$TMP/wavs.lst"
  echo "$txt" >> "$TMP/trans.txt"
done

# Generate Lexicon
log "Generating Lexicon"

prepro_opts=""
[ $MTP -eq 1 ] && prepro_opts="-m"
python3 $SCRIPTS_DIR/scripts/align-prepro.py $prepro_opts "$TMP/trans.txt" "$TMP/prepro"

nvoc=$(cat "$TMP/prepro/transcript.vocab" | wc -l)
[ $nvoc -eq 0 ] && error "Empty vocabulary! Aborting." 

awk '$3 == 1 {print $2}' "$TMP/prepro/transcript.vocab" | sort > "$TMP/prepro/transcript.vocab.g2p"
awk '$3 == 0 {print $2}' "$TMP/prepro/transcript.vocab" | sort > "$TMP/prepro/transcript.vocab.sp"
awk '{print $2}' "$TMP/prepro/transcript.vocab" | sort > "$TMP/prepro/transcript.vocab.all"

$W2P "$TMP/prepro/transcript.vocab.g2p" > "$TMP/mono.lex"
for w in `<"$TMP/prepro/transcript.vocab.sp"`; do
  echo "$w 0 ${SP_TOKEN}"
done >> "$TMP/mono.lex"
 
# Check untranscribed words
cat "$TMP/mono.lex" | awk '{ if($1 != "LEXICON" && NF<3) print $1}' > "$TMP/mono.untranscribed.txt"
notxs=$(cat "$TMP/mono.untranscribed.txt" | wc -l)

if [ $notxs -gt 0 ]; then
  perc_notxs=$(echo "$notxs $nvoc" | awk '{printf("%d", $1/$2*100)}')
  if [ $perc_notxs -ge $MAX_OOVS_PERCENT ]; then
    error "Found a lot of untranscribed words ($notxs/$nvoc = $perc_notxs%) in the generated monophone lexicon. See: '$TMP/mono.untranscribed.txt'. Aborting."
  else
    warn "Some untranscribed words ($notxs/$nvoc = $perc_notxs%) found in the generated monophone lexicon:"
    cat "$TMP/mono.untranscribed.txt" >&2
    cat "$TMP/mono.lex" | awk '{ if($1 != "LEXICON" && NF<3) print $1" "$2" SP"; else print;}' > "$TMP/mono.fixed.lex"
  fi
else
  CDIR=$PWD
  cd $TMP
  ln -s "mono.lex" "mono.fixed.lex"
  cd $CDIR
fi

# Check omitted (OOVs) words
cat "$TMP/mono.fixed.lex" | grep -v "^LEXICON$" | awk '{print $1}' | sort > "$TMP/mono.fixed.vocab.txt"
grep -vxF -f "$TMP/mono.fixed.vocab.txt" "$TMP/prepro/transcript.vocab.all" | sort > "$TMP/mono.fixed.out-of-vocab.txt"
oovs=$(cat "$TMP/mono.fixed.out-of-vocab.txt" | wc -l)

if [ $oovs -gt 0 ]; then
  perc_oovs=$(echo "$oovs $nvoc" | awk '{printf("%d", $1/$2*100)}')
  if [ $perc_oovs -ge $MAX_OOVS_PERCENT ]; then
    error "Found a lot of OOVs ($oovs/$nvoc = $perc_oovs%) in the generated monophone lexicon. See: '$TMP/mono.fixed.out-of-vocab.txt'. Aborting."
  else
    warn "Some OOVs ($oovs/$nvoc = $perc_oovs%) found in the generated monophone lexicon:"
    cat "$TMP/mono.fixed.out-of-vocab.txt" >&2
    cat "$TMP/mono.fixed.out-of-vocab.txt" | awk '{print $1" 0 SP"}' >> "$TMP/mono.fixed.lex"
  fi
else
  rm "$TMP/mono.fixed.vocab.txt" "$TMP/mono.fixed.out-of-vocab.txt"
fi

# Check untranscribed + OOVs
tperc_oovs=$(echo "$notxs $oovs $nvoc" | awk '{printf("%d", ($1+$2)/$3*100)}')
if [ $tperc_oovs -ge $MAX_OOVS_PERCENT ]; then
  error "Found a lot of untranscribed + OOVs ( ($notx+$oovs)/$nvoc = $tperc_oovs%) in the generated monophone lexicon. Aborting."
fi


cat "$TMP/mono.fixed.lex" | $lexmono2tri $LEXMONO2TRI_OPTS "$TIED_LIST" > "$TMP/tied.lex"

set -e

# Feature Extraction
log "Extracting Features"

mkdir -p "$TMP/feas"

cat "$TMP/wavs.lst" | sed -e "s|$TMP/wav/|$TMP/feas/|g" -e 's|\.wav$|\.tLfea|g' > "$TMP/feas.lst"

tLextract $TLEXTRACT_OPTS "$TMP/wavs.lst" "$TMP/feas.lst"

ts_pr_e=$(date +%s)

# Alignment
log "Aligning Features"

ts_al_s=$(date +%s)

did_align=0

if [ $TRAIN -eq 1 ]; then
  mkdir -p "$TMP/wgs"
  cat "$TMP/wavs.lst" | sed -e "s|$TMP/wav/|$TMP/wgs/|g" -e 's|\.wav$|\.tLwg|g' > "$TMP/wgs.lst"
  TLRECOGNISE_OPTS="$TLRECOGNISE_OPTS -W $TMP/wgs.lst -N 1 --htk-wgs"
fi

for i in 1 2 3 ; do
    cprune=$(echo $(eval "echo $""PRUNE_$i"))
    if [ -z "$cprune" ]; then
      if [ $i -eq 1 ]; then 
        error "\$PRUNE_$i variable was not set on config file ($CONFIG)"
      else
        warn "\$PRUNE_$i variable was not set on config file ($CONFIG)"
        continue
      fi
    fi

    nvidia-smi
    log "CUDA set by SGE: $CUDA_VISIBLE_DEVICES"

    log "- Using prune LEVEL $i ($cprune) ..."
    log "tLrecognise $TLRECOGNISE_OPTS $cprune -v -v --sym-align --lm-align -l $TMP/tied.lex -d $DNN -o $TMP/align.txt $TMP/prepro/transcript.align.txt $AM $TMP/feas.lst"
    tLrecognise $TLRECOGNISE_OPTS $cprune -v -v --sym-align --lm-align -l "$TMP/tied.lex" -d "$DNN" -o "$TMP/align.txt" "$TMP/prepro/transcript.align.txt" "$AM" "$TMP/feas.lst"

    if [ $(cat "$TMP/align.txt" | grep -A 1 '^"' | grep '^\.' | wc -l) -eq 1 ]; then
        warn "Could not align some samples using PRUNE LEVEL ${i}."
    else
        cp "$TMP/align.txt" "$OUTDIR/align.tlk"
        did_align=1
        break
    fi

done

ts_al_e=$(date +%s)

[ $did_align -eq 0 ] && error "Could not align some samples. Aborting."

ts_po_s=$(date +%s)

cp "$TMP/prepro/transcript.align.txt" "$OUTDIR/transcript.clean.txt"
cp "$TMP/prepro/transcript.ind" "$OUTDIR/transcript.ind"
cp "$TMP/prepro/transcript.vocab" "$OUTDIR/transcript.ind.vocab"

a2t_opts=""

if [ $RESEG -eq 1 ]; then
    if [ $TRAIN -eq 1 ]; then 
        while read wg; do
            cat $wg | $wgraph -A
        done < "$TMP/wgs.lst" > "$OUTDIR/align.scores.txt"
        a2t_opts_train="$a2t_opts --for-training --am-scores $OUTDIR/align.scores.txt"
        log "python $SCRIPTS_DIR/scripts/tlkalign2trans.py $a2t_opts_train --write-stats-file $OUTDIR/align.filtered.stats $OUTDIR/align.tlk $OUTDIR/align.filtered"
        python $SCRIPTS_DIR/scripts/tlkalign2trans.py $a2t_opts_train --write-stats-file "$OUTDIR/align.filtered.stats" "$OUTDIR/align.tlk" "$OUTDIR/align.filtered" 
    fi
else
    a2t_opts="$a2t_opts --keep-segmentation"
fi

[ $RECOVER_TEXT_FORMAT -eq 1 ] && a2t_opts="$a2t_opts --recover-text-format --ind-file $OUTDIR/transcript.ind --vocab-file $OUTDIR/transcript.ind.vocab"

log "python $SCRIPTS_DIR/scripts/tlkalign2trans.py $a2t_opts --write-stats-file $OUTDIR/align.stats $OUTDIR/align.tlk $OUTDIR/align"
python $SCRIPTS_DIR/scripts/tlkalign2trans.py $a2t_opts --write-stats-file "$OUTDIR/align.stats" "$OUTDIR/align.tlk" "$OUTDIR/align"


ts_po_e=$(date +%s)

log "$(date)"

ts_g_e=$(date +%s)

# Compute stats
log "Computing time stats"
log "$(date)"
set +e

export LC_NUMERIC="en_US.UTF-8"

echo -e "\n----------------------------------"
echo -e "\tTIME\tRTF"
time_stats $ts_ca_s $ts_ca_e $vlen
echo -e "Cache\t$time\t$rtf"
time_stats $ts_pr_s $ts_pr_e $vlen
echo -e "Prepro\t$time\t$rtf"
time_stats $ts_al_s $ts_al_e $vlen
echo -e "Align\t$time\t$rtf"
time_stats $ts_po_s $ts_po_e $vlen
echo -e "Postpr\t$time\t$rtf"
time_stats $ts_g_s $ts_g_e $vlen
echo -e "TOTAL\t$time\t$rtf"
echo -e "----------------------------------\n"

log "$(date)"


