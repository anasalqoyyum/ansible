source ~/zsh-snap/znap.zsh

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

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git z tmux)

ZSH_TMUX_AUTOSTART=true

source $ZSH/oh-my-zsh.sh

znap source zsh-users/zsh-autosuggestions
znap source zsh-users/zsh-syntax-highlighting
# znap source marlonrichert/zsh-autocomplete

# User configuration

alias vs="code ."
alias lg="lazygit"
alias bat="batcat"
alias exp="explorer.exe ."
alias yolo="find . -name 'node_modules' -type d -prune -print -exec sudo rm -rf '{}' \;"
alias nuke="find . -name 'dist' -type d -prune -print -exec sudo rm -rf '{}' \;"

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

# Enable only if you prefer to use volta
# export VOLTA_HOME="$HOME/.volta"
# export PATH="$VOLTA_HOME/bin:$PATH"
