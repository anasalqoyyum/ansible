import importlib.util
import io
import json
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT = (
    Path(__file__).resolve().parents[1]
    / "dotfiles/hyprland/.config/waybar/media-player.py"
)
SPEC = importlib.util.spec_from_file_location("waybar_media", SCRIPT)
MEDIA = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MEDIA)


class WaybarMediaTest(unittest.TestCase):
    def test_browser_cannot_displace_playing_spotify(self):
        with patch.object(
            MEDIA,
            "playerctl",
            return_value="chromium.instance1\tPlaying\nspotify\tPlaying",
        ):
            self.assertEqual(MEDIA.select_player(), "spotify")

    def test_fallback_and_spotify_recovery_follow_playback_status(self):
        statuses = [
            "spotify\tPaused\nchromium.instance1\tPlaying",
            "chromium.instance1\tPlaying\nspotify\tPlaying",
            "chromium.instance1\tPaused\nspotify\tPlaying",
        ]
        with patch.object(MEDIA, "playerctl", side_effect=statuses):
            self.assertEqual(MEDIA.select_player(), "chromium.instance1")
            self.assertEqual(MEDIA.select_player(), "spotify")
            self.assertEqual(MEDIA.select_player(), "spotify")

    def test_spotify_instance_has_priority(self):
        with patch.object(
            MEDIA,
            "playerctl",
            return_value="firefox.instance1\tPlaying\nspotify.instance2\tPlaying",
        ):
            self.assertEqual(MEDIA.select_player(), "spotify.instance2")

    def test_no_playing_player_hides_media(self):
        for statuses in [None, "", "spotify\tPaused\nchromium.instance1\tStopped"]:
            with (
                self.subTest(statuses=statuses),
                patch.object(MEDIA, "playerctl", return_value=statuses),
                patch("sys.stdout", new_callable=io.StringIO) as output,
            ):
                MEDIA.main([])
                self.assertEqual(json.loads(output.getvalue())["text"], "")

    def test_metadata_handles_quotes_markup_and_line_breaks(self):
        with (
            patch.object(
                MEDIA,
                "playerctl",
                side_effect=["spotify\tPlaying", 'Artist & "guest"', "Title\n<live>"],
            ),
            patch("sys.stdout", new_callable=io.StringIO) as output,
        ):
            MEDIA.main([])
            result = json.loads(output.getvalue())
            self.assertEqual(result["text"], 'Artist & "guest" - Title <live>')
            self.assertEqual(
                result["tooltip"], 'spotify: Artist & "guest" - Title <live>'
            )

    def test_player_disappearing_during_metadata_lookup_hides_media(self):
        with (
            patch.object(
                MEDIA, "playerctl", side_effect=["spotify\tPlaying", None, None]
            ),
            patch("sys.stdout", new_callable=io.StringIO) as output,
        ):
            MEDIA.main([])
            self.assertEqual(json.loads(output.getvalue())["text"], "")

    def test_controls_target_the_prioritized_player(self):
        for action in ["play-pause", "previous", "next"]:
            with (
                self.subTest(action=action),
                patch.object(
                    MEDIA,
                    "playerctl",
                    side_effect=["chromium.instance1\tPlaying\nspotify\tPlaying", ""],
                ) as command,
            ):
                MEDIA.main([action])
                command.assert_called_with("--player", "spotify", action)


if __name__ == "__main__":
    unittest.main()
