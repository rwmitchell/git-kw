#!/bin/bash

# $Id$

# when invoked from git, there are no cmdline args

# FN=$1


FN=$(printf "%s" "$@" | sed -e 's,/,\\/,g' -e 's,&,\\&,g')
FQ=$( git rev-parse --show-toplevel )
DT=$( git show -s --date=format:"%F %T %z" --format="%ad" )
ID=$( git show -s --date=format:"%F %T %z" --format="$( basename $PWD) %ad %d %h" )
AN=$( git show -s --format="%an <%aE>" )
VN=$( git describe --tags --long --always --dirty )

# 2022-03-19: sed breaks on nur_util.c, disabling
LG=$( git log -n 3 --format="%aD%n%B" -- $FN )
LG=$( echo "$LG" | sed 's/^/  /;s/^ *$//' )   # insert two space before each line
LG=${LG//$'\n'/\\
}                                             # escape newlines for sed

  printf "Updating keywords: %s|%s\n" "$0" "$*" > /dev/tty

  sed "s#\\\$MyId.*\\\$#\\\$MyId: $ID \\\$#;     \
       s#\\\$Source.*\\\$#\\\$Source: $FQ \\\$#; \
       s#\\\$Date.*\\\$#\\\$Date: $DT \\\$#;     \
       s#\\\$Auth.*\\\$#\\\$Auth: $AN \\\$#;     \
       s#\\\$Vrsn.*\\\$#\\\$Vrsn: $VN \\\$#;     \
       s#\\\$File.*\\\$#\\\$File: $FN \\\$#"     \
  | sed -e '/$GLog:/,/:GLog\$/c\
  $GLog:\
  '"$LG"' \
  :GLog$'

# printf "FN :  %s\n" "$FN" > /dev/tty
# printf "LOG:\n%s\n" "$LG" > /dev/tty

exit 0;

# '%f' added to smudge filter in .gitconfig
# this provides filename, no need for 'if'
if [[ $FN ]]; then
  FQ+="/$FN"

  printf "Updating Keywords: %s|%s\n" "$0" "$*" > /dev/tty
  sed "s#\\\$MyId.*\\\$#\\\$MyId: $ID \\\$#;     \
       s#\\\$Source.*\\\$#\\\$Source: $FQ \\\$#; \
       s#\\\$Date.*\\\$#\\\$Date: $DT \\\$#;     \
       s#\\\$Auth.*\\\$#\\\$Auth: $AN \\\$#;     \
       s#\\\$File.*\\\$#\\\$File: $FN \\\$#"     \
       < $FN
else
  printf "Updating keywords: %s|%s\n" "$0" "$*" > /dev/tty

  sed "s#\\\$MyId.*\\\$#\\\$MyId: $ID \\\$#;     \
       s#\\\$Source.*\\\$#\\\$Source: $FQ \\\$#; \
       s#\\\$Date.*\\\$#\\\$Date: $DT \\\$#;     \
       s#\\\$Auth.*\\\$#\\\$Auth: $AN \\\$#;
       s#\\\$File.*\\\$#\\\$File: $FN \\\$#"     \
fi

##### 2023-05-26 Using tags for version numbers:


#!/bin/bash

version_regex='v([0-9]+)\.([0-9]+)\.?([0-9]*)-([0-9]+)-g([0-9|a-z]+)'

git_string=$(git describe --tags --long)

if [[ $git_string =~ $version_regex ]]; then
  maj_ver="${BASH_REMATCH[1]}"
  min_ver="${BASH_REMATCH[2]}"
  pch_ver="${BASH_REMATCH[3]}"
  cmt_ver="${BASH_REMATCH[4]}"
else
  printf "Error!\n"
fi

printf "maj_version: %s\n" "$maj_ver"
printf "min_version: %s\n" "$min_ver"
printf "pch_version: %s\n" "$pch_ver"
printf "cmt_version: %s\n" "$cmt_ver"
