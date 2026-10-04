"""Bring the running ExtraDock 5 in line with extradock-config.nix, over MCP.

Usage: extradock-apply [--dry-run] <state.json> <path to extradock-mcp>

Speaks MCP (newline-delimited JSON-RPC over stdio) to ExtraDock's bundled
helper, which relays to the running app. Docks are matched by name and items
by what they are (app bundle ID, folder/file path, system kind, widget type),
since ExtraDock gives anything added through MCP a fresh ID. Only what
differs is changed, so a run against an up-to-date app writes nothing.

Exit codes: 0 done, 1 something failed, 2 ExtraDock isn't reachable (not
running, MCP switched off, or licence not admitted) — nothing was touched.
"""
import json
import subprocess
import sys
import time

DOCK_SECTIONS = ("anchor", "appearance", "behavior", "orientation")
ITEM_FIELDS = ("customization", "span", "config")
CONFIRM_TIMEOUT = 120


class ToolError(Exception):
    def __init__(self, payload):
        super().__init__(payload.get("message", json.dumps(payload)))
        self.payload = payload


class Client:
    def __init__(self, helper):
        self.proc = subprocess.Popen(
            [helper, "--app", "v5"],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True,
        )
        self.next_id = 0
        self.request("initialize", {
            "protocolVersion": "2025-06-18",
            "capabilities": {},
            "clientInfo": {"name": "extradock-apply", "version": "1"},
        })
        self.send({"jsonrpc": "2.0", "method": "notifications/initialized"})

    def send(self, msg):
        self.proc.stdin.write(json.dumps(msg) + "\n")
        self.proc.stdin.flush()

    def request(self, method, params):
        self.next_id += 1
        self.send({"jsonrpc": "2.0", "id": self.next_id, "method": method, "params": params})
        while True:
            line = self.proc.stdout.readline()
            if not line:
                raise RuntimeError("extradock-mcp exited")
            msg = json.loads(line)
            if msg.get("id") != self.next_id:
                continue
            if "error" in msg:
                raise ToolError(msg["error"])
            return msg["result"]

    def tool(self, name, args=None):
        result = self.request("tools/call", {"name": name, "arguments": args or {}})
        content = result.get("structuredContent")
        if content is None:
            content = json.loads(result["content"][0]["text"])
        if result.get("isError"):
            raise ToolError(content)
        return content

    def read(self, name, args=None):
        return self.tool("extradock_read_tool", {"name": name, "arguments": args or {}})

    def change(self, name, args):
        call = {"name": name, "arguments": args}
        try:
            return self.tool("extradock_change_tool", call)
        except ToolError as e:
            # Destructive: ExtraDock shows its own dialog and answers
            # `pending_user_confirmation` with an ID to poll.
            confirmation = find_key(e.payload, "confirmationId")
            if not confirmation:
                raise
        # Wait for the answer on this connection, then retry the identical
        # call once.
        print("  waiting for you to approve this in ExtraDock…", flush=True)
        deadline = time.monotonic() + CONFIRM_TIMEOUT
        while time.monotonic() < deadline:
            status = self.tool(
                "extradock_get_confirmation_status", {"confirmationId": confirmation})
            if status.get("status") != "pending_user_confirmation":
                break
            time.sleep(1)
        else:
            raise RuntimeError("timed out waiting for approval in ExtraDock")
        if status.get("status") != "approved":
            raise RuntimeError(f"not approved in ExtraDock ({status.get('status')})")
        return self.tool("extradock_change_tool", call)

    def close(self):
        self.proc.stdin.close()
        self.proc.wait(timeout=5)


def find_key(obj, key):
    if isinstance(obj, dict):
        if key in obj:
            return obj[key]
        obj = obj.values()
    elif not isinstance(obj, list):
        return None
    for v in obj:
        found = find_key(v, key)
        if found is not None:
            return found
    return None


def covers(have, want):
    """Whether `have` already holds everything `want` declares."""
    if isinstance(want, dict):
        return isinstance(have, dict) and all(covers(have.get(k), v) for k, v in want.items())
    if isinstance(want, list):
        return (isinstance(have, list) and len(have) == len(want)
                and all(covers(h, w) for h, w in zip(have, want)))
    if isinstance(want, (int, float)) and not isinstance(want, bool):
        return isinstance(have, (int, float)) and abs(have - want) < 1e-9
    return have == want


def item_key(item):
    kind = item["kind"]
    if kind == "app":
        return (kind, item["bundleID"])
    if kind == "system":
        return (kind, item["systemKind"])
    if kind == "widget":
        return (kind, item["typeID"])
    return (kind, item["path"])


