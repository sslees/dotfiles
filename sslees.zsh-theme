typeset -A ZSH_HIGHLIGHT_STYLES

ZSH_HIGHLIGHT_STYLES[alias]="fg=14"
ZSH_HIGHLIGHT_STYLES[arg0]="fg=12"
ZSH_HIGHLIGHT_STYLES[autodirectory]="fg=12,underline"
ZSH_HIGHLIGHT_STYLES[function]="fg=14"
ZSH_HIGHLIGHT_STYLES[precommand]="fg=12,bold"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=8"

PROMPT='%F{6}%n%F{8}@%F{6}%m%F{8}:%F{4}%1~%f$(git_prompt_info)$(git_prompt_status)%f %(?.%F{8}.%F{1})%(!.#.$)%f '
RPROMPT=""

ZSH_THEME_GIT_PROMPT_PREFIX=" %F{5}"
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_SUFFIX="%f"

ZSH_THEME_GIT_PROMPT_UNTRACKED="%F{1}?"
ZSH_THEME_GIT_PROMPT_ADDED="%F{2}+"
ZSH_THEME_GIT_PROMPT_MODIFIED="%F{3}*"

_format_elapsed() {
  emulate -L zsh
  LC_NUMERIC=C
  local sec=$1 ms t h m s
  if (( sec < 0.9995 )); then
    ms=$(( sec * 1000.0 ))
    printf '%.3gms' "$ms"
  elif (( sec < 60.0 )); then
    printf '%.3gs' "$sec"
  else
    t=$(printf '%.0f' "$sec")
    h=$(( t / 3600 ))
    m=$(( (t % 3600) / 60 ))
    s=$(( t % 60 ))
    if (( h > 0 )); then
      printf '%d:%02d:%02d' h m s
    else
      printf '%d:%02d' m s
    fi
  fi
}

function preexec() {
  zsh_cmd_start=${zsh_cmd_start:-$(date +%s.%N)}
}

function precmd() {
  if [[ -n $zsh_cmd_start ]]; then
    local sec=$(( $(date +%s.%N) - zsh_cmd_start ))
    export RPROMPT="%F{8}$(_format_elapsed "$sec")%f"
    unset zsh_cmd_start
  else
    export RPROMPT=""
  fi
}
