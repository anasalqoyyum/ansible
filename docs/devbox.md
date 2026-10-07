# Dedicated Ubuntu devbox

Target: Geekom A5, Ryzen 7 7730U, 32 GB RAM, 1 TB SSD, Ubuntu Desktop
26.04 LTS on x86_64. Run provisioning as your regular development user. Do not
run the bootstrap with `sudo`, or use this profile inside WSL.

## Before installing

Install Ubuntu manually with a monitor and keyboard attached. Create a regular
user with sudo access, connect Ethernet, install Ubuntu updates, and keep a local
password for sudo and physical recovery. Choose a hostname such as `devbox`.
Have the existing SSH private key on your connecting computer and the Ansible
Vault password available for the optional outbound-key restore.

Use these installer choices:

- Leave disk encryption off. The devbox must boot unattended after a power cut.
  Passphrase-based LUKS stops boot before networking and Tailscale start, so
  nobody can unlock it remotely. TPM-backed unlock is also out, because a
  firmware, Secure Boot, or kernel change can drop it back to a passphrase
  prompt. Anyone who takes the machine or its SSD can read the disk. If that
  happens, remove the device from Tailscale, revoke its GitHub and AI tool
  sessions, sign out the agent Chrome profile's websites, and rotate the
  outbound SSH key if you restored it.
- Leave **Install third-party software for graphics and Wi-Fi hardware**
  unchecked. The 7730U's Radeon graphics use Ubuntu's open-source `amdgpu`
  driver, and the devbox uses Ethernet. If `ubuntu-drivers devices` lists a
  driver later, install it with `sudo ubuntu-drivers install`.
- Leave **Download and install support for additional media formats**
  unchecked. Nothing plays media on the devbox, and Chrome bundles its own
  codecs. Run `sudo apt install ubuntu-restricted-extras` later if you need them.
- Leave **Use Active Directory** unchecked and create a local user.

Ansible does not configure disk encryption or unlocking. Adding encryption later
means reinstalling Ubuntu and repeating the acceptance tests.

