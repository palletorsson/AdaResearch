"""live_update_test.py — the end-to-end test of a live JSON update, with a log.

2026-10-22, the brief's Phase 4: move an object in the editor, publish, confirm
the desktop applied it, confirm the Quest applied it, a second update, then a
reconnect and an invalid revision. Every step records the revision id it sent
and the acks the ledger holds, into ada_run/live_update_test_<stamp>.md.

The chain exercised is the REAL one: the encyclopedia's save route
(POST /api/voxel-editor, the Three.js editor's own save) writes the canonical
map_data.json, diffs it (src/lib/live-update.ts), posts the envelope to
tools/vr_link.py (/update), which broadcasts to every attached game; each game's
commons/bridge/live_update.gd answers with an update_ack. The only thing not
driven here is the mouse.

The bench map is a COPY of a real map (default Point_One) under
commons/maps/Live_Update_Bench/, made at the start and removed at the end, so
no tracked map changes hands.

  python tools/live_update_test.py                 # desktop: starts vr_link.py + the game
  python tools/live_update_test.py --quest         # also wait for an Android ack (app armed, worn)
  python tools/live_update_test.py --no-game       # a game is already attached (yours)
  python tools/live_update_test.py --keep          # keep the bench map afterwards
  python tools/live_update_test.py --void [--floor 10]   # The Void: /lab-editor?mode=void saves
                                                   # rooms.json; floor <n>'s last artifact is moved
                                                   # and moved back (the file ends byte-identical)

Needs the encyclopedia dev server on localhost:3003 (ADA_ENC_URL to change).
"""
from __future__ import annotations

import argparse
import copy
import json
import os
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENC = os.environ.get("ADA_ENC_URL", "http://localhost:3003")
BRIDGE = os.environ.get("ADA_VR_LINK_URL", "http://127.0.0.1:8772")
GODOT = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
BENCH = "Live_Update_Bench"
LOG: list[str] = []


def say(line: str) -> None:
    print(line)
    LOG.append(line)


def http(method: str, url: str, body: dict | None = None, timeout: float = 20.0) -> tuple[int, dict]:
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, method=method,
                                 headers={"content-type": "application/json"} if data else {})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, json.loads(r.read().decode("utf-8") or "{}")
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read().decode("utf-8") or "{}")
        except Exception:
            return e.code, {}
    except Exception as e:  # noqa: BLE001
        return 0, {"error": repr(e)}


def bridge_state() -> dict:
    code, j = http("GET", f"{BRIDGE}/state", timeout=3)
    return j if code == 200 else {}


def wait_for(pred, what: str, timeout: float, every: float = 0.5) -> bool:
    t0 = time.time()
    while time.time() - t0 < timeout:
        if pred():
            return True
        time.sleep(every)
    say(f"  TIMEOUT waiting {timeout:.0f}s for {what}")
    return False


def acks_for(rid: str, since: float = 0.0) -> list[dict]:
    code, j = http("GET", f"{BRIDGE}/revisions?id={rid}", timeout=3)
    if code != 200:
        return []
    return [r for r in j.get("rows", []) if r.get("k") == "update_ack" and float(r.get("t", 0)) >= since]


def last_per_device(acks: list[dict], devices: set[str] | None = None) -> list[dict]:
    """A device's answer is its LAST ack for the revision (an earlier one may be a
    late arrival from the previous step, inside the one-second grace window). Only
    the devices under test count: a headset attached in another scene answers too."""
    out: dict[str, dict] = {}
    for a in acks:
        if devices is None or str(a.get("device")) in devices:
            out[str(a.get("device"))] = a
    return list(out.values())


