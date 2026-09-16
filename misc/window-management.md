# Window Management

| OS | Tiling WM | Hotkey daemon |
| --- | --- | --- |
| Windows | Komorebi | whkd |
| macOS | yabai | skhd |

Config lives in `dotfiles/komorebi` (Windows) and `dotfiles/yabai` (macOS). Both are stowed by the usual dotfiles flow; the Windows files are pushed to the Windows home directory by `make sync-dotfiles-windows`.

## Windows

1. Install through Scoop: `komorebi` and `whkd`
2. Setup komorebi-run, komorebi-stop, komorebi-kill through Raycast
3. [Optional] Komorebi-switcher for switching UI in Taskbar

## macOS

1. Install through Brew: `asmvik/formulae/yabai` and `asmvik/formulae/skhd` (both are in `tasks/core-brew-setup.yml`).
2. Create at least **8 native Spaces** in Mission Control. yabai does not create or destroy Spaces here, so `Alt+1` .. `Alt+8` only work for Spaces that already exist.
3. Turn **off** System Settings → Desktop & Dock → Mission Control → *Automatically rearrange Spaces based on most recent use*. Without this, Space numbers shift around and `Alt+N` stops being predictable.
4. Turn **on** System Settings → Desktop & Dock → Mission Control → *Displays have separate Spaces* (yabai requires it).
5. Start the services:

   ```sh
   yabai --start-service
   skhd --start-service
   ```

6. Grant **Accessibility** permission to `yabai` and `skhd` when macOS prompts on first launch (System Settings → Privacy & Security → Accessibility). This is deliberately not automated by Ansible.
7. Restart the services after granting permission, and after any config change:

   ```sh
   yabai --restart-service
   skhd --restart-service
   ```

`--start-service` installs a launchd agent, so both survive logout and reboot.

### Scripting addition and SIP

The scripting addition is deliberately **not** part of this setup, so System Integrity Protection stays enabled. What is given up: moving/creating/destroying Spaces, window transparency and shadows, window animations, sticky windows, scratchpads, and window layer control.

One gap matters in practice and is **not** listed in the yabai wiki: `yabai -m space --focus N` is a silent no-op without the scripting addition — it exits 0, logs nothing, and the focused Space does not change. `yabai -m window --space N` is unaffected and works normally.

`Alt+1` .. `Alt+8` therefore go through `~/.config/yabai/focus-space`, which focuses a window that lives on the target Space and lets macOS follow. The consequence: **an empty Space cannot be reached with `Alt+N`.** Use Mission Control or Ctrl+Arrow for those, or move a window there first with `Alt+Shift+N`.

### Verifying

```sh
yabai -m query --spaces | jq -r '.[] | "space \(.index): windows=\(.windows|length)"'
launchctl list | grep -E 'yabai|skhd'
```

Logs are at `/tmp/yabai_$USER.err.log` and `/tmp/skhd_$USER.err.log`.

## Shortcuts

Identical on both platforms: `alt + q` close, `alt + m` minimize, `alt + shift + h/j/k/l` focus, `alt + shift + t` float, `alt + shift + f` fullscreen/monocle, `alt + shift + r` retile/balance, `alt + shift + x` / `alt + shift + y` flip/mirror layout, `alt + 1..8` focus workspace, `alt + shift + 1..8` send window to workspace.

Note that yabai targets native macOS Space numbers starting at `1`, while `komorebic` workspace indices are zero-based. The chords match even though the arguments differ:

| Action | macOS skhd | Windows whkd |
| --- | --- | --- |
| Focus workspace 1 | `alt - 1` → `yabai -m space --focus 1` | `alt + 1` → `komorebic focus-workspace 0` |
| Send window to workspace 1 | `alt + shift - 1` → `yabai -m window --space 1` | `alt + shift + 1` → `komorebic move-to-workspace 0` |

Where the chords differ:

| Action | macOS skhd | Windows whkd |
| --- | --- | --- |
| Toggle shortcuts | - | `alt + shift + i` |
| Move left | `ctrl + alt - left` | `alt + shift + left` |
| Move down | `ctrl + alt - down` | `alt + shift + down` |
| Move up | `ctrl + alt - up` | `alt + shift + up` |
| Move right | `ctrl + alt - right` | `alt + shift + right` |
| Promote | `ctrl + alt - return` or `alt + shift - return` | `alt + shift + return` |

macOS gaps relative to Komorebi:

- Promote maps to `yabai -m window --swap first`, which swaps with the first window in the Space rather than Komorebi's promote-to-primary.
- Unstack has no clean yabai equivalent and is left unbound.
- `Alt+N` cannot reach an empty Space (see the SIP section above). Komorebi has no such restriction.
