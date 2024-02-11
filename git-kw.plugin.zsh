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
alias -- glogg="is_git && git glog -G"       # grep log entries for string
alias -- glogp="is_git && git glogp"         # show patches
alias -- glogw="is_git && git glog --since '1 week'"  # show past week commits

# works great when there are commits to be pushed
# else it shows the entire log
# alias --  gpl="is_git && git glog HEAD...ORIG_HEAD"   # to-be-pushed log
alias --   glm="is_git && git log HEAD..FETCH_HEAD"    # fetched log
alias --   grv="is_git && git remote -v"  # show remotes with url
alias --   gdu="is_git && git diff --stat --cached ORIG_HEAD"     # needs to be in a function
alias --   gi="is_git && git fetch --dry-run -v"
# These aliases match those in OMZ/plugins/git - START
alias --   ga="is_git && git add"
alias --  gau="is_git && git add --update"

# 2023-05-25: remove --all from log output
# without --all, log output starts with current HEAD

# NOTE: --follow ONLY works for a single file, will generate an error on an entire repo
alias --   glg="is_git && git log --graph --abbrev-commit --decorate \
                                  --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(bold yellow)%d%C(reset)'"

# Show only tags or branches
alias --  glgb="is_git && git log --graph --simplify-by-decoration \
                                  --pretty='format:%C(green)%as %C(auto)%d - %s'"

alias -- glgba="is_git && git log --graph --simplify-by-decoration \
                                  --pretty='format:%C(cyan)%h %C(green)%as %C(yellow)%al%C(auto)%d - %s'"

alias --  glgf="is_git && git log --graph --abbrev-commit --decorate \
                                  --name-status \
                                  --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(bold yellow)%d%C(reset)%n'"

function gltag() {
  git log --decorate --oneline --pretty=format:"%h %d %s" $@ | \
    awk '{ if ($2 ~ /\(tag:.*/) {gsub(/[()]/, "", $2); printf "(%-7s  ", $3 } else { printf ("%-10s","") } print }' | \
  sed 's/ tag:.*)/ /' | expand -t8 | $PAGER
}
# to use to get commit date for applying to tags
alias --   glgdt="git log --all --abbrev-commit --decorate \
                                  --format=format:'%h|%ai|%s|%d'"

function commit_date() {
  [[ $1 == "" ]] && printf "Need Hash number\n" && return
  glgdt | grep "$1" | awk -F'|' '{printf "%s\n", $2; }'
}

function git_tag() {
  [[ $1 == "" ]] && printf "Need Hash    number\n"  && return
  [[ $2 == "" ]] && printf "Need Version number\n"  && return
  [[ $3 == "" ]] && printf "Need Commit  message\n" && return

  glog $1 -1
  rsp=$(prompt -e "is this correct ?:" "yY" "nNq")
  [[ *$rsp* == "Yy" ]] && \
    GIT_COMMITTER_DATE="$( commit_date $1 )" git tag -a $2 $1 -m \""$3"\"
}

alias --   gb="is_git && git branch"
alias --  gba="is_git && git branch --all"

