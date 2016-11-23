#!/bin/bash -u

. path.sh

main_dir=$1
data_dir=$main_dir
lang_dir=$data_dir/lang_test_bg
lang_local_dir=$data_dir/local/lang_test_bg
dict_dir=$data_dir/local/dict_timit
tmp_dir=$data_dir/local/tmp
trans_file=data/train/trans_for_fst_train.txt

source path.sh
rm -r $tmp_dir $lang_dir $lang_local_dir
mkdir -p $tmp_dir

rm -r data/local/tmp_lm
mkdir data/local/tmp_lm

utils/prepare_lang.sh --sil-prob 0.0 --num-sil-states 3 $dict_dir '<UNK>' $lang_local_dir $lang_dir || exit 1;

# Create the phone bigram LM
(
  [ -z "$IRSTLM" ] && \
    error_exit "LM building wo'nt work without setting the IRSTLM env variable"
  $IRSTLM/bin/build-lm.sh -i $trans_file -n 2 -o data/local/tmp_lm/lm_phone_bg.ilm.gz
  $IRSTLM/bin/compile-lm --text="yes" data/local/tmp_lm/lm_phone_bg.ilm.gz data/local/tmp_lm/lm_phone_bg.ilm.lm
	
) >& data/prepare_lm.log

cat data/local/tmp_lm/lm_phone_bg.ilm.lm | grep -v unk | gzip -c > $lang_dir/lm_phone_bg.arpa.gz 
#cp lm_phone_bg.ilm.lm data/lang/lm_phone_bg.arpa.gz

gunzip -c $lang_dir/lm_phone_bg.arpa.gz | utils/find_arpa_oovs.pl $lang_dir/words.txt  > data/local/tmp_lm/oov.txt

gunzip -c $lang_dir/lm_phone_bg.arpa.gz | grep -v '<s> <s>' | grep -v '<s> </s>' | grep -v '</s> </s>' | /$KALDI_ROOT/src/lmbin/arpa2fst - | fstprint | utils/remove_oovs.pl data/local/tmp_lm/oov.txt | utils/eps2disambig.pl | utils/s2eps.pl | fstcompile --isymbols=$lang_dir/words.txt --osymbols=$lang_dir/words.txt --keep_isymbols=false --keep_osymbols=false | fstrmepsilon > $lang_dir/G.fst
fstisstochastic $lang_dir/G.fst
