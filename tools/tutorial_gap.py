#!/usr/bin/env python3
"""WHICH OF A ROOM'S OWN ARTIFACTS ITS TUTORIAL NEVER NAMES.

    python tools/tutorial_gap.py                 # the whole corpus
    python tools/tutorial_gap.py --map=Array_Patterns
    python tools/tutorial_gap.py --named          # what IS named, for once
    python tools/tutorial_gap.py --json

2026-08-31, Palle: "I need a similar thing for the tutorials. But can we do the
other way around, like a process where we find the artifact in the tutorial text?
The tutorial also needs code formatting, what is the status? Can we make the
right call here?"

THE MEASUREMENT CAME BACK AGAINST BOTH HALVES OF THE QUESTION, so this tool is
the third thing.

Code formatting is not a gap. All 244 tutorials carry fenced blocks — 1698 of
them, 1694 tagged gdscript, the other four python/text/json. There is nothing to
fix and nothing to build.

Finding artifacts in the tutorial text would find almost nothing. Scoped to each
tutorial's OWN room — not to all 2899 registry tokens, which is where the
concordance's 67.7% junk rate comes from — only 100 of 1402 placed artifacts are
named in the tutorial of the room they stand in. 7%. 173 of 242 tutorials name
none at all. A propose-and-confirm queue over that would be empty most of the
time.

MATCHING THE CODE IS WORSE, and was tested before it was dismissed: 6 of 60
distinctive code lines sampled from tutorials appear verbatim in any artifact
source, and the six are false friends — `modulate = Color(0.7, 0.9, 0.7)`,
`var mat := ParticleProcessMaterial.new()`. Tutorial code is WRITTEN for the
tutorial. There is no provenance to recover.

WHAT IS ACTUALLY THERE IS THE ABSENCE, and it is not a genre mismatch — checked
by reading two of the silent ones. Accumulation_Riemann teaches `riemann_sum()`
as a function while riemann_sum_workbench, riemann_pi, integral_area and
riemann_pump stand in that room unnamed. Array_Patterns says "paint sixteen cells
and watch them multiply" over a room holding pattern_tile_4x4, tiling_demo and
panel_bridge_loom. The tutorial and the room teach the same thing in two
vocabularies that never meet. That is a writing prompt with 1302 entries, and it
is worth more than a tagger.

THE RULE, and it is deliberately generous in the direction of "already named":
a token counts as named if its lookup name appears anywhere in the text, or if
its display name does and is longer than six characters. Generous means this
UNDER-reports the gap, which is the safe error: it will not send anyone to write
about a work the tutorial already covers.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MAPS = REPO / "commons" / "maps"

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")


def registry() -> dict:
    out = {}
    for f in (REPO / "commons" / "artifacts" / "registry").glob("*.json"):
        try:
            d = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        arts = d.get("artifacts", d) if isinstance(d, dict) else {}
        if isinstance(arts, dict):
            for k, v in arts.items():
                if isinstance(v, dict):
                    out[k] = str(v.get("name") or k)
    return out


def placed(map_name: str) -> list[str]:
    """The tokens the map's interactables layer actually places, in reading
    order, config suffix and rotation stripped."""
    f = MAPS / map_name / "map_data.json"
    if not f.exists():
        return []
    try:
        d = json.loads(f.read_text(encoding="utf-8"))
    except Exception:
        return []
    inter = (d.get("layers") or d).get("interactables") or []
    out: list[str] = []
    for row in inter:
        cells = row if isinstance(row, list) else str(row).split()
        for c in cells:
            c = str(c).strip()
            if not c:
                continue
            tok = c.split("#")[0].split(":")[0]
            if tok and tok not in out:
                out.append(tok)
    return out


def survey(reg: dict, only: str = "") -> list[dict]:
    rows = []
    for p in sorted(MAPS.glob("*/tutorial.md")):
        mp = p.parent.name
        if only and mp != only:
            continue
        toks = [t for t in placed(mp) if t in reg]
        if not toks:
            continue
        text = p.read_text(encoding="utf-8", errors="replace").lower()
        named, unnamed = [], []
        for t in toks:
            nm = reg[t].lower()
            (named if (t.lower() in text or (len(nm) > 6 and nm in text)) else unnamed).append(t)
        rows.append({"map": mp, "chars": len(text), "placed": len(toks),
                     "named": named, "unnamed": unnamed})
    return rows


def main() -> int:
    ap = argparse.ArgumentParser(description="artifacts a room's tutorial never names")
    ap.add_argument("--map", default="")
    ap.add_argument("--named", action="store_true", help="list what IS named instead")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()

    reg = registry()
    rows = survey(reg, a.map)
    if not rows:
        print("no tutorial for %s, or its map places nothing" % (a.map or "any map"), file=sys.stderr)
        return 2

    tot_p = sum(r["placed"] for r in rows)
    tot_n = sum(len(r["named"]) for r in rows)

    if a.json:
        print(json.dumps({"tutorials": len(rows), "placed": tot_p, "named": tot_n,
                          "rows": rows}, ensure_ascii=False, indent=1))
        return 0

    print("THE TUTORIAL AND THE ROOM — %d tutorial(s) whose map places artifacts" % len(rows))
    print()
    print("  artifacts standing in those rooms : %d" % tot_p)
    print("  named in the tutorial             : %d  (%.0f%%)" % (tot_n, 100.0 * tot_n / max(tot_p, 1)))
    print("  NEVER NAMED                       : %d" % (tot_p - tot_n))
    print("  tutorials naming none at all      : %d of %d"
          % (sum(1 for r in rows if not r["named"]), len(rows)))
    print()

    if a.map:
        r = rows[0]
        print("  %s — %d characters, %d artifact(s) in the room" % (r["map"], r["chars"], r["placed"]))
        print()
        if r["named"]:
            print("    named:")
            for t in r["named"]:
                print("      %-34s %s" % (t, reg[t]))
        print("    never named:" if r["unnamed"] else "    (every one is named)")
        for t in r["unnamed"]:
            print("      %-34s %s" % (t, reg[t]))
        return 0

    if a.named:
        print("  where the tutorial DOES point at the room:")
        for r in sorted(rows, key=lambda r: -len(r["named"]))[:20]:
            if not r["named"]:
                break
            print("    %-32s %2d of %2d   %s" % (r["map"], len(r["named"]), r["placed"],
                                                 ", ".join(r["named"][:3])))
        return 0

    print("  the widest gaps — a room full of work its own lesson never mentions:")
    for r in sorted(rows, key=lambda r: -len(r["unnamed"]))[:20]:
        print("    %-32s %2d unnamed of %2d   %s" % (
            r["map"], len(r["unnamed"]), r["placed"], ", ".join(r["unnamed"][:3])))
    print()
    print("  --map=<Name> for one room's list, --named for what already lands.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
