# Git aliases
#
# $MyId$
# $Source$
# $Date$
#
alias --  gllf="is_git && git diff-tree --name-only --no-commit-id -r -a HEAD"   # List last files committed
alias --    gs="is_git && git status"
alias --   gdo="is_git && git difftool"      # uses opendiff
alias --  gdoy="is_git && git difftool -y"   # uses opendiff, no prompting
alias --  glog="is_git && git glog"
alias -- glogp="is_git && git glogp"         # show patches

# works great when there are commits to be pushed
# else it shows the entire log
# alias --  gpl="is_git && git glog HEAD...ORIG_HEAD"   # to-be-pushed log
alias --   glg="is_git && git lg"         # fancier but shorter log
alias --   glm="is_git && git log HEAD..FETCH_HEAD"    # fetched log
alias --   grv="is_git && git remote -v"  # show remotes with url
alias --   gdu="is_git && git diff --stat --cached ORIG_HEAD"     # needs to be in a function
alias --   gi="is_git && git fetch --dry-run -v"
# These aliases match those in OMZ/plugins/git - START
alias --   ga="is_git && git add"
alias --  gau="is_git && git add --update"

alias --  glgb="is_git && git log --all --graph --simplify-by-decoration --pretty='format:%C(green)%as %C(auto)%d - %s'"
alias -- glgba="is_git && git log --all --graph --simplify-by-decoration --pretty='format:%C(cyan)%h %C(green)%as %C(yellow)%al%C(auto)%d - %s'"

alias --   gb="is_git && git branch"
alias --  gba="is_git && git branch --all"

alias --   gd="is_git && git diff --ignore-space-change"
alias -- gdca="is_git && git diff --cached"
alias --  gds="is_git && git diff --staged"
alias --  gdw="is_git && git diff --word-diff"
alias --  gdf="is_git && git diff HEAD..FETCH_HEAD"                # diff after gf
alias -- gdup="is_git && git diff @{upstream}"

alias --  gss="is_git && git status --short --branch"
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

  local rsp="X"
  for file in $fl
  do

    if [[ $rsp != "Y" ]]; then
      rsp=$(prompt -p "delete ?: $file" "yYnNaq")
    fi

    case "$rsp" in
      n)                  ;;    # skip
      N|a|q) break        ;;    # skip and exit
      y|Y)   printf "Resetting %s\n" $file;
             rm $file;          # do this file
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
  git commit $@
  rc=$?
  [[ $rc -eq 0 ]] && guk
  echo $root
  [[ $rc -eq 0 && -x $cmd ]] && ( printf "%s\n" "$root"; $cmd; return 0 )
  return $rc
}
compdef _git gc=git-commit

function gp() {
  git status > /dev/null  # only get result code or show error
  [[ $? == 0 ]] || return 0

  local root=$( git rev-parse --show-toplevel )
  local branch=$( git_current_branch )    # defined in OMZ/lib/git.zsh
  local rc=0
  echo $root
  local gr=($( git remote show ));
  local lid=$( git rev-parse HEAD );
  local th
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
        th=$h
#       NEW_COMMIT=$( git rev-parse $h/$branch )
        [[ $? == 0 ]] && ((rc+=1))
      else
        ssay "$h is current"
      fi
    else
      ssay "$h matches local"
    fi
  done

  [[ $rc == 1 ]] && ssay "Pushed files to $th"
  [[ $rc  > 1 ]] && ssay "Pushed files to $rc of $#gr hosts"
  return 0    # $rc   # 2022-12-02 stop zsh from announcing error code
}

