"""Merge the declared GitButler GUI preferences into its state database.

The GPUI build of GitButler keeps its preferences as one JSON object under
the `prefs` key of a SQLite key/value table, alongside UI state (panel
widths, window bounds, per-project ordering), in
~/Library/Application Support/com.gitbutler.app/gpui-state/state.sqlite.
So the database stays app-owned, and only the declared keys are set inside
that object: every other preference is kept as it is.

A running GitButler holds its preferences in memory and would write them
back over the edit, so it's quit first and reopened afterwards. Nothing
happens when every declared key already matches. If GitButler hasn't
written its preferences yet (a fresh machine), nothing is written; the next
`ns` after it has been opened once applies them.

Usage: gitbutler-apply [--dry-run] <declared.json>
The JSON maps preference name → value, named as GitButler stores them
(e.g. `open_branch_on_click`).
"""

import json
import os
import sqlite3
import subprocess
import sys
import time

DB = os.path.expanduser(
    "~/Library/Application Support/com.gitbutler.app/gpui-state/state.sqlite"
)
BUNDLE_ID = "com.gitbutler.app"
PROCESS = "GitButler.app/Contents/MacOS/"


def read_prefs():
    if not os.path.exists(DB):
        return None
    con = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    try:
        row = con.execute("SELECT value FROM state WHERE key = 'prefs'").fetchone()
    except sqlite3.OperationalError:
        return None
    finally:
        con.close()
    return json.loads(row[0]) if row else None


def write_prefs(prefs):
    con = sqlite3.connect(DB)
    try:
        with con:
            con.execute(
                "UPDATE state SET value = ? WHERE key = 'prefs'",
                (json.dumps(prefs, separators=(",", ":")),),
            )
    finally:
        con.close()


def is_running():
    return subprocess.run(
        ["/usr/bin/pgrep", "-qf", PROCESS], capture_output=True
    ).returncode == 0


def main():
    args = sys.argv[1:]
    dry_run = "--dry-run" in args
    args = [a for a in args if a != "--dry-run"]
    with open(args[0]) as f:
        declared = json.load(f)

    prefs = read_prefs()
    if prefs is None:
        print("gitbutler-apply: no GitButler preferences yet; open GitButler once, then rerun `ns`")
        return
    changed = [k for k, v in declared.items() if prefs.get(k) != v]
    if not changed:
        return
    print(f"gitbutler-apply: updating {', '.join(changed)}")
    if dry_run:
        return

    running = is_running()
    if running:
        subprocess.run(
            ["/usr/bin/osascript", "-e", f'quit app id "{BUNDLE_ID}"'],
            capture_output=True,
        )
        for _ in range(100):
            if not is_running():
                break
            time.sleep(0.1)
        else:
            print("gitbutler-apply: GitButler didn't quit; skipping")
            sys.exit(1)

    # Re-read: it may have saved on the way out.
    prefs = read_prefs()
    prefs.update(declared)
    write_prefs(prefs)

    if running:
        subprocess.run(["/usr/bin/open", "-g", "-b", BUNDLE_ID], check=True)


if __name__ == "__main__":
    main()