def match_items(live, wanted):
    """Pair each wanted item with an unused live item of the same key, in order."""
    pool = {}
    for item in live:
        pool.setdefault(item_key(item), []).append(item)
    pairs = [(w, (pool.get(item_key(w)) or [None]).pop(0)) for w in wanted]
    leftover = [i for items in pool.values() for i in items]
    return pairs, leftover


def main():
    args = sys.argv[1:]
    dry = "--dry-run" in args
    state_path, helper = [a for a in args if a != "--dry-run"]
    state = json.load(open(state_path))
    tag = " (dry run)" if dry else ""

    try:
        client = Client(helper)
        status = client.tool("extradock_get_status")
    except (ToolError, RuntimeError, OSError) as e:
        print(f"extradock-apply: ExtraDock isn't reachable ({e}); skipped")
        return 2
    if not status.get("connectionEnabled") or not status.get("admitted"):
        print("extradock-apply: ExtraDock's MCP access is off or its licence isn't "
              "admitted; skipped")
        return 2

    changes = 0
    failed = []

    # One change failing (or a removal you decline) skips just that change.
    def change(desc, tool, **kw):
        nonlocal changes
        changes += 1
        print(f"  {desc}{tag}", flush=True)
        try:
            client.change(tool, {**kw, "dryRun": True} if dry else kw)
            return True
        except (ToolError, RuntimeError) as e:
            print(f"    failed: {e}", flush=True)
            failed.append(desc)
            return False

    def docks():
        return client.read("extradock_list_docks")["result"]

    settings = client.read("extradock_get_settings")
    for section, want in state["settings"].items():
        if not covers(settings.get(section), want):
            change(f"settings: {section}", "extradock_update_settings",
                   section=section, patch=want)

    live = docks()
    for want in state["docks"]:
        name = want["name"]
        dock = next((d for d in live if d["name"] == name), None)
        if dock is None:
            before = {d["id"] for d in live}
            created = change(f"{name}: create dock", "extradock_create_dock", name=name,
                             patch={k: want[k] for k in DOCK_SECTIONS})
            if not created:
                continue
            if dry:
                print(f"  {name}: (items would be added after creation)")
                continue
            live = docks()
            dock = next(d for d in live if d["name"] == name and d["id"] not in before)
        dock_id = dock["id"]

        patch = {k: want[k] for k in DOCK_SECTIONS if not covers(dock.get(k), want[k])}
        if patch:
            change(f"{name}: update {', '.join(patch)}", "extradock_update_dock",
                   dockID=dock_id, patch=patch)

        pairs, extra = match_items(dock["elements"], want["elements"])
        for item in extra:
            change(f"{name}: remove {item.get('name') or item_key(item)[1]}",
                   "extradock_remove_item", dockID=dock_id, itemID=item["id"], confirm=True)
        for index, (w, have) in enumerate(pairs):
            label = f"{name}: {item_key(w)[1]}"
            if have is None:
                fields = {k: v for k, v in w.items() if k != "name"}
                change(f"{label}: add", "extradock_add_item",
                       dockID=dock_id, index=index, **fields)
                continue
            patch = {k: w[k] for k in ITEM_FIELDS if k in w and not covers(have.get(k), w[k])}
            if patch:
                change(f"{label}: update {', '.join(patch)}", "extradock_update_item",
                       dockID=dock_id, itemID=have["id"], patch=patch)

        # A dry run's adds and removes didn't happen, so compare the items
        # that are there and leave the rest out.
        if not dry:
            dock = client.read("extradock_get_dock", {"dockID": dock_id})
            dock = dock.get("result", dock)
        pairs, _ = match_items(dock["elements"], want["elements"])
        order = [have["id"] for _, have in pairs if have]
        if order != [e["id"] for e in dock["elements"] if e["id"] in order]:
            if dry:
                changes += 1
                print(f"  {name}: reorder items{tag}")
            else:
                change(f"{name}: reorder items", "extradock_reorder_items",
                       dockID=dock_id, itemIDs=order)

    if not dry:
        live = docks()
    names = [d["name"] for d in state["docks"]]
    declared = [d["id"] for n in names for d in live if d["name"] == n][:len(names)]
    others = [d for d in live if d["name"] not in names]
    for d in others:
        print(f"  note: dock {d['name']!r} isn't in extradock-config.nix; left alone")
    if [d["id"] for d in live] != declared + [d["id"] for d in others]:
        change("reorder docks", "extradock_reorder_docks",
               dockIDs=declared + [d["id"] for d in others])

    client.close()
    if failed:
        print(f"extradock-apply: {len(failed)} of {changes} change(s) failed{tag}: "
              + "; ".join(failed))
        return 1
    print(f"extradock-apply: {changes} change(s){tag}" if changes
          else "extradock-apply: ExtraDock already matches")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ToolError, RuntimeError) as e:
        print(f"extradock-apply: failed: {e}", file=sys.stderr)
        sys.exit(1)
