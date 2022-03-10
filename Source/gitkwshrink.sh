#!/bin/sh

# $Id$

# when invoked from git, there are no cmdline args

FN=$1

if [[ $FN ]]; then

  sed "s#\\\$MyId.*\\\$#\\\$MyId\\\$#;     \
       s#\\\$Source.*\\\$#\\\$Source\\\$#; \
       s#\\\$Date.*\\\$#\\\$Date\\\$#;     \
       s#\\\$Auth.*\\\$#\\\$Auth\\\$#"     \
       < $FN
else
  sed "s#\\\$MyId.*\\\$#\\\$MyId\\\$#;     \
       s#\\\$Source.*\\\$#\\\$Source\\\$#; \
       s#\\\$Date.*\\\$#\\\$Date\\\$#;     \
       s#\\\$Auth.*\\\$#\\\$Auth\\\$#"
fi
