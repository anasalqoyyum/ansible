# if it's windows revert the bell-style to none in /etc/inputrc (the one below should fix it though)
# none, visible or audible
# set bell-style none
bind 'set bell-style none'

export STARSHIP_CONFIG=$HOME/starship.toml
alias vim="nvim"

# Run starship if the terminal supports it
if [[ "$TERM" != "dumb" ]]; then
  eval "$(starship init zsh)"
fi
eval "$(mise activate bash | sed 's|eval "$(mise hook-env -s bash)";|& export PATH="$(/usr/bin/cygpath -u -p "$PATH")";|')"
