import os
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parents[1]
TASKS = yaml.safe_load((REPO / "tasks/dotfiles.yml").read_text())


class DotfilesTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.source = self.root / "repo/dotfiles"
        self.dotfiles = self.home / ".dotfiles"
        self.write(self.source / "pi/.pi/agent/settings.json", "managed settings\n")
        self.write(
            self.source / "pi/.pi/agent/extensions/demo/index.js", "managed code\n"
        )
        self.write(self.source / "demo/.config/demo/config.ini", "managed config\n")
        shutil.copy(REPO / "dotfiles/.sync-exclude", self.source / ".sync-exclude")
        for name in ["install", "stow"]:
            shutil.copy(REPO / "dotfiles" / name, self.source / name)
        self.env = {
            **os.environ,
            "HOME": str(self.home),
            "DOTFILES": str(self.dotfiles),
            "STOW_FOLDERS": "pi,demo",
            "ANSIBLE_HOME": str(self.root / "ansible-home"),
            "ANSIBLE_LOCAL_TEMP": str(self.root / "ansible-local"),
            "ANSIBLE_REMOTE_TEMP": str(self.root / "ansible-remote"),
        }

    def write(self, path, content):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)

    def run_command(self, argv, **kwargs):
        return subprocess.run(
            [str(arg) for arg in argv],
            env=self.env,
            check=True,
            capture_output=True,
            text=True,
            **kwargs,
        )

    def rsync(self, check=False):
        name = (
            "Preview dotfiles sync changes in check mode"
            if check
            else "Sync dotfiles from repo (idempotent)"
        )
        task = next(task for task in TASKS if task["name"] == name)
        argv = [
            arg.replace("{{ playbook_dir }}/dotfiles/", str(self.source) + "/").replace(
                "{{ lookup('env', 'HOME') }}/.dotfiles/", str(self.dotfiles) + "/"
            )
            for arg in task["ansible.builtin.command"]["argv"]
        ]
        self.dotfiles.mkdir(exist_ok=True)
        return self.run_command(argv)

    def legacy_install(self):
        self.rsync()
        self.run_command(["stow", "-R", "pi", "demo"], cwd=self.dotfiles)

    def preserve(self, dry_run=False):
        argv = [
            sys.executable,
            REPO / "utils/preserve-local-dotfiles.py",
            "--source",
            self.source,
            "--dotfiles",
            self.dotfiles,
            "--target",
            self.home,
        ]
        if dry_run:
            argv.append("--dry-run")
        return self.run_command(argv)

    def restow(self, dry_run=False):
        argv = ["zsh", self.dotfiles / "stow"]
        if dry_run:
            argv.append("--dry-run")
        return self.run_command(argv)

    def sync(self):
        self.preserve()
        self.rsync()
        self.restow()

    def add_runtime_state(self):
        paths = {
            ".pi/agent/auth.json": "fake auth\n",
            ".pi/agent/mcp-auth.json": "fake mcp auth\n",
            ".pi/agent/sessions/session.jsonl": "session fixture\n",
            ".pi/agent/.cache/cache.bin": "cache fixture\n",
            ".pi/agent/vstack/sessions/run.json": "nested session fixture\n",
            ".config/demo/cache/data.bin": "other app cache\n",
        }
        for relative, content in paths.items():
            self.write(self.home / relative, content)
        (self.home / ".pi/agent/auth.json").chmod(0o600)
        return paths

    def assert_runtime_state(self, paths):
        for relative, content in paths.items():
            path = self.home / relative
            self.assertEqual(path.read_text(), content)
            self.assertFalse(path.is_symlink(), relative)
            self.assertTrue(path.resolve().is_relative_to(self.home))
            self.assertFalse(path.resolve().is_relative_to(self.dotfiles), relative)
        self.assertEqual(
            stat.S_IMODE((self.home / ".pi/agent/auth.json").stat().st_mode), 0o600
        )

    def snapshot(self):
        result = {}
        for path in self.home.rglob("*"):
            relative = str(path.relative_to(self.home))
            if path.is_symlink():
                result[relative] = ("link", os.readlink(path))
            elif path.is_file():
                result[relative] = (
                    "file",
                    path.read_bytes(),
                    stat.S_IMODE(path.stat().st_mode),
                )
            else:
                result[relative] = ("directory",)
        return result

    def test_fresh_install_links_only_files_and_preserves_future_runtime_state(self):
        self.sync()
        for relative in [
            ".pi",
            ".pi/agent",
            ".pi/agent/extensions/demo",
            ".config/demo",
        ]:
            self.assertFalse((self.home / relative).is_symlink(), relative)
        settings = self.home / ".pi/agent/settings.json"
        self.assertTrue(settings.is_symlink())
        paths = self.add_runtime_state()
        self.write(self.source / "pi/.pi/agent/settings.json", "updated settings\n")
        self.sync()
        self.assertEqual(settings.read_text(), "updated settings\n")
        self.assert_runtime_state(paths)

    def test_migration_preserves_auth_sessions_caches_and_other_apps(self):
        self.legacy_install()
        self.assertTrue((self.home / ".pi").is_symlink())
        paths = self.add_runtime_state()
        self.write(
            self.dotfiles / "pi/.pi/agent/extensions/demo/node_modules/dep/index.js",
            "dependency\n",
        )
        self.sync()
        self.assert_runtime_state(paths)
        self.assertFalse((self.home / ".pi").is_symlink())
        self.assertTrue((self.home / ".pi/agent/settings.json").is_symlink())
        self.assertEqual(
            (
                self.dotfiles / "pi/.pi/agent/extensions/demo/node_modules/dep/index.js"
            ).read_text(),
            "dependency\n",
        )
        self.assertEqual(self.preserve().stdout, "")
        self.sync()
        self.assert_runtime_state(paths)

    def test_migration_preserves_runtime_state_even_when_old_copies_exist_in_repo(self):
        self.legacy_install()
        paths = self.add_runtime_state()
        for relative in paths:
            if relative.startswith(".pi/"):
                self.write(self.source / "pi" / relative, "stale repo runtime state\n")
        self.sync()
        self.assert_runtime_state(paths)
        self.assertFalse((self.dotfiles / "pi/.pi/agent/auth.json").exists())
        self.assertFalse((self.dotfiles / "pi/.pi/agent/sessions").exists())
        self.assertFalse((self.dotfiles / "pi/.pi/agent/.cache").exists())
        self.sync()
        self.assert_runtime_state(paths)

    def test_fresh_install_does_not_copy_ignored_runtime_state_from_repo(self):
        for relative in ["auth.json", "sessions/run.jsonl", "cache/package/index.js"]:
            self.write(
                self.source / "pi/.pi/agent" / relative, "stale repo runtime state\n"
            )
        self.sync()
        for relative in ["auth.json", "sessions", "cache"]:
            self.assertFalse((self.home / ".pi/agent" / relative).exists(), relative)
            self.assertFalse(
                (self.dotfiles / "pi/.pi/agent" / relative).exists(), relative
            )

    def test_migration_finds_nested_folded_links_in_shared_directories(self):
        (self.home / ".config").mkdir()
        self.write(self.home / ".config/unmanaged/keep.txt", "local config\n")
        self.legacy_install()
        self.assertFalse((self.home / ".config").is_symlink())
        self.assertTrue((self.home / ".config/demo").is_symlink())
        self.write(self.home / ".config/demo/cache/keep.txt", "local cache\n")
        self.sync()
        self.assertEqual(
            (self.home / ".config/demo/cache/keep.txt").read_text(), "local cache\n"
        )
        self.assertFalse((self.home / ".config/demo/cache").is_symlink())
        self.assertEqual(
            (self.home / ".config/unmanaged/keep.txt").read_text(), "local config\n"
        )

    def test_migration_dry_run_changes_nothing(self):
        self.legacy_install()
        self.add_runtime_state()
        before = self.snapshot()
        result = self.preserve(dry_run=True)
        self.assertIn("Would preserve", result.stdout)
        self.assertEqual(self.snapshot(), before)

    def test_stow_dry_run_does_not_unfold_directories(self):
        self.legacy_install()
        self.restow(dry_run=True)
        self.assertTrue((self.home / ".pi").is_symlink())
        self.assertTrue((self.home / ".config").is_symlink())

    def test_migration_moves_unmanaged_symlinks_without_following_them(self):
        self.legacy_install()
        external = self.root / "external"
        self.write(external / "keep.txt", "external content\n")
        (self.home / ".pi/agent/runtime-link").symlink_to(external)
        self.sync()
        link = self.home / ".pi/agent/runtime-link"
        self.assertTrue(link.is_symlink())
        self.assertEqual(link.resolve(), external)
        self.assertEqual((external / "keep.txt").read_text(), "external content\n")
        self.assertFalse((self.dotfiles / "pi/.pi/agent/runtime-link").exists())

    def test_unrelated_home_directory_links_are_not_replaced(self):
        self.rsync()
        external = self.root / "external"
        self.write(external / "auth.json", "external auth\n")
        (self.home / ".pi").symlink_to(external)
        result = self.preserve()
        self.assertEqual(result.stdout, "")
        self.assertEqual((self.home / ".pi").resolve(), external)
        self.assertEqual((external / "auth.json").read_text(), "external auth\n")

    def test_auth_exclusions_protect_staging_in_normal_and_check_sync(self):
        self.rsync()
        for name in ["auth.json", "mcp-auth.json"]:
            self.write(self.dotfiles / "pi/.pi/agent" / name, "local auth\n")
            self.write(self.source / "pi/.pi/agent" / name, "must not overwrite auth\n")
        self.assertNotIn("auth.json", self.rsync(check=True).stdout)
        self.rsync()
        for name in ["auth.json", "mcp-auth.json"]:
            self.assertEqual(
                (self.dotfiles / "pi/.pi/agent" / name).read_text(), "local auth\n"
            )

    def test_copy_local_still_excludes_pi_credentials_and_sessions(self):
        self.legacy_install()
        self.add_runtime_state()
        output = self.root / "copy-output"
        output.mkdir()
        self.run_command(
            [
                "make",
                "--no-print-directory",
                "copy-local",
                f"DOTFILES_SRC={output}/",
                f"DOTFILES_DEST={self.dotfiles}/",
                "DETECTED_WINDOWS_USER=",
                "WINDOWS_USER=fixture",
            ],
            cwd=REPO,
        )
        for relative in [
            "auth.json",
            "mcp-auth.json",
            "sessions",
            ".cache",
            "vstack/sessions",
        ]:
            self.assertFalse((output / "pi/.pi/agent" / relative).exists(), relative)
        self.assertTrue((output / "pi/.pi/agent/settings.json").exists())

    def test_windows_copy_preserves_runtime_state_on_first_and_repeat_sync(self):
        windows_home = self.root / "windows-home"
        target = windows_home / ".pi"
        self.write(target / "agent/auth.json", "windows auth\n")
        self.write(target / "agent/sessions/run.jsonl", "windows session\n")
        self.write(target / "agent/cache/data.bin", "windows cache\n")
        shutil.copy(
            REPO / "dotfiles/pi/.pi/.gitignore", self.source / "pi/.pi/.gitignore"
        )
        self.write(self.source / "pi/.pi/agent/auth.json", "must not copy repo auth\n")
        script = (REPO / "utils/sync-dotfiles-to-windows.sh").read_text()
        functions = script.split("validate_windows_target() {", 1)[1].split(
            '\nsync_dir "agents"', 1
        )[0]
        command = (
            'set -euo pipefail\nwindows_home="$1"\nvalidate_windows_target() {'
            + functions
            + '\nsync_dir "pi" "$2" "$windows_home/.pi"\n'
        )
        for _ in range(2):
            self.run_command(
                ["bash", "-c", command, "fixture", windows_home, self.source / "pi/.pi"]
            )
            self.assertEqual((target / "agent/auth.json").read_text(), "windows auth\n")
            self.assertEqual(
                (target / "agent/sessions/run.jsonl").read_text(), "windows session\n"
            )
            self.assertEqual(
                (target / "agent/cache/data.bin").read_text(), "windows cache\n"
            )
            self.assertEqual(
                (target / "agent/settings.json").read_text(), "managed settings\n"
            )

    def test_ansible_runs_migration_before_sync_and_respects_check_mode(self):
        self.legacy_install()
        paths = self.add_runtime_state()
        utils = self.source.parent / "utils"
        utils.mkdir()
        shutil.copy(REPO / "utils/preserve-local-dotfiles.py", utils)
        names = {
            "Ensure .dotfiles directory exists",
            "Preserve local state behind legacy directory symlinks",
            "Sync dotfiles from repo (idempotent)",
            "Preview dotfiles sync changes in check mode",
            "Make scripts executable",
            "Run stow to create symlinks",
        }
        playbook = self.source.parent / "test.yml"
        playbook.write_text(
            yaml.safe_dump(
                [
                    {
                        "hosts": "localhost",
                        "connection": "local",
                        "gather_facts": False,
                        "tasks": [task for task in TASKS if task["name"] in names],
                    }
                ],
                sort_keys=False,
            )
        )
        before = self.snapshot()
        argv = ["ansible-playbook", "-i", "localhost,", playbook]
        self.run_command(argv + ["--check"])
        self.assertEqual(self.snapshot(), before)
        self.run_command(argv)
        self.assert_runtime_state(paths)
        self.assertFalse((self.home / ".pi").is_symlink())
        self.run_command(argv)
        self.assert_runtime_state(paths)


if __name__ == "__main__":
    unittest.main()
