#!/usr/bin/env python

#------------------------------------------------------------------------------
# This program is used to generate the wp_gram from the district or commodity list
# eg ./generate_bigram.py unique_word_list > wp_gram
#------------------------------------------------------------------------------

import sys
from collections import defaultdict

word_list = [xx.strip().split() for xx in open(sys.argv[1])]
word_list = [ ["SENTENCE-END"] + xx + ["SENTENCE-END"]
              for xx in word_list ]

suc_list = defaultdict(set)

for line in word_list:
    for w1, w2 in zip(line[:-1], line[1:]):
        suc_list[w1].add(w2)

list_of_keys = suc_list.keys()
list_of_keys.sort()

for ww in list_of_keys:
    print ">" + ww
    for ss in suc_list[ww]:
        print " " + ss
