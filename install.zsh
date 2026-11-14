#!/bin/zsh

setopt errexit pipefail

# prompts

while true; do
  read -r '_git_remote?dotfiles git remote (https/ssh): '
  _git_remote=${(L)_git_remote}
  case "$_git_remote" in
    https|ssh) break ;;
  esac
  echo "${0:t}: enter https or ssh." >&2
done

_ask_yn() {
  while true; do
    read -r "$1?$2 (y/n): "
    case "${(L)${(P)1}}" in
      y|yes) typeset -g "$1=y"; return ;;
      n|no) typeset -g "$1=n"; return ;;
    esac
    echo "${ZSH_ARGZERO:t}: enter y or n." >&2
  done
}

_ask_yn _git_identity 'set git identity'
_git_sign=n
if [[ "$_git_identity" == y ]]; then
  git config --global --get user.name >/dev/null 2>&1 || read -r '_git_name?git user.name: '
  git config --global --get user.email >/dev/null 2>&1 || read -r '_git_email?git user.email: '
  _ask_yn _git_sign 'sign git commits'
fi
_ask_yn _mise 'install mise'

# packages

if [[ "$OSTYPE" == darwin* ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  brew install git sheldon fzf zoxide
  [[ "$_git_sign" == y ]] && brew install gpg
  [[ "$_mise" == y ]] && brew install mise

  _login_shell=$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')
elif command -v apt >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y git fzf zoxide
  [[ "$_git_sign" == y ]] && sudo apt install -y gpg

  export PATH="$HOME/.local/bin:$PATH"
  if ! command -v sheldon >/dev/null 2>&1; then
    curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
      | bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin
  fi
  if [[ "$_mise" == y ]] && ! command -v mise >/dev/null 2>&1; then
    curl -fsSL https://mise.run | sh
  fi

  _login_shell=$(getent passwd "$USER" | cut -d: -f7)
else
  echo "${0:t}: Installer not supported on this system." >&2
  exit 1
fi

# login shell

if [[ "${_login_shell:t}" != zsh ]]; then
  chsh -s "$(command -v zsh)"
fi

# remote

if [[ "$_git_remote" == ssh ]]; then
  if [[ ! -f ~/.ssh/id_ed25519 ]] && [[ ! -f ~/.ssh/id_rsa ]]; then
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "$USER@$(hostname)"
    echo
    echo "Add SSH key to https://github.com/settings/keys"
    echo
    cat ~/.ssh/id_ed25519.pub
    echo
  fi

  if [[ "$OSTYPE" == darwin* && ! -f ~/.ssh/config ]]; then
    printf 'Host *\n\tUseKeychain no\n' > ~/.ssh/config
  fi

  git -C ~/dotfiles remote set-url origin \
    "$(git -C ~/dotfiles remote get-url origin | sed 's|https://github.com/|git@github.com:|')"
else
  git -C ~/dotfiles remote set-url origin \
    "$(git -C ~/dotfiles remote get-url origin | sed 's|git@github.com:|https://github.com/|')"
fi

# git

[[ -n "$_git_name" ]] && git config --global user.name "$_git_name"
[[ -n "$_git_email" ]] && git config --global user.email "$_git_email"

git config --global advice.detachedHead false
git config --global alias.conflicts '!git ls-files -u | cut -f 2 | sort -u'
git config --global fetch.prune true
git config --global init.defaultBranch main
git config --global pull.ff only

# gpg

if [[ "$_git_sign" == y ]]; then
  git config --global commit.gpgSign true
  git config --global tag.forceSignAnnotated true

  _gpg_new_key=0
  _gpg_key_list=$(gpg --list-secret-keys --with-colons 2>/dev/null)
  if ! grep -q '^sec:' <<< "$_gpg_key_list"; then
    gpg --full-generate-key
    _gpg_key_list=$(gpg --list-secret-keys --with-colons 2>/dev/null)
    _gpg_new_key=1
  fi

  _gpg_key=
  if [[ "$(grep -c '^sec:' <<< "$_gpg_key_list" || true)" -eq 1 ]]; then
    _gpg_key=$(awk -F: '/^sec:/ {print $5; exit}' <<< "$_gpg_key_list")
  fi

  if ! git config --global --get user.signingkey >/dev/null 2>&1; then
    [[ -n "$_gpg_key" ]] && git config --global user.signingkey "$_gpg_key"
  fi

  if [[ "$_gpg_new_key" -eq 1 ]]; then
    echo
    echo "Add GPG key to https://github.com/settings/keys"
    echo
    gpg --armor --export "$_gpg_key"
    echo
  fi
else
  git config --global --unset commit.gpgSign 2>/dev/null || true
  git config --global --unset tag.forceSignAnnotated 2>/dev/null || true
fi

# symlinks

_links=(
  .zshrc ~/.zshrc
  .config/git/ignore ~/.config/git/ignore
  .config/sheldon/plugins.toml ~/.config/sheldon/plugins.toml
)
[[ "$_mise" == y ]] && _links+=(.config/mise/global.toml ~/.config/mise/config.toml)

for _src _dst in $_links; do
  if [[ -e "$_dst" && ! -L "$_dst" ]]; then
    echo "${0:t}: $_dst exists and is not a symlink." >&2
    exit 1
  fi
  mkdir -p "${_dst:h}" && ln -sf ~/dotfiles/"$_src" "$_dst"
done

# misc

[[ "$_mise" == y ]] && mise install
mkdir -p ~/bin
touch ~/.hushlogin
