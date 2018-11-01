#rename processing files CRS 
#! /usr/bin/sh
for x in 2014*
do
mv $x `echo $x | awk -F+ '{print $3}'`
done