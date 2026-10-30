import importlib.util
import io
import json
import os
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

SCRIPT = (
    Path(__file__).resolve().parents[1]
    / "dotfiles/hyprland/.config/waybar/notifications.py"
)
SPEC = importlib.util.spec_from_file_location("waybar_notifications", SCRIPT)
NOTIFICATIONS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(NOTIFICATIONS)

class WaybarNotificationsTest(unittest.TestCase):
    def setUp(self):
        root = tempfile.TemporaryDirectory()
        self.addCleanup(root.cleanup)
        self.bin = Path(root.name) / "bin"
        self.bin.mkdir()
        patcher = patch.dict(os.environ, {"PATH": str(self.bin)})
        patcher.start()
        self.addCleanup(patcher.stop)

    def fake_hokum(self, lines: list[str], code: int = 0) -> None:
        quoted = " ".join(f"'{line}'" for line in lines)
        body = f"printf '%s\\n' {quoted}\n" if lines else ""
        path = self.bin / "hokum"
        path.write_text(f"#!/bin/sh\n{body}exit {code}\n")
        path.chmod(0o755)

    def fake_hokum_that_waits(self, pidfile: Path) -> None:
        path = self.bin / "hokum"
        path.write_text(
            "#!/bin/sh\n"
            'printf \'%s\\n\' \'{"dnd":false}\'\n'
            f'echo $$ > {pidfile}\n'
            "exec /bin/sleep 60\n"
        )
        path.chmod(0o755)

    def render(self) -> list[dict]:
        output = io.StringIO()
        with redirect_stdout(output):
            NOTIFICATIONS.main()
        return [json.loads(line) for line in output.getvalue().splitlines()]

    def states(self) -> list[dict]:
        cards = self.render()
        self.assertEqual(cards[-1]["class"], "unavailable")
        return cards[:-1]

    def test_do_not_disturb_states_render_with_their_own_icon(self):
        self.fake_hokum(['{"dnd":false}', '{"dnd":true}'])
        self.assertEqual(
            [(card["class"], card["tooltip"]) for card in self.states()],
            [("none", "Do Not Disturb off"), ("dnd", "Do Not Disturb on")],
        )

    def test_icons_come_from_the_nerd_font(self):
        self.fake_hokum(['{"dnd":true}'])
        self.assertEqual(
            self.states()[0]["text"],
            f'<span font_desc="GoogleSansCode Nerd Font">{NOTIFICATIONS.ICONS[True]}</span>',
        )

    def test_malformed_lines_and_non_booleans_are_skipped(self):
        self.fake_hokum(["not json", '{"dnd":"yes"}', '{"other":true}', '{"dnd":true}'])
        self.assertEqual([card["class"] for card in self.states()], ["dnd"])

    def test_missing_hokum_reports_unavailable(self):
        self.assertEqual([card["class"] for card in self.render()], ["unavailable"])

    def test_a_hokum_that_exits_reports_unavailable(self):
        self.fake_hokum([], code=1)
        self.assertEqual(
            [(card["class"], card["tooltip"]) for card in self.render()],
            [("unavailable", "Hokum is not running")],
        )

    def test_a_watcher_that_dies_mid_stream_reports_unavailable(self):
        self.fake_hokum(['{"dnd":true}'])
        self.assertEqual(
            [card["class"] for card in self.render()], ["dnd", "unavailable"]
        )

    def wait_for_death(self, pid: int) -> None:
        for _ in range(50):
            try:
                os.kill(pid, 0)
            except ProcessLookupError:
                return
            time.sleep(0.1)
        self.fail(f"process {pid} is still running")

    def test_sigterm_takes_the_watcher_down_with_it(self):
        pidfile = Path(self.bin.parent) / "hokum.pid"
        self.fake_hokum_that_waits(pidfile)
        process = subprocess.Popen(
            [sys.executable, str(SCRIPT)],
            env={**os.environ, "PATH": str(self.bin)},
            stdout=subprocess.PIPE,
            text=True,
        )
        self.addCleanup(process.kill)
        self.assertEqual(json.loads(process.stdout.readline())["class"], "none")
        watcher = int(pidfile.read_text())

        process.send_signal(signal.SIGTERM)
        self.assertEqual(process.wait(timeout=10), 0)
        process.stdout.close()
        self.wait_for_death(watcher)

    def test_closed_output_takes_the_watcher_down_with_it(self):
        pidfile = Path(self.bin.parent) / "hokum.pid"
        self.fake_hokum_that_waits(pidfile)
        process = subprocess.Popen(
            [sys.executable, str(SCRIPT)],
            env={**os.environ, "PATH": str(self.bin)},
            stdout=subprocess.PIPE,
            text=True,
        )
        self.addCleanup(process.kill)
        self.assertEqual(json.loads(process.stdout.readline())["class"], "none")
        watcher = int(pidfile.read_text())

        # Waybar exits without signalling its custom scripts.
        process.stdout.close()
        self.assertEqual(process.wait(timeout=10), 0)
        self.wait_for_death(watcher)

if __name__ == "__main__":
    unittest.main()
