#!/bin/sh

# $Id: mykeywords 2022-03-08 12:17:31 -0500  (HEAD -> main, origin/main, origin/HEAD) d757e7a Richard W. Mitchell rwmitchell@mac.com $

# when invoked from git, there are no cmdline args

# ID="Keep it going"
FN=$1
FQ=$PWD
DT=$( git show -s --date=format:"%F %T %z" --format="%ad" )
ID=$( git show -s --date=format:"%F %T %z" --format="$( basename $PWD) %ad %d %h %an %aE" )

if [[ $FN ]]; then
  FQ=$PWD/$FN

  sed "s#\$Id: mykeywords 2022-03-08 12:17:31 -0500  (HEAD -> main, origin/main, origin/HEAD) d757e7a Richard W. Mitchell rwmitchell@mac.com $
       s#\$Source: /Users/rwmitchell/git/RWM/mykeywords $
       s#\$Date: 2022-03-08 12:17:31 -0500 $
       < $FN
else
  sed "s#\$Id: mykeywords 2022-03-08 12:17:31 -0500  (HEAD -> main, origin/main, origin/HEAD) d757e7a Richard W. Mitchell rwmitchell@mac.com $
       s#\$Source: /Users/rwmitchell/git/RWM/mykeywords $
       s#\$Date: 2022-03-08 12:17:31 -0500 $
fi
