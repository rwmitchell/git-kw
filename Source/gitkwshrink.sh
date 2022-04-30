#!/bin/bash

# $Id$

# when invoked from git, there are no cmdline args

FN=$1

if [[ $FN ]]; then

  sed "s#\\\$MyId.*\\\$#\\\$MyId\\\$#;     \
       s#\\\$Source.*\\\$#\\\$Source\\\$#; \
       s#\\\$Date.*\\\$#\\\$Date\\\$#;     \
       s#\\\$Auth.*\\\$#\\\$Auth\\\$#;     \
       s#\\\$File.*\\\$#\\\$File\\\$#"
       < $FN
#      s#\\\$Log.*\\\$#\\\$Log\\\$#"       \
else
  sed "s#\\\$MyId.*\\\$#\\\$MyId\\\$#;     \
       s#\\\$Source.*\\\$#\\\$Source\\\$#; \
       s#\\\$Date.*\\\$#\\\$Date\\\$#;     \
       s#\\\$Auth.*\\\$#\\\$Auth\\\$#;     \
       s#\\\$File.*\\\$#\\\$File\\\$#"
# | sed -e '/$Log:/,/:Log\$/c\
# \$Log\$'
fi
