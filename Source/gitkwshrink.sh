#!/bin/sh

# $Id$

# when invoked from git, there are no cmdline args

# ID="Keep it going"
FN=$1
FQ=$PWD
DT=$( git show -s --date=format:"%F %T %z" --format="%ad" )
ID=$( git show -s --date=format:"%F %T %z" --format="$( basename $PWD) %ad %d %h %an %aE" )

if [[ $FN ]]; then
  FQ=$PWD/$FN

  sed "s#\$Id.*\$#\$Id\$#; \
       s#\$Source.*\$#\$Source\$#; \
       s#\$Date.*\$#\$Date\$#"     \
       < $FN
else
  sed "s#\$Id.*\$#\$Id\$#; \
       s#\$Source.*\$#\$Source\$#; \
       s#\$Date.*\$#\$Date\$#"
fi
