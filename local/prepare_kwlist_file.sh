#!/bin/bash

#This script is used to create kwslist file for KWS. It takes kws data directory path as input and expects 'keywords.txt' (obtained after running local/kws_data_prep.sh) to be present in kws data directory. You need to redirect output to 'kwlist.xml' file in kws data directory

source path.sh
keyword_file=$1/keywords.txt
kws_dir=$1

if [ $# != 1 ]; then
  echo "This script is used to create kwslist file for KWS."
  echo "It takes kws data directory path as input and expects 'keywords.txt' (obtained after running local/generate_example_kws.sh) to be present in data directory. You need to redirect output to 'kwslist.xml' file in kws data directory."
  echo ""
  echo "Usage: local/prepare_kwslist_file.xml <kws-data-dir> > <kws-data-dir/kwlist.xml>"
  echo " e.g.: local/prepare_kwslist_file.xml  data/kws_mandi_test_setA > data/kws_mandi_test_setA/kwlist.xml"

  exit 1;
fi

echo "<kwlist ecf_filename=\"ecf.xml\" language=\"Marathi\" encoding=\"UTF-8\" compareNormalize=\"\" version=\"Example keywords\">"
while read kid kname
do
echo "	<kw kwid=\"$kid\">"
echo "	    <kwtext>$kname</kwtext>"
echo "	</kw>"
done < $keyword_file
echo "</kwlist>"


