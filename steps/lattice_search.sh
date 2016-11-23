#!/bin/bash

acwt=0.083
lmwt=3
n=10

source path.sh; # source the path.

lang_dir=$1
kws_dir=$2
kws_ip_dir=$3

raw_keyword_file=$3/raw_keywords.txt
rm ${kws_dir}/result.1
#lattice-to-nbest --acoustic-scale=$acwt --lm-scale=$lmwt --n=$n "ark:gzip -cdf ${kws_dir}/lat_rescore.*.gz|" ark:- | nbest-to-ctm ark:- ${kws_dir}/${lmwt}.ctm || exit 1;

lattice-to-ctm-conf --inv-acoustic-scale=$lmwt "ark:gzip -cdf ${kws_dir}/lat_rescore.*.gz|" ${kws_dir}/${lmwt}.ctm || exit 1;
while read keyword
do
	kw_lang_no=`cat $lang_dir/words.txt | grep -F "$keyword " | cut -d ' ' -f2`
	kw_id=`cat $kws_ip_dir/keywords.txt | grep -F " $keyword" | cut -d ' ' -f1`
	cat ${kws_dir}/${lmwt}.ctm | grep -F " $kw_lang_no" | awk -v kw_id=$kw_id '{print kw_id,$1,$3*100,$4*100,-1*log($6)}' >> ${kws_dir}/result.1
done < $raw_keyword_file

