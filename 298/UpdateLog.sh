
grep X0x $1 | cut -d ' ' -f 2 | sed s/X//g | sort | uniq | awk '{system("echo s/"$1"/`addr2line "$1" -e navit -f -s`/g >> sedscr")}'
#not all function pointers find mappings, investigating why, but rather than replace them with ?? entires:
grep -v ? sedscr > sedscr2

sed -f sedscr2 $1 > newTrace.log


