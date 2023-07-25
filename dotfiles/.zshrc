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

ZSH_THEME="powerlevel10k/powerlevel10k"

# Enable fzf
# git clone https://github.com/joshskidmore/zsh-fzf-history-search ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-fzf-history-search
plugins=(git tmux yarn dotenv zoxide zsh-syntax-highlighting zsh-autosuggestions zsh-fzf-history-search)

# ZSH_TMUX_AUTOSTART=true
# ZSH_TMUX_AUTOCONNECT=false

source $ZSH/oh-my-zsh.sh

# znap source zsh-users/zsh-autosuggestions
# znap source zsh-users/zsh-syntax-highlighting
# znap source marlonrichert/zsh-autocomplete

# User configuration

alias vs="code ."
alias lg="lazygit"
alias bat="batcat"
alias exp="explorer.exe ."
alias nv="nvim"
alias tkas="tmux kill-session -a"
alias yolo="find . -name 'node_modules' -type d -prune -print -exec sudo rm -rf '{}' \;"
alias nuke="find . -name 'dist' -type d -prune -print -exec sudo rm -rf '{}' \;"
alias t="tmux"

# Run `cargo install exa` to install exa
alias ll="exa -lg --icons --git"
alias lla="exa -alg --icons --git"
alias llt="exa -1 --icons --tree --git-ignore"
alias search="fzf --preview 'batcat --color=always --style=numbers --line-range=:500 {}' | xargs nvim"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Add Golang to $PATH
export PATH="$PATH:/usr/local/go/bin"

# Add Rust to $PATH
export PATH="$HOME/.cargo/bin:$PATH"

export PATH="$HOME/.local/share/bob/nvim-bin:$PATH"

# Loads pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Java Stuff
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export ANDROID_HOME="$HOME/android"
export GRADLE_HOME=/opt/gradle/gradle-7.6.1 # Might need to change this depending on your version
export ANDROID_SDK_ROOT=${ANDROID_HOME}

export PATH="$JAVA_HOME/bin:$PATH"
export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${PATH}"
export PATH="${GRADLE_HOME}/bin:${PATH}"

# Enable only if you prefer to use volta
# export VOLTA_HOME="$HOME/.volta"
# export PATH="$VOLTA_HOME/bin:$PATH"
