#!/bin/bash

export mode="${1:-fix-best}"
export cfg_fn="${2:-navit_shipped.xml}"
export dir="${3:-./xpm}"

export wet=${mode/#*-dry/}

msg () {
	echo "$@" > /dev/stderr
}

msg1 () {
	if [ "${1:0:1}" = "-" ]; then
		echo $1 > /dev/stderr
	fi
}

msg0 () {
	[ "${1}" != "-n" ] && nl="\n" && shift
	echo -e "$1$nl" > /dev/stderr
}

add_cfg_pattern () {
	base=$1
	from=$2
	to=$3
	msg " - fixing config-file."
	cfg_fix_cnt=$(( $cfg_fix_cnt + 1 ))
	cfg_pat='$_ =~ s/ src="'$base'\\.'$from'"/ src="'$base'.'$to'"/;
'$cfg_pat
}

fix_icon_file () {
	base=$1
	from=$2
	to=$3
	msg " - generating $base.$to."
	icon_fix_cnt=$(( $icon_fix_cnt + 1 ))
	[ "$wet" != "" ] && convert $dir/$base.$from $dir/$base.$to && icon_fix_list="xpm_DATA += $base.$to
$icon_fix_list"
}

msg "Checking $cfg_fn for missing icons..."

list=`perl -ne 'if ($_ =~ /<icon\s+src="([^"]+)"/i) { print $1."\n"; }' $cfg_fn | sort | uniq`
#set -x
tot_cnt=0; miss_cnt=0; size_cnt=0; ext_cnt=0
cfg_fix_cnt=0; icon_fix_cnt=0
for fn in $list; do
	[ "$fn" = "%s" ] && continue
	tot_cnt=$(( $tot_cnt + 1 ))
	if [ ! -f "$dir/$fn" ]; then
		miss_cnt=$(( $miss_cnt + 1 ))
		base=${fn/%.*/}
		ext=${fn/#*./}
		if [ -f "$dir/${base}_*_*.${ext}" ]; then
			msg "$dir/$fn is missing, but one with size suffix is there."
			size_cnt=$(( $size_cnt + 1 ))
			continue
		fi
		ext_cnt=$(( $ext_cnt + 1 ))
		if [ "$ext" = "xpm" -a -f "$dir/${base}.png" ]; then
			msg -n "$dir/$fn is missing, but $dir/${base}.png is there"
			case $mode in
				fix-best*|fix-cfg*) add_cfg_pattern $base "xpm" "png" ;;
				fix-icon*) fix_icon_file $base "png" "xpm" ;;
			esac
			continue
		fi
		if [ "$ext" = "png" -a -f "$dir/${base}.xpm" ]; then
			msg -n "$dir/$fn is missing, but $dir/${base}.xpm is there"
			case $mode in
				fix-cfg*) add_cfg_pattern $base "png" "xpm" ;;
				fix-best*|fix-icon*) fix_icon_file $base "xpm" "png" ;;
			esac
			continue
		fi
		msg "$dir/$fn is missing."
	fi
done

ok_cnt=$(( $tot_cnt - $miss_cnt ))
msg -e "\n$tot_cnt icons checked, $ok_cnt ok"
msg "  $miss_cnt missing, of which $size_cnt have size suffix and $ext_cnt have wrong extension"
msg "  $cfg_fix_cnt fixes in config-file, $icon_fix_cnt fixes by converting icons"

if [ "$icon_fix_list" != "" ]; then
	msg -e "\nYou might wanna add the following list to $dir/Makefile.am:"
	msg -e "$icon_fix_list"
fi

if [ $cfg_fix_cnt -gt 0 ]; then
	msg -e "\n$cfg_fn with fixed extensions comes through stdout:\n"
	perl -ne "$cfg_pat print \$_;" $cfg_fn
fi
