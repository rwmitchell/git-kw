# Git aliases
#
# $MyId$
# $Source$
# $Date$
#
alias -- gllf="git diff-tree --name-only --no-commit-id -r -a HEAD"   # List last files committed
alias -- gs="git status"
alias -- gss="git status -s"
alias -- gau="git add -u"
alias -- gc="git commit"
alias -- gp="git push"
alias -- gu="git pull"        # u for update
alias -- gd="git diff"
alias -- gdw="git diff --word-diff"
alias -- glog="git log"
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