The physical monitor logs your user in to Hyprland automatically at boot (see
[Hyprland](#hyprland)). Anyone at the keyboard can act as you without a password,
except for sudo. The opt-in agent desktop is a separate virtual XFCE desktop that
a systemd user manager starts at boot through `loginctl enable-linger`. It also
belongs to your user: anyone who can access its forwarded VNC connection can act
as you. This is intended for a dedicated, single-user machine.

Chrome uses a dedicated directory, `~/.local/share/devbox/chrome`, and
`--password-store=basic` so a login-unlocked GNOME keyring is not required after
boot. The normal Chrome and Helium launchers also use `--password-store=basic`.
Chrome's basic store does not provide the protection of a locked desktop
keyring. Keep sensitive personal browsing in another profile, avoid saving
passwords there, and protect physical access. The directory is mode `0700`.
Logged-in websites still grant agents the permissions of those accounts.

Provisioning enables UFW with incoming traffic denied except SSH on port 22,
which is open on every interface, including the LAN and Tailscale. SSH accepts
keys only. Existing UFW rules are retained, so audit them on an existing system.
Do not forward SSH, VNC, BrowserSkill, or application ports on your router.

## What Ansible does

| Automatic | Manual or interactive |
| --- | --- |
| Reuse shared Git, Zsh, Herdr, Neovim, Stow, mise, language runtimes, Rust, Cargo, Docker/Compose, AI CLIs, and BrowserSkill CLI tasks | Install Ubuntu unencrypted, without third-party drivers or extra media formats |
| Sync managed dotfiles without replacing local auth, sessions, or caches | Authenticate Tailscale, GitHub, Codex, and other AI tools |
| Install CLIProxyAPI core and keep it running with a lingering systemd user service | Authenticate upstream providers and set the client API key |
| Install or update Chrome stable, the latest Helium AppImage, Ghostty's latest community Ubuntu package, and the newest T3 Code nightly; install Zed | Sign in to browsers, T3 Code, and Zed as needed |
| Install Hyprland with Waybar, fuzzel, a wallpaper, and an idle lock screen, and log in to it automatically at boot | Reboot once for automatic login to take effect |
| Create `~/repo/` and `~/repo/worktrees/` | Clone your development repositories when needed |
| Install, enable, and start native OpenSSH and Tailscale | Restore outbound SSH files using Ansible Vault if wanted |
| Authorize the existing `.ssh/id_ed25519.pub` without removing other authorized keys | Install and connect the BrowserSkill Chrome extension |
| Configure Chrome's agent profile, a virtual display, and XFCE only with `--tags devbox-desktop` | Configure BIOS power recovery and test the actual machine |
| Mask suspend/hibernate targets without changing CPU idle states | Revoke the devbox's credentials if the machine is lost or stolen |

The BrowserSkill skill comes from
`dotfiles/agents/.agents/skills/browser-skill/`. Codex reads the shared agent skills;
Claude links to the same managed copy. Ansible does not run `bsk install-skill`.
The existing Codex `approval_policy = "never"` and
`sandbox_mode = "danger-full-access"` remain unchanged.

## Initial bootstrap

At the Ubuntu console:

```bash
sudo apt update
sudo apt install -y git
mkdir -p ~/repo
git clone https://github.com/anasalqoyyum/ansible.git ~/repo/ansible
cd ~/repo/ansible
bash run-devbox.sh
# Equivalent: make setup-devbox
```

Enter your sudo password when prompted. Bootstrap installs Ansible if needed,
installs the declared collections, and runs `local-devbox.yml`. Ubuntu Desktop
keeps FUSE 3; the profile installs `libfuse2t64` for the shared AppImages instead of the conflicting `fuse` package. The broad shared
mise configuration installs more than the languages listed here. Downloads and
Rust builds can take time. You can rerun a failed bootstrap after fixing its
cause.

The default authorized public key is `.ssh/id_ed25519.pub` in this repository.
To add a different connecting computer's public key instead:

```bash
bash run-devbox.sh -e devbox_authorized_key_file=/absolute/path/client-key.pub
```

Never supply a private key as this input. Provisioning appends the public key to
`~/.ssh/authorized_keys`, enables public-key authentication, disables password
and keyboard-interactive SSH login, and prohibits root SSH login. It switches
Ubuntu's SSH socket activation to the enabled `ssh.service` and verifies that
port 22 answers locally. Verify a real key-authenticated connection before
removing the monitor; the port check alone cannot prove authentication works.

SSH validation checks both the global settings and settings for your development
user. It uses `100.64.0.1` as a representative Tailscale client address and host.
If an existing SSH configuration uses `Match Address` or `Match Host`, supply
your connecting computer's actual Tailscale IP and host name so those rules are
evaluated:

```bash
bash run-devbox.sh \
  -e 'devbox_ssh_client_address=<client-tailscale-ip>' \
  -e 'devbox_ssh_client_host=<client-host-name>'
```

Repeat validation for each allowed client when their matching rules differ.

Private SSH keys and SSH client config are not restored by the bootstrap.
Restore the existing Vault-managed files explicitly, without rotation:

```bash
cd ~/repo/ansible
make ssh-devbox-vault
```

This prompts for the Vault password. Sensitive copies use `no_log` and disable
Ansible diffs. The encrypted private key remains passphrase-protected after Vault
decryption. Use `ssh-agent` and `ssh-add ~/.ssh/id_ed25519` when needed; its
passphrase is an interactive step, not stored in Git or a service. Do not print
private keys or run the setup with shell tracing. Vault encryption is preserved
in the repository; the intentional private-key destination is mode `0600`.

Log out and reconnect after provisioning for Docker group membership and shell
changes. Membership in the Docker group gives effective root privileges. The
physical GNOME desktop and the virtual XFCE desktop are separate sessions.

## CLIProxyAPI core

The devbox profile installs the latest Linux amd64 release of
[CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI/releases), verifies
its SHA-256 digest, and enables `cli-proxy-api.service` as a systemd user service.
User lingering starts it at boot before login and keeps it running after logout.
Systemd restarts the process if it exits. Install or update only the core with:

```bash
ansible-playbook local-devbox.yml --tags cliproxyapi --ask-become-pass
```

The API listens at `http://127.0.0.1:8317/v1`. Its configuration is
`~/.config/cliproxyapi/config.yaml`, with a generated client key under
`access.api-keys`. Set `CPA_PROXY_API_KEY` to that key when using the managed
Codex provider. The control panel is enabled at
`http://127.0.0.1:8317/management.html` on new installations. The initial management
password is saved in `~/.config/cliproxyapi/management-key` with user-only
permissions. CLIProxyAPI hashes the password in `config.yaml` on startup, so use the saved password to
sign in. Management access is restricted to localhost.
Provisioning preserves existing configuration and OAuth credentials in
`~/.cli-proxy-api`. Authenticate a provider before making model requests, for
example:

```bash
cli-proxy-api -config "$HOME/.config/cliproxyapi/config.yaml" -codex-login
systemctl --user status cli-proxy-api.service
journalctl --user -u cli-proxy-api.service -f
```

After editing the configuration, use
`systemctl --user restart cli-proxy-api.service` to apply it.
This service is devbox-only. The macOS profile already installs the
`cliproxyapi` Homebrew formula, but does not start it with `brew services`.

## Desktop applications

Normal provisioning installs Chrome, Helium, Ghostty, Zed, and T3 Code for the physical
Ubuntu desktop. They do not require the opt-in virtual desktop. To install or
update just these applications:

```bash
ansible-playbook local-devbox.yml --tags devbox-apps --ask-become-pass
```

Use `--tags chrome`, `--tags helium`, `--tags ghostty`, `--tags zed`, or
`--tags t3code` to update only one. Each run resolves the current release rather
than keeping a pinned version, except Zed, which updates itself.

Chrome uses Google's current stable amd64 `.deb`. The `devbox-desktop` tag also
installs Chrome so the opt-in agent desktop still works on its own.

Helium uses the latest x86_64 AppImage from
[imputnet/helium-linux](https://github.com/imputnet/helium-linux/releases), linked
by [Helium's download page](https://helium.computer/download). Ansible verifies
the GitHub release asset's SHA-256 digest and installs it at
`/opt/helium/helium.AppImage`, with a `helium` command and an application-menu
launcher. The `helium` tag installs `libfuse2t64` without replacing Ubuntu's FUSE 3.
On its first launch, Helium may ask for administrator authorization to install
its AppArmor profile, as implemented by its upstream AppImage wrapper. The
launcher does not disable the Chromium sandbox or change your default browser.

Ghostty uses the latest stable `.deb` from
[ghostty-ubuntu](https://github.com/mkasberg/ghostty-ubuntu/releases), the community
build linked by [Ghostty's install docs](https://ghostty.org/docs/install/binary#debian-and-ubuntu).
This may be newer than Ubuntu's official package. It is a third-party build, not
an official Ghostty binary. Ansible selects the Ubuntu 26.04 amd64 asset directly
instead of executing the community install script. The Ghostty tasks also install
`wl-clipboard`, which provides `wl-copy` and `wl-paste` for CLI clipboard access
on Wayland. Install just this dependency with `--tags clipboard`.

Zed uses the official installer, `curl -fsSL https://zed.dev/install.sh | sh`,
which unpacks the stable release into `~/.local/zed.app` and links
`~/.local/bin/zed`. It runs only when `~/.local/bin/zed` is missing, because Zed
updates itself. Its settings come from the shared `dotfiles/zed` package.

T3 Code uses the newest published nightly from
[pingdotgg/t3code](https://github.com/pingdotgg/t3code/releases), sorted by
publication time among the latest 100 releases. It installs the amd64 `.deb`,
never the stable release. Provisioning fails if no nightly is found or the newest
nightly lacks that package; it does not silently install an older build.
Applications are installed but not launched. Updates happen when you rerun these
tasks, not through a scheduled Ansible job.

### Keyring and SSH-only use

Automatic desktop login and SSH public-key login do not supply a password to
unlock GNOME Keyring. Apps that depend on it can wait for a graphical password
prompt after reboot. SSH, Tailscale, and Docker do not need the desktop keyring.

Provisioning installs `google-chrome` and `helium` command wrappers with
`--password-store=basic`. Their application-menu launchers use those wrappers,
including Chrome's New Window and Incognito actions. The Chrome launcher
overrides the packaged desktop entry under `/usr/local/share/applications`.
Launching `/usr/bin/google-chrome-stable` or `/opt/helium/helium.AppImage`
directly bypasses the wrappers. GNOME Keyring and its existing secrets remain
unchanged.

Before applying this to existing browser profiles, close both browsers and back
up `~/.config/google-chrome` and `~/.config/net.imput.helium` if they exist.
Passwords and cookies encrypted with the previous keyring backend may be
unavailable with `basic`, so expect to sign in again. Restore the old launch
settings and profile backup if you need to return to the keyring backend.
The basic backend does not provide keyring encryption for browser secrets.

After reviewing that tradeoff, apply only the launcher changes:

```bash
ansible-playbook local-devbox.yml --tags keyring --ask-become-pass
```

This does not open browsers, change the login password, or unlock the keyring.
Launch each browser again and verify its command line on `chrome://version`.

Lazygit uses Git's authentication. For SSH remotes, load the outbound key with
`ssh-add ~/.ssh/id_ed25519` after connecting, or forward your client's SSH agent
with `ssh -A <user>@<devbox>`. `ssh-add -l` should then list an available key.
The local agent loses its loaded keys after reboot. Unattended Git operations
still require an available agent; these browser settings do not unlock SSH keys.

GitHub CLI credentials are separate. If `gh` also prompts for the desktop
keyring, authenticate once with file storage:

```bash
gh auth login --hostname github.com --git-protocol ssh --skip-ssh-key --insecure-storage
chmod 600 ~/.config/gh/hosts.yml
```

This stores the token in plain text in your user-only GitHub CLI configuration.
Provisioning does not migrate or print existing tokens. For unattended jobs,
`GH_TOKEN` supplied by the job's secret configuration also avoids the keyring.

### Hyprland

Hyprland, a BSP tiling Wayland compositor, is installed from the Ubuntu archive
as the physical monitor's session, with the `hyprland` tag. Keybindings follow
komorebi and yabai; see [window management](../misc/window-management.md).

Ubuntu 26.04 packages the GUI dialog helpers as `hyprland-qtutils`. Provisioning
installs it to provide `hyprland-dialog` and resolve the missing
`hyprland-guiutils` warning.

Press `super + shift + s` and drag to select a screenshot area. `slurp` selects
the area, `grim` captures it, and `wl-clipboard` copies the PNG for pasting.
The image is also saved in your XDG Pictures directory under `Screenshots`,
with a unique timestamped filename. Press Escape to cancel.

Provisioning enables GDM automatic login for your user in `/etc/gdm3/custom.conf`
and saves Hyprland as your login session in AccountsService. GDM reads both at
startup, so the change takes effect at the next boot; provisioning does not
restart GDM, which would end the running desktop. To use GNOME once, log out with
`ctrl + alt + delete` and choose Ubuntu from the session menu. GDM saves that
choice, and the next provisioning run sets Hyprland again.

SwayNotificationCenter displays notifications and keeps their history. Click
the bell in Waybar to open its panel, or right-click to toggle Do Not Disturb.
The bell changes its icon and turns yellow when Do Not Disturb is enabled.

Press `super + v` to choose a previous clipboard item in fuzzel. Cliphist records
text and images, and selecting an entry copies its original contents back to
the clipboard for pasting. History persists locally; clear it with `cliphist wipe`.
Press `super + shift + c` to pick a screen color with hyprpicker and copy its hex
value. Escape cancels either picker.

The `fonts` tag installs the bundled Noto Sans and Google Sans Code Nerd Fonts.
Noto Sans is the desktop default for fontconfig, GTK, Waybar, fuzzel, Hyprland
group labels, and hyprlock. Google Sans Code is the monospace default and an icon
fallback in Waybar. The standard Noto Sans family comes from `fonts-noto-core`.
Install or refresh the fonts with:

```bash
ansible-playbook local-devbox.yml --tags fonts
```

hypridle locks the session with hyprlock after 5 minutes without input and turns
the monitor off 30 seconds later. After a reboot, the auto-login desktop is
therefore open at the monitor for up to 5 minutes. Lock it immediately with
`super + l`. hyprlock checks your login password through PAM. hypridle never
suspends the machine.

If hyprlock crashes, Hyprland keeps the session locked behind a crash screen.
Restart the lock screen over SSH:

```bash
hyprctl --instance 0 dispatch exec hyprlock
```

Hyprland does not touch SSH, Tailscale, Docker, or power settings, which work
whether or not anyone is logged in on the monitor.

## Tailscale and SSH

On the devbox, authenticate once:

```bash
sudo tailscale up
tailscale status
tailscale ip -4
systemctl is-enabled tailscaled.service ssh.service docker.service
systemctl is-active tailscaled.service ssh.service docker.service
```

Open the authentication URL on a trusted computer and approve the device if your
tailnet requires it. Ansible never runs `tailscale up`, supplies an auth key, or
stores credentials in Git. Tailscale keeps its local machine state across reboot.
Review device key expiry in the Tailscale admin console for this always-on box;
expired authorization requires reauthentication. Limit SSH access with tailnet
access policies to your own devices/user as appropriate.

Install/authenticate Tailscale on your client too. From that client:

```bash
ssh -i ~/.ssh/id_ed25519 <ubuntu-user>@<tailscale-ip-or-magicdns-name>
```

Verify the SSH host-key fingerprint against the local console before trusting
the first connection:

```bash
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

This uses ordinary OpenSSH key authentication over Tailscale, not Tailscale SSH.
You do not need `tailscale up --ssh`. Avoid router port forwarding. UFW permits
SSH on every interface, so LAN SSH also works without Tailscale. Tailscale can
use relays when direct connectivity is unavailable.

Authenticate the other tools interactively, for example `gh auth login` and
`codex login` (or `codex login --device-auth` for an SSH-only login). Follow the
installed CLI's help for the current login flow. The bootstrap skips GitHub
extensions until `gh` is authenticated; afterward run
`ansible-playbook local-devbox.yml --tags gh-extensions` to install them. If GitHub
rate limits interrupted an installer, authenticate and rerun bootstrap.
Local authentication data, Chrome cookies, BrowserSkill state, and caches are not committed or reset by
provisioning.

## Remote desktop and Chrome

This desktop is opt-in and not installed by bootstrap. Its services left GNOME
autologin on the physical monitor at a black screen. The Hyprland auto-login has
not been tested alongside it, so install it only on a headless box:

```bash
ansible-playbook local-devbox.yml --tags devbox-desktop --ask-become-pass
```

Once installed, the following user services start at boot, even before an SSH
or physical login:

| Service | Responsibility |
| --- | --- |
| `devbox-display.service` | TigerVNC virtual X display `:20`, 1920x1080, private VNC Unix socket |
| `devbox-desktop.service` | XFCE desktop on that display with its own D-Bus session |
| `devbox-chrome.service` | Graphical Chrome using the dedicated automation profile |
| `devbox-browser-skill.service` | Foreground BrowserSkill daemon managed by systemd |

Chrome is launched explicitly by systemd. BrowserSkill CLI does not launch it.
No HDMI dummy plug is needed for this virtual display. It does not depend on the
AMD GPU detecting a monitor. Hardware-accelerated rendering and the physical
GNOME desktop are outside this virtual display setup; verify your applications'
rendering on the Geekom A5.

VNC has no TCP listener on the devbox. Its Unix socket is mode `0600` inside a
private runtime directory. SSH authenticates access and forwards it to a local
client port. Find your devbox user UID with `id -u` (often `1000`). On your client,
substitute that numeric UID and keep this tunnel open:

```bash
ssh -N -o ExitOnForwardFailure=yes \
  -L 127.0.0.1:15920:/run/user/<uid>/devbox/vnc.sock \
  <ubuntu-user>@<tailscale-ip-or-magicdns-name>
```

Connect a VNC viewer, such as TigerVNC Viewer, to `127.0.0.1:15920`. Some viewers
require `127.0.0.1::15920` to specify a port rather than a display number. VNC has
no additional password because access is through the user-owned socket and SSH.
The forwarded port allows other processes on your **client** to access the
session while the tunnel is open; use a trusted client and close the tunnel when
finished.

Closing the viewer or SSH tunnel leaves Chrome, XFCE, and browser sessions
running. Do not select XFCE Log Out or restart these services during active
browser tasks. Reconnect to the same socket to resume viewing the same desktop.
Ubuntu's built-in remote login/RDP can create another desktop and is not the
access path to this browser session.

## BrowserSkill extension and verification

In Chrome **inside the virtual desktop**:

1. Open `chrome://version` and confirm Profile Path is inside
   `~/.local/share/devbox/chrome`.
2. Install [BrowserSkill from the Chrome Web Store](https://chromewebstore.google.com/detail/hhcmgoofomhgciiibhipgmgkgnoenaoi).
3. Open its popup, enable its **local** connection, and match the port displayed
   by the local daemon. Name this instance `Devbox Agent` in BrowserSkill.
   This label is independent of Chrome's profile name.
4. Keep the extension enabled in this profile. Complete website sign-ins in that
   profile only as needed. Disconnecting the VNC client should leave it connected.

The CLI and Chrome are on the same computer, even when you SSH from elsewhere.
Use local extension connection mode, not a separate remote/WSS pairing server.
Store consent and pairing are manual; copying a skill is not extension setup.

From an SSH shell on the devbox:

```bash
bsk --version
bsk status
bsk doctor
bsk browsers
bsk session start --browser "Devbox Agent" --no-focus --json
```

Retain the returned `session_id`. With an application listening on loopback port
3001, replace `<id>` with that ID:

```bash
bsk navigate http://127.0.0.1:3001 --session <id>
bsk observe --session <id>
# Use a real element ref from observe for a suitable interaction:
bsk click @e3 --session <id>
bsk observe --session <id>
bsk screenshot --session <id> --out /tmp/devbox-browser-test.png
bsk session stop <id>
```

Choose a harmless control; `@e3` is an example, not a stable selector. Stop the
session even if the task fails. Then start a fresh Codex session and ask it to use
the repository-managed `browser-skill` to inspect your local app, interact with a
control, and save a screenshot. Confirm Codex discovers the skill and inspect the
image. Repository-managed symlinked skills can produce an automatic skill-update
warning; keep them managed by Git/Stow and verify harness discovery directly.
`bsk doctor` alone does not establish skill discovery or a successful UI
task. The skill treats page content as untrusted data, not agent instructions.

Independent BrowserSkill sessions get separate Agent Windows. They share the
same profile's cookies and login state, so separate sessions do not isolate
accounts or application backend data. Always retain each session's ID and pass
`--session` for every operation. Do not restart the shared daemon to end one task.

## Repositories, worktrees, and multiple agents

Clone projects under `~/repo/<project-name>/`. Group worktrees under
`~/repo/worktrees/<project-name>/<task>/`. Ansible creates the two root
directories but never clones your private projects.

```bash
cd ~/repo/project-a
mkdir -p ~/repo/worktrees/project-a
git worktree add \
  ~/repo/worktrees/project-a/issue-101 \
  -b fix/issue-101 main
git worktree add \
  ~/repo/worktrees/project-a/issue-102 \
  -b fix/issue-102 main

# Open one Herdr workspace per worktree in the named main session.
herdr --session main workspace create \
  --cwd ~/repo/worktrees/project-a/issue-101 --label issue-101
herdr --session main workspace create \
  --cwd ~/repo/worktrees/project-a/issue-102 --label issue-102

# Attach, run codex in each workspace root pane, and switch workspaces with
# prefix (Ctrl-a) + shift + 1..9. Detach with prefix + d and reattach later
# with the same command.
herdr --session main
```

Install dependencies in each worktree using that project's package manager.
Run frontend servers in separate Herdr panes, with distinct explicit ports:

```bash
# In issue-101, for a Vite project:
pnpm dev --host 127.0.0.1 --port 3001 --strictPort
# In issue-102:
pnpm dev --host 127.0.0.1 --port 3002 --strictPort
```

Adjust flags for the actual framework. Reserve distinct backend, database, test,
and WebSocket ports too; a frontend port alone does not isolate the backend.
Use separate Compose project names and explicit loopback port mappings when
running multiple stacks. For example, map `127.0.0.1:5433:5432` and
`127.0.0.1:5434:5432`. Docker-published ports can bypass UFW, so do not rely on
UFW to protect containers bound to `0.0.0.0`.

Chrome runs on the devbox, so `http://127.0.0.1:3001` and `:3002` reach those
servers without exposing them to the tailnet. Each Codex agent starts its own
BrowserSkill session against the intended URL. If you want to view an app on your
client browser, forward its port with SSH, for example
`ssh -N -L 127.0.0.1:3001:127.0.0.1:3001 <user>@<devbox>`.

Herdr survives client disconnects and logout; reattach with
`herdr --session main`. Pane processes do not survive a reboot or power failure,
although Herdr resumes supported agent conversations when its server restarts.
Worktree files survive; restart development servers after boot. This setup does
not automatically replay agent tasks.

## Power recovery

Configure the Geekom A5's BIOS manually while a keyboard and monitor are attached:
press Delete during power-on and find **Auto Power On**, **AC Power Loss**, or
**Restore on AC Power Loss**. Select **Always On / Power On**, rather than
Previous State, and save using the key shown by your BIOS.

Firmware menu paths vary. GEEKOM's A5 guidance places AC loss control under
Advanced → AMD CBS → FCH Common Options → Ac Power Loss Options, with
**Ac Loss Control** set to **Always On**. Related A5-series firmware exposes the
same behavior as **Power On Automatically After Power Loss** set to **S0 State**.
Some A5 units hide the Advanced menu; GEEKOM's [BIOS unlock
tool](https://service.geekompc.com/faq/bios-unlock-tool-user-guide/) is a utility
program rather than a boot-time key combination. Check the exact 7730U unit and
firmware; do not flash another model's BIOS to obtain this setting. See
[GEEKOM's A5 power-on guide](https://help.geekompc.com/hc/en-us/articles/11004517115919-Enable-Power-On-Auto-Start-Function-on-A5-5800H).

Ansible masks suspend/hibernate targets and sets logind's idle action to ignore.
The logind drop-in applies on the next reboot. Normal CPU idle states, frequency
scaling, and power-saving are retained; no performance governor is forced.
Ethernet and the home router/ONT must also recover after an outage. A UPS can
reduce abrupt shutdowns and protect work that has not reached disk.

## Updates and idempotency

From the repository, review/pull updates and rerun:

```bash
cd ~/repo/ansible
git pull --ff-only
bash run-devbox.sh
```

For installed machines, preview with `make check-devbox`. For just the new
profile's tasks:

```bash
ansible-playbook local-devbox.yml --tags devbox --check --diff --ask-become-pass
ansible-playbook local-devbox.yml --tags devbox --ask-become-pass
```

The desktop tag assumes BrowserSkill CLI was installed by the full bootstrap.
Changed graphical helpers or units restart the graphical services; finish browser
tasks before applying those updates. Unchanged units/services are not restarted.
Dotfiles sync preserves local-only runtime data and uses the existing migration
and Stow implementation. Back up before migrating legacy directory symlinks.

Shared installers generally install missing tools; they do not update every
installed binary. Mise versions and upstream `latest` packages can change, so
this is a reproducible configuration, not an immutable image. Use Ubuntu's
normal update workflow for OS, Chrome, Tailscale, and Docker packages, and the
shared tools' own update commands for versions not changed by Ansible. Schedule
reboots yourself and retest remote access after networking/browser updates.

For a BrowserSkill CLI update, finish all sessions and use the documented
supervisor update path:

```bash
systemctl --user stop devbox-browser-skill.service
BSK_AUTO_START=0 bsk update --yes --no-restart-daemon
systemctl --user start devbox-browser-skill.service
bsk doctor
```

Its foreground daemon does not auto-update itself. The repository owns the skill
and references; update them through Git and Stow. Do not run `bsk install-skill`
or force an upstream skill overwrite. A pre-existing standalone Claude BrowserSkill directory is moved to
`~/.local/state/ansible/browser-skill-claude-backup` before linking the managed
copy. Its content is preserved outside harness skill discovery. A second backup
is never overwritten; resolve that conflict explicitly if you later create
another standalone copy.

## Troubleshooting and recovery

Run service commands as the same development user that provisioned the machine:

```bash
systemctl status tailscaled.service ssh.service docker.service
systemctl --user status devbox-{display,desktop,chrome,browser-skill}.service
journalctl --user -u devbox-chrome.service -b --no-pager
journalctl --user -u devbox-display.service -b --no-pager
journalctl --user -u devbox-browser-skill.service -b --no-pager
loginctl show-user "$USER" -p Linger
sudo ufw status verbose
```

If `systemctl --user` cannot find the bus, use a fresh normal SSH login, not a
root shell or `sudo su`. Check `user@$(id -u).service` from the console. The
playbook supplies the user bus environment while provisioning.

If SSH fails, inspect `sudo sshd -t`, `sudo sshd -T`, authorized-key permissions,
Tailscale device authorization/access policy, and UFW rules from the local
console. Check that `ssh.service` is enabled and `ssh.socket` is disabled. If an
existing `sshd_config` sets authentication options before its Include directive,
resolve that configuration before operating unattended.

If the desktop is blank, inspect display/desktop logs and the VNC socket. The
socket belongs to your devbox user and exists only while its display service is
running. Confirm the numeric UID and tunnel target. Connect to the virtual
session, not Ubuntu's physical login screen. If Chrome is closed, systemd opens
it again; `systemctl --user restart devbox-chrome.service` intentionally interrupts
browser tasks. Do not delete Chrome's profile, cookies, or lock files as a first
recovery step. Avoid launching a second Chrome against the same user-data-dir.

If BrowserSkill is disconnected, inspect `bsk status`, `bsk doctor`, and the
extension popup **in the agent profile**. Match its local connection port. Check
that Chrome and the foreground daemon are running. Inspect errors before
starting another daemon or deleting runtime state. Extension permissions,
website login/CAPTCHA, and account reauthentication can still need a human.

The disk is unencrypted, so boot has no unlock prompt. If boot still stops at
the console, for example at a filesystem check or the GRUB menu, Ansible cannot
fix it remotely because networking has not started. Keep physical console access
available. A hard outage can lose unsaved application data even when all
services subsequently recover.

## Validation before removing the monitor

Repository checks:

```bash
make bootstrap-collections syntax-check lint test-dotfiles test-devbox
# On the provisioned Geekom A5:
make check-devbox
```

Check mode on a fresh machine cannot fully validate shared installers whose
binaries/configurations do not exist yet. Run it after provisioning. Some shared
shell/tool tasks report changes on every run, so a full-playbook zero-change
recap is not promised. Reapply the `devbox` tag and check that managed files and
services settle without changes. Package releases arriving between runs can
still change installation results.

The regression tests cover temporary-home directory provisioning/check mode,
public-key enrollment, Vault copy redaction, GitHub authentication gating, shared
BrowserSkill linking, and preservation of Codex authentication/session state during dotfiles sync. They do
not establish physical hardware or authenticated browser operation.

Record the following acceptance results on the actual Geekom A5:

1. Shut down cleanly, remove AC, then restore it. The machine powers on without
   touching the power button. Once this passes, test outage recovery with work
   saved and a backup available.
2. Ubuntu reaches its services without a keyboard, monitor, or disk-unlock
   prompt.
3. Tailscale reconnects after reboot; the device remains authorized.
4. From outside the home network, key-authenticated SSH works through Tailscale.
   Confirm no router port-forwarding rules are needed.
5. With no physical monitor, the display, XFCE, Chrome, and BrowserSkill services
   start. The extension reconnects to the named automation profile.
6. A fresh Codex session discovers the managed skill, opens an Agent Window,
   interacts with a local application, and saves a readable screenshot through
   BrowserSkill. Stop its test session afterward.
7. Disconnect SSH and VNC, wait, reconnect, and confirm the same Herdr workspaces
   and panes, browser windows, and BrowserSkill sessions are still present.
8. Run two Codex sessions in separate worktrees under
   `~/repo/worktrees/project-a/`, with frontend ports 3001 and 3002 and different
   BrowserSkill session IDs. Each agent reaches its own app and screenshot.
9. Test Docker/Compose networking while Tailscale and SSH are active. Confirm
   loopback-bound container ports are not reachable from another network device.
10. Reapply Ansible, verify credentials and browser data survive, then perform
    another unattended reboot and repeat the remote SSH/browser checks.

## Upstream references

- [Tailscale's Ubuntu 26.04 package instructions](https://pkgs.tailscale.com/stable/#ubuntu-resolute)
- [Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
- [TigerVNC Xvnc options](https://tigervnc.org/doc/Xvnc.html)
- [BrowserSkill installation guide](https://github.com/Tencent/BrowserSkill/blob/main/AGENT_INSTALL.md)
- [BrowserSkill profiles and sessions](https://github.com/Tencent/BrowserSkill/blob/main/docs/browser-profiles.md)
