#!/usr/bin/env bash
set -g mode-style "fg=#EBBCBA,bg=#25233A"

set -g message-style "fg=#EBBCBA,bg=#25233A"
set -g message-command-style "fg=#EBBCBA,bg=#25233A"

set -g pane-border-style "fg=#25233A"
set -g pane-active-border-style "fg=#EBBCBA"

set -g status "on"
# set -g status-justify absolute-centre
set -g status-justify "left"

set -g status-style "fg=#EBBCBA,bg=#16161e"

set -g status-left-length "100"
set -g status-right-length "100"

set -g status-left-style NONE
set -g status-right-style NONE

# set -g status-left "#[fg=#15161e,bg=#EBBCBA]  #S "
# set -g status-right " #[fg=#15161e,bg=#EBBCBA] 󰥔 %I:%M "
set -g status-left "#[fg=#15161e,bg=#EBBCBA] #S "
set -g status-right "#{prefix_highlight} #[fg=#15161e,bg=#EBBCBA] %H:%M "

setw -g window-status-activity-style "underscore,fg=#a9b1d6,bg=#16161e"
setw -g window-status-separator ""
setw -g window-status-style "NONE,fg=#a9b1d6,bg=#16161e"
# No need to change between since this is when window not active
setw -g window-status-format " #[fg=#252530,bg=#d7d7d7] #I #[fg=#a9b1d6,bg=#16161e] #W "
setw -g window-status-current-format " #[fg=#15161e,bg=#EBBCBA] #I #[fg=#EBBCBA,bg=#25233A] #W "

# tmux-plugins/tmux-prefix-highlight support
set -g @prefix_highlight_output_prefix "#[fg=#e0af68]#[bg=#16161e]"
set -g @prefix_highlight_output_suffix ""
