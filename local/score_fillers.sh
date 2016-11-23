#!/bin/bash
# Copyright 2012  Johns Hopkins University (Author: Daniel Povey)
# Apache 2.0

[ -f ./path.sh ] && . ./path.sh

# begin configuration section.
cmd=run.pl
stage=0
decode_mbr=true
reverse=false
word_ins_penalty=0
min_lmwt=1
max_lmwt=20
#end configuration section.

[ -f ./path.sh ] && . ./path.sh
. parse_options.sh || exit 1;

if [ $# -ne 4 ]; then
  echo "Usage: local/score.sh [--cmd (run.pl|queue.pl...)] <data-dir> <lang-dir|graph-dir> <decode-dir>"
  echo " Options:"
  echo "    --cmd (run.pl|queue.pl...)      # specify how to run the sub-processes."
  echo "    --stage (0|1|2)                 # start scoring script from part-way through."
  echo "    --decode_mbr (true/false)       # maximum bayes risk decoding (confusion network)."
  echo "    --min_lmwt <int>                # minumum LM-weight for lattice rescoring "
  echo "    --max_lmwt <int>                # maximum LM-weight for lattice rescoring "
  echo "    --reverse (true/false)          # score with time reversed features "
  exit 1;
fi

data=$1
lang_or_graph=$2
dir=$3
noise_type=$4
symtab=$lang_or_graph/words.txt
<<"over"
for f in $symtab $dir/lat.1.gz $data/text; do
  [ ! -f $f ] && echo "score.sh: no such file $f" && exit 1;
done

mkdir -p $dir/scoring/log

cat $data/text | sed 's:<NOISE>::g' | sed 's:<SPOKEN_NOISE>::g' > $dir/scoring/test_filt.txt

$cmd LMWT=$min_lmwt:$max_lmwt $dir/scoring/log/best_path.LMWT.log \
  lattice-scale --inv-acoustic-scale=LMWT "ark:gunzip -c $dir/lat.*.gz|" ark:- \| \
  lattice-add-penalty --word-ins-penalty=$word_ins_penalty ark:- ark:- \| \
  lattice-best-path --word-symbol-table=$symtab \
    ark:- ark,t:$dir/scoring/LMWT.tra || exit 1;

if $reverse; then
  for lmwt in `seq $min_lmwt $max_lmwt`; do
    mv $dir/scoring/$lmwt.tra $dir/scoring/$lmwt.tra.orig
    awk '{ printf("%s ",$1); for(i=NF; i>1; i--){ printf("%s ",$i); } printf("\n"); }' \
       <$dir/scoring/$lmwt.tra.orig >$dir/scoring/$lmwt.tra
  done
fi
over
# Note: the double level of quoting for the sed command
mkdir -p $dir/wer_${noise_type}
$cmd LMWT=$min_lmwt:$max_lmwt $dir/scoring_${noise_type}/log/score.LMWT.log \
    cat $dir/scoring_${noise_type}/LMWT.tra \| \
    utils/int2sym.pl -f 2- $symtab \| sed "'s|\bfb_.......\b||g;s|sil||g;s|\bfb_......\b||g;s|\bfb_.....\b||g;s|\bfb_....\b||g;s|\bfb_...\b||g;s|\bfb_..\b||g;s|<s>||g;s|</s>||g;s|<pau>||g;s|<aah>||g;s|<hmm>||g;s|<hm>||g;s|<laugh>||g;s|<vn>||g;s|<babble>||g;s|<horn>||g;s|<bang>||g;s|<bn>||g;s|sil||g;'" \| \
    compute-wer --text --mode=present \
    ark:$dir/scoring_${noise_type}/test_filt.txt  ark,p:- ">&" $dir/wer_${noise_type}/wer_LMWT || exit 1;

#$cmd LMWT=$min_lmwt:$max_lmwt $dir/scoring/log/score.LMWT.log \
#   cat $dir/scoring/LMWT.tra \| \
#    utils/int2sym.pl -f 2- $symtab \| sed "'s|\bfb_.......\b||g;s|xyz||g;s|\bfb_......\b||g;s|\bfb_.....\b||g;s|\bfb_....\b||g;s|\bfb_...\b||g;s|\bfb_..\b||g;s|<s>||g;s|</s>||g'" \| \
#    compute-wer --text --mode=present \
#     ark:$dir/scoring/test_filt.txt  ark,p:- ">&" $dir/wer_LMWT || exit 1;






#$cmd LMWT=$min_lmwt:$max_lmwt $dir/scoring/log/score.LMWT.log \
#   cat $dir/scoring/LMWT.tra \| \
#      utils/int2sym.pl -f 2- $symtab \| sed "'s|\bfb_.......\b||g;s|xyz||g;s|\bfb_......\b||g;s|\bfb_.....\b||g;s|\bfb_....\b||g;s|\bfb_...\b||g;s|\bfb_..\b||g;s|<s>||g;s|</s>||g'" \| \
#      ark:$dir/scoring/test_filt.txt  ark,p:- ">&" $dir/wer_LMWT || exit 1;
#     utils/int2sym.pl -f 2- $symtab \| sed "'s|\bfb_.......\b||g;s|sil||g;s|\bfb_......\b||g;s|\bfb_.....\b||g;s|\bfb_....\b||g;s|\bfb_...\b||g;s|\bfb_..\b||g;s|<s>||g;s|</s>||g'" \| \
#     ark:$dir/scoring/test_filt.txt  ark,p:- ">&" $dir/wer_LMWT || exit 1;

exit 0;
