#!/bin/bash

. ./cmd.sh 
[ -f path.sh ] && . ./path.sh

decode_nj=32
train_nj=32
train_cmd=run.pl
decode_cmd=run.pl

mfcc=0
mono=1
tri1=1
tri2=1

train_dir=data/train
test_dir=data/test
lang_dir=data/lang_test_bg

model_dir=`echo $train_dir | cut -d'/' -f 2`
graph_name=`echo $lang_dir | cut -d '/' -f 2 | sed "s/lang/graph/"`
decode_name=`echo $test_dir | cut -d '/' -f 2`
if [ $mfcc -eq 1 ]; then

echo ============================================================================
echo "         MFCC Feature Extration & CMVN for Training and Test set           "
echo ============================================================================


for x in  $train_dir $test_dir; do
	steps/make_mfcc.sh --cmd "$train_cmd" --nj "$train_nj" $x || exit 1;
 	steps/compute_cmvn_stats.sh $x || exit 1;
done
fi

if [ $mono -eq 1 ]; then

echo ============================================================================
echo "                     MonoPhone Training & Decoding                        "
echo ============================================================================

steps/train_mono.sh  --nj "$train_nj" --cmd "$train_cmd" $train_dir $lang_dir exp/mono_$model_dir || exit 1;

utils/mkgraph.sh --mono $lang_dir exp/mono_$model_dir exp/mono_$model_dir/$graph_name || exit 1;

steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" exp/mono_$model_dir/$graph_name $test_dir exp/mono_$model_dir/decode_${decode_name}_${graph_name} || exit 1;

fi

if [ $tri1 -eq 1 ]; then

echo ============================================================================
echo "           tri1 : Deltas + Delta-Deltas Training & Decoding               "
echo ============================================================================

steps/align_si.sh --nj "$train_nj" --cmd "$train_cmd" $train_dir $lang_dir exp/mono_$model_dir exp/mono_${model_dir}_ali || exit 1;

for sen in 1000; do
for gauss in 8; do
gauss=$(($sen * $gauss))
steps/train_deltas.sh --cmd "$train_cmd" $sen $gauss $train_dir $lang_dir exp/mono_${model_dir}_ali exp/tri1_${sen}_${gauss}_${model_dir} || exit 1;

utils/mkgraph.sh $lang_dir exp/tri1_${sen}_${gauss}_$model_dir exp/tri1_${sen}_${gauss}_$model_dir/$graph_name || exit 1;

steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" exp/tri1_${sen}_${gauss}_${model_dir}/$graph_name $test_dir exp/tri1_${sen}_${gauss}_$model_dir/decode_${decode_name}_${graph_name} || exit 1;

done
done
fi

if [ $tri2 -eq 1 ]; then
echo ============================================================================
echo "                 tri2 : LDA + MLLT Training & Decoding                    "
echo ============================================================================


for sen in 1000; do
for gauss in 8; do
gauss=$(($sen * $gauss))

steps/align_si.sh --nj "$train_nj" --cmd "$train_cmd" $train_dir $lang_dir exp/tri1_${sen}_${gauss}_$model_dir exp/tri1_${sen}_${gauss}_${model_dir}_ali || exit 1;

steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" $sen $gauss $train_dir $lang_dir exp/tri1_${sen}_${gauss}_${model_dir}_ali exp/tri2_${sen}_${gauss}_$model_dir  || exit 1;

utils/mkgraph.sh $lang_dir exp/tri2_${sen}_${gauss}_$model_dir exp/tri2_${sen}_${gauss}_$model_dir/$graph_name || exit 1;

steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" exp/tri2_${sen}_${gauss}_$model_dir/$graph_name $test_dir exp/tri2_${sen}_${gauss}_$model_dir/decode_${decode_name}_${graph_name} || exit 1;

done
done

fi

echo ============================================================================
echo "Finished successfully on" `date`
echo ============================================================================
