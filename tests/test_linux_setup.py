import copy
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parents[1]


class LinuxSetupTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="linux-setup-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.records = self.root / "records"
        self.records.mkdir()
        config = self.root / "ansible.cfg"
        config.write_text("[defaults]\ninterpreter_python=auto_silent\n")
        self.env = {
            **os.environ,
            "ANSIBLE_CONFIG": str(config),
            "ANSIBLE_HOME": str(self.root / "ansible"),
            "ANSIBLE_LOCAL_TEMP": str(self.root / "local"),
            "ANSIBLE_REMOTE_TEMP": str(self.root / "remote"),
            "ANSIBLE_NOCOLOR": "1",
        }
        self.record_paths = {}

    def tasks(self, filename):
        source = (REPO / "tasks" / filename).read_text()
        source = source.replace("/etc/apt", str(self.root / "etc/apt"))
        source = source.replace("/tmp/cuda-keyring", str(self.root / "cuda-keyring"))
        return yaml.safe_load(source)

    def sandbox(self, tasks):
        tasks = copy.deepcopy(tasks)
        modules = {
            "ansible.builtin.apt",
            "apt",
            "ansible.builtin.deb822_repository",
            "ansible.builtin.get_url",
            "get_url",
            "ansible.builtin.systemd_service",
            "ansible.builtin.command",
            "command",
            "user",
        }
        for task in tasks:
            task.pop("become", None)
            if "block" in task:
                task["block"] = self.sandbox(task["block"])
            for module in modules & task.keys():
                arguments = task.pop(module)
                path = self.records / f"{len(self.record_paths)}.json"
                self.record_paths[task["name"]] = path
                task.setdefault("vars", {})["recorded_arguments"] = arguments
                task["ansible.builtin.copy"] = {
                    "dest": str(path),
                    "content": "{{ recorded_arguments | to_json }}",
                    "mode": "0600",
                }
        return tasks

    def play(self, tasks, variables, success=True):
        playbook = self.root / "play.yml"
        playbook.write_text(
            yaml.safe_dump(
                [
                    {
                        "hosts": "localhost",
                        "connection": "local",
                        "gather_facts": False,
                        "vars": variables,
                        "tasks": tasks,
                    }
                ],
                sort_keys=False,
            )
        )
        result = subprocess.run(
            [shutil.which("ansible-playbook"), "-i", "localhost,", str(playbook)],
            env=self.env,
            check=False,
            text=True,
            capture_output=True,
            timeout=60,
        )
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout

    def recorded(self, name):
        return json.loads(self.record_paths[name].read_text())

    def bootstrap(self, cuda=False, arguments=()):
        commands = self.root / "bin"
        commands.mkdir()
        log = self.root / "commands.jsonl"
        stub = (
            f"#!{sys.executable}\n"
            "import json, os, sys\n"
            "from pathlib import Path\n"
            "with open(os.environ['COMMAND_LOG'], 'a') as log:\n"
            "    log.write(json.dumps([Path(sys.argv[0]).name, *sys.argv[1:]]) + '\\n')\n"
            "if sys.argv[1:] == ['--version']:\n"
            "    print('sudo 1.9')\n"
        )
        for name in ["sudo", "ansible", "ansible-galaxy", "ansible-playbook"]:
            path = commands / name
            path.write_text(stub)
            path.chmod(0o755)
        env = {
            **self.env,
            "PATH": f"{commands}:/usr/bin:/bin",
            "COMMAND_LOG": str(log),
        }
        for key in ["INSTALL_CUDA_WSL", "INSTALL_OPENSSH_SERVER_WSL"]:
            env.pop(key, None)
        if cuda:
            env["INSTALL_CUDA_WSL"] = "true"
        subprocess.run(
            ["bash", str(REPO / "run-linux.sh"), *arguments],
            env=env,
            check=True,
            text=True,
            capture_output=True,
            timeout=15,
        )
        return [json.loads(line) for line in log.read_text().splitlines()]

    def test_bootstrap_refreshes_existing_ansible_and_keeps_cuda_opt_in(self):
        calls = self.bootstrap()
        self.assertEqual(calls[0], ["sudo", "apt", "update"])
        install = calls[1]
        self.assertEqual(install[:4], ["sudo", "apt", "install", "-y"])
        self.assertIn("ansible", install)
        self.assertIn("ansible-core", install)
        self.assertFalse(any("apt-add-repository" in call for call in calls))
        playbook = next(call for call in calls if call[0] == "ansible-playbook")
        self.assertIn("install_cuda_wsl=false", playbook)
        self.assertIn("install_openssh_server_wsl=false", playbook)

    def test_bootstrap_forwards_tags_and_preserves_argument_boundaries(self):
        arguments = [
            "--tags",
            "core,docker,cuda-wsl",
            "--extra-vars",
            "label=two words",
        ]
        calls = self.bootstrap(cuda=True, arguments=arguments)
        playbook = next(call for call in calls if call[0] == "ansible-playbook")
        self.assertIn("install_cuda_wsl=true", playbook)
        self.assertEqual(playbook[-len(arguments) :], arguments)

    def test_core_packages_use_current_ncurses_and_explicit_appimage_library(self):
        task = self.sandbox(self.tasks("core-setup.yml")[:1])
        for profile in ["local-linux.yml", "local-devbox.yml"]:
            with self.subTest(profile=profile):
                variables = yaml.safe_load((REPO / profile).read_text())[0]["vars"]
                self.play(task, variables)
                packages = self.recorded("Install Core Packages")["name"]
                self.assertIn("libncurses-dev", packages)
                self.assertNotIn("libncursesw5-dev", packages)
                self.assertIn("libfuse2t64", packages)
                self.assertNotIn("fuse", packages)

    def test_docker_repairs_repository_on_wsl_and_native_ubuntu(self):
        tasks = self.sandbox(self.tasks("docker-setup.yml"))
        sources = self.root / "etc/apt/sources.list.d"
        sources.mkdir(parents=True)
        for kernel in ["6.18-microsoft-standard-WSL2", "7.0.0-generic"]:
            for release in ["noble", "resolute"]:
                with self.subTest(kernel=kernel, release=release):
                    for path in self.records.iterdir():
                        path.unlink()
                    legacy = sources / "docker.list"
                    legacy.write_text(
                        "deb https://download.docker.com/linux/ubuntu jammy stable\n"
                    )
                    disabled = sources / "docker.list.distUpgrade"
                    disabled.write_text(legacy.read_text())
                    self.play(
                        tasks,
                        {
                            "ansible_facts": {
                                "kernel": kernel,
                                "distribution_release": release,
                                "user_id": "developer",
                                "service_mgr": "systemd",
                            }
                        },
                    )
                    self.assertFalse(legacy.exists())
                    self.assertTrue(disabled.exists())
                    repository = self.recorded("Configure Docker apt repository")
                    self.assertEqual(repository["suites"], release)
                    self.assertEqual(
                        repository["uris"], "https://download.docker.com/linux/ubuntu"
                    )
                    self.assertEqual(
                        repository["signed_by"],
                        str(self.root / "etc/apt/keyrings/docker.asc"),
                    )
                    self.assertEqual(repository["state"], "present")
                    packages = self.recorded(
                        "Install Docker Engine and Compose plugins"
                    )
                    self.assertEqual(packages["state"], "latest")
                    self.assertIn("docker-ce", packages["name"])
                    self.assertIn("docker-compose-plugin", packages["name"])
                    iptables = self.record_paths["Update iptables for compatibility"]
                    service = self.record_paths["Enable Docker on native Linux"]
                    self.assertEqual(iptables.exists(), "microsoft" in kernel)
                    self.assertEqual(service.exists(), "microsoft" not in kernel)

    def test_cuda_restores_disabled_repository_and_installs_only_toolkit(self):
        variables = yaml.safe_load((REPO / "local-linux.yml").read_text())[0]["vars"]
        tasks = self.sandbox(self.tasks("cuda-wsl-setup.yml"))
        sources = self.root / "etc/apt/sources.list.d"
        sources.mkdir(parents=True)
        disabled = sources / "cuda-wsl-ubuntu-x86_64.list.distUpgrade"
        disabled.write_text("old disabled source\n")
        repository = sources / "cuda-wsl-ubuntu-x86_64.list"
        for release in ["noble", "resolute"]:
            with self.subTest(release=release):
                repository.unlink(missing_ok=True)
                self.play(
                    tasks,
                    {
                        **variables,
                        "ansible_facts": {
                            "distribution": "Ubuntu",
                            "distribution_release": release,
                            "architecture": "x86_64",
                        },
                    },
                )
                source = repository.read_text()
                self.assertIn(
                    "signed-by=/usr/share/keyrings/cuda-archive-keyring.gpg", source
                )
                self.assertIn(
                    "https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/ /",
                    source,
                )
                self.assertEqual(repository.stat().st_mode & 0o777, 0o644)
                self.assertEqual(disabled.read_text(), "old disabled source\n")
                install = self.recorded("Install CUDA toolkit")
                self.assertEqual(install["name"], "cuda-toolkit-13-3")
                self.assertEqual(install["state"], "latest")

    def test_cuda_rejects_unsupported_release_before_downloads(self):
        variables = yaml.safe_load((REPO / "local-linux.yml").read_text())[0]["vars"]
        tasks = self.sandbox(self.tasks("cuda-wsl-setup.yml"))
        output = self.play(
            tasks,
            {
                **variables,
                "ansible_facts": {
                    "distribution": "Ubuntu",
                    "distribution_release": "stonking",
                    "architecture": "x86_64",
                },
            },
            success=False,
        )
        self.assertIn("does not support this WSL distribution", output)
        self.assertEqual(list(self.records.iterdir()), [])
        self.assertFalse((self.root / "etc/apt").exists())


if __name__ == "__main__":
    unittest.main()
