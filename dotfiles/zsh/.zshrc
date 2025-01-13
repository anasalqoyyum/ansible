# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k
# Remove "zi" alias for default zoxide alias to work
if alias zi &>/dev/null; then
  zinit ice atload'unalias zi'
fi

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZL::clipboard.zsh
zinit snippet OMZL::directories.zsh
zinit snippet OMZL::functions.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found
zinit snippet OMZP::yarn

# Load completions
autoload -Uz compinit && compinit
zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Functions
function sesh-sessions() {
  {
    exec </dev/tty
    exec <&1
    local session
    session=$(sesh list -t -c | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ')
    zle reset-prompt > /dev/null 2>&1 || true
    [[ -z "$session" ]] && return
    sesh connect $session
  }
}
function tms() {
  local selected
  selected=$(sesh list --icons | fzf --height 40% --layout reverse --border \
    --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
    --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
    --bind 'tab:down,btab:up' \
    --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
    --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
    --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
    --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
    --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
    --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --icons)' \
  )

  # Trim any leading/trailing whitespace and newlines
  selected=$(echo "$selected" | xargs)

  if [ -n "$selected" ]; then
    sesh connect "$selected"
  else
    echo "No session selected."
  fi
}

# Keybinds
bindkey -e
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
zle     -N             sesh-sessions
bindkey -M emacs '\es' sesh-sessions
bindkey -M vicmd '\es' sesh-sessions
bindkey -M viins '\es' sesh-sessions

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

## $PATH
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="${HOME}/.local/bin:${PATH}"
export XDG_CONFIG_HOME="$HOME/.config"
# Add Golang
export PATH="$PATH:/usr/local/go/bin"
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"
# Add Rust
export PATH="$HOME/.cargo/bin:$PATH"
# Add Java
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export ANDROID_HOME="$HOME/android"
export GRADLE_HOME=/opt/gradle/gradle-7.6.1 # Might need to change this depending on your version
export ANDROID_SDK_ROOT=${ANDROID_HOME}
export PATH="$JAVA_HOME/bin:$PATH"
export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${PATH}"
export PATH="${GRADLE_HOME}/bin:${PATH}"
# Add Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export BAT_THEME="OneHalfDark"

# Shell Integrations
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source ~/.completion-for-pnpm.zsh
eval "$(mise activate zsh)"
eval "$(zoxide init zsh)"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Aliases
alias vs="code ."
alias lg="lazygit"
alias exp="explorer.exe ."
alias nv="nvim"
alias vim="nvim"
alias tkas="tmux kill-session -a"
alias yolo="find . -name 'node_modules' -type d -prune -print -exec sudo rm -rf '{}' \;"
alias nuke="find . -name 'dist' -type d -prune -print -exec sudo rm -rf '{}' \;"
alias t="tmux new-session -A -s main"
alias search="rg --files --hidden | fzf --preview 'batcat --color=always --style=numbers --line-range=:500 {}' | xargs nvim"
alias p="pnpm"
alias ll="eza -lg --icons --git"
alias lla="eza -alg --icons --git"
alias llt="eza -1 --icons --tree --git-ignore"
if command -v batcat &>/dev/null; then
  alias bat="batcat"
  if [ ! -e "$HOME/.local/bin/bat" ]; then
    ln -s "$(which batcat)" "$HOME/.local/bin/bat"
  fi
fi
if command -v fdfind &>/dev/null; then
  alias fd="fdfind"
  if [ ! -e "$HOME/.local/bin/fd" ]; then
    ln -s "$(which fdfind)" "$HOME/.local/bin/fd"
  fi
fi


## Device specific
# Aliases
alias v="print -z --"
# PATH
export FLYCTL_INSTALL="$HOME/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"
