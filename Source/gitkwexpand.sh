#!/bin/bash

# $Id$

# when invoked from git, there are no cmdline args

# FN=$1


FN=$(printf "%s" "$@" | sed -e 's,/,\\/,g' -e 's,&,\\&,g')
FQ=$( git rev-parse --show-toplevel )
DT=$( git show -s --date=format:"%F %T %z" --format="%ad" )
ID=$( git show -s --date=format:"%F %T %z" --format="$( basename $PWD) %ad %d %h" )
AN=$( git show -s --format="%an <%aE>" )

# 2022-03-19: sed breaks on nur_util.c, disabling
# LG=$( git log -n 3 --format="%aD%n%B" -- $FN )
# LG=$( echo "$LG" | sed 's/^/  /;s/^ *$//' )   # insert two space before each line
# LG=${LG//$'\n'/\\n}                          # escape newlines for sed

  printf "Updating keywords: %s|%s\n" "$0" "$*" > /dev/tty

  sed "s#\\\$MyId.*\\\$#\\\$MyId: $ID \\\$#;     \
       s#\\\$Source.*\\\$#\\\$Source: $FQ \\\$#; \
       s#\\\$Date.*\\\$#\\\$Date: $DT \\\$#;     \
       s#\\\$Auth.*\\\$#\\\$Auth: $AN \\\$#;     \
       s#\\\$File.*\\\$#\\\$File: $FN \\\$#"
#      s#\\\$Log.*\\\$#\\\$Log:\\n$LG\n  :Log\\\$#"

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
