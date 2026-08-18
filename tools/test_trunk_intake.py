#!/usr/bin/env python3
"""The intake, proven on the paragraph it was built for.

Palle's stream (2026-08-17) is the fixture. Asserts what the heuristic MUST
get right — the node stays sticky through the stream, the readings that
name their kind loudly are typed, no token is ever invented — and then
round-trips a candidate through pending -> keep on a TEMP copy of the trunk
file: the seeder carries pending, keep makes a hand branch, hero_walk sees
it. Prints every clause's verdict so a wrong one is visible, not just counted.

    python tools/test_trunk_intake.py
"""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from trunk_intake import TokenIndex, propose, write_pending  # noqa: E402
from build_trunk_branches import OUT  # noqa: E402
import hero_walk  # noqa: E402

PARAGRAPH = (
    "point, o before the point?, throwiness, ok the point, o a vector, must have body, ok must have "
    "interactive be grabbable, things spiral fast, already, a big framework, the have a point. To point "
    "a line, Line. a line is also always measure, a line in many thing, lazer, trajectories, divider, "
    "end of the line, a line in the sand, vertical line horizontal line, many line for a grid, before "
    "that the trace, that with the line can hold, the resolution of the line, the digital is always "
    "crocked, but it not reasonable to register every part of the trace, and there is no original. "
    "Then the triangle, and the angle, all we need not build meshes, what can we build, think more of "
    "triangles, etc etc."
)


def main() -> int:
    fails: list[str] = []
    idx = TokenIndex()
    rows = propose(PARAGRAPH, "", idx)          # NO hint: the first word must carry the node
    for r in rows:
        print(f"  {r['anchor'] or '?':12s} {r['kind'] or '?':12s} {r['space'] or '-':6s} "
              f"{(r['token'] or '(' + str(len(r['token_options'])) + ' options)'):34s} | {r['why'][:64]}")

    def find(sub: str) -> dict:
        for r in rows:
            if sub in r["why"]:
                return r
        fails.append(f"no clause contains {sub!r}")
        return {}

    if len(rows) < 8:
        fails.append(f"only {len(rows)} candidates")
    if any(r["anchor"] != "primitives" for r in rows):
        fails.append("a clause left primitives: " + ", ".join(r["why"][:30] for r in rows if r["anchor"] != "primitives"))
    inherited = sum(1 for r in rows if r["cues"]["node"] == "sticky")
    if inherited < 3:
        fails.append(f"the sticky node carried only {inherited} clause(s)")
    r = find("also always measure")
    if r and r.get("kind") not in ("queers", "contradicts"):
        fails.append(f"'a line is also always measure' typed {r.get('kind')!r}")
    r = find("always crocked")
    if r and r.get("kind") != "contradicts":
        fails.append(f"'the digital is always crocked' typed {r.get('kind')!r}")
    r = find("no original")
    if r and r.get("kind") != "contradicts":
        fails.append(f"'there is no original' typed {r.get('kind')!r}")
    r = find("before the point")
    if r and r.get("kind") != "edge":
        fails.append(f"'before the point?' typed {r.get('kind')!r}")
    r = find("think more of triangles")
    if r and r.get("kind") != "hero":
        fails.append(f"'think more of triangles' typed {r.get('kind')!r}")
    r = find("many line for a grid")
    if r and r.get("kind") != "varies":
        fails.append(f"'many line for a grid' typed {r.get('kind')!r} (a series)")
    reg = set(idx.reg.keys())
    bad = [r["token"] for r in rows if r["token"] and r["token"] not in reg]
    if bad:
        fails.append("invented tokens: " + ", ".join(bad))
    blank_kind = sum(1 for r in rows if not r["kind"])
    print(f"  -- {len(rows)} clauses · {blank_kind} kind left blank · "
          f"{sum(1 for r in rows if r['token'])} tokens named, {sum(1 for r in rows if not r['token'])} left to the hand")

    # ── round trip on a TEMP copy: write pending -> seeder carries it -> keep -> hero walk
    tmp = Path(tempfile.mkdtemp()) / "trunk_branches.json"
    shutil.copy(OUT, tmp)
    before = json.loads(tmp.read_text(encoding="utf-8"))
    hand0 = int(before["counts"].get("hand", 0))
    pend0 = len(before.get("pending", []))          # the live file may already hold candidates
    info = write_pending(rows, tmp)
    if info["added"] != len(rows):
        fails.append(f"write_pending added {info['added']} of {len(rows)}")
    info2 = write_pending(rows, tmp)
    if info2["added"] != 0:
        fails.append("a second write of the same paragraph duplicated rows")
    # the seeder must carry pending verbatim
    subprocess.run([sys.executable, str(REPO / "tools" / "build_trunk_branches.py"), "--out", str(tmp)],
                   check=True, capture_output=True, cwd=REPO)
    d = json.loads(tmp.read_text(encoding="utf-8"))
    if len(d.get("pending", [])) != pend0 + len(rows):
        fails.append(f"the seeder lost pending on reseed ({len(d.get('pending', []))} of {pend0 + len(rows)})")
    # keep: the queers reading becomes a hand branch on primitives (python twin of the API's op:keep)
    pick = next(p for p in d["pending"] if "also always measure" in p["why"])
    pick_kind = pick["kind"] or "queers"
    d["pending"] = [p for p in d["pending"] if p["id"] != pick["id"]]
    d["branches"].append({"anchor": pick["anchor"], "token": pick["token"] or "grabbable_line",
                          "kind": pick_kind, "why": pick["why"], "via": "intake", "provenance": "hand",
                          "space": pick["space"] or "room", "space_by": "heuristic", "at": pick["at"]})
    d["counts"]["hand"] = sum(1 for b in d["branches"] if b["provenance"] == "hand")
    d["counts"]["pending"] = len(d["pending"])
    tmp.write_text(json.dumps(d), encoding="utf-8")
    if d["counts"]["hand"] != hand0 + 1:
        fails.append("keep did not add exactly one hand branch")
    walk = hero_walk.hero_walk("primitives", d)
    if not walk:
        fails.append("hero_walk did not open primitives after the keep")
    elif (pick["token"] or "grabbable_line") not in walk.get("cast", []):
        fails.append("the kept reading is not in primitives' walk")
    else:
        print(f"  -- keep: primitives now walks with {walk['hand_branches']} hand branch(es); pending {d['counts']['pending']}")
    live = json.loads(OUT.read_text(encoding="utf-8"))
    if live["counts"].get("hand") != hand0 or len(live.get("pending", [])) != len(before.get("pending", [])):
        fails.append("the LIVE trunk file changed during the test")
    shutil.rmtree(tmp.parent, ignore_errors=True)

    if fails:
        print(f"TRUNK INTAKE: FAIL {len(fails)}")
        for f in fails:
            print("  - " + f)
        return 1
    print("TRUNK INTAKE: PASS — sticky node, loud kinds typed, no invented token, pending -> keep -> walk")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
