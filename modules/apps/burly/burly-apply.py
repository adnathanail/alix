"""Merge the declared Burly settings into Burly's own.

Burly keeps every setting in one JSON document, stored as Data under the
`burly.settings.v1` key of its defaults domain. Declared top-level keys
replace Burly's; any others (runtime state like `lastUsedDestinationID`,
`hasCompletedOnboarding`) are kept.

Burly holds its settings in memory and may write them back on quit, so a
running Burly is stopped before the write and reopened after. It's sent
SIGTERM rather than asked to quit: it cancels an AppleScript `quit`. Nothing happens
when the merged settings already match.

Usage: burly-apply [--dry-run] <declared.json>
Exit 2 = skipped (Burly never launched).
"""

import json
import plistlib
import subprocess
import sys
import time

DOMAIN = "com.mattsenter.Burly"
KEY = "burly.settings.v1"


def read_current():
    out = subprocess.run(
        ["/usr/bin/defaults", "export", DOMAIN, "-"], capture_output=True, check=True
    ).stdout
    blob = plistlib.loads(out).get(KEY)
    return json.loads(blob) if blob is not None else None


def is_running():
    return subprocess.run(
        ["/usr/bin/pgrep", "-qx", "Burly"], capture_output=True
    ).returncode == 0


def main():
    args = sys.argv[1:]
    dry_run = "--dry-run" in args
    args = [a for a in args if a != "--dry-run"]
    with open(args[0]) as f:
        declared = json.load(f)

    current = read_current()
    if current is None:
        print("burly-apply: no settings yet; open Burly once and finish onboarding")
        sys.exit(2)

    merged = {**current, **declared}
    if merged == current:
        return
    changed = sorted(k for k in declared if current.get(k) != declared[k])
    print(f"burly-apply: updating {', '.join(changed)}")
    if dry_run:
        return

    running = is_running()
    if running:
        subprocess.run(["/usr/bin/pkill", "-TERM", "-x", "Burly"])
        for _ in range(50):
            if not is_running():
                break
            time.sleep(0.1)
        # It may have saved on the way out; merge over that instead.
        merged = {**read_current(), **declared}

    data = json.dumps(merged, separators=(",", ":")).encode()
    subprocess.run(
        ["/usr/bin/defaults", "write", DOMAIN, KEY, "-data", data.hex()], check=True
    )
    if running:
        subprocess.run(["/usr/bin/open", "-g", "-b", DOMAIN], check=True)


if __name__ == "__main__":
    main()
