# source ~/zsh-snap/znap.zsh

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export PATH="${HOME}/.local/bin:${PATH}"
export XDG_CONFIG_HOME="$HOME/.config"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git tmux yarn zoxide zsh-syntax-highlighting zsh-autosuggestions)
# zsh-fzf-history-search -> also available

ZSH_TMUX_AUTOSTART=false
# ZSH_TMUX_AUTOCONNECT=false
ZSH_TMUX_DEFAULT_SESSION_NAME="main"

source $ZSH/oh-my-zsh.sh
# source /usr/share/doc/fzf/examples/key-bindings.zsh
# source /usr/share/doc/fzf/examples/completion.zsh

# znap source zsh-users/zsh-autosuggestions
# znap source zsh-users/zsh-syntax-highlighting
# znap source marlonrichert/zsh-autocomplete

# User configuration
alias vs="code ."
alias lg="lazygit"
# TODO: Disable bat and fd alias if it's newer
alias bat="batcat"
alias fd="fdfind"
alias exp="explorer.exe ."
alias nv="nvim"
alias vim="nvim"
alias tkas="tmux kill-session -a"
alias yolo="find . -name 'node_modules' -type d -prune -print -exec sudo rm -rf '{}' \;"
alias nuke="find . -name 'dist' -type d -prune -print -exec sudo rm -rf '{}' \;"
alias t="tmux"
alias search="fzf --preview 'batcat --color=always --style=numbers --line-range=:500 {}' | xargs nvim"
alias p="pnpm"
# Run `cargo install exa` to install exa
alias ll="exa -lg --icons --git"
alias lla="exa -alg --icons --git"
alias llt="exa -1 --icons --tree --git-ignore"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Add Golang to $PATH
export PATH="$PATH:/usr/local/go/bin"
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

# Add Rust to $PATH
export PATH="$HOME/.cargo/bin:$PATH"

# Loads pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# place this after nvm initialization!
autoload -U add-zsh-hook

load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use > /dev/null 2>&1
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    nvm use default > /dev/null 2>&1
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Java Stuff
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export ANDROID_HOME="$HOME/android"
export GRADLE_HOME=/opt/gradle/gradle-7.6.1 # Might need to change this depending on your version
export ANDROID_SDK_ROOT=${ANDROID_HOME}

export PATH="$JAVA_HOME/bin:$PATH"
export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${PATH}"
export PATH="${GRADLE_HOME}/bin:${PATH}"

# Enable adb server access in wsl2
# export WSL_HOST=$(tail -1 /etc/resolv.conf | cut -d' ' -f2)
# export ADB_SERVER_SOCKET=tcp:$WSL_HOST:5037

# Enable only if you prefer to use volta
# export VOLTA_HOME="$HOME/.volta"
# export PATH="$VOLTA_HOME/bin:$PATH"
