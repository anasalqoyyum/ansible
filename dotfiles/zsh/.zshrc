# Enable this for profiling zsh (also the one EOF)
# zmodload zsh/zprof

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

# Disable zinit aliases (for zoxide alias to work zi)
declare -A ZINIT
ZINIT[NO_ALIASES]=1
# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice lucid atload'source ~/.p10k.zsh' nocd depth=1
zinit light romkatv/powerlevel10k

# Add in zsh plugins (with wait for lucid)
zinit wait lucid for \
    Aloxaf/fzf-tab \
 atinit"zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
 blockf \
    zsh-users/zsh-completions \
 atload"!_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions

# Add in snippets (with wait)
zinit wait lucid for \
    OMZL::clipboard.zsh \
    OMZL::git.zsh \
  atload"alias ll='eza -lg --icons --git'" \
    OMZL::directories.zsh \
    OMZL::functions.zsh \
    OMZP::git \
    OMZP::sudo \
    OMZP::kubectl \
    OMZP::kubectx \
    OMZP::command-not-found \
    OMZP::zoxide \
    OMZP::fzf \
  atload"unalias y" \
    OMZP::yarn \
    OMZP::mise \
    OMZP::bun

# pnpm completion
zinit ice wait lucid atload"zpcdreplay" atclone"./zplug.zsh" atpull"%atclone"
zinit light g-plane/pnpm-shell-completion

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
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Keybinds
# Useful keybinds set by other plugins
# CTRL+R to search history (fzf)
# CTRL+T to search files and paste to commandline (fzf)
# ALT+C to cd to the selected directory (fzf)

# Emacs mode keybindings
bindkey -e

# [Ctrl-Delete] - delete whole forward-word
bindkey -M emacs '^[[3;5~' kill-word
bindkey -M viins '^[[3;5~' kill-word
bindkey -M vicmd '^[[3;5~' kill-word

# [Ctrl-RightArrow] - move forward one word
bindkey -M emacs '^[[1;5C' forward-word
bindkey -M viins '^[[1;5C' forward-word
bindkey -M vicmd '^[[1;5C' forward-word
# [Ctrl-LeftArrow] - move backward one word
bindkey -M emacs '^[[1;5D' backward-word
bindkey -M viins '^[[1;5D' backward-word
bindkey -M vicmd '^[[1;5D' backward-word

# [Home] - Go to beginning of line
if [[ -n "${terminfo[khome]}" ]]; then
  bindkey -M emacs "${terminfo[khome]}" beginning-of-line
  bindkey -M viins "${terminfo[khome]}" beginning-of-line
  bindkey -M vicmd "${terminfo[khome]}" beginning-of-line
fi
# [End] - Go to end of line
if [[ -n "${terminfo[kend]}" ]]; then
  bindkey -M emacs "${terminfo[kend]}"  end-of-line
  bindkey -M viins "${terminfo[kend]}"  end-of-line
  bindkey -M vicmd "${terminfo[kend]}"  end-of-line
fi

# sesh-sessions bindings (ALT+S)
zle     -N             sesh-sessions
bindkey -M emacs '\es' sesh-sessions
bindkey -M vicmd '\es' sesh-sessions
bindkey -M viins '\es' sesh-sessions

# CTRL+X+E to edit the current command in editor
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line

bindkey '\ew' kill-region # [Esc-w] - Kill from the cursor to the mark

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

export FLYCTL_INSTALL="$HOME/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"

export KUBE_EDITOR="nvim"
export EDITOR="nvim"

# Aliases
alias vs="code ."
alias vc="cursor ."
alias lg="lazygit"
alias exp="explorer.exe ."
alias nv="nvim"
alias vim="nvim"
alias tkas="tmux kill-session -a"
alias yolo="find . -name 'node_modules' -type d -prune -print -exec sudo rm -rf '{}' \;"
alias nuke="find . -name 'dist' -type d -prune -print -exec sudo rm -rf '{}' \;"
alias t="tmux new-session -A -s main"
alias search="rg --files --hidden | fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' | xargs nvim"
alias p="pnpm"
alias ll="eza -lg --icons --git"
alias lla="eza -alg --icons --git"
alias llt="eza -1 --icons --tree --git-ignore"
alias k="kubectl"
alias v="print -z --"

# Shell Integrations (Optional)
# [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
# source ~/.completion-for-pnpm.zsh

# Enable zsh profiling
# zprof
