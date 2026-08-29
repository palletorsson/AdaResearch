#!/usr/bin/env python3
"""
em_autopilot.py — the endless museum's walkthrough gate, wrapped.

Runs the scene in --em-autopilot mode under the 16-second watchdog and judges
by the VERDICT FILE, not the exit code. The distinction matters: a successful
walk can still end in a watchdog kill, because by the time the walker crosses
its last threshold the streamer has dealt artifacts from the next chapter, and
some artifact scenes (the GPU marching-cubes class) hang engine teardown on
quit. The verdict is written before quitting, so the file is the truth and the
process's death is an implementation detail.

THE INTERLOCK (2026-08-28). A second Godot on the same project does not fail
loudly — it dies on the user:// lock, or worse, it boots and walks a tree the
resident editor is still saving into. On 2026-08-28 09:0x this gate answered
`no_route, frontier_z 7` while the editor had been up since 07:44 and
Point_One/map_data.json was written at 09:08:43, mid-run. The previous three
measured breaths had put the frontier at 21, 37 and 44. Nothing in the verdict
said "contended": it read exactly like a corridor severed seven rows in, and the
only reason the same reading was not acted on in the 2026-08-14 baseline is that
a human noticed the clock and wrote a caveat by hand.

So the tool now looks first, and refuses. A refusal writes its own verdict with
`reason: contended_builder`, so the gate reports which failure this is instead of
inheriting a corridor story. `--allow-contended` forces the old behaviour;
`--check` runs the detector alone and says what it sees.

Usage:
  python tools/em_autopilot.py                      # 3 museums, default order
  python tools/em_autopilot.py --museums=2 --first=chichu-buried-cells
  python tools/em_autopilot.py --check              # detector only, no boot
Exit 0 iff the verdict says done && ok; 3 if refused for a contended builder.
"""
from __future__ import annotations
import json
import os
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
VERDICT = REPO / "ada_run" / "em_autopilot.json"
GODOT = os.environ.get("GODOT_EXE", r"C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
CONTENDED_EXIT = 3


def _all_godot_processes() -> tuple[list[tuple[int, str]], str]:
    """Every live Godot process and its command line, plus how we found out.

    Returns ([(pid, cmdline)], source). A source of "" means the platform gave
    us no way to look — which is NOT the same as "nothing is running", and the
    caller must not read it as an all-clear.
    """
    try:
        import psutil  # type: ignore
    except ImportError:
        pass
    else:
        out: list[tuple[int, str]] = []
        for p in psutil.process_iter(["pid", "name", "cmdline"]):
            try:
                if "godot" in (p.info.get("name") or "").lower():
                    out.append((int(p.info["pid"]), " ".join(p.info.get("cmdline") or [])))
            except Exception:
                continue
        return out, "psutil"

    if sys.platform == "win32":
        # Win32_Process over CIM: wmic is gone from Windows 11, and tasklist
        # does not print a command line, which is the field that says WHICH
        # project a Godot is holding open.
        ps = ("Get-CimInstance Win32_Process -Filter \"Name like '%Godot%'\" | "
              "ForEach-Object { \"$($_.ProcessId)`t$($_.CommandLine)\" }")
        try:
            r = subprocess.run(["powershell", "-NoProfile", "-NonInteractive", "-Command", ps],
                               capture_output=True, text=True, timeout=30)
        except Exception:
            return [], ""
        if r.returncode != 0:
            return [], ""
        out = []
        for line in (r.stdout or "").splitlines():
            pid, _, cmd = line.partition("\t")
            if pid.strip().isdigit():
                out.append((int(pid.strip()), cmd.strip()))
        return out, "Win32_Process"

    try:
        r = subprocess.run(["ps", "-eo", "pid=,args="], capture_output=True, text=True, timeout=30)
    except Exception:
        return [], ""
    if r.returncode != 0:
        return [], ""
    out = []
    for line in (r.stdout or "").splitlines():
        pid, _, cmd = line.strip().partition(" ")
        if pid.isdigit() and "godot" in cmd.lower():
            out.append((int(pid), cmd.strip()))
    return out, "ps"


def _contenders() -> tuple[list[tuple[int, str]], str]:
    """Live Godot processes bound to THIS repo — the ones that share the lock.

    A Godot open on some other project has its own user:// and cannot collide,
    so matching on the repo path rather than on the name keeps the interlock
    from refusing work it has no business refusing. A Godot whose command line
    we cannot read is counted: an unattributable instance on this machine is
    exactly the one that already cost two runs.
    """
    procs, source = _all_godot_processes()
    if not source:
        return [], ""
    return _match(procs, str(REPO)), source


def _match(procs: list[tuple[int, str]], repo: str) -> list[tuple[int, str]]:
    """Which of these processes hold `repo`. Pure, so --selftest can prove it.

    Separator-blind on purpose: the editor writes `--path C:\\Users\\...` and the
    play-run it spawns writes `--path C:/Users/...`, and an interlock that saw
    only one of those spellings would have let exactly the pair that collided on
    2026-08-28 straight through.
    """
    here = repo.replace("\\", "/").lower()
    return [(pid, cmd) for pid, cmd in procs
            if not cmd.strip() or here in cmd.replace("\\", "/").lower()]


def _selftest() -> int:
    """Both directions, because a detector that never says no is not a gate."""
    repo = r"C:\Users\p\Documents\GitHub\AdaResearch_46"
    cases = [
        ("editor, backslashes", [(1, r"godot.exe --path C:\Users\p\Documents\GitHub\AdaResearch_46 --editor")], [1]),
        ("play-run, forward slashes", [(2, "godot.exe --path C:/Users/p/Documents/GitHub/AdaResearch_46 --scene x")], [2]),
        ("another project entirely", [(3, "godot.exe --path C:/Users/p/Documents/GitHub/SomethingElse --editor")], []),
        ("unreadable command line", [(4, "   ")], [4]),
        ("quiet machine", [], []),
        ("mixed", [(5, "godot.exe --path C:/other"), (6, r"godot.exe --path C:\Users\p\Documents\GitHub\AdaResearch_46")], [6]),
    ]
    bad = 0
    for name, procs, want in cases:
        got = [p for p, _ in _match(procs, repo)]
        ok = got == want
        bad += 0 if ok else 1
        print(f"  [{'ok' if ok else 'FAIL'}] {name}: expected {want}, got {got}")
    print(f"autopilot --selftest: {len(cases) - bad}/{len(cases)} passed")
    return 0 if bad == 0 else 1


def _write_refusal(hits: list[tuple[int, str]], source: str) -> None:
    """A refusal is a verdict too — and it must not look like a walk.

    Gate F reads this file for its metrics. Left empty, the gate would fall back
    to its -1 sentinels; left stale, it would republish yesterday's frontier as
    today's. Written, `reason` says contended_builder and every corridor field
    is absent rather than zero, because a zero here is a number nobody measured.
    """
    VERDICT.parent.mkdir(parents=True, exist_ok=True)
    VERDICT.write_text(json.dumps({
        "done": False,
        "ok": False,
        "reason": "contended_builder",
        "detector": source,
        "contenders": [{"pid": p, "cmd": c[:400]} for p, c in hits],
    }, indent=1), encoding="utf-8")


def main() -> int:
    museums = "3"
    first = ""
    allow_contended = False
    check_only = False
    for a in sys.argv[1:]:
        if a.startswith("--museums="):
            museums = a.split("=", 1)[1]
        elif a.startswith("--first="):
            first = a.split("=", 1)[1]
        elif a == "--allow-contended":
            allow_contended = True
        elif a == "--check":
            check_only = True
        elif a == "--selftest":
            return _selftest()

    hits, source = _contenders()
    if not source:
        print("autopilot: WARNING — no way to enumerate processes on this platform; "
              "the contended-builder interlock is not armed for this run")
    if check_only:
        print(f"autopilot --check: detector={source or 'none'}, "
              f"{len(hits)} Godot instance(s) on {REPO}")
        for pid, cmd in hits:
            print(f"  pid {pid}: {cmd[:200]}")
        return CONTENDED_EXIT if hits else 0
    if hits and not allow_contended:
        print(f"autopilot: REFUSED — {len(hits)} Godot instance(s) already hold this project "
              f"(detector={source}). A second boot either dies on the user:// lock or walks a "
              f"tree the resident session is still saving into, and its verdict then reads as a "
              f"fact about the corridor.")
        for pid, cmd in hits:
            print(f"  pid {pid}: {cmd[:200]}")
        print("  close them, or pass --allow-contended to measure anyway.")
        _write_refusal(hits, source)
        return CONTENDED_EXIT
    cmd = [sys.executable, str(REPO / "tools" / "godot_watchdog.py"),
           f"--expect={VERDICT}", "--stall=20", "--",
           GODOT, "--path", ".", "--xr-mode", "off", "--no-window",
           "res://commons/scenes/endless_museum.tscn", "--",
           f"--em-autopilot={museums}"]
    if first:
        cmd.append(f"--em-first={first}")
    # Up to three attempts: the engine can die on a GPU-artifact access
    # violation during boot (nondeterministic, unrelated to the corridor), and
    # a crash with NO verdict is an engine fact, not a walk verdict. A written
    # verdict — pass or fail — is always final on the spot.
    for attempt in range(1, 4):
        if VERDICT.exists():
            VERDICT.unlink()
        subprocess.run(cmd, cwd=REPO)
        if not VERDICT.exists():
            print(f"autopilot: attempt {attempt} crashed before any verdict; "
                  f"{'retrying' if attempt < 3 else 'giving up'}")
            continue
        v = json.loads(VERDICT.read_text(encoding="utf-8"))
        if not v.get("done"):
            print(f"autopilot: attempt {attempt} died mid-walk (engine, not corridor); "
                  f"{'retrying' if attempt < 3 else 'giving up'}")
            continue
        ok = bool(v.get("ok"))
        # cells_unlearned alone once read as a fact about the corridor when it
        # was a fact about the planner — 26 "cells" were 8 cells and 18 stalls
        # against a dead plan. Print the three fields that tell them apart.
        stalls = v.get("stall_events")
        extra = ""
        if stalls is not None:
            extra = (f", {stalls} stall events, frontier z={v.get('frontier_z')}"
                     f", reason={v.get('reason') or 'none'}")
        print(f"autopilot: {'PASS' if ok else 'FAIL'} (attempt {attempt}) — "
              f"{v.get('museums_target')} museums{' from ' + first if first else ''}, "
              f"z={v.get('z'):.1f}/{v.get('goal_z'):.1f}, {v.get('elapsed_s'):.1f}s walked, "
              f"{v.get('cells_unlearned', 0)} cells unlearned{extra}")
        return 0 if ok else 1
    print("autopilot: NO VERDICT in 3 attempts — the scene never got far enough to write one")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
