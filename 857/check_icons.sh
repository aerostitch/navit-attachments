#!/bin/bash

xml="navit_shipped.xml"

echo "Checking $xml for missing icons..." > /dev/stderr

list=`perl -ne 'if ($_ =~ /<icon\s+src="([^"]+)"/i) { print $1."\n"; }' $xml | sort | uniq`
#set -x
n=0; m=0; s=0; e=0
for fn in $list; do
	[ "$fn" = "%s" ] && continue
	n=$(( $n + 1 ))
	if [ ! -f "./xpm/$fn" ]; then
		base=${fn/%.*/}
		ext=${fn/#*./}
		if [ -f "./xpm/${base}_*_*.${ext}" ]; then
			echo "./xpm/$fn is missing, but one with size suffix is there." > /dev/stderr
			s=$(( $s + 1 ))
			continue
		fi
		if [ "$ext" = "xpm" -a -f "./xpm/${base}.png" ]; then
			echo "./xpm/$fn is missing, but ./xpm/${base}.png is there." > /dev/stderr
			chg='$_ =~ s/ src="'$fn'"/ src="'$base'.png"/;
'$chg
			e=$(( $e + 1 ))
			continue
		fi
		if [ "$ext" = "png" -a -f "./xpm/${base}.xpm" ]; then
			echo "./xpm/$fn is missing, but ./xpm/${base}.xpm is there." > /dev/stderr
			chg='$_ =~ s/ src="'$fn'"/ src="'$base'.xpm"/;
'$chg
			e=$(( $e + 1 ))
			continue
		fi
		echo "./xpm/$fn is missing." > /dev/stderr
		m=$(( $m + 1 ))
	fi
done
ok=$(( $n - $m - $s ))

echo "$n icons checked, $ok ok, $s with size suffix, $e with different extension, $m missing" > /dev/stderr
if [ $e -gt 0 ]; then
	echo "$xml with fixed extensions:" > /dev/stderr
	echo "" > /dev/stderr
	perl -ne "${chg} print \$_;" $xml
fi
