#!/bin/sh

# $Id$

# when invoked from git, there are no cmdline args

FN=$1
FQ=$( git rev-parse --show-toplevel )
DT=$( git show -s --date=format:"%F %T %z" --format="%ad" )
ID=$( git show -s --date=format:"%F %T %z" --format="$( basename $PWD) %ad %d %h" )
AN=$( git show -s --format="%an <%aE>" )

if [[ $FN ]]; then
  FQ+="/$FN"

  printf "Updating Keywords: %s|%s\n" "$0" "$*" > /dev/tty
  sed "s#\\\$MyId.*\\\$#\\\$MyId: $ID \\\$#;     \
       s#\\\$Source.*\\\$#\\\$Source: $FQ \\\$#; \
       s#\\\$Date.*\\\$#\\\$Date: $DT \\\$#;     \
       s#\\\$Auth.*\\\$#\\\$Auth: $AN \\\$#"     \
       < $FN
else
  printf "Updating keywords: %s|%s\n" "$0" "$*" > /dev/tty

  sed "s#\\\$MyId.*\\\$#\\\$MyId: $ID \\\$#;     \
       s#\\\$Source.*\\\$#\\\$Source: $FQ \\\$#; \
       s#\\\$Date.*\\\$#\\\$Date: $DT \\\$#;     \
       s#\\\$Auth.*\\\$#\\\$Auth: $AN \\\$#"
fi
