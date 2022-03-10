# Git aliases
#
# $MyID$
# $Source$
# $Date$
#
alias -- gllf="git diff-tree --name-only --no-commit-id -r -a HEAD"   # List last files committed
alias -- gs="git status"

function guk() {
  fl=$( git diff-tree --name-only --no-commit-id -r -a HEAD )
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
