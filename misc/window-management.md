# Window Management

| OS | Tiling WM | Hotkey daemon |
| --- | --- | --- |
| Windows | Komorebi | whkd |
| macOS | yabai | skhd |
| Ubuntu devbox | Hyprland (dwindle layout) | built in |

Config lives in `dotfiles/komorebi` (Windows), `dotfiles/yabai` (macOS), and `dotfiles/hyprland` (devbox, including the Waybar config). Both are stowed by the usual dotfiles flow; the Windows files are pushed to the Windows home directory by `make sync-dotfiles-windows`.

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

## Ubuntu devbox

1. Provisioning installs Hyprland, its desktop portal, `hyprpolkitagent`, Waybar, fuzzel, hyprlock, hypridle, and hyprpaper from the Ubuntu archive, and copies `bg/underwater.png` to `~/.local/share/backgrounds/` for the wallpaper and lock screen. Install or update just these with `ansible-playbook local-devbox.yml --tags hyprland --ask-become-pass`.
2. Provisioning logs your user in to Hyprland automatically at boot. To use GNOME once, log out and choose Ubuntu from the session menu; the next provisioning run makes Hyprland the saved session again. See [the devbox guide](../docs/devbox.md#hyprland).
3. Hyprland, Waybar, fuzzel, and hyprlock use the savy-dark Ghostty palette.
4. Reload after a config change with `hyprctl reload`. Check a config without a running session with `Hyprland --verify-config`. Restart Waybar with `pkill -x waybar; hyprctl dispatch exec waybar`.
5. Waybar shows workspaces 1–5, the playing track (hidden when nothing plays), Wi-Fi and wired status, volume, CPU, memory, the tray, the clock, and a power menu. Click Wi-Fi or wired to connect or disconnect (disconnecting asks first) and right-click either for `nmtui`. Click the volume to choose an audio output and right-click to mute. The power menu offers lock, display off, log out, restart, and shut down; sleep is absent because the devbox masks suspend. The helper scripts live in `dotfiles/hyprland/.config/waybar/`.

Hyprland is only for the physical desktop. SSH, Tailscale, and Docker do not depend on which session is logged in, or whether anyone is logged in at all.

The Waybar, `hyprpolkitagent`, hypridle, and hyprpaper packages enable their user services for every graphical session, including GNOME. Provisioning disables them globally, and `hyprland.conf` starts them with `exec-once` instead.

Extra devbox bindings: `alt + return` opens Ghostty, `alt + space` opens fuzzel, `alt + shift + m` shows minimized windows, `super + l` locks the screen, and `ctrl + alt + delete` exits Hyprland.

## Shortcuts

Identical on all platforms, except for the Hyprland gaps listed below: `alt + q` close, `alt + m` minimize, `alt + shift + h/j/k/l` focus, `alt + shift + t` float, `alt + shift + f` fullscreen/monocle, `alt + shift + r` retile/balance, `alt + shift + x` / `alt + shift + y` flip/mirror layout, `alt + 1..8` focus workspace, `alt + shift + 1..8` send window to workspace.

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

Hyprland follows the Windows chords (`alt + shift + arrows` to move, `alt + shift + return` to promote). Its gaps relative to Komorebi:

- Minimize sends the window to the `special:minimized` workspace. `alt + shift + m` toggles it so you can pick a window back up.
- Promote runs dwindle's `movetoroot`.
- Stacks are Hyprland groups. `ctrl + alt + shift + arrow` only joins a neighbour that is already a group, so start one with `alt + shift + g` first. `alt + ;` unstacks, and `alt + [` / `alt + ]` cycle the group.
- Flip and mirror act on the focused split, not the whole workspace: `alt + shift + x` swaps the two halves, and `alt + shift + y` toggles their orientation.
- Retile (`alt + shift + r`) has no dwindle equivalent and is left unbound.
- Workspaces are created on demand, so `alt + N` reaches empty workspaces.
