# Git aliases
#
# $MyId$
# $Source$
# $Date$
#
alias -- gllf="git diff-tree --name-only --no-commit-id -r -a HEAD"   # List last files committed
alias -- gs="git status"
alias -- gss="git status -s"
alias -- ga="git add"
alias -- gau="git add -u"
alias -- gc="git commit"
alias -- gp="git push"
alias -- gu="git pull"        # u for update
alias -- gd="git diff"
alias -- gdw="git diff --word-diff"
alias -- glog="git log"
alias -- glg="git lg"         # fancier but shorter log
alias -- grv="git remote -v"  # show remotes with url

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
function gsra() {
  for g in */.git
  do
    d=$( dirname $g )
    printf "%s\n" "$d"
    cd $d
    git status -s
    cd ..
  done
}
function gpra() {
  for g in */.git
  do
    d=$( dirname $g )
    printf "%s\n" "$d"
    cd $d
    git pull
    cd ..
  done
}

function tgc() {
  local root=$( git rev-parse --show-toplevel )
  local cmd=$root/.git_cmt_cmd
  local rc=0
  git commit $@                              # GIT -n HEAD
  echo $root
  rc=$?
  [[ $rc -eq 0 && -x $cmd ]] && ( printf "%s\n" "$root"; $cmd; return 0 )
  return $rc
}

function tgp() {
  local root=$( git rev-parse --show-toplevel )
  local rc=0
  echo $root
  local gr=($( git remote show ));
  for h in $gr; do
    cline 4
    printf "Remote: %s\n" "$h"
    if ( git push $h HEAD ); then            # GIT -n HEAD
      ssay "$h updated!"
    else
      ((rc+=$?))
    fi
  done

  return $rc
}

function tgu() {
  local root=$( git rev-parse --show-toplevel )
  local cmd=$root/.git_upd_cmd
  local rc=0
  echo $root
  local gr=($( git remote show ));
  for h in $gr; do
    cline 4
    printf "Remote: %s\n" "$h"
    if ( git fetch $h ); then                # GIT -n HEAD
      ssay "update from $h"
    else
      ((rc+=$?))
    fi
  done

# [[ $rc -eq 0 && -x $cmd ]] && ( printf "%s\n" "$root"; $cmd; return 0 )
  return $rc
}

function tgm() {
  local root=$( git rev-parse --show-toplevel )
  local cmd=$root/.git_upd_cmd
  local rc=0
  echo $root
  if ( git merge FETCH_HEAD ); then          # GIT -n HEAD
    ssay "merged from FETCH_HEAD"
  else
    ((rc+=$?))
    ssay "that as unexpected"                # to determine when this happens
  fi

  [[ $rc -eq 0 && -x $cmd ]] && ( printf "%s\n" "$root"; $cmd; return 0 )
  return $rc
}

