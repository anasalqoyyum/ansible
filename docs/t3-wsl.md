# T3 Code on a fixed WSL port

The WSL server uses the standalone T3 binary and its official systemd user
service. It does not run through `npx`. T3's installer verifies the release
archive checksum and installs under `~/.t3/runtime/versions/<version>/`, with a
`~/.local/bin/t3` command. Each playbook run checks for the latest nightly using
`T3CODE_CHANNEL=nightly`, then reconciles the service to the installed version.
See the [upstream installation guide](https://github.com/pingdotgg/t3code/blob/main/docs/user/install.md).

## Apply the WSL configuration

Enable systemd in WSL and install/authenticate provider CLIs inside Ubuntu first.
Before migrating an existing desktop-managed backend, stop its active threads,
back up `~/.t3/userdata`, and set **Settings → Sharing & access → WSL backend**
to **Off** in the Windows desktop app. Leave the Windows local environment on.
Two T3 servers must not share the same data directory at the same time.

From this repo in WSL:

```bash
ansible-playbook local-linux.yml --tags t3code \
  -e install_t3_wsl=true --ask-become-pass
```

The task installs/reconciles `t3code.service`, enables user lingering, and writes
these entries to `~/.t3/service.env`, preserving other entries:

```dotenv
T3CODE_PORT=3775
T3CODE_HOST=127.0.0.1
T3CODE_LAN=false
```

A systemd drop-in adds the user tool PATH so Codex, Claude, and mise-managed Node
remain available. The official installer owns the generated service unit.
Existing databases, authentication, projects, threads, and the environment ID in
`~/.t3/userdata/environment-id` remain in place. Do not copy that runtime data or
pairing credentials into this repo.

The service starts when Ubuntu WSL starts. This does not add a Windows task to
start the distro at Windows login. Restart after changing the port or PATH:

```bash
systemctl --user restart t3code.service
```

## Expose WSL through Windows Tailscale

In Windows PowerShell, first confirm that Ubuntu WSL responds locally and inspect
the existing Serve routes:

```powershell
Invoke-RestMethod http://127.0.0.1:3775/.well-known/t3/environment
tailscale serve status
```

The descriptor must report Linux. Port 8443 must be unused or already point to
`http://127.0.0.1:3775`. Add the WSL route on that port:

```powershell
tailscale serve --bg --https=8443 http://127.0.0.1:3775
```

On Real, Windows T3 uses `https://real.pipefish-sirius.ts.net/` and WSL uses
`https://real.pipefish-sirius.ts.net:8443/`. Windows Tailscale terminates HTTPS for
both servers, using different ports. WSL needs no second Tailscale instance.
See the [Serve reference](https://tailscale.com/docs/reference/tailscale-cli/serve).

## Pair clients and linked environments

Run `~/.local/bin/t3 pair` in WSL and paste its `Token:` value into the desktop's
Add environment dialog with `http://localhost:3775`. Keep the managed WSL backend
off; this desktop connection points to the standalone service instead.

For `en`, create the link in **Linked environments · en**, using the WSL HTTPS
address and a fresh WSL pairing token. Full access allows it to read and control
existing WSL threads. The direct link from `en` to WSL was created on 2026-11-11.
The WSL environment ID is `bf14f5df-725f-435c-8d96-f6b34bff2a48`; its reported
label is still `Real`, derived from the distro's hostname.

## Verify

```bash
systemctl --user is-enabled t3code.service
systemctl --user is-active t3code.service
ss -ltnp 'sport = :3775'
curl -fsS http://127.0.0.1:3775/.well-known/t3/environment
```

From a tailnet machine, check the HTTPS route:

```bash
curl -fsS https://real.pipefish-sirius.ts.net:8443/.well-known/t3/environment
```

The local and HTTPS descriptors must identify the same Linux environment. The
fixed-port migration was verified with a service restart, the original Scratch
thread, and Codex, Claude, and Node version checks. Its initial binary came from
the Windows desktop's WSL runtime; the Ansible task uses the upstream standalone
installer for a repeatable setup.
