import importlib.machinery
import importlib.util
import io
import json
import os
import subprocess
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch

SERVICE = "org.freedesktop.Notifications"

SCRIPT = (
    Path(__file__).resolve().parents[1]
    / "dotfiles/hyprland/.config/hypr/notification-history"
)
SPEC = importlib.util.spec_from_file_location(
    "notification_history",
    SCRIPT,
    loader=importlib.machinery.SourceFileLoader("notification_history", str(SCRIPT)),
)
HISTORY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(HISTORY)

def notify_call(
    app="Slack",
    summary="[eng] in #general",
    body="deploy finished",
    replaces=0,
    hints=None,
    cookie=9,
    sender=":1.500",
    daemon=":1.900",
):
    payload = [
        app,
        replaces,
        "",
        summary,
        body,
        [],
        hints if hints is not None else {"urgency": {"type": "y", "data": 1}},
        -1,
    ]
    return json.dumps(
        {
            "type": "method_call",
            "cookie": cookie,
            "sender": sender,
            "destination": daemon,
            "member": "Notify",
            "interface": "org.freedesktop.Notifications",
            "path": "/org/freedesktop/Notifications",
            "payload": {"type": "susssasa{sv}i", "data": payload},
        }
    )

def notify_reply(cookie=9, identifier=42, caller=":1.500", sender=":1.900"):
    return json.dumps(
        {
            "type": "method_return",
            "reply_cookie": cookie,
            "destination": caller,
            "sender": sender,
            "payload": {"type": "u", "data": [identifier]},
        }
    )

