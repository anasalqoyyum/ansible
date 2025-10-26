#!/usr/bin/env bash
set -g mode-style "fg=#a89984,bg=#504945"

set -g message-style "fg=#a89984,bg=#504945"
set -g message-command-style "fg=#a89984,bg=#504945"

set -g pane-border-style "fg=#504945"
set -g pane-active-border-style "fg=#a89984"

set -g status "on"
# set -g status-justify absolute-centre
set -g status-justify "left"

set -g status-style "fg=#a89984,bg=#282828"

set -g status-left-length "100"
set -g status-right-length "100"

set -g status-left-style NONE
set -g status-right-style NONE

set -g status-left "#[fg=#1d2021,bg=#a89984] #S "
set -g status-right "#{prefix_highlight} #[fg=#1d2021,bg=#a89984] %H:%M "

setw -g window-status-activity-style "underscore,fg=#ddc7a1,bg=#282828"
setw -g window-status-separator ""
setw -g window-status-style "NONE,fg=#ddc7a1,bg=#282828"
setw -g window-status-format " #[fg=#252530,bg=#d7d7d7] #I #[fg=#ddc7a1,bg=#282828] #W "
setw -g window-status-current-format " #[fg=#1d2021,bg=#a89984] #I #[fg=#ddc7a1,bg=#504945] #W "

# tmux-plugins/tmux-prefix-highlight support
set -g @prefix_highlight_output_prefix "#[fg=#e0af68]#[bg=#282828]"
set -g @prefix_highlight_output_suffix ""