def wait_acks(rid: str, devices: set[str], timeout: float, since: float = 0.0) -> list[dict]:
    got: list[dict] = []

    def have() -> bool:
        nonlocal got
        got = acks_for(rid, since)
        return devices <= {str(a.get("device")) for a in got}
    wait_for(have, f"acks from {sorted(devices)} on {rid}", timeout)
    for a in got:
        say(f"  ack  {a.get('device')}: {a.get('status')}"
            f"{(' (' + str(a.get('reason')) + ')') if a.get('reason') else ''}"
            f" mode={a.get('mode') or '-'} — {str(a.get('detail', ''))[:110]}")
        for op in a.get("ops") or []:
            say(f"       op {op.get('op')} {op.get('object_id', '')}: {'ok' if op.get('ok') else 'no'} — {op.get('detail', '')}")
    return got


def save_map(name: str, data: dict) -> dict:
    code, j = http("POST", f"{ENC}/api/voxel-editor", {"mapName": name, "data": data}, timeout=30)
    if code != 200:
        say(f"  save FAILED {code}: {j}")
        return {}
    live = j.get("live") or {}
    say(f"  saved {name} -> revision {live.get('revision_id')} ({live.get('operations')} op), "
        f"sent={live.get('sent')} transmitted={live.get('transmitted')} games={live.get('games')}"
        f"{(' error=' + str(live.get('error'))) if live.get('error') else ''}")
    return live


def find_move(data: dict) -> tuple[tuple[int, int], tuple[int, int], str] | None:
    layers = data.get("layers", {})
    inter = layers.get("interactables", [])
    struct = layers.get("structure", [])
    rows = lambda L: [r if isinstance(r, list) else str(r).split(",") for r in L]  # noqa: E731
    I, S = rows(inter), rows(struct)
    src = None
    for z, row in enumerate(I):
        for x, tok in enumerate(row):
            t = str(tok).strip()
            head = t.split("#")[0].split(":")[0]
            if t and not t.startswith("#") and head not in ("mc", "gridagent", "cluster", "criticalinfo", "dialectic"):
                src = ((x, z), t)
                break
        if src:
            break
    if not src:
        return None
    for z, row in enumerate(S):
        for x, h in enumerate(row):
            occupied = z < len(I) and x < len(I[z]) and str(I[z][x]).strip() != ""
            if str(h).strip() == "1" and not occupied and (x, z) != src[0]:
                return src[0], (x, z), src[1]
    return None


def set_cell(data: dict, at: tuple[int, int], value: str) -> None:
    rows = data["layers"]["interactables"]
    x, z = at
    row = rows[z]
    if isinstance(row, str):
        row = row.split(",")
        rows[z] = row
    row[x] = value


# ── The Void ─────────────────────────────────────────────────────────────────

def void_layout() -> dict:
    code, j = http("GET", f"{ENC}/api/void-layout", timeout=60)
    if code != 200:
        say(f"  GET /api/void-layout failed {code}: {j}")
        return {}
    return j


def void_save(rooms: dict, revision: str) -> dict:
    code, j = http("POST", f"{ENC}/api/void-layout", {"rooms": rooms, "revision": revision}, timeout=120)
    if code != 200:
        say(f"  save FAILED {code}: {str(j.get('error', j))[:300]}")
        return {}
    live = j.get("live") or []
    for l in live:
        say(f"  saved floor {l.get('floor')} ({l.get('map')}) -> revision {l.get('revision_id')} ({l.get('operations')} op), "
            f"sent={l.get('sent')} transmitted={l.get('transmitted')}{(' error=' + str(l.get('error'))) if l.get('error') else ''}")
    j["live"] = live
    return j


