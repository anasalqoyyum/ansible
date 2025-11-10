#!/usr/bin/env bash
set -g mode-style "fg=#7aa2f7,bg=#3b4261"

set -g message-style "fg=#7aa2f7,bg=#3b4261"
set -g message-command-style "fg=#7aa2f7,bg=#3b4261"

set -g pane-border-style "fg=#3b4261"
set -g pane-active-border-style "fg=#7aa2f7"

set -g status "on"
# set -g status-justify absolute-centre
set -g status-justify "left"

set -g status-style "fg=#7aa2f7,bg=#080A11"

set -g status-left-length "100"
set -g status-right-length "100"

set -g status-left-style NONE
set -g status-right-style NONE

# set -g status-left "#[fg=#080A11,bg=#7aa2f7]  #S "
# set -g status-right " #[fg=#080A11,bg=#7aa2f7] 󰥔 %I:%M "
set -g status-left "#[fg=#080A11,bg=#7aa2f7] #S "
set -g status-right "#{prefix_highlight} #[fg=#080A11,bg=#7aa2f7] %H:%M "

setw -g window-status-activity-style "underscore,fg=#a9b1d6,bg=#080A11"
setw -g window-status-separator ""
setw -g window-status-style "NONE,fg=#a9b1d6,bg=#080A11"
setw -g window-status-format " #[fg=#252530,bg=#d7d7d7] #I #[fg=#a9b1d6,bg=#080A11] #W "
setw -g window-status-current-format " #[fg=#080A11,bg=#7aa2f7] #I #[fg=#7aa2f7,bg=#3b4261] #W "

# tmux-plugins/tmux-prefix-highlight support
set -g @prefix_highlight_output_prefix "#[fg=#e0af68]#[bg=#080A11]"
set -g @prefix_highlight_output_suffix ""
