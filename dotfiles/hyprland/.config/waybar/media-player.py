import argparse
import json
import subprocess


def playerctl(*args: str) -> str | None:
    result = subprocess.run(
        ["playerctl", "--no-messages", *args],
        capture_output=True,
        text=True,
        check=False,
        timeout=2,
    )
    return result.stdout.strip() if result.returncode == 0 else None


def select_player() -> str | None:
    statuses = playerctl(
        "--all-players", "status", "--format", "{{playerInstance}}\t{{status}}"
    )
    playing = []
    for line in (statuses or "").splitlines():
        name, _, status = line.partition("\t")
        if status == "Playing":
            playing.append(name)
    return next(
        (name for name in playing if name.partition(".")[0] == "spotify"),
        playing[0] if playing else None,
    )


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("action", nargs="?", choices=["play-pause", "previous", "next"])
    args = parser.parse_args(argv)
    player = select_player()
    if args.action:
        if player:
            playerctl("--player", player, args.action)
        return

    text = ""
    if player:
        artist = playerctl("--player", player, "metadata", "artist") or ""
        title = playerctl("--player", player, "metadata", "title") or ""
        text = " - ".join(" ".join(value.split()) for value in [artist, title] if value)
    print(json.dumps({"text": text, "tooltip": f"{player}: {text}" if text else ""}))


if __name__ == "__main__":
    main()
