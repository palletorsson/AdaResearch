"""live_update_spawn_test.py — an `add` and a `remove` applied IN PLACE on a Void floor.

2026-10-22, the spawn menu's step 2: before this, a new record reached the game as an
`add` and the game answered with a floor rebuild. Now commons/bridge/live_update.gd
builds the one new mount through the Void's own builders (`_build_artifact` /
SetDressing.build) and frees one on `remove`, and answers `applied in_place`.

The chain is the real one — the editors' save route — not the bridge's spawn lane:

  GET /api/void-layout -> append a record to floor N -> POST {rooms, revision}
  -> the route diffs (kind add) -> vr_link.py -> the game -> ack
  then the record is removed the same way (kind remove); rooms.json ends byte-identical.

  python tools/live_update_spawn_test.py                  # starts void.tscn on floor 10 with --vr-link
  python tools/live_update_spawn_test.py --no-game        # a desktop Void is already attached
  python tools/live_update_spawn_test.py --token work_light --prop   # spawn a prop instead
Report: ada_run/live_update_spawn_test_<stamp>.md
"""
from __future__ import annotations

import argparse
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import live_update_test as lt  # noqa: E402  (its helpers: http, bridge_state, wait_acks, void_layout, void_save, launch_void)

LOG: list[str] = []