# Git Show Commit to be pushed
# 2023-04-12 same as gcr() with different log command
function gpl() {
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
  local md5
  local ts
  for h in $gr; do
    cline 4
    printf "Remote: %s\n" "$h"
    local rid=($( git ls-remote $h HEAD ))
    rid=$rid[1]
    if [[ $lid != $rid ]]; then
      printf "<%s> %s\n<%s> %s\n" "$lid" "$root" "$rid" "$h"
      printf "\n"
      git diff --name-only HEAD..$h/$branch
      printf "\n"
      ts=$( git log --decorate=short --color HEAD...$h/$branch )
      if [[ $md5 != $( echo $ts | md5 ) ]]; then
        md5=$( echo $ts | md5 )
        echo $ts
      fi
#     git log HEAD...FETCH_HEAD
      printf "\n"
      [[ $silent < 2 ]] && ssay "$root not in sync with $h"
      ((rc+=1))
#   else
#     [[ $silent < 1 ]] && ssay "$h matches $root"
    fi
  done

  return $rc
}

# Git Check Remote - are remotes and local in-sync ?
# 2023-04-12 does this do anything different for new fetch commits?
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
      git diff --name-only HEAD..$h/$branch
      printf "\n"
#     git log HEAD...$h/$branch
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

# Git Fetch and report # of files changed from all repos
function gfa() {
  git status > /dev/null  # only get result code or show error
  [[ $? == 0 ]] || return 0

  local root=$( git rev-parse --show-toplevel )
  local rdir=$(basename $root )
  local branch=$( git_current_branch )    # defined in OMZ/lib/git.zsh
  local rc=0
  printf "Root: %s\n" "$root"
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
    pth=$( git remote get-url $h )
    if [[ $pth == ssh* || -e $pth ]]; then
      local rid=($( git ls-remote $h $branch ))   # HEAD ))
      rid=$rid[1]
      if [[ $lid != $rid ]]; then
        OLD_COMMIT=$( git rev-parse $h/$branch )
        git fetch $h $branch  # HEAD
        NEW_COMMIT=$( git rev-parse FETCH_HEAD )
        printf "<%s> %s\n<%s> %s\n" "$lid" "$root" "$rid" "$h"
        git diff --name-only $OLD_COMMIT..$NEW_COMMIT    # show filenames
        printf "\n"
#       git log HEAD...FETCH_HEAD
        # determine which log approach is better
        printf "git log %s/%s...FETCH_HEAD\n" "$h" "$branch"
        git log $h/$branch...FETCH_HEAD
        printf "\ngit lg HEAD...FETCH_HEAD\n"
        git lg HEAD..FETCH_HEAD
        printf "\n"
        local cnt=$( git diff --name-only $OLD_COMMIT...$NEW_COMMIT | wc -l )
        printf "%d files from %s\n" "$cnt" "$h"
        ssay "Got $cnt files from $h for $rdir!"
        # Checking OLD/NEW here shows if there is an actual transfer
        ((rc+=1))
      else
        printf "%s matches %s\n" "$h" "$branch"
      [[ $silent < 1 ]] && ssay "$h matches local"
      fi
    else
      printf "%s not available\n" $h
    fi
  done

  [[ $rc == 1 ]] && ssay "Fetched files from $h"
  [[ $rc  > 1 ]] && ssay "Fetched files from $rc hosts"
  return 0    # $rc   # 2022-12-02 stop zsh from announcing error code

}

