#!/bin/bash

a=$1
b=$2
op=$3

#sed -e "s|'|sri|g;s|~|bmk|g" $a > ${a}_new
sed -e "s|'|sri|g;s|~|bmk|g" $op > ${op}_new

roman=(`cat ${a}`)
map=(`cat $b`)
num=`cat $a |wc -l`

for (( i=0; i<$num; i++ ))
do
#sed -e "s|${roman[$i]}|${map[$i]}|g" $op > ${op}_new
sed -i "s|${roman[$i]}|${map[$i]}|g" ${op}_new
done
