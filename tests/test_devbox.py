import grp
import os
import pwd
import subprocess
import tempfile
import unittest
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parents[1]


class DevboxTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="devbox-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.env = {
            **os.environ,
            "HOME": str(self.home),
            "ANSIBLE_HOME": str(self.root / "ansible"),
            "ANSIBLE_LOCAL_TEMP": str(self.root / "ansible/tmp"),
            "ANSIBLE_REMOTE_TEMP": str(self.root / "remote"),
            "ANSIBLE_NOCOLOR": "1",
        }

    def tasks(self, filename):
        return yaml.safe_load((REPO / "tasks" / filename).read_text())

    def play(self, tasks, variables=None, check=False, tags=None):
        playbook = self.root / "test.yml"
        playbook.write_text(
            yaml.safe_dump(
                [
                    {
                        "name": "Test devbox behavior in a temporary home",
                        "hosts": "localhost",
                        "connection": "local",
                        "gather_facts": False,
                        "vars": {
                            "ansible_facts": {"user_dir": str(self.home)},
                            **(variables or {}),
                        },
                        "tasks": tasks,
                    }
                ],
                sort_keys=False,
            )
        )
        argv = ["ansible-playbook", "-i", "localhost,", str(playbook), "--diff"]
        if check:
            argv.append("--check")
        if tags:
            argv += ["--tags", tags]
        return subprocess.run(
            argv, env=self.env, capture_output=True, text=True, check=True
        ).stdout

    def assert_no_changes(self, output):
        self.assertRegex(output, r"changed=0\s+unreachable=0\s+failed=0")

    def test_repository_roots_check_mode_and_repeat_apply(self):
        tasks = self.tasks("devbox-directories.yml")
        self.play(tasks, check=True)
        self.assertFalse((self.home / "repo").exists())
        self.play(tasks)
        self.assertTrue((self.home / "repo/worktrees").is_dir())
        self.assert_no_changes(self.play(tasks))
        self.assert_no_changes(self.play(tasks, check=True))
        self.assertEqual(sorted(p.name for p in self.home.iterdir()), ["repo"])

    def test_public_key_enrollment_preserves_existing_keys(self):
        # Fixture is a valid public key, never a private credential.
        public_key = (REPO / ".ssh/id_ed25519.pub").read_text().strip()
        source = self.root / "client.pub"
        source.write_text(public_key + "\n")
        ssh_dir = self.home / ".ssh"
        ssh_dir.mkdir()
        authorized = ssh_dir / "authorized_keys"
        existing = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFixture existing-client"
        authorized.write_text(existing + "\n")
        names = {
            "Ensure SSH directory exists",
            "Require a single OpenSSH public key",
            "Validate the OpenSSH public key blob",
            "Authorize the existing public key without replacing other keys",
        }
        tasks = [
            t for t in self.tasks("openssh-native-setup.yml") if t["name"] in names
        ]
        variables = {"devbox_authorized_key_file": str(source)}
        self.play(tasks, variables, check=True)
        self.assertEqual(authorized.read_text(), existing + "\n")
        self.play(tasks, variables)
        self.assertEqual(authorized.read_text().splitlines(), [existing, public_key])
        self.assertEqual(authorized.stat().st_mode & 0o777, 0o600)
        self.assertEqual(ssh_dir.stat().st_mode & 0o777, 0o700)
        self.assert_no_changes(self.play(tasks, variables))
        self.assert_no_changes(self.play(tasks, variables, check=True))

    def test_invalid_public_key_is_rejected_before_enrollment(self):
        source = self.root / "invalid.pub"
        source.write_text("ssh-ed25519 AAAA\n")
        ssh_dir = self.home / ".ssh"
        ssh_dir.mkdir()
        authorized = ssh_dir / "authorized_keys"
        existing = (REPO / ".ssh/id_ed25519.pub").read_text()
        authorized.write_text(existing)
        names = {
            "Require a single OpenSSH public key",
            "Validate the OpenSSH public key blob",
            "Authorize the existing public key without replacing other keys",
        }
        tasks = [
            t for t in self.tasks("openssh-native-setup.yml") if t["name"] in names
        ]
        for check in [False, True]:
            with self.subTest(check=check):
                with self.assertRaises(subprocess.CalledProcessError) as error:
                    self.play(
                        tasks,
                        {"devbox_authorized_key_file": str(source)},
                        check=check,
                    )
                self.assertIn(
                    "Validate the OpenSSH public key blob", error.exception.stdout
                )
                self.assertNotIn("ssh-ed25519 AAAA", error.exception.stdout)
                self.assertEqual(authorized.read_text(), existing)

    def test_ssh_validation_rejects_matching_authentication_overrides(self):
        host_key = self.root / "host-key"
        subprocess.run(
            ["ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", str(host_key)],
            check=True,
            capture_output=True,
        )
        config = self.root / "sshd_config"
        config.write_text(
            f"HostKey {host_key}\n"
            "PubkeyAuthentication yes\n"
            "PasswordAuthentication no\n"
            "KbdInteractiveAuthentication no\n"
            "AuthenticationMethods publickey\n"
            "PermitRootLogin no\n"
        )
        baseline = config.read_text()
        names = {
            "Inspect effective SSH authentication settings",
            "Require effective key-only SSH authentication",
        }
        tasks = [
            t for t in self.tasks("openssh-native-setup.yml") if t["name"] in names
        ]
        inspection = tasks[0]
        inspection["become"] = False
        inspection["ansible.builtin.command"]["argv"] = (
            "{{ ['/usr/sbin/sshd', '-T', '-f', sshd_config] + item }}"
        )
        user = pwd.getpwuid(os.getuid()).pw_name
        group = grp.getgrgid(os.getgid()).gr_name
        variables = {
            "sshd_config": str(config),
            "ansible_facts": {"user_id": user},
            "devbox_ssh_client_address": "100.100.100.100",
            "devbox_ssh_client_host": "client.example.com",
        }
        self.assert_no_changes(self.play(tasks, variables))
        for condition in [
            f"User {user}",
            f"Group {group}",
            "Address 100.100.100.100",
            "Host client.example.com",
        ]:
            with self.subTest(condition=condition):
                config.write_text(
                    baseline + f"Match {condition}\n"
                    "  PasswordAuthentication yes\n"
                    "  AuthenticationMethods password\n"
                )
                global_settings = subprocess.run(
                    ["/usr/sbin/sshd", "-T", "-f", str(config)],
                    check=True,
                    capture_output=True,
                    text=True,
                ).stdout.splitlines()
                self.assertIn("passwordauthentication no", global_settings)
                self.assertIn("authenticationmethods publickey", global_settings)
                with self.assertRaises(subprocess.CalledProcessError) as error:
                    self.play(tasks, variables)
                self.assertIn(
                    "Existing sshd configuration overrides devbox authentication",
                    error.exception.stdout,
                )

    def test_vault_copies_do_not_expose_decrypted_files_in_diffs(self):
        password_file = self.root / "vault-password"
        password_file.write_text("test-only-vault-password\n")
        self.env["ANSIBLE_VAULT_PASSWORD_FILE"] = str(password_file)
        source_dir = self.root / "source"
        (source_dir / ".ssh").mkdir(parents=True)
        private = source_dir / ".ssh/test-key"
        config = source_dir / ".ssh/config"
        secrets = ["PRIVATE-KEY-FIXTURE-NOT-A-REAL-KEY", "PRIVATE-SSH-CONFIG-FIXTURE"]
        for path, secret in zip([private, config], secrets):
            path.write_text(secret + "\n")
            subprocess.run(
                ["ansible-vault", "encrypt", str(path)],
                env=self.env,
                check=True,
                capture_output=True,
                text=True,
            )
        (source_dir / ".ssh/test-key.pub").write_text("public-key-fixture\n")
        tasks = self.tasks("ssh.yml")
        # Existing shared tasks locate SSH config using playbook_dir.
        for task in tasks:
            module = task.get("copy", task.get("stat", {}))
            for key in ["src", "path"]:
                if key in module:
                    module[key] = module[key].replace(
                        "{{ playbook_dir }}", str(source_dir)
                    )
        variables = {
            "source_key": str(private),
            "dest_key": str(self.home / ".ssh/id_ed25519"),
        }
        for check in [True, False, False, True]:
            output = self.play(tasks, variables, check=check, tags="ssh")
            for secret in secrets:
                self.assertNotIn(secret, output)
        self.assertEqual((self.home / ".ssh/id_ed25519").read_text(), secrets[0] + "\n")
        self.assertEqual((self.home / ".ssh/config").read_text(), secrets[1] + "\n")
        self.assertEqual((self.home / ".ssh/id_ed25519").stat().st_mode & 0o777, 0o600)
        self.assertTrue(private.read_bytes().startswith(b"$ANSIBLE_VAULT;"))

    def test_claude_uses_the_managed_browser_skill(self):
        skill = self.home / ".agents/skills/browser-skill"
        skill.mkdir(parents=True)
        (skill / "SKILL.md").write_text("repository-managed skill\n")
        (self.home / ".claude/skills").mkdir(parents=True)
        names = {
            "Check for a standalone Claude BrowserSkill copy",
            "Preserve a standalone Claude BrowserSkill copy before linking",
            "Find shared agent skills",
            "Link shared agent skills into Claude skills",
        }
        tasks = [t for t in self.tasks("dotfiles.yml") if t["name"] in names]
        self.play(tasks)
        target = self.home / ".claude/skills/browser-skill"
        self.assertTrue(target.is_symlink())
        self.assertEqual(target.resolve(), skill)
        (skill / "SKILL.md").write_text("updated managed skill\n")
        self.assert_no_changes(self.play(tasks))
        self.assertEqual((target / "SKILL.md").read_text(), "updated managed skill\n")

    def test_standalone_claude_skill_is_backed_up_without_losing_customizations(self):
        skill = self.home / ".agents/skills/browser-skill"
        skill.mkdir(parents=True)
        (skill / "SKILL.md").write_text("repository skill\n")
        standalone = self.home / ".claude/skills/browser-skill"
        standalone.mkdir(parents=True)
        (standalone / "SKILL.md").write_text("legacy customized skill\n")
        names = {
            "Check for a standalone Claude BrowserSkill copy",
            "Preserve a standalone Claude BrowserSkill copy before linking",
            "Find shared agent skills",
            "Link shared agent skills into Claude skills",
        }
        tasks = [t for t in self.tasks("dotfiles.yml") if t["name"] in names]
        self.play(tasks, check=True)
        self.assertFalse(standalone.is_symlink())
        self.play(tasks)
        self.assertTrue(standalone.is_symlink())
        backup = self.home / ".local/state/ansible/browser-skill-claude-backup/SKILL.md"
        self.assertEqual(backup.read_text(), "legacy customized skill\n")
        self.assertEqual((standalone / "SKILL.md").read_text(), "repository skill\n")
        self.assert_no_changes(self.play(tasks))

    def test_github_extensions_wait_for_authentication_and_install_once(self):
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        gh = bin_dir / "gh"
        gh.write_text("""#!/usr/bin/env bash
set -euo pipefail
case "$1 $2" in
  "auth status")
    if [ -f "$HOME/stale-account" ]; then
      case " $* " in *" --active "*) ;; *) exit 1 ;; esac
      case " $* " in *" --hostname github.com "*) ;; *) exit 1 ;; esac
    fi
    test -f "$HOME/authenticated"
    ;;
  "extension list") cat "$HOME/installed-extensions" 2>/dev/null || true ;;
  "extension install") printf '%s\\n' "$3" >> "$HOME/installed-extensions" ;;
  *) exit 2 ;;
esac
""")
        gh.chmod(0o755)
        self.env["PATH"] = str(bin_dir) + os.pathsep + self.env["PATH"]
        tasks = self.tasks("git-setup.yml")
        output = self.play(tasks)
        self.assertIn("Run gh auth login", output)
        installed = self.home / "installed-extensions"
        self.assertFalse(installed.exists())
        (self.home / "authenticated").touch()
        (self.home / "stale-account").touch()
        self.play(tasks)
        self.assertEqual(
            installed.read_text().splitlines(), ["dlvhdr/gh-dash", "github/gh-stack"]
        )
        self.assert_no_changes(self.play(tasks))

    def test_profile_preserves_shared_setup_and_excludes_wsl(self):
        play = yaml.safe_load((REPO / "local-devbox.yml").read_text())[0]
        imports = [t["ansible.builtin.import_tasks"] for t in play["tasks"]]
        for required in [
            "dotfiles",
            "docker-setup",
            "browser-skill-setup",
            "mise-tools-setup",
            "ai-tools",
        ]:
            self.assertEqual(imports.count(f"tasks/{required}.yml"), 1)
        for excluded in ["win32yank-setup", "cuda-wsl-setup", "openssh-wsl-setup"]:
            self.assertNotIn(f"tasks/{excluded}.yml", imports)
        bsk_tasks = (REPO / "tasks/browser-skill-setup.yml").read_text()
        self.assertNotIn("install-skill", bsk_tasks)
        docker_tasks = self.tasks("docker-setup.yml")
        legacy = next(t for t in docker_tasks if "iptables" in t["name"])
        self.assertIn("'microsoft' in", legacy["when"])

    def test_virtual_display_exposes_only_a_private_socket(self):
        script = (REPO / "files/devbox/start-display").read_text()
        self.assertIn("-rfbport -1", script)
        self.assertIn("-rfbunixmode 0600", script)
        self.assertIn("-nolisten tcp", script)
        self.assertIn("-MaxDisconnectionTime 0", script)
        unit = (REPO / "templates/devbox/devbox-display.service.j2").read_text()
        self.assertIn("RuntimeDirectoryMode=0700", unit)
        for path in (REPO / "templates/devbox").glob("*.service.j2"):
            self.assertIn("Restart=always", path.read_text())
            self.assertIn("WantedBy=default.target", path.read_text())
        chrome = (REPO / "templates/devbox/devbox-chrome.service.j2").read_text()
        self.assertNotIn("--no-sandbox", chrome)
        self.assertIn("--user-data-dir=%h/.local/share/devbox/chrome", chrome)


if __name__ == "__main__":
    unittest.main()