# Only fetch from origin
function gf() {
  git status > /dev/null  # only get result code or show error
  [[ $? == 0 ]] || return 0

  local root=$( git rev-parse --show-toplevel )
  local rdir=$(basename $root )
  local branch=$( git_current_branch )    # defined in OMZ/lib/git.zsh
  local rc=0
  printf "Root: %s\n" "$root"
  local gr=($( git remote show ));
  local lid=$( git rev-parse HEAD );

  local repo="origin"
  printf "%d repos\n" $#gr
  # ${gr[(ie)$repo]}  <-- this returns position of repo in gr, or size+1
  if [[ ${gr[(ie)$repo]} -gt ${#gr} ]]; then
    printf "origin repo not specified\n"
    return
  fi

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

  cline 4
  printf "Remote: %s\n" "$repo"
  pth=$( git remote get-url $repo )
  if [[ $pth == ssh* || -e $pth ]]; then
    local rid=($( git ls-remote $repo $branch ))   # HEAD ))
    rid=$rid[1]
    if [[ $lid != $rid ]]; then
      OLD_COMMIT=$( git rev-parse $repo/$branch )
      git fetch $repo $branch  # HEAD
      NEW_COMMIT=$( git rev-parse FETCH_HEAD )
      printf "<%s> %s\n<%s> %s\n" "$lid" "$root" "$rid" "$repo"
      git diff --name-only $OLD_COMMIT..$NEW_COMMIT    # show filenames
      printf "\n"
#     git log HEAD...FETCH_HEAD
      # determine which log approach is better
      printf "git log %s/%s...FETCH_HEAD\n" "$repo" "$branch"
      git log $repo/$branch...FETCH_HEAD
      printf "\ngit lg HEAD...FETCH_HEAD\n"
      git lg HEAD..FETCH_HEAD
      printf "\n"
      local cnt=$( git diff --name-only $OLD_COMMIT...$NEW_COMMIT | wc -l )
      printf "%d files from %s\n" "$cnt" "$repo"
      ssay "Got $cnt files from $repo for $rdir!"
      # Checking OLD/NEW here shows if there is an actual transfer
      ((rc+=1))
    else
      printf "%s matches %s\n" "$repo" "$branch"
    [[ $silent < 1 ]] && ssay "$repo matches local"
    fi
  else
    printf "%s not available\n" $repo
  fi

  [[ $rc == 1 ]] && ssay "Fetched files from $repo"
  [[ $rc  > 1 ]] && ssay "Fetched files from $rc hosts"
  return 0    # $rc   # 2022-12-02 stop zsh from announcing error code

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

function gdr() {                             # check subdirs
  setopt localoptions noautopushd nopushdignoredups
  for repo in */.git; do
    local rdir=$(dirname $repo )
    echo $rdir
    cd $rdir
    git diff --ignore-space-change
    cd -
    yline
  done
}

function gir() {                             # check incoming dry-run
  setopt localoptions noautopushd nopushdignoredups
  for repo in */.git; do
    local rdir=$(dirname $repo )
    echo $rdir
    cd $rdir
    git fetch --dry-run -v
    [[ $? != 0 ]] && ssay "Check $rdir"
    cd -
    yline
  done
}


function gm() {                              # git merge
  git status > /dev/null  # only get result code or show error
  [[ $? == 0 ]] || return 0

  local root=$( git rev-parse --show-toplevel )
  local branch=$( git_current_branch )       # defined in OMZ/lib/git.zsh
  local cmd=$root/.git_upd_cmd
# local gr=($( git remote show ));
  local rc=0
  echo $root
# OLD_COMMIT=$( git rev-parse HEAD)          # $h/$branch )
  OLD_COMMIT=$( git rev-parse $branch)
  NEW_COMMIT=$( git rev-parse FETCH_HEAD )
  git diff --name-only $OLD_COMMIT..$NEW_COMMIT    # show filenames
  # -ff is disabled for 'git merge' in .gitconfig
  # to avoid collapsing branches on merge.
  # re-enable for a regular merge
  if ( git merge --ff --log FETCH_HEAD ); then     # GIT -n HEAD
    ssay "merged from FETCH_HEAD"
  else
    ((rc+=$?))
    ssay "that was unexpected - $rc"               # to determine when this happens
  fi

  [[ $rc -eq 0 && -x $cmd ]] && ( printf "%s\n" "$root"; $cmd; return 0 )

# 2023-04-20: what? rc is an error code, not host count
# [[ $rc == 1 ]] && ssay "Merged files"
# [[ $rc  > 1 ]] && ssay "Merged files from $rc hosts"
  return 0    # $rc   # 2022-12-02 stop zsh from announcing error code
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

function gmb() {                              # git merge branch
  git status > /dev/null  # only get result code or show error
  [[ $? == 0 ]] || return 0

  [[ $# -lt 1 || $1 == "-h" ]] \
    && printf "$0 branch_name\n" \
    && printf "\tMerge named branch\n" \
    && git branch --list \
    && return

  local branch=$1

  if [[ $(git rev-parse --verify $branch 2> /dev/null ) ]]; then
    printf "Checking: %s\n" $branch
  else
     printf "$branch not available\n"
     return
  fi


  local root=$( git rev-parse --show-toplevel )
  local cmd=$root/.git_upd_cmd
  local rc=0
  printf "    Root: %s\n" $root
  OLD_COMMIT=$( git rev-parse HEAD )
  NEW_COMMIT=$( git rev-parse $branch )

  git diff --name-only $OLD_COMMIT..$NEW_COMMIT    # show filenames

  if ( git merge --no-ff --log $branch ); then     # GIT -n HEAD
    ssay "merged from $branch"
  else
    ((rc+=$?))
    printf "Error code: %d\n" $rc
    ssay "that was unexpected - $rc"               # to determine when this happens
  fi

  [[ $rc -eq 0 && -x $cmd ]] && ( printf "%s\n" "$root"; $cmd; return 0 )

  return 0
}

function gps() {         # git push status - show files to be pushed
  git status > /dev/null  # only get result code or show error
  [[ $? == 0 ]] || return 0

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


  local root=$( git rev-parse --show-toplevel )
  local branch=$( git_current_branch )    # defined in OMZ/lib/git.zsh
  local rc=0
  echo $root
  local gr=($( git remote show ));
  local lid=$( git rev-parse HEAD );
  for h in $gr; do
    cline 4
    printf "Remote: %s/%s\n" "$h/$branch"
    local rid=$( git diff --color --stat --cached $h/$branch )
    if [[ $rid ]]; then
      ((rc+=1))
      echo $rid
    else
      [[ $silent < 1 ]] && ssay "$h is current"
    fi
  done

  [[ $silent < 2 && $rc  > 0 ]] && ssay "Need to update $rc repos"
  return 0    # $rc   # 2022-12-02 stop zsh from announcing error code
}

function gpsr() {
  setopt localoptions noautopushd nopushdignoredups
  for g in */.git
  do
    d=$( dirname $g )
    printf "%s\n" "$d"
    cd $d
    gps -s
    cd -
  done
}

# OMZ git plugin uses gsw and gswc
# this matches using gmb() to merge branch
alias gsb='git switch'             //            switch to branch
alias gsbc='git switch -c'         // create and switch to branch

function grename() {
  git status > /dev/null  # only get result code or show error
  [[ $? == 0 ]] || return 0

  if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: $0 old_branch new_branch"
    return 1
  fi

  # Rename branch locally
  git branch -m "$1" "$2"
  # Rename branch in origin remote
  if ( git push origin :"$1" ); then
    git push --set-upstream origin "$2"
  fi
}

# https://queirozf.com/entries/git-examples-searching-the-git-history#list-commits-including-string-in-content
function ggrep() {
  [[ $# == 0 || $1 == "-h" ]] \
    && printf "$0 STRING FILE(s)\n" \
    && printf "\tShow log for commit with STRING\n" \
    && return

  local PAT=$1; shift;

  git log --name-status -S"$PAT" $@
}
function ggreprgx() {
  [[ $# == 0 || $1 == "-h" ]] \
    && printf "$0 REGEX FILE(s)\n" \
    && printf "\tShow log for commit with REGEX\n" \
    && return

  local PAT=$1; shift;

  git log --name-status -G"$PAT" $@
}

function gcat() {
  [[ $# < 2 || $1 == "-h" ]] \
    && printf "$0 COMMITID FILE\n" \
    && printf "\tShow file as of COMMITID\n" \
    && return

  git show $1:$2

}
compdef _git gcat=git-show
