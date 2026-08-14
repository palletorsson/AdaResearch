#!/usr/bin/env python3
"""check_interaction.py — drive each artifact's controls and see whether anything moves.

WHAT IT CLOSES. Until now "interactive" in this corpus has meant "the file contains the word
grab". A static grep proves an affordance is DECLARED; it cannot prove the button is wired,
that the artifact listens, or that anything changes when it fires. This instantiates the
artifact, emits its controls' own signals, nudges its grabbables, and measures the subtree
before and after.

EVERY VERDICT IS AGAINST A NEGATIVE CONTROL. commons/testing/probe_interaction.gd snapshots
the subtree, waits, snapshots again to learn what the artifact does BY ITSELF, and only then
fires. A vortex that spins, a ball that falls and a field that advects would all "change
after a button press" without the button doing anything, so the response has to clear the
artifact's own drift by 2x and clear an absolute floor. An artifact that drifts as much as it
responded is reported INCONCLUSIVE rather than green.

ONE GODOT AT A TIME. The runs are serialized through the watchdog; two instances die on the
user:// lock.

Usage:
  python tools/check_interaction.py --tokens=a,b,c
  python tools/check_interaction.py --category=vectors --limit=20
"""
from __future__ import annotations
import glob
import json
import os
import pathlib
import subprocess
import sys

REPO = pathlib.Path(__file__).resolve().parents[1]
REG = REPO / "commons" / "artifacts" / "registry"
OUT = REPO / "ada_run" / "interaction"
GODOT = os.environ.get("GODOT_EXE", r"C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")


def registry() -> dict:
    out = {}
    for f in sorted(glob.glob(str(REG / "*.json"))):
        try:
            d = json.loads(pathlib.Path(f).read_text(encoding="utf-8")).get("artifacts", {})
        except Exception:
            continue
        for t, e in (d or {}).items():
            if isinstance(e, dict):
                out[t] = e
    return out


def run_one(token: str, entry: dict) -> dict | None:
    scene = str(entry.get("scene") or "")
    if not scene:
        return None
    fixture = ((entry.get("dna") or {}).get("fixture") or {})
    done = OUT / "_done.txt"
    if done.exists():
        done.unlink()
    OUT.mkdir(parents=True, exist_ok=True)
    cmd = [sys.executable, str(REPO / "tools" / "godot_watchdog.py"),
           f"--expect={done.as_posix()}", "--",
           GODOT, "--path", str(REPO), "--xr-mode", "off", "--headless",
           "--script", "res://commons/testing/probe_interaction.gd", "--",
           f"--scene={scene}", f"--label={token}", "--out=res://ada_run/interaction"]
    if fixture:
        cmd.append("--fixture=" + json.dumps(fixture))
    try:
        subprocess.run(cmd, cwd=str(REPO), capture_output=True, text=True, timeout=420)
    except subprocess.TimeoutExpired:
        return {"label": token, "verdict": "TIMEOUT"}
    p = OUT / f"{token}.json"
    if not p.exists():
        return {"label": token, "verdict": "no result"}
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return {"label": token, "verdict": "unreadable result"}


# ── corpus mode ──────────────────────────────────────────────────────────────

CHUNK = 60
LIST = REPO / "ada_run" / "interaction_list.json"


def run_chunk(items: list) -> None:
    """One boot, many artifacts. Results land as they go, so a crash costs the remainder."""
    done = OUT / "_done.txt"
    if done.exists():
        done.unlink()
    OUT.mkdir(parents=True, exist_ok=True)
    LIST.parent.mkdir(parents=True, exist_ok=True)
    LIST.write_text(json.dumps(items, indent=1), encoding="utf-8")
    cmd = [sys.executable, str(REPO / "tools" / "godot_watchdog.py"),
           f"--expect={OUT}", "--",
           GODOT, "--path", str(REPO), "--xr-mode", "off", "--headless",
           "--script", "res://commons/testing/probe_interaction.gd", "--",
           f"--list=res://ada_run/interaction_list.json", "--out=res://ada_run/interaction"]
    try:
        subprocess.run(cmd, cwd=str(REPO), capture_output=True, text=True, timeout=3600)
    except subprocess.TimeoutExpired:
        pass


def corpus(resume: bool = True) -> int:
    reg = registry()
    todo = []
    for t, e in sorted(reg.items()):
        scene = str(e.get("scene") or "")
        if not scene:
            continue
        if resume and (OUT / f"{t}.json").exists():
            continue
        fx = ((e.get("dna") or {}).get("fixture") or {})
        item = {"label": t, "scene": scene}
        if fx:
            item["fixture"] = fx
        todo.append(item)
    print(f"{len(todo)} artifacts to measure "
          f"({len(list(OUT.glob('*.json'))) if OUT.exists() else 0} already on disk)")
    for i in range(0, len(todo), CHUNK):
        chunk = todo[i:i + CHUNK]
        print(f"  chunk {i // CHUNK + 1}/{(len(todo) + CHUNK - 1) // CHUNK} "
              f"({len(chunk)} artifacts) …", flush=True)
        run_chunk(chunk)
    return 0


def main() -> int:
    tokens, category, limit = [], "", 0
    for a in sys.argv[1:]:
        if a.startswith("--tokens="):
            tokens = [x.strip() for x in a.split("=", 1)[1].split(",") if x.strip()]
        elif a.startswith("--category="):
            category = a.split("=", 1)[1]
        elif a.startswith("--limit="):
            limit = int(a.split("=", 1)[1])
    if "--corpus" in sys.argv:
        return corpus(resume="--fresh" not in sys.argv)
    reg = registry()
    if category:
        tokens = [t for t, e in sorted(reg.items())
                  if str(e.get("category", "")).lower() == category.lower() and e.get("scene")]
    if not tokens:
        print(__doc__)
        return 2
    if limit:
        tokens = tokens[:limit]

    print(f"{'artifact':<44}{'ctrls':>6}{'grabs':>6}{'drift':>9}{'response':>10}  verdict")
    print("-" * 100)
    rows = []
    for t in tokens:
        e = reg.get(t)
        if not e:
            print(f"{t:<44}{'not in any registry':>31}")
            continue
        r = run_one(t, e)
        if r is None:
            print(f"{t:<44}{'no scene':>31}")
            continue
        rows.append(r)
        print(f"{t:<44}{r.get('controls_found', 0):>6}{r.get('grabbables_found', 0):>6}"
              f"{r.get('drift', 0):>9.4f}{r.get('response', 0):>10.4f}  {r.get('verdict','?')}")
    print("-" * 100)
    tally = {}
    for r in rows:
        v = str(r.get("verdict", "?")).split(" -")[0]
        tally[v] = tally.get(v, 0) + 1
    for v, n in sorted(tally.items(), key=lambda kv: -kv[1]):
        print(f"  {n:>3}  {v}")
    rep = REPO / "doc" / "reports" / "interaction.json"
    rep.parent.mkdir(parents=True, exist_ok=True)
    rep.write_text(json.dumps({
        "_note": "Each verdict is measured against a NEGATIVE CONTROL: the subtree is "
                 "snapshotted, left alone for one interval to learn what it does by itself, "
                 "and only then are its controls fired. A response must clear that drift by "
                 "2x. 'inconclusive' means the artifact moves as much on its own as it did "
                 "when driven, which is a fact about the artifact and not a pass.",
        "rows": rows}, indent=1), encoding="utf-8")
    print(f"-> {rep.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