# alias --   gd="is_git && git diff --ignore-space-change"
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
      rsp=$(prompt -e "delete ?: $file" "yY" "nN" "aq")
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
    printf "\n%s\n" "$d"
    cd $d
    git status -s
    cd - > /dev/null
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
# compdefs not getting auto loaded (will if file is sourced), see .zshrc-complete
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
<<<<<<< HEAD
  [[ $# == 1 ]] && {
    [[ ${gr[(ie)$1]} -le ${#gr} ]] && gr=($1) || {
      printf "Invalid: %s\n" $1
      return
    }
=======
  [[ $# == 1 ]] && [[ ${gr[(ie)$1]} -le ${#gr} ]] && gr=($1) || {
    printf "Invald: %s\n" $1
    return
>>>>>>> de713f6a892cd805451eb3a6778c798eaaa992e2
  }
  for h in $gr; do
    cline 4
    local sch=$( git remote get-url $h | awk -F'[/:]' '{ print $1 }' )
    local hst=$( git remote get-url $h | awk -F'[/:]' '{ print $4 }' )
    printf "Remote: %s using %s on %s\n" "$h" "$sch" "$hst"
    local rid=$( git rev-parse $h/$branch )

    [[ $sch > "" ]] && ssh_ping -t 2 $hst # >2 /dev/null
    if [[ $sch > "" && $? != 0 ]]; then
      printf "Unable to ping %s\n" $hst
    else

      if [[ $lid != $rid ]]; then
        local cnt=$( git diff --name-only $h/$branch...HEAD | wc -l )
        if [[ $cnt > 0 ]]; then
          printf "Updating %d files on %s\n" "$cnt" "$h"
          ssay "Updating $cnt files on $h!"
          # Checking OLD/NEW here shows if there is an actual transfer
  #       OLD_COMMIT=$( git rev-parse $h/$branch )
          git push $mytags $h HEAD
          th=$h
  #       NEW_COMMIT=$( git rev-parse $h/$branch )
          [[ $? == 0 ]] && ((rc+=1))
        else
          ssay "$h is current"
        fi
      else
        ssay "$h matches local"
      fi

    fi     # HST is pingable

  done

  [[ $rc == 1 ]] && ssay "Pushed files to $th"
  [[ $rc  > 1 ]] && ssay "Pushed files to $rc of $#gr hosts"
  return 0    # $rc   # 2022-12-02 stop zsh from announcing error code
}
compdef _gf gp

function gpt() {
  mytags="--follow-tags"
  gp $@
  unset mytags
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

  # show commits to be pushed without connecting to each repo
  cline 2
  # 2024-02-09 : origin/HEAD is correct!!
  # If the following gives an error, you need to:
  # git remote set-head origin -a
  git glog HEAD...origin/HEAD    # ORIG_HEAD    # to-be-pushed log
  cline 2

  # connect to each repo and show repo specific log
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
    local sch=$( git remote get-url $h | awk -F'[/:]' '{ print $1 }' )
    local hst=$( git remote get-url $h | awk -F'[/:]' '{ print $4 }' )
    printf "Remote: %s using %s on %s\n" "$h" "$sch" "$hst"

    [[ $sch > "" ]] && ssh_ping -t 2 $hst # >2 /dev/null
    if [[ $sch > "" && $? != 0 ]]; then
      printf "Unable to ping %s\n" $hst
    else

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

    fi     # HST is pingable
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
    local sch=$( git remote get-url $h | awk -F'[/:]' '{ print $1 }' )
    local hst=$( git remote get-url $h | awk -F'[/:]' '{ print $4 }' )
    printf "Remote: %s using %s on %s\n" "$h" "$sch" "$hst"

    [[ $sch > "" ]] && ssh_ping -t 2 $hst # >2 /dev/null
    if [[ $sch > "" && $? != 0 ]]; then
      printf "Unable to ping %s\n" $hst
    else

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

    fi     # HST is pingable
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
    local sch=$( git remote get-url $h | awk -F'[/:]' '{ print $1 }' )
    local hst=$( git remote get-url $h | awk -F'[/:]' '{ print $4 }' )
    printf "Remote: %s using %s on %s\n" "$h" "$sch" "$hst"
    pth=$( git remote get-url $h )
    if [[ $pth == ssh* || -e $pth ]]; then

      [[ $sch > "" ]] && ssh_ping -t 2 $hst # >2 /dev/null
      if [[ $sch > "" && $? != 0 ]]; then
        printf "Unable to ping %s\n" $hst
      else

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
      fi     # HST is pingable
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
        printf "Repos: %s\n" "$gr"
        return;;
      *) [[ ${gr[(ie)$arg]} -le ${#gr} ]] && repo=$arg || {
        printf "Unexpected: %s\n" "$arg"
        return
      } ;;
    esac
  done

  cline 4
  local sch=$( git remote get-url $repo | awk -F'[/:]' '{ print $1 }' )
  local hst=$( git remote get-url $repo | awk -F'[/:]' '{ print $4 }' )
  printf "Remote: %s using %s on %s\n" "$repo" "$sch" "$hst"
  pth=$( git remote get-url $repo )
  if [[ $pth == ssh* || -e $pth ]]; then

    [[ $sch > "" ]] && ssh_ping -t 2 $hst # >2 /dev/null
    if [[ $sch > "" && $? != 0 ]]; then
      printf "Unable to ping %s\n" $hst
    else

      local rid=($( git ls-remote $repo $branch ))   # HEAD ))
      rid=$rid[1]
      if [[ $lid != $rid ]]; then
        OLD_COMMIT=$( git rev-parse $repo/$branch )
        git fetch $mytags $repo $branch  # HEAD
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
    fi     # HST is pingable
  else
    printf "%s not available\n" $repo
  fi


  [[ $rc == 1 ]] && ssay "Fetched files from $repo"
  [[ $rc  > 1 ]] && ssay "Fetched files from $rc hosts"
  return 0    # $rc   # 2022-12-02 stop zsh from announcing error code

}

function gft() {
  mytags="--tags"
  gf $@
  unset mytags
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
compdef _git gdr=git-diff

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

  [[ $# -lt 1 || $@[(I)-h] -gt 0 ]] \
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
    local hst=$( git remote get-url $h | awk -F'[/:]' '{ print $4 }' )
    local hst=$( git remote get-url $h | awk -F'[/:]' '{ print $4 }' )
    printf "Remote: %s using %s on %s\n" "$h/$branch" "$sch" "$hst"

    [[ $sch > "" ]] && ssh_ping -t 2 $hst # >2 /dev/null
    if [[ $sch > "" && $? != 0 ]]; then
      printf "Unable to ping %s\n" $hst
    else

      local rid=$( git diff --color --stat --cached $h/$branch )
      if [[ $rid ]]; then
        ((rc+=1))
        echo $rid
      else
        [[ $silent < 1 ]] && ssay "$h is current"
      fi

    fi     # HST is pingable
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
alias gsb='git switch'             #             switch to branch
alias gsbc='git switch -c'         #  create and switch to branch

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
  [[ $# == 0 || $@[(I)-h] -gt 0 ]] \
    && printf "$0 STRING FILE(s)\n" \
    && printf "\tShow log for commit with STRING\n" \
    && return

  local PAT=$1; shift;
  local FLW=""
  [[ $# -eq 1 ]] && FLW="--follow"

  git log $FLW --name-status -S"$PAT" $@
}
function ggreprgx() {
  [[ $# == 0 || $@[(I)-h] -gt 0 ]] \
    && printf "$0 REGEX FILE(s)\n" \
    && printf "\tShow log for commit with REGEX\n" \
    && return

  local PAT=$1; shift;
  local FLW=""
  [[ $# -eq 1 ]] && FLW="--follow"

  git log $FLW --name-status -G"$PAT" $@
}
function ggrepd() {
  [[ $# == 0 || $@[(I)-h] -gt 0 ]] \
    && printf "$0 REGEX FILE(s)\n" \
    && printf "\tShow diffs for commit with REGEX\n" \
    && return

  local PAT=$1; shift;
  local FLW=""
  [[ $# -eq 1 ]] && FLW="--follow"

  git log $FLW --patch -G"$PAT" $@
}
compdef _git ggrep=git-log
compdef _git ggreprgx=git-log
compdef _git ggrepd=git-log

# demo/test -h being in any position on cmdline
functio help_test() {
  printf "Cnt: %d\n" $#
  printf "Match: %s\n" $@[(I)-h]
}
function gcat() {
  [[ $# < 2 || $@[(I)-h] -gt 0 ]] \
    && printf "$0 COMMITID FILE\n" \
    && printf "\tShow file as of COMMITID\n" \
    && return

  git show $1:$2

}
compdef _git gcat=git-show

function gd() {     # Show git diff with line breaks between files

  is_git || return

  for file in $( git ls-files --modified $@ )
  do
    git diff --ignore-space-change $file
    lbline 2
  done

}
compdef _git gd=git-commit
function gdwd() {     # Show git diff using dwdiff

  is_git || return

  for file in $( git ls-files --modified $@ )
  do
#   ( printf ">>>\e[1m\e[38;5;6m %s \e[0m<<<\n\n" $file; git difftool -y --tool=dwdiff $file ) # | $PAGER
    ( printf ">>>\e[1m\e[38;5;6m %s \e[0m<<<\n\n" $file; git diff $file | dwdiff -u) # | $PAGER
    lbline 2
  done # | mdless     # mdless parses comments, ie '#',  as header lines

}
compdef _git gdwd=git-diff
function gla() {     # Show last git log for each file

  is_git || return

  for file in $( git ls-files $@ )
  do
    glog -1 $file
    lbline 2
  done | mdless                    # mdless allows inline images

}
compdef _git gla=git-log
