#!/usr/bin/env python3
"""TEST EVERY SPINE MAP — one command, one verdict.

2026-08-25, Palle: "fix so we can do test all spine maps?"

Testing a map meant remembering four tools and running them one at a time:
map_pathfinder for reachability, check_map_tokens for whether an artifact
token resolves to a scene, stamp_ready for the wall and the band,
verify_sequence for whether the sequence itself is coherent. Nobody was going
to do that across 229 maps, so nobody did.

    python tools/test_spine.py                  # every spine sequence
    python tools/test_spine.py --sequence=forces
    python tools/test_spine.py --placed          # the generated museums too
    python tools/test_spine.py --quick           # skip the pathfinder

Exit code is the number of FAILURES, so it gates.

WHAT COUNTS AS A FAILURE, and what does not. A pathfinder fail, a token that
resolves to nothing, or a sequence that does not verify — those break the
walk. A missing wall or an out-of-band size is a READINESS note, printed but
not fatal: 209 of 229 maps are out of band today, and a gate everything fails
is a gate nobody reads.

AND A MAP IN NO SEQUENCE IS A MAP NOTHING TESTS. That is why the generated
museums got commons/maps/sequences/placed_museums.json — every --all tool in
this project walks sequences, so 25 maps written this afternoon were
invisible to all of them until they belonged somewhere. check --all went from
631 maps to 656 the moment they did.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import stamp_ready as SR      # noqa: E402


def sequences(only="", placed=False):
    with open(os.path.join(ROOT, "commons", "maps", "curriculum_spine.json"), encoding="utf-8") as fh:
        names = [s["name"] for s in json.load(fh)["spine"]["sequences"]]
    if placed:
        names.append("placed_museums")
    if only:
        names = [n for n in names if n == only]
    out = []
    for sid in names:
        p = os.path.join(ROOT, "commons", "maps", "sequences", "%s.json" % sid)
        if not os.path.exists(p):
            continue
        with open(p, encoding="utf-8") as fh:
            doc = json.load(fh)
        seqs = doc["sequences"]
        block = seqs[0] if isinstance(seqs, list) else (seqs.get(sid) or list(seqs.values())[0])
        maps = [m if isinstance(m, str) else (m.get("map_id") or m.get("name")) for m in block.get("maps", [])]
        out.append((sid, [m for m in maps if m and os.path.exists(
            os.path.join(ROOT, "commons", "maps", m, "map_data.json"))]))
    return out


def run(cmd):
    return subprocess.run([sys.executable] + cmd, cwd=ROOT, capture_output=True, text=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sequence", default="")
    ap.add_argument("--placed", action="store_true", help="include placed_museums")
    ap.add_argument("--quick", action="store_true", help="skip the pathfinder")
    args = ap.parse_args()

    groups = sequences(args.sequence, args.placed)
    if not groups:
        print("no such sequence: %s" % args.sequence)
        return 1
    every = [m for _s, ms in groups for m in ms]
    print("TEST — %d map(s) across %d sequence(s)\n" % (len(every), len(groups)))

    # THE MUSEUM CAN NAME A HALL THAT NO LONGER EXISTS. map_authored.json is a
    # list of names, and a generator that comes back shorter deletes maps it
    # named last time — the ribbon cap took color from 9 halls to 7 and left
    # two dead names behind. The museum reads that file every build, so this
    # is an error, not a warning.
    ghosts = []
    ap_path = os.path.join(ROOT, "commons", "data", "map_authored.json")
    if os.path.exists(ap_path):
        with open(ap_path, encoding="utf-8") as fh:
            authored = json.load(fh)
        for ch, v in authored.items():
            if ch.startswith("_") or not isinstance(v, list):
                continue
            for m in v:
                if not os.path.exists(os.path.join(ROOT, "commons", "maps", m, "map_data.json")):
                    ghosts.append((ch, m))
    if ghosts:
        print("  GHOST HALLS — named in map_authored.json, not on disk:")
        for ch, m in ghosts:
            print("     %-16s %s" % (ch, m))
        print("")

    # ONE call each, not one per map: the token gate takes every map at once
    # and the pathfinder has its own --all
    tok_bad = set()
    r = run([os.path.join("tools", "check_map_tokens.py")] + ["--map=%s" % m for m in every])
    for line in (r.stdout or "").splitlines():
        if "->" in line and "MISSING" in line.upper():
            tok_bad.add(line.split()[0])
    tokens_ok = "OK: every interactable token resolves" in (r.stdout or "")

    path_bad = set()
    if not args.quick:
        r2 = run([os.path.join("tools", "map_pathfinder.py"), "check"] + every)
        cur = None
        for line in (r2.stdout or "").splitlines():
            s = line.strip()
            if s.startswith("Map:") or s.startswith("=== "):
                continue
            for m in every:
                if s.startswith(m):
                    cur = m
            if "[FAIL]" in s and cur:
                path_bad.add(cur)

    fails = len(ghosts)
    print("  %-24s %5s %6s %6s %8s  %s" % ("sequence", "maps", "verify", "ready", "notes", ""))
    for sid, maps in groups:
        v = run([os.path.join("tools", "verify_sequence.py"), sid])
        # ERRORS fail, warnings do not. verify_sequence prints "ALL CHECKS
        # PASSED" only when both are zero, so keying on that phrase counted a
        # sequence with four warnings as broken — which it is not, and a gate
        # that cries wolf on a warning is a gate that gets ignored.
        out = v.stdout or ""
        mm = re.search(r"(\d+) errors?, (\d+) warnings?", out)
        v_ok = ("ALL CHECKS PASSED" in out) or (mm is not None and mm.group(1) == "0")
        v_warn = int(mm.group(2)) if mm else 0
        ready = notes = 0
        for m in maps:
            with open(os.path.join(ROOT, "commons", "maps", m, "map_data.json"), encoding="utf-8") as fh:
                a = SR.analyse(json.load(fh))
            if not a["gaps"] and a["band"]:
                ready += 1
            else:
                notes += 1
        bad_here = [m for m in maps if m in path_bad or m in tok_bad]
        if not v_ok:
            fails += 1
        fails += len(bad_here)
        print("  %-24s %5d %6s %4d/%-3d %8d  %s"
              % (sid, len(maps), ("OK" if not v_warn else "OK*") if v_ok else "FAIL",
                 ready, len(maps), notes,
                 ("BROKEN: " + ", ".join(bad_here[:3])) if bad_here else
                 ("%d warning(s)" % v_warn if v_warn else "")))

    print("\n  tokens: %s" % ("every one resolves" if tokens_ok else "%d unresolved" % len(tok_bad)))
    if not args.quick:
        print("  pathfinder: %s" % ("every map reachable" if not path_bad
                                    else "%d map(s) failed" % len(path_bad)))
    tot_ready = sum(1 for _s, ms in groups for m in ms
                    if not SR.analyse(json.load(open(os.path.join(
                        ROOT, "commons", "maps", m, "map_data.json"), encoding="utf-8")))["gaps"])
    print("  readiness: %d of %d map(s) have a complete wall (not fatal)" % (tot_ready, len(every)))
    print("\n  %s" % ("ALL TESTS PASSED" if fails == 0 else "%d FAILURE(S)" % fails))
    return fails


if __name__ == "__main__":
    sys.exit(main())
