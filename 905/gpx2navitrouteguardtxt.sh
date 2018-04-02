#!/bin/bash

if [ $# -ne 3 ] 
then
	echo "usage:"
	echo "$0 [inputfile] [outputfile] [simplify_count]"
exit
fi

outfilename=$2
infilename=$1
simplify_count=$3

tmpfile=`tempfile`
tmpfile2=`tempfile`

echo 'type=track name="route_guard_test"' > $outfilename

gpsbabel -i gpx -f  $infilename -x simplify,count=$simplify_count -o gpx  -F $tmpfile

gpsbabel -t  -i gpx -f  $tmpfile  -o unicsv -F $tmpfile2 

cut -f 2,3 -d, $tmpfile2 | sed -e 's/,/ /' | grep -vi longitude |awk '{print $2 " " $1}' >>$outfilename

rm -f $tmpfile $tmpfile2