def launch_void(floor: int) -> subprocess.Popen:
    return subprocess.Popen([GODOT, "--path", str(ROOT), "--xr-mode", "off",
                             "res://commons/void/void.tscn", "--",
                             f"--void-start-floor={floor}", "--vr-link"], cwd=ROOT,
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def run_void(args, procs: list, stamp: str) -> int:
    floor = args.floor
    rooms_file = ROOT / "commons" / "void" / "rooms.json"
    text0 = rooms_file.read_text(encoding="utf-8")
    devices: set[str] = set()
    if not args.no_game:
        procs.append(launch_void(floor))
        say(f"desktop game launched: void.tscn --void-start-floor={floor} --vr-link")
    if not args.no_game or not args.quest:
        devices.add("Windows")
    if args.quest:
        devices.add("Android")

    def attached() -> bool:
        st = bridge_state()
        pose = st.get("pose") or {}
        return bool(st.get("connected")) and pose.get("proj") == "void" and int(st.get("games", 1)) >= len(devices)
    if not wait_for(attached, "the Void to attach (pose proj=void)", args.attach_timeout, every=2.0):
        return 1
    st = bridge_state()
    say(f"attached: games={st.get('games')} proj={(st.get('pose') or {}).get('proj')} hz={st.get('hz')}")
    time.sleep(4.0)   # let the start floor finish building

    layout = void_layout()
    rooms = layout.get("rooms") or {}
    rev = layout.get("revision", "")
    floors = rooms.get("floors", [])
    if floor >= len(floors) or not floors[floor].get("artifacts"):
        say(f"floor {floor} has no artifacts")
        return 1
    item = floors[floor]["artifacts"][-1]
    pos0 = list(item.get("position", [0, 0]))
    say("")
    say(f"## 1. move {item.get('id')} ({item.get('artifact')}) on floor {floor}: {pos0} -> [{pos0[0] + 1.5}, {pos0[1]}]")
    item["position"] = [pos0[0] + 1.5, pos0[1]]
    r1 = void_save(rooms, rev)
    live1 = [l for l in r1.get("live", []) if l.get("floor") == floor]
    rid1 = live1[0]["revision_id"] if live1 else ""
    acks1 = wait_acks(rid1, devices, args.ack_timeout) if rid1 else []
    # the desktop started ON this floor, so it must apply in place; a headset may be on
    # another floor, where the record is replaced (mode data) and builds when entered
    ok1 = bool(acks1) and {a.get("device") for a in acks1 if a.get("status") == "applied"
                           and (a.get("mode") == "in_place" or a.get("device") != "Windows")} >= devices
    say(f"  RESULT 1: {'PASS' if ok1 else 'FAIL'} (desktop in place; a headset applied on its floor or by record)")

    say("")
    say(f"## 2. second update: {item.get('id')} back to {pos0}")
    item["position"] = pos0
    r2 = void_save(rooms, r1.get("revision", rev))
    live2 = [l for l in r2.get("live", []) if l.get("floor") == floor]
    rid2 = live2[0]["revision_id"] if live2 else ""
    acks2 = wait_acks(rid2, devices, args.ack_timeout) if rid2 else []
    ok2 = bool(acks2) and {a.get("device") for a in acks2 if a.get("status") == "applied"} >= devices
    say(f"  RESULT 2: {'PASS' if ok2 else 'FAIL'}")
    text2 = rooms_file.read_text(encoding="utf-8")
    say(f"  rooms.json byte-identical to the start: {text2 == text0}")

    say("")
    say("## 3. invalid revision")
    code, j = http("POST", f"{BRIDGE}/update", {"revision_id": "rev-badop-void-%s" % stamp, "project_id": "void",
                                                 "map_id": "void", "floor_id": floor, "base_revision": "", "revision": "",
                                                 "operations": [{"op": "teleport"}]})
    rid3 = j.get("revision_id", "")
    acks3 = wait_acks(rid3, devices, args.ack_timeout) if rid3 else []
    ok3 = code == 200 and len(last_per_device(acks3, devices)) >= len(devices) and all(a.get("status") == "rejected" and a.get("reason") == "invalid" for a in last_per_device(acks3, devices))
    say(f"  RESULT 3: {'PASS' if ok3 else 'FAIL'} (every game rejected it as invalid)")

    say("")
    say("## 4. duplicate of revision 2")
    code, j = http("GET", f"{BRIDGE}/revisions?id={rid2}")
    req_rows = [r for r in j.get("rows", []) if r.get("k") == "request"]
    env2 = (req_rows[-1].get("env") if req_rows else {}) or {}
    env2 = {k: v for k, v in env2.items() if k not in ("seq", "cmd", "has_map_data", "has_map")}
    t4 = time.time() - 1.0
    code, j = http("POST", f"{BRIDGE}/update", env2)
    acks4 = wait_acks(j.get("revision_id", rid2), devices, args.ack_timeout, since=t4) if rid2 else []
    ok4 = len(acks4) >= len(devices) and all(a.get("status") == "rejected" and a.get("reason") in ("duplicate", "already_current") for a in last_per_device(acks4, devices))
    say(f"  RESULT 4: {'PASS' if ok4 else 'FAIL'} (rejected as duplicate / already_current)")

    ok5 = True
    if not args.no_game:
        say("")
        say("## 5. reconnect: the Void relaunches; the bridge replays the latest revision on entering it")
        g = procs[-1]
        g.terminate()
        try:
            g.wait(timeout=10)
        except subprocess.TimeoutExpired:
            g.kill()
        procs.remove(g)
        wait_for(lambda: not bridge_state().get("connected"), "the game to drop", 15)
        t5 = time.time() - 1.0
        procs.append(launch_void(floor))
        wait_for(lambda: bridge_state().get("connected") and (bridge_state().get("pose") or {}).get("proj") == "void",
                 "the Void to re-attach", args.attach_timeout, every=2.0)
        time.sleep(6.0)
        acks5 = [a for a in acks_for(rid2, since=t5) if a.get("device") == "Windows" and a.get("replay")]
        for a in acks5:
            say(f"  replay ack Windows: {a.get('status')} ({a.get('reason')}) - {a.get('detail')}")
        ok5 = bool(acks5) and all(a.get("status") == "rejected" and a.get("reason") in ("already_current", "duplicate") for a in acks5)
        say(f"  RESULT 5: {'PASS' if ok5 else 'FAIL'}")

    say("")
    say(f"## verdict: {'PASS' if all([ok1, ok2, ok3, ok4, ok5]) else 'FAIL'}  (1 move {ok1}, 2 second {ok2}, 3 invalid {ok3}, 4 duplicate {ok4}, 5 reconnect {ok5})")
    say(f"ledger: ada_run/live_updates.jsonl - revisions {rid1} {rid2} {rid3}")
    return 0 if all([ok1, ok2, ok3, ok4, ok5]) else 1


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--source", default="Point_One", help="the map the bench copies")
    ap.add_argument("--quest", action="store_true", help="also wait for the Android game's acks")
    ap.add_argument("--no-game", action="store_true", help="do not launch the desktop game")
    ap.add_argument("--no-bridge", action="store_true", help="do not launch vr_link.py (already running)")
    ap.add_argument("--keep", action="store_true", help="keep the bench map")
    ap.add_argument("--void", action="store_true", help="test The Void (rooms.json floors) instead of a grid map")
    ap.add_argument("--floor", type=int, default=10, help="with --void: the floor to edit")
    ap.add_argument("--ack-timeout", type=float, default=25.0)
    ap.add_argument("--attach-timeout", type=float, default=90.0,
                    help="seconds to wait for the game(s) to attach (a headset needs to be worn)")
    args = ap.parse_args()

    stamp = time.strftime("%Y%m%d-%H%M%S")
    report = ROOT / "ada_run" / f"live_update_test_{stamp}.md"
    say(f"# Live update test {stamp}")
    say("")

    # 0. the bench map (grid flow only; the Void edits rooms.json and restores it)
    src_dir = ROOT / "commons" / "maps" / args.source
    bench_dir = ROOT / "commons" / "maps" / BENCH
    if args.void:
        bench_dir = None
    elif not (src_dir / "map_data.json").exists():
        say(f"no map_data.json for {args.source}")
        return 2
    data0: dict = {}
    if bench_dir is not None:
        bench_dir.mkdir(exist_ok=True)
        shutil.copyfile(src_dir / "map_data.json", bench_dir / "map_data.json")
        original_text = (bench_dir / "map_data.json").read_text(encoding="utf-8")
        data0 = json.loads(original_text)
        if "map_info" in data0:
            data0["map_info"]["name"] = BENCH
            data0["map_info"]["lookup_name"] = BENCH
            (bench_dir / "map_data.json").write_text(json.dumps(data0, indent=2) + "\n", encoding="utf-8")
        say(f"bench map {BENCH} copied from {args.source}")

    procs: list[subprocess.Popen] = []
    try:
        # 1. the bridge
        if not args.no_bridge and not bridge_state():
            p = subprocess.Popen([sys.executable, str(ROOT / "tools" / "vr_link.py")], cwd=ROOT,
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            procs.append(p)
            wait_for(lambda: bool(bridge_state()), "vr_link.py on :8772", 20)
        say(f"bridge: {'up' if bridge_state() else 'DOWN'} at {BRIDGE}")

        if args.void:
            return run_void(args, procs, stamp)

        # 2. the desktop game, armed, on the bench map
        devices = set()
        if not args.no_game:
            g = subprocess.Popen([GODOT, "--path", str(ROOT), "--xr-mode", "off",
                                  "res://commons/scenes/desktop_map_tester.tscn", "--",
                                  f"--map={BENCH}", "--vr-link"], cwd=ROOT,
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            procs.append(g)
            say("desktop game launched: desktop_map_tester --map=%s --vr-link" % BENCH)
        if not args.no_game or not args.quest:
            devices.add("Windows")
        if args.quest:
            devices.add("Android")
        def attached() -> bool:
            st = bridge_state()
            if not (st.get("connected") and (st.get("pose") or {}).get("map")):
                return False
            # with --quest, wait until BOTH games are attached (the bridge counts game clients)
            return int(st.get("games", 1)) >= len(devices)
        ok_attach = wait_for(attached, "the game(s) to attach and send a pose", args.attach_timeout, every=2.0)
        st = bridge_state()
        say(f"attached: connected={st.get('connected')} map={(st.get('pose') or {}).get('map')} hz={st.get('hz')}")
        if not ok_attach:
            return 1
        time.sleep(3.0)   # let the grid finish generating before the first revision

        # 3. first update: move one artifact
        mv = find_move(data0)
        if not mv:
            say("no artifact + free floor cell to move in the bench map")
            return 1
        frm, to, token = mv
        say("")
        say(f"## 1. move {token} {frm} -> {to}")
        data1 = copy.deepcopy(data0)
        set_cell(data1, frm, " ")
        set_cell(data1, to, token)
        live1 = save_map(BENCH, data1)
        rid1 = live1.get("revision_id", "")
        acks1 = wait_acks(rid1, devices, args.ack_timeout)
        ok1 = {a.get("device") for a in acks1 if a.get("status") == "applied"} >= devices
        say(f"  RESULT 1: {'PASS' if ok1 else 'FAIL'}")

        # 4. second update: move it back
        say("")
        say(f"## 2. second update: {token} {to} -> {frm}")
        live2 = save_map(BENCH, data0)
        rid2 = live2.get("revision_id", "")
        acks2 = wait_acks(rid2, devices, args.ack_timeout)
        ok2 = {a.get("device") for a in acks2 if a.get("status") == "applied"} >= devices
        say(f"  RESULT 2: {'PASS' if ok2 else 'FAIL'}")

        # 5. an invalid revision, straight at the bridge and through it to the games
        say("")
        say("## 3. invalid revision")
        code, j = http("POST", f"{BRIDGE}/update", {"revision_id": "rev-invalid-%s" % stamp,
                                                     "map_id": BENCH, "operations": "nope"})
        say(f"  bridge refused a non-list operations: HTTP {code} {j.get('error', '')}")
        code, j = http("POST", f"{BRIDGE}/update", {"revision_id": "rev-badop-%s" % stamp, "map_id": BENCH,
                                                     "base_revision": "", "revision": "",
                                                     "operations": [{"op": "teleport", "layer": "interactables"}]})
        rid3 = j.get("revision_id", "")
        acks3 = wait_acks(rid3, devices, args.ack_timeout)
        ok3 = code == 200 and all(a.get("status") == "rejected" and a.get("reason") == "invalid" for a in last_per_device(acks3, devices)) and len(last_per_device(acks3, devices)) >= len(devices)
        say(f"  RESULT 3: {'PASS' if ok3 else 'FAIL'} (every game rejected it as invalid)")

        # 6. a stale replay: the same revision 2 again must be a duplicate, not applied twice
        say("")
        say("## 4. duplicate of revision 2")
        code, j = http("GET", f"{BRIDGE}/revisions?id={rid2}")
        req_rows = [r for r in j.get("rows", []) if r.get("k") == "request"]
        env2 = (req_rows[-1].get("env") if req_rows else {}) or {}
        env2 = {k: v for k, v in env2.items() if k not in ("seq", "cmd", "has_map_data", "has_map")}
        env2["operations"] = env2.get("operations", [])
        t4 = time.time() - 1.0
        code, j = http("POST", f"{BRIDGE}/update", env2)
        acks4 = wait_acks(j.get("revision_id", rid2), devices, args.ack_timeout, since=t4)
        ok4 = len(acks4) >= len(devices) and all(a.get("status") == "rejected" and a.get("reason") in ("duplicate", "already_current") for a in last_per_device(acks4, devices))
        say(f"  RESULT 4: {'PASS' if ok4 else 'FAIL'} (rejected as duplicate / already_current)")

        # 7. reconnect: kill and relaunch the desktop game; the bridge replays the latest
        ok5 = True
        if not args.no_game:
            say("")
            say("## 5. reconnect — the desktop game relaunches; the bridge replays the latest revision")
            g.terminate()
            try:
                g.wait(timeout=10)
            except subprocess.TimeoutExpired:
                g.kill()
            procs.remove(g)
            wait_for(lambda: not bridge_state().get("connected"), "the game to drop", 15)
            t5 = time.time() - 1.0
            g = subprocess.Popen([GODOT, "--path", str(ROOT), "--xr-mode", "off",
                                  "res://commons/scenes/desktop_map_tester.tscn", "--",
                                  f"--map={BENCH}", "--vr-link"], cwd=ROOT,
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            procs.append(g)
            wait_for(lambda: bridge_state().get("connected"), "the game to re-attach", 90)
            time.sleep(4.0)
            acks5 = [a for a in acks_for(rid2, since=t5) if a.get("device") == "Windows" and a.get("replay")]
            # the relaunched game loaded the file as revision 2 wrote it: the replay must be already_current (or a duplicate), never applied twice
            for a in acks5:
                say(f"  replay ack Windows: {a.get('status')} ({a.get('reason')}) — {a.get('detail')}")
            ok5 = bool(acks5) and all(a.get("status") == "rejected" and a.get("reason") in ("already_current", "duplicate") for a in acks5)
            say(f"  RESULT 5: {'PASS' if ok5 else 'FAIL'}")

        say("")
        say(f"## verdict: {'PASS' if all([ok1, ok2, ok3, ok4, ok5]) else 'FAIL'}  (1 move {ok1}, 2 second {ok2}, 3 invalid {ok3}, 4 duplicate {ok4}, 5 reconnect {ok5})")
        say(f"ledger: ada_run/live_updates.jsonl · revisions {rid1} {rid2} {rid3}")
        return 0 if all([ok1, ok2, ok3, ok4, ok5]) else 1
    finally:
        for p in procs:
            try:
                p.terminate()
            except Exception:
                pass
        if not args.keep and bench_dir is not None:
            shutil.rmtree(bench_dir, ignore_errors=True)
            say(f"bench map {BENCH} removed")
        report.parent.mkdir(exist_ok=True)
        report.write_text("\n".join(LOG) + "\n", encoding="utf-8")
        print(f"report: {report}")


if __name__ == "__main__":
    raise SystemExit(main())