def say(line: str) -> None:
    print(line)
    LOG.append(line)
    lt.LOG.clear()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--floor", type=int, default=10)
    ap.add_argument("--token", default="film_profile_travels", help="artifact lookup name (or prop kind with --prop)")
    ap.add_argument("--prop", action="store_true")
    ap.add_argument("--at", nargs=2, type=float, default=[-14.0, -6.5], metavar=("X", "Z"))
    ap.add_argument("--no-game", action="store_true")
    ap.add_argument("--quest", action="store_true")
    ap.add_argument("--attach-timeout", type=float, default=90.0)
    ap.add_argument("--ack-timeout", type=float, default=15.0)
    ap.add_argument("--via-bridge", action="store_true",
                    help="spawn through the bridge's own lane (POST :8772/spawn, what the VR hand sends) instead of editing the layout here")
    ap.add_argument("--game-log", default="", help="pass --log-file to the launched game (to read the spawn menu's lines)")
    ap.add_argument("--move", default="", metavar="ID",
                    help="instead of add/remove: move this existing record through the bridge's move lane (what VR grab-and-move sends) by +1.5 m in x, then back")
    args = ap.parse_args()
    stamp = time.strftime("%Y%m%d-%H%M%S")
    report = ROOT / "ada_run" / f"live_update_spawn_test_{stamp}.md"
    (ROOT / "ada_run").mkdir(exist_ok=True)
    say(f"# Live update spawn test {stamp}")
    rooms_file = ROOT / "commons" / "void" / "rooms.json"
    text0 = rooms_file.read_text(encoding="utf-8")
    procs: list[subprocess.Popen] = []
    devices = {"Windows"} if not (args.no_game and args.quest) else set()
    if args.quest:
        devices.add("Android")
    try:
        if not lt.bridge_state():
            procs.append(subprocess.Popen([sys.executable, str(ROOT / "tools" / "vr_link.py")], cwd=ROOT,
                                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
            lt.wait_for(lambda: bool(lt.bridge_state()), "vr_link.py", 20)
        if not args.no_game:
            if args.game_log:
                procs.append(subprocess.Popen([lt.GODOT, "--path", str(ROOT), "--xr-mode", "off", "--log-file", args.game_log,
                                               "res://commons/void/void.tscn", "--", f"--void-start-floor={args.floor}", "--vr-link"],
                                              cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
            else:
                procs.append(lt.launch_void(args.floor))
            say(f"desktop game launched: void.tscn --void-start-floor={args.floor} --vr-link")

        def attached() -> bool:
            st = lt.bridge_state()
            names = {str(n).split("/")[0] for n in (st.get("game_names") or [])}
            return bool(st.get("connected")) and devices <= names
        if not lt.wait_for(attached, f"{sorted(devices)} to attach", args.attach_timeout, every=2.0):
            return 1
        time.sleep(5.0)

        if args.move:
            # the grab-and-move lane: {"move": id, position, facing} -> the bridge rewrites the
            # record's transform and saves; the game applies the revision as a `transform`
            layout = lt.void_layout()
            fl = layout["rooms"]["floors"][args.floor]
            rec = next((it for c in ("artifacts", "copies", "props") for it in fl.get(c, []) if it.get("id") == args.move), None)
            if rec is None:
                say(f"no record {args.move} on floor {args.floor}")
                return 1
            pos0 = list(rec.get("position", [0, 0]))
            fac0 = rec.get("facing", 0)
            oks = []
            for step, target in ((1, [pos0[0] + 1.5, pos0[1]]), (2, pos0)):
                say("")
                say(f"## {step}. POST {lt.BRIDGE}/spawn move {args.move} -> {target} facing {fac0} (the bridge saves it)")
                code, j = lt.http("POST", f"{lt.BRIDGE}/spawn", {"floor": args.floor, "move": args.move, "position": target, "facing": fac0}, timeout=240)
                say(f"  bridge answered {code}: {str(j)[:200]}")
                rid = str(j.get("revision_id", "")) if code == 200 else ""
                acks = lt.wait_acks(rid, devices, args.ack_timeout) if rid else []
                ok = bool(acks) and all(a.get("status") == "applied" and (a.get("mode") == "in_place" or a.get("device") != "Windows")
                                        and any(op.get("kind") == "transform" and op.get("ok") for op in (a.get("ops") or [])) for a in lt.last_per_device(acks, devices))
                say(f"  RESULT {step}: {'PASS' if ok else 'FAIL'} (moved in place, op transform ok)")
                oks.append(ok)
            same = rooms_file.read_text(encoding="utf-8") == text0
            say(f"  rooms.json byte-identical to the start: {same}")
            say("")
            say(f"## verdict: {'PASS' if all(oks) and same else 'FAIL'}")
            return 0 if all(oks) and same else 1

        coll = "props" if args.prop else "artifacts"
        say("")
        if args.via_bridge:
            # the VR hand's lane: the bridge GETs the layout, appends the record, POSTs it
            say(f"## 1. POST {lt.BRIDGE}/spawn {args.token} at {args.at} on floor {args.floor} (the bridge saves it)")
            body = {"floor": args.floor, "position": args.at, "facing": 0, "by": "spawn-test"}
            body["kind" if args.prop else "token"] = args.token
            code, j = lt.http("POST", f"{lt.BRIDGE}/spawn", body, timeout=240)
            say(f"  bridge answered {code}: {str(j)[:200]}")
            rid_new = str(j.get("id", ""))
            rid1 = str(j.get("revision_id", "")) if code == 200 else ""
            rooms, rev = None, ""
        else:
            layout = lt.void_layout()
            rooms, rev = layout["rooms"], layout["revision"]
            floor = rooms["floors"][args.floor]
            rid_new = f"spawn-test-{stamp}"
            if args.prop:
                rec = {"id": rid_new, "kind": args.token, "position": args.at, "facing": 0, "scale": 1}
            else:
                rec = {"id": rid_new, "artifact": args.token, "station": "NW", "position": args.at, "height": 0, "facing": 0, "scale": 1,
                       "config": {"editor_label": f"spawn test {stamp}"}}
            floor.setdefault(coll, []).append(rec)
            say(f"## 1. add {coll}/{rid_new} ({args.token}) at {args.at} on floor {args.floor}")
            r1 = lt.void_save(rooms, rev)
            live1 = [l for l in r1.get("live", []) if l.get("floor") == args.floor]
            rid1 = live1[0]["revision_id"] if live1 else ""
            rev = r1.get("revision", rev)
        acks1 = lt.wait_acks(rid1, devices, args.ack_timeout) if rid1 else []
        ok1 = bool(acks1) and all(a.get("status") == "applied" and (a.get("mode") == "in_place" or a.get("device") != "Windows")
                                  and any(op.get("kind") == "add" and op.get("ok") for op in (a.get("ops") or [])) for a in lt.last_per_device(acks1, devices))
        say(f"  RESULT 1: {'PASS' if ok1 else 'FAIL'} (added in place, op add ok)")

        say("")
        say(f"## 2. remove {coll}/{rid_new}")
        if args.via_bridge:
            code, j = lt.http("POST", f"{lt.BRIDGE}/spawn", {"floor": args.floor, "remove": rid_new}, timeout=240)
            say(f"  bridge answered {code}: {str(j)[:200]}")
            rid2 = str(j.get("revision_id", "")) if code == 200 else ""
        else:
            floor[coll] = [it for it in floor[coll] if it.get("id") != rid_new]
            r2 = lt.void_save(rooms, rev)
            live2 = [l for l in r2.get("live", []) if l.get("floor") == args.floor]
            rid2 = live2[0]["revision_id"] if live2 else ""
        acks2 = lt.wait_acks(rid2, devices, args.ack_timeout) if rid2 else []
        ok2 = bool(acks2) and all(a.get("status") == "applied" and (a.get("mode") == "in_place" or a.get("device") != "Windows")
                                  and any(op.get("kind") == "remove" and op.get("ok") for op in (a.get("ops") or [])) for a in lt.last_per_device(acks2, devices))
        say(f"  RESULT 2: {'PASS' if ok2 else 'FAIL'} (removed in place, op remove ok)")
        same = rooms_file.read_text(encoding="utf-8") == text0
        say(f"  rooms.json byte-identical to the start: {same}")
        say("")
        say(f"## verdict: {'PASS' if ok1 and ok2 and same else 'FAIL'}")
        return 0 if ok1 and ok2 and same else 1
    finally:
        for p in procs:
            if "void.tscn" in " ".join(map(str, p.args)):
                p.terminate()
                try:
                    p.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    p.kill()
        report.write_text("\n".join(LOG) + "\n", encoding="utf-8")
        print(f"\nreport: {report}")


if __name__ == "__main__":
    sys.exit(main())
