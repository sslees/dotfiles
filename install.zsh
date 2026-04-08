#!/bin/zsh

setopt errexit pipefail

# packages

if [[ "$OSTYPE" == darwin* ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  brew install git gpg sheldon fzf zoxide mise

  _login_shell=$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')
elif command -v apt >/dev/null 2>&1; then
  sudo apt install -y git gpg sheldon fzf zoxide

  export PATH="$HOME/.local/bin:$PATH"
  if ! command -v mise >/dev/null 2>&1; then
    curl https://mise.run | sh
  fi

  _login_shell=$(getent passwd "$USER" | cut -d: -f7)
else
  echo "${0:t}: Installer not supported on this system." >&2
  exit 1
fi

# login shell

_zsh_bin=$(command -v zsh)
if [[ "$_login_shell" != "$_zsh_bin" ]]; then
  chsh -s "$_zsh_bin"
fi

# ssh

if [[ ! -f ~/.ssh/id_ed25519 ]]; then
  ssh-keygen -t ed25519 -C "$USER@$(hostname)"
fi

if [[ "$OSTYPE" == darwin* && ! -f ~/.ssh/config ]]; then
  printf 'Host *\n\tUseKeychain no\n' > ~/.ssh/config
fi

git -C ~/dotfiles remote set-url origin \
  "$(git -C ~/dotfiles remote get-url origin | sed 's|https://github.com/|git@github.com:|')"

# git

if ! git config --global --get user.name >/dev/null 2>&1; then
  read -r '_git_name?git user.name: '
  git config --global user.name "$_git_name"
fi
if ! git config --global --get user.email >/dev/null 2>&1; then
  read -r '_git_email?git user.email: '
  git config --global user.email "$_git_email"
fi

git config --global advice.detachedHead false
git config --global alias.conflicts '!git ls-files -u | cut -f 2 | sort -u'
git config --global commit.gpgSign true
git config --global fetch.prune true
git config --global init.defaultBranch main
git config --global pull.ff only
git config --global tag.forceSignAnnotated true

# gpg

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

# symlinks

ln -sf ~/dotfiles/.zshrc ~
mkdir -p ~/.config/git && ln -sf ~/dotfiles/.config/git/ignore ~/.config/git
mkdir -p ~/.config/sheldon && ln -sf ~/dotfiles/.config/sheldon/plugins.toml ~/.config/sheldon
mkdir -p ~/.config/mise && ln -sf ~/dotfiles/.config/mise/global.toml ~/.config/mise/config.toml

# misc

mise install
mkdir -p ~/bin
touch ~/.hushlogin
