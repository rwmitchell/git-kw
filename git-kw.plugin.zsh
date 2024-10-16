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
alias --   glm="is_git  && git log HEAD..FETCH_HEAD"    # fetched log
alias --   grv="is_bare && git remote -v"  # show remotes with url
alias --   gdu="is_git  && git diff --stat --cached ORIG_HEAD"     # needs to be in a function
alias --   gi="is_git && git fetch --dry-run -v"
# These aliases match those in OMZ/plugins/git - START
alias --   ga="is_git && git add"
alias --  gau="is_git && git add --update"
# from OMZ git.plugin.zsh
alias --  gtl='gtl(){ git tag --sort=-v:refname -n --list "${1}*" }; noglob gtl'

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
  --format=format:'%C(auto)%h|%C(bold blue)%ai%C(reset)|%s|%C(auto)%d'"

function gl2tag() {      # show short log back to last tag
  # if defined as an alias, $(git describe) gets defined when sourcing this file
  glgdt $(git describe --tags --abbrev=0)..HEAD
}


function commit_date() {
  [[ $1 == "" ]] && printf "Need Hash number\n" && return
  glgdt | grep "$1" | awk -F'|' '{printf "%s\n", $2; }'
}

function git_tag() {
  [[ $1 == "" ]] && printf "Need Hash    number\n"  && return
  [[ $2 == "" ]] && printf "Need Version number\n"  && return
  [[ $3 == "" ]] && printf "Need Commit  message\n" && return

  glog $1 -1
  rsp=$(prompt -e "is this correct ?" "yY" "nNq")
  [[ "Yy" == *$rsp* ]] && \
    GIT_COMMITTER_DATE="$( commit_date $1 )" git tag -a $2 $1 -m "$3"  # add -f to force message change
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
      rsp=$(prompt -e "Delete ? $file" "yY" "nN" "aq")
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

  local root=$(basename $( git rev-parse --show-toplevel ) )
  local branch=$( git_current_branch )    # defined in OMZ/lib/git.zsh
  local rc=0
  printf "Root: %s\n" $root
  local gr=($( git remote show ));
  local lid=$( git rev-parse HEAD );

  local th arg tgr=()
  for arg in $@; do
    # verify user supplied repos exist in list
    [[ ${gr[(ie)$arg]} -le ${#gr} ]] && tgr+=($arg) || {
      printf "Invalid: %s\n" $arg
      return
    }
  done
  [[ $# -gt 0 ]] && gr=($tgr)

  for h in $gr; do
    cline 4
    local url=$( git remote get-url $h )
    local sch=$( echo $url | awk -F'[/:]' '{ print $1 }' )
    local hst=$( echo $url | awk -F'[/:]' '{ print $4 }' )
    [[ -n $sch ]] && printf "%s Remote: %s using %s on %s\n" "$0" "$h" "$sch" "$hst" \
                  || printf "%s Local : %s using %s\n"       "$0" "$h" "$url"
    local rid=$( git rev-parse $h/$branch )

    local err=0
    local lcl=true              # assume repo is local
    if [[ -n $sch ]]; then
      lcl=false;
      ssh_ping -t 2 $hst
      err=$?          # 2> /dev/null
      [[ $err -ne 0 ]] && printf "Unable to ping %s\n" $hst
    else
      [[ ! -e $url ]] && { printf "Not mounted: %s\n" $url; err=1 }
    fi

    if [[ $err -eq 0 ]]; then

      if [[ $lid != $rid ]]; then
        local cnt=$( git diff --name-only $h/$branch...HEAD | wc -l )
        if [[ $cnt > 0 ]]; then
          printf "Updating %d files on %s\n" "$cnt" "$h"
          ssay "Updating $cnt files on $h!" | hl "^.*$"
          # Checking OLD/NEW here shows if there is an actual transfer
#         OLD_COMMIT=$( git rev-parse $h/$branch )
          git push $mytags $h HEAD # |& hl -n -G "^Enum.*$|^Count.*$|^Delta.*$|^Comp.*$|^Writ.*$" -z -c "^To.*$"
          th=$h
#         NEW_COMMIT=$( git rev-parse $h/$branch )
          [[ $? == 0 ]] && ((rc+=1))

          [[ $? == 0 && $lcl == true ]] && {             # IF   we had something to push
            # remove everything after /git/ subdir       # AND  repo is local
            # append log filename                        # THEN create a log and msg file
            local log="${url%%/git/*}/Log-$host".txt
            printf "Local URL: %s\n" $url
            printf "Local LOG: %s\n" $log
            # put (local program) reads all stdin before opening output
            grep -v $root $log | put $log    # remove previous entries
            printf "%s %s\n" "$(date +'%Y-%m-%d %H:%M')" $root >> $log
            _gp_update
            lbline 2
            prism -Lw8 < $log
          }
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
function _gp_update () {

# local url="."                                # Test file
  local url=$( git remote get-url GitRepo )
  local msg="${url%%/git/*}/Msg-$host".txt
  local hsh="$(git rev-parse HEAD)"
  printf "MSG: %s\n" $msg
# printf "HSH: >%s<\n" $hsh

# Testing lines #
# printf "=======\n"
# [[ -e $msg  ]] && tr '\n' 'X' < $msg | hl X
# printf "=======\n"

  # remove old entry - this is to keep multiple runs from stacking
  [[ -e $msg  ]] && tr '\n' '\a' < $msg | sed "s|<${hsh}>.*</${hsh}>||g" | tr '\a' '\n' | put $msg

  # add    new entry
  printf "<%s>\n\n"     $hsh   >> $msg
  printf "REPO: %s\n"   $url   >> $msg
  printf "PWD : %s\n\n" $(pwd) >> $msg
  git log -1                   >> $msg
  printf "\n</%s>\n"    $hsh   >> $msg

}

function gp_del_hash() {     # remove hash record from file
  local file=$1
  [[ ! -e $file ]] && printf "%s does not exist, exiting\n" $file && return -1
  shift     # pop file off list

  foreach hsh in $@; do
    printf "HASH: %s\n" $hsh
#   tr '\n' '\a' < $file | sed -n "s|<${hsh}>.*</${hsh}>|FOO|p" | tr '\a' '\n'
    tr '\n' '\a' < $file | sed -n "s|<${hsh}>.*</${hsh}>||p" | tr '\a' '\n' | put $file
  done

}
function gp_show_msg() {                # show repo logs from Msg-*.txt
  local all help
  zparseopts -D -E -K a=all h=help

  local url=$( git remote get-url GitRepo )
  local vol="${url%%/git/*}"
  local lmsg="$vol/Msg-$host".txt

# printf "VOL: %s\n" "$vol"
# printf "URL: %s\n" "$url"
# printf "MSG: %s\n" "$lmsg"

# printf "\n"

  foreach msg in $vol/Msg-*.txt; do
# printf "MSG: %s\n" "$msg"
#   [[ $msg != $lmsg ]] && printf "REM: %s\n" "$msg" || printf "LOC: %s\n" "$msg"

    [[ $all || $msg != $lmsg ]] && {         # only show remote Msg files
      # split records into lines then search for matching url
      # sed needs 2 patterns to match when only one entry exists
      # | sed -n 's|><|>\n<|gp;s|<|\n<\n|p' \
      # | sed -n 's|><|>\n<|gp;s|\(<.*$\)|\n\1\n|p;' \
      # | sed -n 's|\(<.*$\)|\n\1\n|p;s|><|>\n<|gp;' \

      local cnt=$(grep '</' $msg | wc -l)
      [[ $cnt == 1 ]] && {

#         No need to rewrite the record boundaries, there be only one
#         | sed -n 's|<|\n<|p' \
        tr '\n' '\a' < $msg \
          | command grep $url \
          | tr '\a' '\n' | command grep -v -e "REPO:|PWD :|Author" | hl "REPO:.*$|PWD.*$" -n -G "commit.*$|Auth.*$|^<.*>$" -z -c "Date.*$" -y "^.*$"
      } || {
        tr '\n' '\a' < $msg \
          | sed -n 's|><|>\n<|gp' \
          | command grep $url \
          | tr '\a' '\n' | command grep -v -e "REPO:|PWD :|Author" | hl "REPO:.*$|PWD.*$" -n -G "commit.*$|Auth.*$|^<.*>$" -z -c "Date.*$" -y "^.*$"

      }
    }
  done
  return 0

}

function gp_del_msg() {                # show repo logs from Msg-*.txt
  local url=$( git remote get-url GitRepo )
  local vol="${url%%/git/*}"
  local lmsg="$vol/Msg-$host".txt

# printf "VOL: %s\n" "$vol"
# printf "URL: %s\n" "$url"
# printf "MSG: %s\n" "$lmsg"

# printf "\n"

  foreach msg in $vol/Msg-*.txt; do
# printf "MSG: %s\n" "$msg"
#   [[ $msg != $lmsg ]] && printf "REM: %s\n" "$msg" || printf "LOC: %s\n" "$msg"

    [[ $msg != $lmsg ]] && {         # only show remote Msg files

      # split records into lines then search for matching url
      # sed needs 2 patterns to match when only one entry exists
      # | sed -n 's|><|>\n<|gp;s|<|\n<\n|p' \
      # | sed -n 's|><|>\n<|gp;s|\(<.*$\)|\n\1\n|p;' \
      # | sed -n 's|\(<.*$\)|\n\1\n|p;s|><|>\n<|gp;' \
      # | sed -n 's|<|\n<|p' \

      local cnt=$(grep '</' $msg | wc -l)
      [[ $cnt == 1 ]] && {
        tr '\n' '\a' < $msg \
          | grep -v $url \
          | tr '\a' '\n' | put $msg
      } || {
        tr '\n' '\a' < $msg \
          | sed -n 's|><|>\n<|gp' \
          | grep -v $url \
          | tr '\a' '\n' | put $msg

      }
    }
  done
  return 0

}

function gflog() {
  local gr=($( git remote show ));
  local root=$(basename $( git rev-parse --show-toplevel ) )

  local url=$( git remote get-url GitRepo )
  local vol="${url%%/git/*}"
  local llog="$vol/Log-$host".txt

  for h in $gr; do
    [[ -e /Volumes/$h ]] && {

      local -a logs=($( echo /Volumes/$h/Log-*.txt ))
      local log
      for log in $logs; do
        printf "Log: %s\n" $log
        grep $root $log > /dev/null     # just to get status
        [[ $? == 0 ]] && {
          grep $root $log | prism -Lw8
          [[ $llog != $log ]] && {

            rsp=$(prompt -e "Remove entry for $root" "yY" "nN" "qa")
            case "$rsp" in
              n)                  ;;    # skip
              N|a|q) break        ;;    # skip and exit
              y|Y)   printf "Removing %s\n" $root;
                     grep -v $root $log | put $log    # remove previous entries
                     gp_del_msg                       # remove commit messages
            esac

          } || gp_show_msg -a
        }
        lbline 2
      done
    }
  done
# gplog -l
  return 0
}
function gplog() {

  local lcl help
  zparseopts -D -E -K l=lcl h=help

  local gr=($( git remote show ));
  for h in $gr; do
    [[ -e /Volumes/$h ]] && {

      local -a logs=($( echo /Volumes/$h/Log-*.txt ))
      local log
      for log in $logs; do
        printf "Log: %s\n" $log
        prism -Lw8 < $log
        lbline 2
      done
      [[ $lcl ]] && gp_show_msg || gp_show_msg -a
    }
  done
  [[ $#gr -gt 0 ]] && return 0 || return 1
}

function gpt() {
  mytags=("--tags" "--follow-tags")
  gp $@
  unset mytags
}
compdef _gf gpt

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
    local url=$( git remote get-url $h )
    local sch=$( echo $url | awk -F'[/:]' '{ print $1 }' )
    local hst=$( echo $url | awk -F'[/:]' '{ print $4 }' )
    [[ -n $sch ]] && printf "%s Remote: %s using %s on %s\n" "$0" "$h" "$sch" "$hst" \
                  || printf "%s Local : %s using %s\n"       "$0" "$h" "$url"
    local cnt=$( git rev-list --count $branch...$h/$branch )

    [[ $cnt -gt 0 ]] && printf "Cnt: %2d (%s...%s/%s)\n" "$cnt" "$branch" "$h" "$branch"

    local err=0
    # Do not need to verify host repo is reachable
#   if [[ -n $sch ]]; then
#     ssh_ping -t 2 $hst # 2> /dev/null
#     err=$?
#     [[ $err -ne 0 ]] && printf "Unable to ping %s\n" $hst
#   else
#     [[ ! -e $url ]] && { printf "Not mounted: %s\n" $url; err=1 }
#   fi

    if [[ $err -eq 0 ]]; then

#     local rid=($( git ls-remote $h HEAD ))
#     rid=$rid[1]
#     if [[ $lid != $rid ]]; then
#       printf "<%s> %s\n<%s> %s\n" "$lid" "$root" "$rid" "$h"
#       printf "\n"
#       git diff --name-only HEAD..$h/$branch
#       printf "\n"
        ts=$( git log --decorate=short --color HEAD...$h/$branch )
        if [[ $md5 != $( echo $ts | md5 ) ]]; then
          md5=$( echo $ts | md5 )
          echo $md5
          echo $ts
        fi
  #     git log HEAD...FETCH_HEAD
        printf "\n"
        [[ $silent < 2 ]] && ssay "$root not in sync with $h"
        ((rc+=1))
  #   else
  #     [[ $silent < 1 ]] && ssay "$h matches $root"
#     fi

    fi     # HST is pingable
  done

  return $rc
}
function gpb() {                          # push bare repo
  local rs;
  rs=$( git rev-parse --is-bare-repository )
  [[ $rs == "true" ]] || return 0

  local branch=$( git_current_branch )    # defined in OMZ/lib/git.zsh
  local rc=0
  local gr=($( git remote show ));
  local lid=$( git rev-parse HEAD );

  local th
  [[ $# == 1 ]] && {
    [[ ${gr[(ie)$1]} -le ${#gr} ]] && gr=($1) || {
      printf "Invalid: %s\n" $1
      return
    }
  }
  for h in $gr; do
    cline 4
    local url=$( git remote get-url $h )
    local sch=$( echo $url | awk -F'[/:]' '{ print $1 }' )
    local hst=$( echo $url | awk -F'[/:]' '{ print $4 }' )
    [[ -n $sch ]] && printf "%s Remote: %s using %s on %s\n" "$0" "$h" "$sch" "$hst" \
                  || printf "%s Local : %s using %s\n"       "$0" "$h" "$url"
    local rid=$( git rev-parse $h/$branch )

    local err=0
    if [[ -n $sch ]]; then
      ssh_ping -t 2 $hst
      err=$?          # 2> /dev/null
      [[ $err -ne 0 ]] && printf "Unable to ping %s\n" $hst
    else
      [[ ! -e $url ]] && { printf "Not mounted: %s\n" $url; err=1 }
    fi

    if [[ $err -eq 0 ]]; then

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

    [[ $sch > "" ]] && ssh_ping -t 2 $hst # 2> /dev/null
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

      [[ $sch > "" ]] && ssh_ping -t 2 $hst # 2> /dev/null
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

    [[ $sch > "" ]] && ssh_ping -t 2 $hst # 2> /dev/null
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

function gdcs() {                # diff commits sequentially }
  local ahash=($( git log --abbrev-commit --oneline $@ | awk '{print $1}' ))
  local phash=$ahash[1];
  local hash rsp prmpt=1

  printf "%3d commits\n" ${#ahash[@]}

  for hash in ${ahash[@]:1}; do    # walk thru array starting on second element
#   [[ $prmpt ]] &&
    dt=$( git show -s --date=format:'%Y-%m-%d %H:%M' --format=%cd $phash )
    su=$( git log --pretty=format:"%s" $phash -n 1 )         # get commit subject
    fn=($( git show --name-only --pretty=format: $phash ))   # get commit filenames
#   fn=$( git show --name-only --pretty=format:"%s" $phash ) # get commit filenames+subj
    printf "File: %s\n" $fn[@]
    rsp=$(prompt -e "log $dt: $su ?" "yY" "nN" "qa")
    [[ "qa" == *$rsp* && $prmpt ]] && printf "ABORT!!!\n" && return 0
    [[ "Yy" == *$rsp* || ! $prmpt ]] && {
#     printf ">>>\e[1m\e[38;5;6m %s \e[0m<<<\n\n" "$phash -> $hash";
      lbline 1
      git glog $phash -n 1
      lbline 1
    }
    for file in ${fn[@]}; do
      rsp=$(prompt -e "diff $file: $hash $phash?" "yY" "nN" "qa")
      [[ "qa" == *$rsp* && $prmpt ]] && printf "ABORT!!!\n" && return 0
      [[ "Yy" == *$rsp* || ! $prmpt ]] && {
        # reversing order colorizes red-delete green-add properly
        lbline 1
        git diff $hash $phash $file | dwdiff -u
      }
    done
    yline 2
    phash=$hash
  done
}

function gfb() {          # fetch into bare repo
  local rs;
  rs=$( git rev-parse --is-bare-repository )
  [[ $rs == "true" ]] || return 0

  local branch=$( git_current_branch )    # defined in OMZ/lib/git.zsh
  local rc=0
  local gr=($( git remote show ));
  local lid=$( git rev-parse HEAD );

  printf "repos: %s\n" "$gr"
  repo=$gr[1];

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
  local pth=$( git remote get-url $repo )
  local sch=$( echo $pth | awk -F'[/:]' '{ print $1 }' )
  local hst=$( echo $pth | awk -F'[/:]' '{ print $4 }' )
  printf "Remote: %s using %s on %s\n" "$repo" "$sch" "$hst"
  if [[ $pth == ssh* || -e $pth ]]; then

    [[ $sch > "" ]] && ssh_ping -t 2 $hst # 2> /dev/null
    if [[ $sch > "" && $? != 0 ]]; then
      printf "Unable to ping %s\n" $hst
    else

      local rid=($( git ls-remote $repo $branch ))   # HEAD ))
      rid=$rid[1]
      if [[ $lid != $rid ]]; then
        OLD_COMMIT=$( git rev-parse $repo/$branch )
        git fetch $mytags $repo $branch  # HEAD
        NEW_COMMIT=$( git rev-parse FETCH_HEAD )
        printf "<%s>\n<%s> %s\n" "$lid" "$rid" "$repo"
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

    [[ $sch > "" ]] && ssh_ping -t 2 $hst # 2> /dev/null
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
function ggrepdw() {
  [[ $# == 0 || $@[(I)-h] -gt 0 ]] \
    && printf "$0 REGEX FILE(s)\n" \
    && printf "\tShow diffs for commit with REGEX\n" \
    && return

  local PAT=$1; shift;
  local FLW=""
  [[ $# -eq 1 ]] && FLW="--follow"

  git log $FLW --patch -G"$PAT" $@ | dwdiff -u
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

  local prmpt rsp all cmmit quiet help
  zparseopts -D -E -K p=prmpt a=all c=cmmit q=quiet h=help

  [[ $help ]] && {
    printf "Usage: %s [ -cph ]\n" "$0"
    printf "\nUse dwdiff to compare changes to repo\n"
    printf "\t-a : commit all files together\n"
    printf "\t-c : prompt to commit     for each file\n"
    printf "\t-p : prompt to show diffs for each file\n"
    return 0
  }

  files=($( git ls-files --modified $@ ))

  printf "%3d Files\n" $#files
  printf "\t%s\n" $files

  [[ $#files -gt 1 ]] && prmpt=1   # arbitrary limit of 2^H1, else use -q

  [[ $quiet ]] && {                # Quickly show diffs for all files
    for file in $files; do
      ( printf ">>>\e[1m\e[38;5;6m %s \e[0m<<<\n\n" $file; git diff $file | dwdiff -u )
      lbline 2
    done
    return 0
  }

  [[ $#files == 0 ]] && return 0

  [[ $cmmit || $all ]] || {

    rsp=$(prompt -e "Commit files ?" "yY" "nN" "qa" )
    [[ "Yy" == *$rsp* ]] && cmmit=1
    [[ "qa" == *$rsp* ]] && return 0

    [[ $cmmit && $prmpt ]] && {
      rsp=$(prompt -e "Commit all files together ?" "yY" "nN" "qa" )
      [[ "Yy" == *$rsp* ]] && all=1
      [[ "qa" == *$rsp* ]] && return 0
      [[ $all ]] && {
        rsp=$(prompt -e "Commit files now ?" "yY" "nN" "qa" )
        [[ "Yy" == *$rsp* ]] && { printf "Committing $files\n"; gc $files 2>&1 > /dev/null &; unset cmmit }
        [[ "qa" == *$rsp* ]] && return 0
      }
    }

  }

  [[ $all ]] && {
    for file in $files; do
      rsp=$(prompt -e "show $file ?" "yY" "nN" "qa")
      [[ "qa" == *$rsp* ]] && return 0
      [[ "Yy" == *$rsp* ]] && \
        ( printf ">>>\e[1m\e[38;5;6m %s \e[0m<<<\n\n" $file; git diff $file | dwdiff -u)
    done
    rsp=$(prompt -e "Commit $files ?" "yY" "nN" "qa" )
    [[ "Yy" == *$rsp* ]] && { printf "Committing $files\n"; gc $files }

  }

  [[ ! $all ]] && {
    for file in $files; do
  #   ( printf ">>>\e[1m\e[38;5;6m %s \e[0m<<<\n\n" $file; git difftool -y --tool=dwdiff $file ) # | $PAGER
      [[ $prmpt ]] && rsp=$(prompt -e "show $file ?" "yY" "nN" "qa")
      [[ "qa" == *$rsp* && $prmpt ]] && return 0
      [[ "Yy" == *$rsp* || ! $prmpt ]] && \
      ( printf ">>>\e[1m\e[38;5;6m %s \e[0m<<<\n\n" $file; git diff $file | dwdiff -u) # | $PAGER
      lbline 2
      [[ $cmmit ]] && rsp=$(prompt -e "Commit $file ?" "yY" "nN" "qa" )
      [[ "qa" == *$rsp* && $cmmit ]] && return 0
      [[ "Yy" == *$rsp* && $cmmit ]] && { printf "Committing $file\n"; gc $file }
    done # | mdless     # mdless parses comments, ie '#',  as header lines

  }

  [[ "Yy" == *$rsp* ]] && return 0 || return 1

}
compdef _git gdwd=git-diff
function gla() {     # Show last git log for each file

  is_git || return

  for file in $( git ls-files $@ )
  do
    glog -1 $file
    lbline 2
  done | mdless -I                 # mdless allows lbline inline image

}
compdef _git gla=git-log