class NotificationHistoryTest(unittest.TestCase):
    def setUp(self):
        root = tempfile.TemporaryDirectory()
        self.addCleanup(root.cleanup)
        self.root = Path(root.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.env = patch.dict(
            os.environ,
            {
                "XDG_STATE_HOME": str(self.root / "state"),
                "PATH": f"{self.bin}:{os.environ['PATH']}",
            },
        )
        self.env.start()
        self.addCleanup(self.env.stop)
        bus = patch.object(HISTORY, "BUS_ID", "bus")
        bus.start()
        self.addCleanup(bus.stop)
        self.log = self.root / "state/hokum-history/log.jsonl"
        self.forget()
        self.addCleanup(self.forget)

    def forget(self):
        HISTORY.ORPHAN_IDS.clear()

    def records(self):
        return HISTORY.load()

    def deliver(self, line):
        """What the recorder does with one bus message."""
        if json.loads(line).get("type") == "method_return":
            HISTORY.on_reply(line)
        else:
            HISTORY.on_call(line)

    def command(self, name, body):
        path = self.bin / name
        path.write_text(f"#!/bin/sh\nset -eu\n{body}\n")
        path.chmod(0o755)

    def test_a_notify_call_becomes_a_record(self):
        entry = HISTORY.parse(notify_call())
        self.assertEqual(entry["app"], "Slack")
        self.assertEqual(entry["summary"], "[eng] in #general")
        self.assertEqual(entry["body"], "deploy finished")
        self.assertEqual(entry["replaces"], 0)
        self.assertIsNotNone(entry["time"])

    def test_other_messages_are_ignored(self):
        for line in [
            notify_reply(),
            json.dumps({"type": "method_call", "member": "GetCapabilities"}),
            json.dumps({"type": "signal", "member": "Notify"}),
            "not json",
            "",
        ]:
            with self.subTest(line=line):
                self.assertIsNone(HISTORY.parse(line))

    def test_volume_and_brightness_cards_stay_out_of_the_log(self):
        for hint in ["x-dunst-stack-tag", "x-canonical-private-synchronous"]:
            with self.subTest(hint=hint):
                self.assertIsNone(
                    HISTORY.parse(notify_call(hints={hint: {"type": "s", "data": "vol"}}))
                )

    def test_multiline_bodies_survive_the_bus_format(self):
        entry = HISTORY.parse(notify_call(body='line one\nline two\ttabbed "quoted" \\'))
        self.assertEqual(entry["body"], 'line one\nline two\ttabbed "quoted" \\')

    def test_the_newest_records_are_kept(self):
        for index in range(HISTORY.LIMIT + 20):
            self.deliver(notify_call(summary=f"note {index}"))
        records = self.records()
        self.assertEqual(len(records), HISTORY.LIMIT)
        self.assertEqual(records[-1]["summary"], f"note {HISTORY.LIMIT + 19}")
        self.assertEqual(records[0]["summary"], "note 20")

    def test_the_daemons_reply_gives_a_card_its_id(self):
        self.deliver(notify_call(summary="Downloading", cookie=9))
        self.deliver(notify_reply(cookie=9, identifier=42))
        self.assertEqual(self.records()[0]["id"], 42)

    def test_a_reply_from_another_caller_is_not_matched(self):
        self.deliver(notify_call(summary="Downloading", cookie=9, sender=":1.500"))
        self.deliver(notify_reply(cookie=9, identifier=42, caller=":1.501"))
        self.assertIsNone(self.records()[0]["id"])

    def test_an_update_rewrites_the_row_it_names_and_leaves_others_alone(self):
        self.deliver(notify_call(summary="Card A", cookie=1))
        self.deliver(notify_reply(cookie=1, identifier=41))
        self.deliver(notify_call(summary="Card B", cookie=2))
        self.deliver(notify_reply(cookie=2, identifier=42))
        self.deliver(notify_call(summary="Card A updated", replaces=41, cookie=3))
        self.deliver(notify_reply(cookie=3, identifier=43))
        self.assertEqual(
            [record["summary"] for record in self.records()],
            ["Card B", "Card A updated"],
        )

    def test_ids_from_an_earlier_daemon_are_not_reused(self):
        self.deliver(notify_call(summary="Before restart", cookie=1))
        self.deliver(notify_reply(cookie=1, identifier=5))
        self.deliver(
            notify_call(summary="After restart", replaces=5, cookie=2, daemon=":1.901")
        )
        self.deliver(notify_reply(cookie=2, identifier=5, sender=":1.901"))
        self.assertEqual(
            [record["summary"] for record in self.records()],
            ["Before restart", "After restart"],
        )

    def test_a_reused_daemon_name_on_another_bus_is_another_generation(self):
        self.deliver(notify_call(summary="Old session", cookie=1))
        self.deliver(notify_reply(cookie=1, identifier=5))
        with patch.object(HISTORY, "BUS_ID", "another-bus"):
            self.deliver(notify_call(summary="New session", replaces=5, cookie=2))
        self.assertEqual(
            [record["summary"] for record in self.records()],
            ["Old session", "New session"],
        )

    def test_an_id_that_arrives_after_its_card_was_replaced_cleans_up(self):
        self.deliver(notify_call(summary="Card A", cookie=1))
        self.deliver(notify_call(summary="Card B", replaces=41, cookie=2))
        self.deliver(notify_reply(cookie=1, identifier=41))
        self.assertEqual([record["summary"] for record in self.records()], ["Card B"])

    def test_the_newest_replacement_wins_when_replies_come_back_out_of_order(self):
        self.deliver(notify_call(summary="A", cookie=1))
        self.deliver(notify_call(summary="B", replaces=41, cookie=2))
        self.deliver(notify_call(summary="C", replaces=41, cookie=3))
        self.deliver(notify_reply(cookie=1, identifier=41))
        self.deliver(notify_reply(cookie=3, identifier=41))
        self.deliver(notify_reply(cookie=2, identifier=41))
        self.assertEqual([record["summary"] for record in self.records()], ["C"])

    def test_a_call_to_the_well_known_name_never_replaces_another_card(self):
        self.deliver(notify_call(summary="By name", cookie=1, daemon=SERVICE))
        self.deliver(notify_reply(cookie=1, identifier=41))
        self.deliver(notify_call(summary="By name again", replaces=41, cookie=2))
        self.assertEqual(
            [record["summary"] for record in self.records()],
            ["By name", "By name again"],
        )

    def test_an_unresolved_card_cannot_be_replaced_across_daemons(self):
        # Daemon X answered a call addressed to the well-known name, then Y took
        # the name and handed out the same id. Neither may delete the other.
        self.deliver(notify_call(summary="From X", cookie=1, daemon=SERVICE))
        self.deliver(notify_reply(cookie=1, identifier=7, sender=":1.900"))
        self.deliver(notify_call(summary="From Y", cookie=2, daemon=":1.901"))
        self.deliver(notify_reply(cookie=2, identifier=7, sender=":1.901"))
        self.deliver(notify_call(summary="Y updates", replaces=7, cookie=3, daemon=":1.901"))
        self.assertEqual(
            [record["summary"] for record in self.records()],
            ["From X", "Y updates"],
        )

    def test_a_reply_read_before_its_call_still_names_the_card(self):
        self.deliver(notify_reply(cookie=9, identifier=42))
        self.deliver(notify_call(summary="Racing", cookie=9))
        self.assertEqual(self.records()[0]["id"], 42)

    def test_an_update_for_an_unknown_card_is_recorded_on_its_own(self):
        self.deliver(notify_call(summary="Orphan", replaces=7))
        self.assertEqual([record["summary"] for record in self.records()], ["Orphan"])

    def test_the_log_is_private_to_the_user(self):
        self.deliver(notify_call())
        self.assertEqual(self.log.stat().st_mode & 0o777, 0o600)
        self.assertEqual(self.log.parent.stat().st_mode & 0o777, 0o700)

    def test_show_lists_newest_first_and_copies_the_whole_notification(self):
        self.deliver(notify_call(summary="Older", cookie=1))
        self.deliver(notify_call(app="Spotify", summary="Newer", cookie=2))
        listed = self.root / "listed"
        self.command("fuzzel", f'cat > {listed}\nhead -1 {listed}')
        copied = self.root / "copied"
        self.command("wl-copy", f"cat > {copied}")

        with redirect_stdout(io.StringIO()):
            self.assertEqual(HISTORY.main(["show"]), 0)

        lines = listed.read_text().splitlines()
        self.assertEqual(len(lines), 2)
        self.assertIn("Newer", lines[0])
        self.assertIn("Older", lines[1])
        self.assertIn("Newer", copied.read_text())
        self.assertIn("Spotify", copied.read_text())
        self.assertIn("deploy finished", copied.read_text())

    def test_an_empty_log_still_answers_the_click(self):
        listed = self.root / "listed"
        self.command("fuzzel", f'cat > {listed}')
        self.command("wl-copy", "cat > /dev/null")

        self.assertEqual(HISTORY.main(["show"]), 0)
        self.assertEqual(listed.read_text().strip(), "No notifications yet")

    def test_cancelling_the_picker_copies_nothing(self):
        self.deliver(notify_call())
        copied = self.root / "copied"
        self.command("fuzzel", "cat > /dev/null\nexit 1")
        self.command("wl-copy", f"cat > {copied}")

        self.assertEqual(HISTORY.main(["show"]), 0)
        self.assertFalse(copied.exists())

    def test_a_missing_fuzzel_is_reported(self):
        stderr = io.StringIO()
        with (
            patch.dict(os.environ, {"PATH": str(self.root / "empty")}),
            patch("sys.stderr", stderr),
        ):
            self.assertEqual(HISTORY.main(["show"]), 1)
        self.assertIn("fuzzel is not installed", stderr.getvalue())

    def test_unknown_arguments_print_usage(self):
        with redirect_stdout(io.StringIO()), patch("sys.stderr", io.StringIO()) as stderr:
            self.assertEqual(HISTORY.main([]), 2)
        self.assertIn("usage", stderr.getvalue())

if __name__ == "__main__":
    unittest.main()
