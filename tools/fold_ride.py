#!/usr/bin/env python3
"""fold_ride.py — Fold 5: walk the built room and file the ride back into the book.

Runs gaze_ride on a map, parses the token stream, and distills the machine's
field observations — what filled the view, what was never seen, what collides —
into doc/book/ride_logs/<seq>.json. The tutorial builder attaches it to the
chapter's "In the World" page; the manuscript prints it as the second machine
register (the first is the dig). The book reads the room it wrote.

Usage:
  python tools/fold_ride.py <MapName> --seq=<seq>
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.environ.get("ADA_ENCYCLOPEDIA_PATH", "C:/Users/palle/Documents/GitHub/ada_encyclopedia")
TUTORIAL_DIR = os.path.join(ENC, "public", "tutorial")
OUT_DIR = os.path.join(REPO, "doc", "book", "ride_logs")


def main() -> int:
    args = sys.argv[1:]
    map_name = next((a for a in args if not a.startswith("--")), None)
    seq = next((a.split("=", 1)[1] for a in args if a.startswith("--seq=")), None)
    if not map_name or not seq:
        print(__doc__)
        return 1

    t = json.load(open(os.path.join(TUTORIAL_DIR, f"{seq}.json"), encoding="utf-8"))
    walked = set()
    for p in t.get("pages", []):
        if p["kind"] == "primitive" and isinstance(p.get("artifact"), dict):
            walked.add(p["artifact"]["name"])
        elif p["kind"] == "walk":
            walked |= {a["name"] for a in p.get("artifacts") or []}

    r = subprocess.run([sys.executable, os.path.join(REPO, "tools", "gaze_ride.py"), map_name],
                       capture_output=True, text=True, encoding="utf-8", cwd=REPO)
    log = r.stdout
    if not log.strip():
        print(f"!! gaze_ride produced nothing: {r.stderr[:300]}")
        return 1

    bodies = re.search(r"(\d+) bodies", log)
    sizes = {m.group(1): float(m.group(2))
             for m in re.finditer(r"^  (\S+)\s+base\s+([\d.]+)m", log, re.M)}
    steps = re.findall(r"^  step \d+\s+@\([^)]*\)\s+->\s+(\S+)", log, re.M)
    gazed: dict[str, list[float]] = {}
    for m in re.finditer(r"^    (\S+)\s+(?:HUGE|big|med|small)\s+(\d+)deg", log, re.M):
        gazed.setdefault(m.group(1), []).append(float(m.group(2)))
    # real collisions only: both bodies walked, centers apart (centers 0.0 = an
    # artifact seated ON its own plinth — correct seating, not an overlap)
    overlaps = []
    for m in re.finditer(r"\[OVERLAP\] (\S+)\s+<->\s+(\S+)\s+gap (-[\d.]+)m \(centers ([\d.]+)m\)", log):
        a, b, gap, centers = m.group(1), m.group(2), float(m.group(3)), float(m.group(4))
        if centers > 0.5 and a in walked and b in walked:
            overlaps.append((a, b, gap))

    visited = set(steps)
    seen_walked = {n: v for n, v in gazed.items() if n in walked}
    ghosts = sorted(n for n in walked if n not in visited and n not in gazed)
    blind = sorted(n for n in walked if n in visited and n not in gazed)
    dominant = max(seen_walked, key=lambda n: len(seen_walked[n])) if seen_walked else None
    smallest = min((n for n in walked if n in sizes), key=lambda n: sizes[n], default=None)

    lines = [f"{len(steps)} stations from spawn to exit; "
             f"{bodies.group(1) if bodies else '?'} bodies measured."]
    for n in ghosts:
        lines.append(f"{n} ({sizes.get(n, 0):.1f} m) was neither visited nor seen — "
                     "the biggest body in the room is missing from its own ride.")
    if blind:
        lines.append(f"{len(blind)} of {len(walked)} walked bodies appear only on arrival, "
                     "never from a distance — the gallery hides its exhibits until you "
                     "stand at them.")
    if dominant:
        v = seen_walked[dominant]
        lines.append(f"{dominant} held the view at {len(v)} of {len(steps)} stations, "
                     f"peaking at {int(max(v))}° — the room has one voice louder than the rest.")
    if smallest and smallest in sizes:
        lines.append(f"the smallest walked body is {smallest} at {sizes[smallest]:.1f} m.")
    for a, b, gap in overlaps:
        lines.append(f"{a} and {b} overlap by {abs(gap):.1f} m — two exhibits share ground.")
    if not overlaps:
        lines.append("no two exhibits share ground.")

    os.makedirs(OUT_DIR, exist_ok=True)
    with open(os.path.join(OUT_DIR, f"{map_name}.log.md"), "w", encoding="utf-8") as f:
        f.write(f"# gaze_ride — {map_name}\n\n```\n{log}\n```\n")
    with open(os.path.join(OUT_DIR, f"{seq}.json"), "w", encoding="utf-8") as f:
        json.dump({"map": map_name, "lines": lines}, f, indent=1, ensure_ascii=False)
    print(f"ride log -> doc/book/ride_logs/{seq}.json ({len(lines)} observations)")
    for ln in lines:
        print("  ·", ln)
    # the ride as a graph: the loudest gaze angle at each station
    step_maxes = []
    for block in re.split(r"^  step ", log, flags=re.M)[1:]:
        degs = [float(d) for d in re.findall(r"(?:HUGE|big|med|small)\s+(\d+)deg", block)]
        step_maxes.append(max(degs) if degs else 0.0)
    sys.path.insert(0, os.path.join(REPO, "tools"))
    from book_log import log_event
    log_event("ride", f"{map_name} walked and folded into {seq}: {len(lines)} observations"
                      + (f"; ghosts: {', '.join(ghosts)}" if ghosts else "")
                      + " — gaze profile per station:",
              spark=step_maxes)
    return 0


if __name__ == "__main__":
    sys.exit(main())
