"""Merge the declared qBittorrent settings into its INI file.

qBittorrent keeps preferences and UI state (window geometry, column
layouts) together in ~/.config/qBittorrent/qBittorrent.ini, and rewrites
the whole file when it quits or preferences change. So the file stays
app-owned, and only the declared keys are set in place: other lines are
kept as they are.

A running qBittorrent would overwrite the edit on quit, so it's stopped
first (SIGTERM, which it treats as a clean shutdown, skipping the
"active torrents" exit prompt) and reopened afterwards. Nothing happens
when every declared key already matches.

Usage: qbittorrent-apply [--dry-run] <declared.json>
The JSON maps INI section → { key → value }, keys written as qBittorrent
writes them (e.g. `Session\\GlobalMaxRatio` under `BitTorrent`).
"""

import json
import os
import re
import subprocess
import sys
import time

INI = os.path.expanduser("~/.config/qBittorrent/qBittorrent.ini")
BUNDLE_ID = "org.qbittorrent.qBittorrent"
PROCESS = "qbittorrent.app/Contents/MacOS/"

SECTION = re.compile(r"^\[(.+)\]\s*$")


def read_lines():
    try:
        with open(INI) as f:
            return f.read().splitlines()
    except FileNotFoundError:
        return []


def current_values(lines):
    values, section = {}, None
    for line in lines:
        m = SECTION.match(line)
        if m:
            section = m.group(1)
        elif section and "=" in line:
            key, value = line.split("=", 1)
            values[(section, key)] = value
    return values


def merge(lines, declared):
    """Return `lines` with each declared key set, adding sections as needed."""
    pending = {s: dict(keys) for s, keys in declared.items()}
    out, section = [], None

    def flush(section):
        # Keys this section still lacks go at its end, before any blank line.
        rest = pending.pop(section, {})
        if rest:
            trailing = []
            while out and out[-1] == "":
                trailing.append(out.pop())
            out.extend(f"{k}={v}" for k, v in rest.items())
            out.extend(trailing)

    for line in lines:
        m = SECTION.match(line)
        if m:
            flush(section)
            section = m.group(1)
        elif section in pending and "=" in line:
            key = line.split("=", 1)[0]
            if key in pending[section]:
                line = f"{key}={pending[section].pop(key)}"
        out.append(line)
    flush(section)

    for s, keys in pending.items():
        if keys:
            if out and out[-1] != "":
                out.append("")
            out.append(f"[{s}]")
            out.extend(f"{k}={v}" for k, v in keys.items())
    return out


def is_running():
    return subprocess.run(
        ["/usr/bin/pgrep", "-qf", PROCESS], capture_output=True
    ).returncode == 0


def main():
    args = sys.argv[1:]
    dry_run = "--dry-run" in args
    args = [a for a in args if a != "--dry-run"]
    with open(args[0]) as f:
        declared = {
            s: {k: str(v) for k, v in keys.items()} for s, keys in json.load(f).items()
        }

    current = current_values(read_lines())
    changed = [
        f"{s}/{k}"
        for s, keys in declared.items()
        for k, v in keys.items()
        if current.get((s, k)) != v
    ]
    if not changed:
        return
    print(f"qbittorrent-apply: updating {', '.join(changed)}")
    if dry_run:
        return

    running = is_running()
    if running:
        subprocess.run(["/usr/bin/pkill", "-TERM", "-f", PROCESS])
        # Shutdown saves resume data and tells trackers it's leaving.
        for _ in range(300):
            if not is_running():
                break
            time.sleep(0.1)
        else:
            print("qbittorrent-apply: qBittorrent didn't quit; skipping")
            sys.exit(1)

    # Re-read: it may have saved on the way out.
    lines = merge(read_lines(), declared)
    os.makedirs(os.path.dirname(INI), exist_ok=True)
    with open(INI, "w") as f:
        f.write("\n".join(lines) + "\n")

    if running:
        subprocess.run(["/usr/bin/open", "-g", "-b", BUNDLE_ID], check=True)


if __name__ == "__main__":
    main()
