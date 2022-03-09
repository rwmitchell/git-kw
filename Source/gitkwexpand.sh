#!/bin/sh

# $Id$

# when invoked from git, there are no cmdline args

# ID="Keep it going"
FN=$1
FQ=$( git rev-parse --show-toplevel )
DT=$( git show -s --date=format:"%F %T %z" --format="%ad" )
ID=$( git show -s --date=format:"%F %T %z" --format="$( basename $PWD) %ad %d %h %an %aE" )

if [[ $FN ]]; then
  FQ+="/$FN"

  sed "s#\$MyId.*\$#\$MyId: $ID \$#; \
       s#\$Source.*\$#\$Source: $FQ \$#; \
       s#\$Date.*\$#\$Date: $DT \$#"     \
       < $FN
else
  printf "Updating keywords: %s|%s\n" "$0" "$*" > /dev/tty

  sed "s#\$MyId.*\$#\$MyId: $ID \$#; \
       s#\$Source.*\$#\$Source: $FQ \$#; \
       s#\$Date.*\$#\$Date: $DT \$#" # | tee /dev/tty
fi
