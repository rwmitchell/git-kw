#!/bin/bash

# $Id$

# when invoked from git, there are no cmdline args

FN=$1

if [[ $FN ]]; then

  sed "s#\\\$MyId.*\\\$#\\\$MyId\\\$#;     \
       s#\\\$Source.*\\\$#\\\$Source\\\$#; \
       s#\\\$Date.*\\\$#\\\$Date\\\$#;     \
       s#\\\$Auth.*\\\$#\\\$Auth\\\$#;     \
       s#\\\$File.*\\\$#\\\$File\\\$#;     \
       s#\\\$GLog.*\\\$#\\\$GLog\\\$#"     \
       < $FN
else
  sed "s#\\\$MyId.*\\\$#\\\$MyId\\\$#;     \
       s#\\\$Source.*\\\$#\\\$Source\\\$#; \
       s#\\\$Date.*\\\$#\\\$Date\\\$#;     \
       s#\\\$Auth.*\\\$#\\\$Auth\\\$#;     \
       s#\\\$File.*\\\$#\\\$File\\\$#"     \
  | sed -e '/$GLog:/,/:GLog\$/c\
  $GLog:\
  :GLog\$'
fi
