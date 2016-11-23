#!/bin/bash

#This script is used to create ecf file for KWS. It takes data directory path as input and expects 'wav.dur' to be present in data directory. You need to redirect output to 'ecf.xml' file in kws data directory.

source path.sh
wavdur_file=$1/wav.dur
data_dir=$1

if [ $# != 1 ]; then
  echo "This script is used to create ecf file for KWS."
  echo "It takes data directory path as input and expects 'wav.dur' to be present in data directory. You need to redirect output to 'ecf.xml' file in kws data directory."
  echo ""
  echo "Usage: local/prepare_ecf_file.xml <data-dir> > <kws-data-dir/ecf.xml>"
  echo " e.g.: local/prepare_ecf_file.xml  data/mandi_test_setA > data/kws_mandi_test_setA/ecf.xml"

  exit 1;
fi

total_dur=`cat $wavdur_file | awk '{sum+=$2}; END {print sum}'`
echo "<ecf source_signal_duration=\"$total_dur\" language=\"Marathi\" version=\"Excluded noscore regions\">"
#echo $data_dir
while read filename dur
do
echo "	<excerpt audio_filename=\"$filename\" channel=\"1\" tbeg=\"0.000\" dur=\"$dur\" source_type=\"splitcts\"/>"
done < $wavdur_file
echo "</ecf>"


