source ~/dotfiles/all.zsh
if [[ "$OSTYPE" == darwin* ]]; then
  source ~/dotfiles/mac.zsh
elif [[ -n "$WSL_DISTRO_NAME" ]]; then
  source ~/dotfiles/wsl.zsh
elif [[ "$OSTYPE" == linux-gnu* ]]; then
  source ~/dotfiles/linux.zsh
fi

autoload -Uz compinit && compinit

eval "$(sheldon source)"

command -v fzf >/dev/null && source <(fzf --zsh)
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
command -v mise >/dev/null && eval "$(mise activate zsh)"

if [[ -f ~/.local.sh ]]; then
  source ~/.local.sh
fi
