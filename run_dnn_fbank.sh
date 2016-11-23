#!/bin/bash

# Copyright 2012-2014  Brno University of Technology (Author: Karel Vesely)
# Apache 2.0

# This example script trains a DNN on top of FBANK features. 
# The training is done in 3 stages,
#
# 1) RBM pre-training:
#    in this unsupervised stage we train stack of RBMs, 
#    a good starting point for frame cross-entropy trainig.
# 2) frame cross-entropy training:
#    the objective is to classify frames to correct pdfs.
# 3) sequence-training optimizing sMBR: 
#    the objective is to emphasize state-sequences with better 
#    frame accuracy w.r.t. reference alignment.

# Note: With DNNs in RM, the optimal LMWT is 2-6. Don't be tempted to try acwt's like 0.2, 
# the value 0.1 is better both for decoding and sMBR.

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. ./path.sh ## Source the tools/utils (import the queue.pl)


#. ./gpu_path.sh ## GPu server path

dev=data-fbank/dev
train=data-fbank/train
pretrain=data-fbank/train
test=data-fbank/test

dev_original=data/dev   #path of test_comm data
train_original=data/train  # path of train data
pretrain_original=data/train
test_original=data/test

gmm=exp/tri2  # path of tri2 model

dir=exp/dnn4d-timit-fbank_pretrain-dbn_dnn

ali=exp/tri2_ali # path of tri2_ali model
feature_transform=exp/dnn4d-timit-fbank_pretrain-dbn/final.feature_transform # path of feature_transform inside $dir
dbn_dir=exp/dnn4d-timit-fbank_pretrain-dbn  # path of dbn directory

dbn=exp/dnn4d-timit-fbank_pretrain-dbn/4.dbn #path of dbn 

lang_dir=data/lang_test_bg
graph_dir=$gmm/graph
decode_dir=$dir/decode_test

stage=3

. utils/parse_options.sh || exit 1;
#<<"over"
set -eu
# RUN IN CPU FBANK FEATURES

# Make the FBANK features
#[ ! -e $dev ] && if [ $stage -le 0 ]; then
  # Dev set
# utils/copy_data_dir.sh $dev_original $dev || exit 1; rm $dev/{cmvn,feats}.scp
# steps/make_fbank.sh --nj 10 --cmd "$train_cmd" --fbank-config conf/fbank.conf \
#     $dev $dev/log $dev/data || exit 1;
#  steps/compute_cmvn_stats.sh $dev $dev/log $dev/data || exit 1;

 # Pretrain
# utils/copy_data_dir.sh $pretrain_original $pretrain || exit 1; rm $pretrain/{cmvn,feats}.scp
# steps/make_fbank.sh --nj 10 --cmd "$train_cmd" --fbank-config conf/fbank.conf \
#     $pretrain $pretrain/log $pretrain/data || exit 1;
#  steps/compute_cmvn_stats.sh $pretrain $pretrain/log $pretrain/data || exit 1;
 
 # Training set
#  utils/copy_data_dir.sh $train_original $train || exit 1; rm $train/{cmvn,feats}.scp
#  steps/make_fbank.sh --nj 10 --cmd "$train_cmd --max-jobs-run 10" \
#     $train $train/log $train/data || exit 1;
#  steps/compute_cmvn_stats.sh $train $train/log $train/data || exit 1;
  # Split the training set
#  utils/subset_data_dir_tr_cv.sh --cv-spk-percent 10 $train ${train}_tr90 ${train}_cv10
#fi


# RUN IN GPU Pre-train and optimizing

if [ $stage -le 1 ]; then
  # Pre-train DBN, i.e. a stack of RBMs (small database, smaller DNN)
 dir=/exp/dnn4d-fbank_pretrain-dbn
  $cuda_cmd $dbn_dir/log/pretrain_dbn.log \
    steps/nnet/pretrain_dbn.sh \
      --cmvn-opts "--norm-means=true --norm-vars=true" \
      --delta-opts "--delta-order=2" --splice 5 \
      --hid-dim 2048 --nn-depth 4 --rbm-iter 4 $pretrain $dbn_dir || exit 1; #--rbm-iter 20
fi

if [ $stage -le 2 ]; then
  # Train the DNN optimizing per-frame cross-entropy.
  # Train
  $cuda_cmd $dir/log/train_nnet.log \
    steps/nnet/train.sh --feature-transform $feature_transform --dbn $dbn --hid-layers 0 --learn-rate 0.008 \
    ${train}_tr90 ${train}_cv10 $lang_dir $ali $ali $dir || exit 1;

fi
# Decode (reuse HCLG graph) RUN IN CPU
  steps/nnet/decode.sh --nj 24 --cmd "$decode_cmd" --config conf/decode_dnn.config --acwt 0.1 \
    $graph_dir $test $decode_dir || exit 1;
#fi


# Getting results [see RESULTS file]
# for x in /tmp1/selvi/commodity/exp/*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done
