import io
import json
import shutil
import subprocess
import tarfile
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parents[1]


class ToolUpgradeTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="tool-upgrade-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.bin = self.home / ".local/bin"
        self.bin.mkdir(parents=True)
        self.payloads = {}
        payloads = self.payloads

        class Handler(BaseHTTPRequestHandler):
            def respond(self, body):
                payload = payloads[self.path]
                data = (
                    payload
                    if isinstance(payload, bytes)
                    else json.dumps(payload).encode()
                )
                self.send_response(200)
                self.send_header("Content-Length", str(len(data)))
                self.send_header(
                    "Content-Type",
                    "application/json"
                    if isinstance(payload, dict)
                    else "application/octet-stream",
                )
                self.end_headers()
                if body:
                    self.wfile.write(data)

            def do_GET(self):
                self.respond(True)

            def do_HEAD(self):
                self.respond(False)

            def log_message(self, *args):
                pass

        server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(server.server_close)
        self.addCleanup(thread.join)
        self.addCleanup(server.shutdown)
        self.url = f"http://127.0.0.1:{server.server_port}"
        self.ansible = shutil.which("ansible-playbook")
        config = self.root / "ansible.cfg"
        config.write_text("[defaults]\ninterpreter_python=auto_silent\n")
        self.env = {
            "HOME": str(self.home),
            "PATH": str(self.bin) + ":/usr/bin:/bin",
            "LANG": "C.UTF-8",
            "ANSIBLE_CONFIG": str(config),
            "ANSIBLE_HOME": str(self.root / "ansible"),
            "ANSIBLE_LOCAL_TEMP": str(self.root / "ansible/tmp"),
            "ANSIBLE_REMOTE_TEMP": str(self.root / "remote"),
            "ANSIBLE_NOCOLOR": "1",
            "ANSIBLE_NOCOWS": "1",
            "XDG_CONFIG_HOME": str(self.home / ".config"),
            "XDG_CACHE_HOME": str(self.home / ".cache"),
            "XDG_DATA_HOME": str(self.home / ".local/share"),
            "XDG_STATE_HOME": str(self.home / ".local/state"),
            "CARGO_HOME": str(self.home / ".cargo"),
            "RUSTUP_HOME": str(self.home / ".rustup"),
            "BUN_INSTALL": str(self.home / ".bun"),
        }

    def tasks(self, filename):
        source = (REPO / "tasks" / filename).read_text()
        source = source.replace("/tmp/", str(self.root) + "/")
        source = source.replace("/usr/local/bin", str(self.bin))
        tasks = yaml.safe_load(source)
        for task in tasks:
            task.pop("become", None)
        return tasks

    def play(self, tasks, tags=None, check=False):
        path = self.root / "test.yml"
        path.write_text(
            yaml.safe_dump(
                [
                    {
                        "hosts": "localhost",
                        "connection": "local",
                        "gather_facts": False,
                        "vars": {
                            "ansible_facts": {
                                "env": {
                                    "HOME": str(self.home),
                                    "PATH": self.env["PATH"],
                                }
                            }
                        },
                        "tasks": tasks,
                    }
                ],
                sort_keys=False,
            )
        )
        command = [self.ansible, "-i", "localhost,", str(path)]
        if tags:
            command += ["--tags", tags]
        if check:
            command.append("--check")
        result = subprocess.run(
            command, env=self.env, text=True, capture_output=True, check=False
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def binary(self, version):
        return f"#!/bin/sh\nprintf '%s\\n' '{version}'\n".encode()

    def version(self, path):
        return subprocess.check_output(
            [str(path), "--version"], env=self.env, text=True
        ).strip()

    def archive(self, name, version):
        data = io.BytesIO()
        with tarfile.open(fileobj=data, mode="w:gz") as archive:
            binary = self.binary(version)
            entry = tarfile.TarInfo(name)
            entry.size = len(binary)
            entry.mode = 0o755
            archive.addfile(entry, io.BytesIO(binary))
        return data.getvalue()

    def linux_releases(self, version):
        for name, repo, asset in [
            ("fzf", "junegunn/fzf", f"fzf-{version}-linux_amd64.tar.gz"),
            (
                "lazygit",
                "jesseduffield/lazygit",
                f"lazygit_{version}_Linux_x86_64.tar.gz",
            ),
            ("diff-so-fancy", "so-fancy/diff-so-fancy", "diff-so-fancy"),
        ]:
            self.payloads[f"/repos/{repo}/releases/latest"] = {
                "tag_name": f"v{version}"
            }
            self.payloads[f"/{repo}/releases/latest/download/{asset}"] = (
                self.binary(version)
                if name == "diff-so-fancy"
                else self.archive(name, version)
            )
        for repo, asset in [
            ("neovim/neovim", "nvim-linux-x86_64.appimage"),
            ("kiyoon/tmux-appimage", "tmux.appimage"),
        ]:
            self.payloads[f"/{repo}/releases/latest/download/{asset}"] = self.binary(
                version
            )

    def test_linux_tools_upgrade_and_respect_tags_and_check_mode(self):
        tasks = self.tasks("linux-tools-setup.yml")
        for task in tasks:
            for module in ["get_url", "unarchive", "uri"]:
                if module in task:
                    task[module]["url" if module != "unarchive" else "src"] = (
                        task[module]["url" if module != "unarchive" else "src"]
                        .replace("https://api.github.com", self.url)
                        .replace("https://github.com", self.url)
                    )
        self.linux_releases("1.0.0")
        self.play(tasks, check=True)
        self.assertEqual(list(self.bin.iterdir()), [])
        self.play(tasks)
        tools = ["nvim", "tmux", "fzf", "lazygit", "diff-so-fancy"]
        self.assertEqual(
            [self.version(self.bin / tool) for tool in tools], ["1.0.0"] * 5
        )
        self.linux_releases("2.0.0")
        self.play(tasks, tags="lazygit")
        self.assertEqual(self.version(self.bin / "lazygit"), "2.0.0")
        self.assertEqual(self.version(self.bin / "diff-so-fancy"), "1.0.0")
        self.play(tasks, tags="neovim,tmux,fzf,diff-so-fancy")
        self.assertEqual(
            [self.version(self.bin / tool) for tool in tools], ["2.0.0"] * 5
        )
        self.assertRegex(self.play(tasks), r"changed=0\s+unreachable=0\s+failed=0")
        self.linux_releases("3.0.0")
        self.play(tasks, check=True)
        self.assertEqual(
            [self.version(self.bin / tool) for tool in tools], ["2.0.0"] * 5
        )

    def installer(self, path, tool, version):
        binary = self.binary(version).decode()
        self.payloads[path] = (
            f"#!/bin/sh\nset -eu\n"
            f'mkdir -p "$HOME/{Path(tool).parent}"\n'
            f"cat > \"$HOME/{tool}\" <<'BINARY'\n{binary}BINARY\n"
            f'chmod +x "$HOME/{tool}"\n'
        ).encode()

    def test_native_installers_refresh_scripts_and_existing_binaries(self):
        tasks = []
        installers = {}
        for filename, tool in [
            ("herdr-setup.yml", ".local/bin/herdr"),
            ("mise.yml", ".local/bin/mise"),
            ("browser-skill-setup.yml", ".local/bin/bsk"),
            ("rust-tools-setup.yml", ".cargo/bin/cargo-binstall"),
        ]:
            selected = self.tasks(filename)
            if filename == "rust-tools-setup.yml":
                selected = selected[:2]
            tasks.extend(selected)
            installers["/" + filename] = tool
            for task in selected:
                for child in task.get("block", [task]):
                    if "ansible.builtin.get_url" in child:
                        child["ansible.builtin.get_url"]["url"] = (
                            self.url + "/" + filename
                        )
        ai = self.tasks("ai-tools.yml")[:4]
        for task in ai:
            if "ansible.builtin.get_url" in task:
                name = "claude" if "Claude" in task["name"] else "codex"
                task["ansible.builtin.get_url"]["url"] = self.url + "/" + name
                installers["/" + name] = ".local/bin/" + name
        tasks.extend(ai)
        for version in ["1.0.0", "2.0.0"]:
            for path, tool in installers.items():
                self.installer(path, tool, version)
            if version == "1.0.0":
                self.play(tasks, check=True)
                self.assertTrue(
                    all(not (self.home / tool).exists() for tool in installers.values())
                )
            self.play(tasks)
            self.assertEqual(
                [self.version(self.home / tool) for tool in installers.values()],
                [version] * len(installers),
            )
        for path, tool in installers.items():
            self.installer(path, tool, "3.0.0")
        self.play(tasks, check=True)
        self.assertEqual(
            [self.version(self.home / tool) for tool in installers.values()],
            ["2.0.0"] * len(installers),
        )

    def test_mise_upgrades_installed_tools_without_bumping_or_pruning(self):
        mise = self.bin / "mise"
        mise.write_text("""#!/bin/sh
set -eu
case "$*" in
  "install --dry-run-code") test -f "$HOME/runtime" ;;
  "install --yes") cp "$HOME/available-runtime" "$HOME/runtime" ;;
  "upgrade --dry-run-code") cmp -s "$HOME/available-runtime" "$HOME/runtime" ;;
  "upgrade --yes --no-prune") cp "$HOME/available-runtime" "$HOME/runtime" ;;
  *) exit 2 ;;
esac
""")
        mise.chmod(0o755)
        available = self.home / "available-runtime"
        available.write_text("1.0.0")
        tasks = self.tasks("mise-tools-setup.yml")
        self.play(tasks)
        self.assertEqual((self.home / "runtime").read_text(), "1.0.0")
        available.write_text("1.1.0")
        self.play(tasks, check=True)
        self.assertEqual((self.home / "runtime").read_text(), "1.0.0")
        self.play(tasks)
        self.assertEqual((self.home / "runtime").read_text(), "1.1.0")
        self.assertRegex(self.play(tasks), r"changed=0\s+unreachable=0\s+failed=0")

    def test_pi_and_opencode_update_when_already_installed(self):
        tasks = self.tasks("ai-tools.yml")[4:]
        for task in tasks:
            for child in [task] + task.get("block", []):
                if "ansible.builtin.shell" in child:
                    child["ansible.builtin.shell"] = (
                        child["ansible.builtin.shell"]
                        .replace("https://pi.dev/install.sh", self.url + "/pi")
                        .replace("https://opencode.ai/install", self.url + "/opencode")
                    )
        pi = self.bin / "pi"
        pi.write_text("#!/bin/sh\nexit 127\n")
        pi.chmod(0o755)
        pi_source = """#!/bin/sh
set -eu
if [ "$1" = update ]; then
  cp "$HOME/available-pi" "$HOME/pi-version"
else
  cat "$HOME/pi-version"
fi
"""
        self.payloads["/pi"] = (
            f"#!/bin/sh\ncat > '{pi}' <<'BINARY'\n{pi_source}BINARY\n"
            f'chmod +x \'{pi}\'\ncp "$HOME/available-pi" "$HOME/pi-version"\n'
        ).encode()
        for version in ["1.0.0", "2.0.0"]:
            (self.home / "available-pi").write_text(version)
            self.installer("/opencode", ".opencode/bin/opencode", version)
            self.play(tasks)
            self.assertEqual(self.version(pi), version)
            self.assertEqual(self.version(self.bin / "opencode"), version)
        (self.home / "available-pi").write_text("3.0.0")
        self.installer("/opencode", ".opencode/bin/opencode", "3.0.0")
        self.play(tasks, check=True)
        self.assertEqual(self.version(pi), "2.0.0")
        self.assertEqual(self.version(self.bin / "opencode"), "2.0.0")

    def test_rust_tools_do_not_skip_existing_binaries(self):
        cargo_bin = self.home / ".cargo/bin"
        cargo_bin.mkdir(parents=True)
        installer = """#!/bin/sh
set -eu
case "$0" in
  *rustup)
    case "$1 ${2:-}" in
      "toolchain install"|"component list") exit 0 ;;
      "component add") name=rust-analyzer ;;
      update*) name=rustc ;;
      *) exit 2 ;;
    esac ;;
  *)
    [ "$1" != install ] || shift
    while [ "${1#--}" != "$1" ]; do shift; done
    case "$1" in
      typst-cli) name=typst ;;
      usage-cli) name=usage ;;
      ripgrep) name=rg ;;
      fd-find) name=fd ;;
      yazi-build) name=yazi ;;
      tree-sitter-cli) name=tree-sitter ;;
      *) name="$1" ;;
    esac ;;
esac
version=$(cat "$HOME/available-rust")
printf '#!/bin/sh\necho %s\n' "$version" > "$HOME/.cargo/bin/$name"
chmod +x "$HOME/.cargo/bin/$name"
"""
        for name in ["cargo-binstall", "cargo", "rustup"]:
            path = cargo_bin / name
            path.write_text(installer)
            path.chmod(0o755)
        tasks = self.tasks("rust-tools-setup.yml")[2:]
        tasks += [self.tasks("rust-setup.yml")[-1]]
        names = [
            "eza",
            "typst",
            "just",
            "usage",
            "zoxide",
            "rg",
            "fd",
            "bat",
            "yazi",
            "xh",
            "tree-sitter",
            "rust-analyzer",
            "rustc",
        ]
        for version in ["1.0.0", "2.0.0"]:
            (self.home / "available-rust").write_text(version)
            self.play(tasks)
            self.assertEqual(
                [self.version(cargo_bin / name) for name in names],
                [version] * len(names),
            )
        (self.home / "available-rust").write_text("3.0.0")
        self.play(tasks, check=True)
        self.assertEqual(
            [self.version(cargo_bin / name) for name in names], ["2.0.0"] * len(names)
        )

    def test_homebrew_upgrades_keep_adoption_out_of_upgrade_options(self):
        tasks = self.tasks("core-brew-setup.yml")
        casks = {}
        for task in tasks:
            if "community.general.homebrew" in task:
                self.assertEqual(task["community.general.homebrew"]["state"], "latest")
            if "community.general.homebrew_cask" in task:
                module = task["community.general.homebrew_cask"]
                for name in module["name"]:
                    casks.setdefault(name, []).append(module)
        for name, modules in casks.items():
            with self.subTest(cask=name):
                self.assertEqual(modules[0]["install_options"], ["adopt"])
                self.assertEqual(modules[1]["state"], "latest")
                self.assertTrue(modules[1]["greedy"])
                self.assertNotIn("install_options", modules[1])


if __name__ == "__main__":
    unittest.main()
