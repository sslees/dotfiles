# variables

export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

export EDITOR="nvim"
export VISUAL="cursor -w"

export GPG_TTY="$(tty)"

export PIP_REQUIRE_VIRTUALENV=true

# aliases

alias c='clear'

alias ga='git add'
alias gaa='git add --all'
alias gcm='git commit -m'
alias gco='git switch'
alias gcom='git switch main || git switch master'
alias gd='git diff'
alias gf='git fetch'
alias gfu='git commit --amend --no-edit'
alias gl='git pull'
alias glo='git log --oneline'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gr='git reset --mixed'
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbi='git rebase --interactive'
alias grh='git reset --hard'
alias grs='git reset --soft'
alias grv='git remote --verbose'
alias gs='git status'
alias gsa='git stash apply'
alias gsh='git stash push'
alias gsl='git stash list'
alias gsp='git stash pop'

alias m='make'
alias mc='make clean'
alias mt='make test'

alias pl='pip list'

alias q='exit'

# functions

function mkcd() { mkdir -p "$@" && cd "$_"; }
