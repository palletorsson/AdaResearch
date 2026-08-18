#!/usr/bin/env python3
"""The mode may decide only WHO MOVES THE EYE and the desktop keys — nothing
about what is BUILT. Counts every live `_vr` fork in endless_museum.gd and
names them; more than the allowed set fails. (2026-08-18: fifteen forks gave
VR a museum that never streamed and culled the room the visitor stood in.)"""
import re, sys
from pathlib import Path
P = Path(__file__).resolve().parent.parent / "commons/scenes/endless_museum.gd"
ALLOWED = {
    "_eye_pos": "who moves the eye",
    "_setup_world": "the rig builds the walker/camera or not",
    "_process": "wait for the XR camera before streaming",
    "_input": "the desktop keys (SPACE jump, TAB editor)",
}
src = P.read_text(encoding="utf-8").split("\n")
func = ""
forks = []
for i, line in enumerate(src, 1):
    m = re.match(r"^func (\w+)", line)
    if m:
        func = m.group(1)
    if line.lstrip().startswith("var _vr"):
        continue                                     # the declaration, not a fork
    code = line.split("#", 1)[0]
    if re.search(r"\bnot _vr\b|\bif _vr\b|\b_vr\s*(and|or)\b|(and|or)\s*_vr\b|\b_vr\s*:", code) and "_vr_" not in code and "_force_vr" not in code:
        forks.append((i, func, code.strip()))
bad = [f for f in forks if f[1] not in ALLOWED]
print(f"{len(forks)} mode fork(s) in endless_museum.gd:")
for i, fn, c in forks:
    print(f"  {'ok ' if fn in ALLOWED else 'BAD'} {i:5d} {fn:14s} {c[:70]}")
if bad:
    print(f"MODE FORKS: FAIL — {len(bad)} fork(s) outside {sorted(ALLOWED)}: the mode is deciding what is built")
    sys.exit(1)
print("MODE FORKS: PASS — the mode decides only the eye and the desktop keys")
