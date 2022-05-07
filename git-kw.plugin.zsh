# Git aliases
#
# $MyId$
# $Source$
# $Date$
#
alias -- gllf="git diff-tree --name-only --no-commit-id -r -a HEAD"   # List last files committed
alias --   gs="git status"
alias --  gdo="git difftool"      # uses opendiff
alias -- gdoy="git difftool -y"   # uses opendiff, no prompting
alias -- glog="git glog"
alias --  glg="git lg"         # fancier but shorter log
alias --  glm="git log HEAD..FETCH_HEAD"
alias --  grv="git remote -v"  # show remotes with url
alias --  gdu="git diff --stat --cached origin/main"     # needs to be in a function

# These aliases match those in OMZ/plugins/git - START
alias --   ga="git add"
alias --  gau="git add --update"

alias --   gb="git branch"
alias --  gba="git branch -a"

alias --   gd="git diff"
alias -- gcda="git diff --cached"
alias --  gds="git diff --staged"
alias --  gdw="git diff --word-diff"

alias --  gss="git status -s"
# These aliases match those in OMZ/plugins/git - END

# Git Update Keywords
# guk : update keywords inlast committed files
# guk FILE: update keywords in FILE
function guk() {
  if [[ $# -gt 0 ]]; then        # use cmdline args
    fl=($@)
  else                           # use last modified files
    fl=($( git diff-tree --name-only --no-commit-id -r -a HEAD ))  # convert output to array
  fi

  printf "Update: %s\n" $fl

  for file in $fl
  do
    rsp=$(prompt -p "delete ?: $file" "yYnNaq")

    case "$rsp" in
      n)                  ;;    # skip
      N|a|q) break        ;;    # skip and exit
      y|Y)   rm $file;          # do this file
             git checkout -f $file ;;
    esac
  done
}

function gsr() {
  setopt localoptions noautopushd nopushdignoredups  # disable options here only
  for g in */.git
  do
    d=$( dirname $g )
    printf "%s\n" "$d"
    cd $d
    git status -s
    cd -
  done
}

function gpr() {
  setopt localoptions noautopushd nopushdignoredups
  for g in */.git
  do
    d=$( dirname $g )
    printf "%s\n" "$d"
    cd $d
    git pull
    cd -
  done
}

function gc() {
  local root=$( git rev-parse --show-toplevel )
  local cmd=$root/.git_cmt_cmd
  local rc=0
  git commit $@                              # GIT -n HEAD
  echo $root
  rc=$?
  [[ $rc -eq 0 && -x $cmd ]] && ( printf "%s\n" "$root"; $cmd; return 0 )
  return $rc
}
compdef _git gc=git-commit

function gp() {
  local root=$( git rev-parse --show-toplevel )
  local branch=$( git_current_branch )    # defined in OMZ/lib/git.zsh
  local rc=0
  echo $root
  local gr=($( git remote show ));
  local lid=$( git rev-parse HEAD );
  for h in $gr; do
    cline 4
    printf "Remote: %s\n" "$h"
    local rid=$( git rev-parse $h/$branch )
    if [[ $lid != $rid ]]; then
      local cnt=$( git diff --name-only $h/$branch...HEAD | wc -l )
      if [[ $cnt > 0 ]]; then
        printf "Updating %d files on %s\n" "$cnt" "$h"
        ssay "Updating $cnt files on $h!"
        # Checking OLD/NEW here shows if there is an actual transfer
#       OLD_COMMIT=$( git rev-parse $h/$branch )
        git push $h HEAD
#       NEW_COMMIT=$( git rev-parse $h/$branch )
        ((rc+=1))
      else
        ssay "$h is current"
      fi
    else
      ssay "$h matches local"
    fi
  done

  return $rc
}

# Git Check Remote - are remotes and local in-sync ?
function gcr() {
  local arg silent=0
  for arg in $@; do
    case $arg in
      -s|--silent) (( silent+=1 ));;
      -ss) (( silent+=2 ));;
      -h|--help  )
        printf "-s|--silent : (1) silence 'in sync' message\n"
        printf "-s|--silent : (2) silence 'not in sync' message\n"
        return;;
      *) printf "Unexpected: %s\n" "$arg"
        return;;
    esac
  done

  local root=$(basename $( git rev-parse --show-toplevel ) )
  local branch=$( git_current_branch )    # defined in OMZ/lib/git.zsh
  local rc=0
  echo $root
  local gr=($( git remote show ));
  local lid=$( git rev-parse HEAD );
  for h in $gr; do
    cline 4
    printf "Remote: %s\n" "$h"
    local rid=($( git ls-remote $h HEAD ))
    rid=$rid[1]
    if [[ $lid != $rid ]]; then
      printf "<%s> %s\n<%s> %s\n" "$lid" "$root" "$rid" "$h"
      printf "\n"
      git diff --name-only HEAD..FETCH_HEAD
      printf "\n"
      git log HEAD...FETCH_HEAD
      printf "\n"
      [[ $silent < 2 ]] && ssay "$root not in sync with $h"
      ((rc+=1))
    else
      [[ $silent < 1 ]] && ssay "$h matches $root"
    fi
  done

  return $rc
}

