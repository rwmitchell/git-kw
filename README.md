# git-kw
## About
Provide keyword support for git.

## Keywords Supported
- $Id$    : Commit hash   ( this is natively supported )
- $Source$: Fuly-qualified filename
- $Date$  : Commit date as YYYY-MM-DD HH:MM:SS TZ
- $Auth$  : Commit author
- $File$  : filename
- $Log$   : Last 3 commit dates each followed by the log message
- $MyId$  : Repo name and combination of above

## Using
- Define each file extension to support keywords in ```.gitattributes```
  - *.EXT ident     # converts $Id$ supported by git natively
  - *.EXT filter=kw # converts other keywords
- Add to ```.gitconfig```

```
[filter "kw"]
  smudge = gitkwexpand %f
  clean  = gitkwshrink
```

- Load supporting aliases and functions
  - ```source git-kw.plugin.zsh```
- After committing changes, run:
  - guk   # (stands for git update keywords)
- This updates working files with new keyword values.
- keywords.txt contains sample output

## History
I have used various version control programs over the years.

sccs -> cvs -> hg -> git

The initial programs supported keywords and have been using them ever since,
despite more intelligent programmers saying they are not productive.

My programs have an option to output version info including the above keywords.
Knowing the date when the source code was committed for the program is an easy
way to know how current it is.  The rest is just vanity.
