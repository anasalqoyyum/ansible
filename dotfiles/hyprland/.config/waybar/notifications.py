import io
import json
import os
import select
import signal
import subprocess
import sys

ICONS = {True: "󰂠", False: "󰂜"}
FONT = "GoogleSansCode Nerd Font"

def emit(text: str, style: str, tooltip: str) -> None:
    print(
        json.dumps(
            {
                "text": f'<span font_desc="{FONT}">{text}</span>',
                "class": style,
                "tooltip": tooltip,
            },
            ensure_ascii=False,
        ),
        flush=True,
    )

def report(line: str) -> None:
    try:
        dnd = json.loads(line)["dnd"]
    except (json.JSONDecodeError, KeyError, TypeError):
        return
    if isinstance(dnd, bool):
        emit(
            ICONS[dnd],
            "dnd" if dnd else "none",
            "Do Not Disturb on" if dnd else "Do Not Disturb off",
        )

def watch() -> bool:
    """Stream Do Not Disturb to Waybar. False once Waybar has stopped reading."""
    try:
        process = subprocess.Popen(
            ["hokum", "dnd", "--json", "--watch"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except FileNotFoundError:
        return True
    try:
        watcher = process.stdout.fileno()
        poll = select.poll()
        poll.register(watcher, select.POLLIN)
        try:
            ours = sys.stdout.fileno()
        except (AttributeError, io.UnsupportedOperation):
            ours = None
        if ours is not None:
            poll.register(ours, select.POLLERR)
        while True:
            events = dict(poll.poll(1000))
            # Waybar exits without signalling its custom scripts, and a
            # watcher left behind would hold a D-Bus connection forever.
            if ours is not None and events.get(ours, 0) & select.POLLERR:
                return False
            flags = events.get(watcher, 0)
            if flags & (select.POLLERR | select.POLLNVAL):
                return True
            if not flags:
                continue
            # A closed pipe still reports what the watcher wrote before it
            # exited, then returns "" for the end of the stream.
            line = process.stdout.readline()
            if not line:
                return True
            report(line)
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)
        process.stdout.close()

def main() -> None:
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    try:
        if not watch():
            os._exit(0)
        emit(ICONS[False], "unavailable", "Hokum is not running")
    except BrokenPipeError:
        # Waybar went away while we were writing; flushing a closed pipe at
        # exit would only turn the exit status into 120.
        os._exit(0)

if __name__ == "__main__":
    main()
