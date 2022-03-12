#!/bin/sh

# $Id$

# when invoked from git, there are no cmdline args

FN=$1

if [[ $FN ]]; then

  sed "s#\\\$MyId.*\\\$#\\\$MyId\\\$#;     \
       s#\\\$Source.*\\\$#\\\$Source\\\$#; \
       s#\\\$Date.*\\\$#\\\$Date\\\$#;     \
       s#\\\$Auth.*\\\$#\\\$Auth\\\$#;     \
       s#\\\$File.*\\\$#\\\$File\\\$#;     \
       s#\\\$Log.*\\\$#\\\$Log\\\$#"       \
       < $FN
else
  sed "s#\\\$MyId.*\\\$#\\\$MyId\\\$#;     \
       s#\\\$Source.*\\\$#\\\$Source\\\$#; \
       s#\\\$Date.*\\\$#\\\$Date\\\$#;     \
       s#\\\$Auth.*\\\$#\\\$Auth\\\$#;     \
       s#\\\$File.*\\\$#\\\$File\\\$#"     \
  | sed -e '/$Log:/,/:Log\$/c\
  \$Log\$'
fi
