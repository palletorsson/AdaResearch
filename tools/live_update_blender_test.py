"""live_update_blender_test.py — Blender as the third live editor, end to end, with a log.

2026-10-22. The chain is the one the web editor drives (doc/LIVE_UPDATE_BRIDGE.md):
Blender (tools/blender/ada_void) reads GET /api/void-layout + the glTF export,
moves a mount, saves through POST /api/void-layout {rooms, revision}; the route
diffs the floor, tools/vr_link.py broadcasts the revision, the desktop's
commons/bridge/live_update.gd (and a headset's, if one is attached) answers.

  python tools/live_update_blender_test.py                 # starts the bridge if down, void.tscn on floor 10, Blender headless
  python tools/live_update_blender_test.py --no-game       # a desktop Void is already attached (yours)
  python tools/live_update_blender_test.py --quest         # also require an Android ack
  python tools/live_update_blender_test.py --render out.png --samples 64   # add a Cycles still at the end

Steps (in Blender, tools/blender/ada_void/headless.py): import floor 10; verify the
glTF importer's axis conversion against the raw glb and the film artifact's record;
an untouched import reads back to the same document; move film_profile_travels
+1.5 m in x, publish, wait for `applied in_place`; move it back, publish again.
Here: rooms.json must be byte-identical afterwards and the ledger
(ada_run/live_updates.jsonl) must hold both acks. Report in
ada_run/live_update_blender_test_<stamp>.md. Needs the encyclopedia on :3003.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def _load_chain():
    """tools/blender/ada_void/chain.py is pure Python; load it by path so the package's
    __init__ (which imports bpy) is never run outside Blender."""
    import importlib.util
    spec = importlib.util.spec_from_file_location("ada_void_chain", ROOT / "tools" / "blender" / "ada_void" / "chain.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


chain = _load_chain()

ENC = os.environ.get("ADA_ENC_URL", "http://localhost:3003")
BRIDGE = os.environ.get("ADA_VR_LINK_URL", "http://127.0.0.1:8772")
GODOT = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
BLENDER = os.environ.get("BLENDER_EXE", r"C:\Program Files\Blender Foundation\Blender 4.2\blender.exe")
FILM = "museum-primitives_profiles-15-1"
LOG: list[str] = []


def say(line: str) -> None:
    print(line)
    LOG.append(line)


def bridge_state() -> dict:
    code, j = chain.http("GET", f"{BRIDGE}/state", timeout=3)
    return j if code == 200 else {}


def wait_for(pred, what: str, timeout: float, every: float = 1.0) -> bool:
    t0 = time.time()
    while time.time() - t0 < timeout:
        if pred():
            return True
        time.sleep(every)
    say(f"  TIMEOUT waiting {timeout:.0f}s for {what}")
    return False


def ledger_acks(rid: str) -> list[dict]:
    path = ROOT / "ada_run" / "live_updates.jsonl"
    out = []
    if not path.exists():
        return out
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        try:
            r = json.loads(line)
        except json.JSONDecodeError:
            continue
        if r.get("k") == "update_ack" and r.get("revision_id") == rid:
            out.append(r)
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--floor", type=int, default=10)
    ap.add_argument("--id", default=FILM, help="the artifact to move (default: the film artifact on floor 10)")
    ap.add_argument("--dx", type=float, default=1.5)
    ap.add_argument("--no-game", action="store_true", help="a desktop Void with --vr-link is already attached")
    ap.add_argument("--no-bridge", action="store_true", help="do not start vr_link.py")
    ap.add_argument("--quest", action="store_true", help="also require an Android ack")
    ap.add_argument("--attach-timeout", type=float, default=90.0)
    ap.add_argument("--ack-wait", type=float, default=10.0)
    ap.add_argument("--render", default="", help="also render a still to this path (Cycles)")
    ap.add_argument("--samples", type=int, default=64)
    ap.add_argument("--blend", default="", help="save the .blend here")
    ap.add_argument("--keep-game", action="store_true")
    args = ap.parse_args()

    stamp = time.strftime("%Y%m%d-%H%M%S")
    (ROOT / "ada_run").mkdir(exist_ok=True)
    report_md = ROOT / "ada_run" / f"live_update_blender_test_{stamp}.md"
    report_json = ROOT / "ada_run" / f"live_update_blender_test_{stamp}.json"
    say(f"# Live update test (Blender) {stamp}")
    say("")

    code, _ = chain.http("GET", f"{ENC}/api/live-update", timeout=5)
    if code == 0:
        say(f"encyclopedia not reachable at {ENC} — start `npm run dev` in ada_encyclopedia")
        return 2
    rooms_file = ROOT / "commons" / "void" / "rooms.json"
    text0 = rooms_file.read_text(encoding="utf-8")

    procs: list[subprocess.Popen] = []
    try:
        if not args.no_bridge and not bridge_state():
            procs.append(subprocess.Popen([sys.executable, str(ROOT / "tools" / "vr_link.py")], cwd=ROOT,
                                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
            wait_for(lambda: bool(bridge_state()), "vr_link.py on :8772", 20)
        say(f"bridge: {'up' if bridge_state() else 'DOWN'} at {BRIDGE}")

        devices = set()
        if not args.no_game:
            procs.append(subprocess.Popen([GODOT, "--path", str(ROOT), "--xr-mode", "off",
                                           "res://commons/void/void.tscn", "--",
                                           f"--void-start-floor={args.floor}", "--vr-link"], cwd=ROOT,
                                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
            say(f"desktop game launched: void.tscn --void-start-floor={args.floor} --vr-link")
        if not args.no_game or not args.quest:
            devices.add("Windows")
        if args.quest:
            devices.add("Android")

        def attached() -> bool:
            st = bridge_state()
            names = st.get("game_names") or []
            have = {n.split("/")[0] for n in names}
            return bool(st.get("connected")) and devices <= have
        if not wait_for(attached, f"{sorted(devices)} to attach", args.attach_timeout, every=2.0):
            return 1
        st = bridge_state()
        say(f"attached: {st.get('game_names')} proj={(st.get('pose') or {}).get('proj')}")
        time.sleep(5.0)  # let the start floor finish building

        # Blender does the editing
        hl = ROOT / "tools" / "blender" / "ada_void" / "headless.py"
        cmd = [BLENDER, "-b", "-P", str(hl), "--", "--floor", str(args.floor), "--move", args.id, str(args.dx), "0",
               "--report", str(report_json), "--wait", str(args.ack_wait), "--expect", str(len(devices)), "--enc", ENC]
        if args.render:
            cmd += ["--render", args.render, "--samples", str(args.samples)]
        if args.blend:
            cmd += ["--blend", args.blend]
        say("")
        say("## Blender headless: " + " ".join(c if " " not in c else f'"{c}"' for c in cmd[1:]))
        t = time.time()
        env = {**os.environ, "ADA_ENC_URL": ENC}
        r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace", env=env, timeout=1800)
        for line in r.stdout.splitlines():
            if line.startswith("[headless]") or line.startswith("[ada_void]"):
                say("  " + line)
        if r.returncode != 0 and not report_json.exists():
            say(f"  blender exited {r.returncode}; tail of its output:")
            for line in (r.stdout + r.stderr).splitlines()[-25:]:
                say("    " + line)
            return 1
        say(f"  blender finished in {time.time() - t:.0f} s (exit {r.returncode})")
        rep = json.loads(report_json.read_text(encoding="utf-8"))

        say("")
        say("## checks")
        allok = True
        for name, c in rep.get("checks", {}).items():
            say(f"  {'PASS' if c['pass'] else 'FAIL'} {name}: {c['detail']}")
            allok = allok and c["pass"]

        say("")
        say("## the ledger (ada_run/live_updates.jsonl)")
        rids = []
        for p in rep.get("publishes", []):
            for rid in p.get("acks", {}):
                rids.append((p["step"], rid))
        for step, rid in rids:
            acks = ledger_acks(rid)
            want = {d for d in devices}
            got = {str(a.get("device")) for a in acks if a.get("status") == "applied" and a.get("mode") in ("in_place", "data")}
            ok = want <= got and all(a.get("mode") == "in_place" for a in acks if a.get("device") == "Windows")
            allok = allok and ok
            say(f"  step {step} {rid}: " + (" · ".join(f"{a.get('name') or a.get('device')} {a.get('status')} {a.get('mode') or ''}" for a in acks) or "no ack row") + f" -> {'PASS' if ok else 'FAIL'}")
        if not rids:
            say("  no revision was published")
            allok = False

        text1 = rooms_file.read_text(encoding="utf-8")
        same = text1 == text0
        allok = allok and same
        say("")
        say(f"## rooms.json byte-identical afterwards: {same}")
        if rep.get("render", {}).get("file"):
            say(f"## render: {rep['render']['file']} ({rep['render'].get('seconds')} s, {rep['render'].get('device')})")
        say("")
        say(f"## verdict: {'PASS' if allok else 'FAIL'}")
        return 0 if allok else 1
    finally:
        if not args.keep_game:
            for p in procs:
                if p.args and "void.tscn" in " ".join(map(str, p.args)):
                    p.terminate()
                    try:
                        p.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        p.kill()
        report_md.write_text("\n".join(LOG) + "\n", encoding="utf-8")
        print(f"\nreport: {report_md}")


if __name__ == "__main__":
    sys.exit(main())