function gcrr() {
  setopt localoptions noautopushd nopushdignoredups
  local dir
  foreach dir in **/.git; do
    cd $( dirname $dir  )
    gcr -s
    cd -
  done
}

# Git Fetch and report # of files changed
function gf() {
  local root=$( git rev-parse --show-toplevel )
  local rdir=$(basename $root )
  local branch=$( git_current_branch )    # defined in OMZ/lib/git.zsh
  local rc=0
  echo $root
  local gr=($( git remote show ));
  local lid=$( git rev-parse HEAD );

  local arg silent=0
  for arg in $@; do
    case $arg in
      -s|--silent) (( silent+=1 ));;
      -ss) (( silent+=2 ));;
      -h|--help  )
        printf "-s|--silent : (1) silence 'in sync' message\n"
        printf "-s|--silent : (2) silence 'not in sync' message\n"
        return;;
      *) printf "Unexpected: %s\n" "$arg"
        return;;
    esac
  done

  for h in $gr; do
    cline 4
    printf "Remote: %s\n" "$h"
    local rid=($( git ls-remote $h HEAD ))
    rid=$rid[1]
    if [[ $lid != $rid ]]; then
      OLD_COMMIT=$( git rev-parse $h/$branch )
      git fetch $h HEAD
      NEW_COMMIT=$( git rev-parse FETCH_HEAD )
      printf "<%s> %s\n<%s> %s\n" "$lid" "$root" "$rid" "$h"
      git diff --name-only $OLD_COMMIT..$NEW_COMMIT    # show filenames
      printf "\n"
      git log HEAD...FETCH_HEAD
      printf "\n"
      local cnt=$( git diff --name-only $OLD_COMMIT...$NEW_COMMIT | wc -l )
      printf "%d files from %s\n" "$cnt" "$h"
      ssay "Got $cnt files from $h for $rdir!"
      # Checking OLD/NEW here shows if there is an actual transfer
      ((rc+=1))
    else
      [[ $silent < 1 ]] && ssay "$h matches local"
    fi
  done

  return $rc
}

function gfr() {                             # check subdirs
  setopt localoptions noautopushd nopushdignoredups
  for repo in */.git; do
    local rdir=$(dirname $repo )
    echo $rdir
    cd $rdir
    gf -s                                    # git fetch, silence no changes
    cd -
    yline
  done
}

function gm() {                              # git merge
  local root=$( git rev-parse --show-toplevel )
  local branch=$( git_current_branch )    # defined in OMZ/lib/git.zsh
  local cmd=$root/.git_upd_cmd
  local rc=0
  echo $root
  OLD_COMMIT=$( git rev-parse HEAD)     # $h/$branch )
  NEW_COMMIT=$( git rev-parse FETCH_HEAD )
  git diff --name-only $OLD_COMMIT..$NEW_COMMIT    # show filenames
  if ( git merge FETCH_HEAD ); then          # GIT -n HEAD
    ssay "merged from FETCH_HEAD"
  else
    ((rc+=$?))
    ssay "that as unexpected"                # to determine when this happens
  fi

  [[ $rc -eq 0 && -x $cmd ]] && ( printf "%s\n" "$root"; $cmd; return 0 )
  return $rc
}

function gmr() {
  setopt localoptions noautopushd nopushdignoredups
  for repo in */.git; do
    rdir=$(dirname $repo )
    echo $rdir
    cd $rdir
    gm                                       # git merge
    cd -
    yline
  done
}

# Copied from OMZ git plugin

alias gsw='git switch'
alias gswc='git switch -c'

function grename() {
  if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: $0 old_branch new_branch"
    return 1
  fi

  # Rename branch locally
  git branch -m "$1" "$2"
  # Rename branch in origin remote
  if git push origin :"$1"; then
    git push --set-upstream origin "$2"
  fi
}

