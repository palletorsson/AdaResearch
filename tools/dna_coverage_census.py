#!/usr/bin/env python3
"""
dna_coverage_census.py — which artifacts are outside the DNA system entirely?

The promotion loop has produced 184 families and 258 declared axes, and it is easy to read
that as progress against a total nobody has stated. This states the total. For every entry
in the artifact registry it asks four independent yes/no questions and reports the artifacts
that answer no to all of them:

  DECLARED   the registry entry carries `dna.axes` — it is a family
  RESEARCHED it appears in the stage-2 research ledger published by
             artifact_dna_research.py (<enc>/public/artifact-dna/index.json)
  SWEPT      a bite report exists for it in doc/reports/*_bite.json, so its axes have
             actually been rendered and measured rather than merely declared
  PLACED     a map places it, so a player can meet it

The interesting column is the intersection: PLACED and none of the other three. Those are
artifacts a player walks past that the research loop has never touched — not a backlog of
things nobody wanted, but the actual unexplored surface.

An artifact that is DECLARED but not SWEPT matters too and is reported separately: the
declaration is a claim, and until the sweep runs the claim has no evidence under it.

Usage:
  python tools/dna_coverage_census.py                      # summary + top of the list
  python tools/dna_coverage_census.py --all                # every untouched artifact
  python tools/dna_coverage_census.py --json=doc/reports/dna_coverage.json
  python tools/dna_coverage_census.py --min-placements=5
"""
from __future__ import annotations
import json
import sys
import collections
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_dna_declarations import registry  # noqa: E402

REPO = Path(__file__).resolve().parents[1]
ENC = REPO.parent / "ada_encyclopedia" / "public"


def placements() -> collections.Counter:
    """How many map cells place each lookup name."""
    cnt: collections.Counter = collections.Counter()
    for mp in (REPO / "commons" / "maps").glob("*/map_data.json"):
        try:
            d = json.loads(mp.read_text(encoding="utf-8"))
        except Exception:
            continue
        for row in (d.get("layers") or {}).get("interactables") or []:
            if not isinstance(row, list):
                continue
            for c in row:
                if isinstance(c, str) and c.strip():
                    # `token:rot:offset#key:value` — the lookup name is the first field
                    cnt[c.split("#")[0].split(":")[0].strip()] += 1
    return cnt


def researched() -> set:
    """Lookup names the stage-2 runner has published a manifest for."""
    idx = ENC / "artifact-dna" / "index.json"
    if not idx.exists():
        return set()
    try:
        d = json.loads(idx.read_text(encoding="utf-8"))
    except Exception:
        return set()
    arts = d.get("artifacts", d)
    if isinstance(arts, dict):
        return set(arts.keys())
    if isinstance(arts, list):
        out = set()
        for a in arts:
            if isinstance(a, str):
                out.add(a)
            elif isinstance(a, dict):
                for k in ("token", "artifact", "lookup_name", "name"):
                    if a.get(k):
                        out.add(str(a[k]))
                        break
        return out
    return set()


def swept() -> set:
    """Lookup names with a bite report — axes that were rendered and measured."""
    out = set()
    for f in (REPO / "doc" / "reports").glob("*_bite.json"):
        name = f.stem[:-len("_bite")]
        if name.startswith("sweep_"):
            name = name[len("sweep_"):]
        out.add(name)
    # The galleries carry the same fact in a form that survives a renamed report.
    for mf in ENC.glob("*/manifest.json"):
        try:
            d = json.loads(mf.read_text(encoding="utf-8"))
        except Exception:
            continue
        for e in d.get("entries", []):
            if isinstance(e, dict) and e.get("prop"):
                out.add(str(e["prop"]))
    return out


def main() -> int:
    show_all = "--all" in sys.argv
    out_json = None
    min_pl = 1
    for a in sys.argv[1:]:
        if a.startswith("--json="):
            out_json = REPO / a.split("=", 1)[1]
        elif a.startswith("--min-placements="):
            min_pl = int(a.split("=", 1)[1])

    reg = registry()
    place = placements()
    res = researched()
    swp = swept()

    rows = []
    for tok, (e, rf) in reg.items():
        declared = bool((e.get("dna") or {}).get("axes"))
        rows.append({
            "token": tok,
            "registry": rf,
            "placements": int(place.get(tok, 0)),
            "declared": declared,
            "researched": tok in res,
            "swept": tok in swp,
            "scene": str(e.get("scene") or e.get("scene_path") or ""),
        })

    total = len(rows)
    declared = [r for r in rows if r["declared"]]
    placed = [r for r in rows if r["placements"] > 0]
    # THE LIST: placed, and untouched by every arm of the loop.
    untouched = [r for r in rows
                 if not r["declared"] and not r["researched"] and not r["swept"]]
    untouched_placed = sorted([r for r in untouched if r["placements"] >= min_pl],
                              key=lambda r: -r["placements"])
    # A declaration with no evidence under it.
    claimed_only = sorted([r for r in declared if not r["swept"]],
                          key=lambda r: -r["placements"])

    print(f"{total} registry entries")
    print(f"  {len(declared):5d} declared a dna.axes block   ({100*len(declared)/total:.1f}%)")
    print(f"  {len(swp & set(r['token'] for r in rows)):5d} have been swept and measured")
    print(f"  {len(placed):5d} are placed in at least one map")
    print()
    print(f"OUTSIDE THE SYSTEM ENTIRELY — not declared, not researched, never swept:")
    print(f"  {len(untouched):5d} artifacts, of which {len([r for r in untouched if r['placements'] > 0])} are placed in a map")
    print()
    print(f"DECLARED BUT NEVER SWEPT — a claim with no evidence under it: {len(claimed_only)}")
    if claimed_only[:8]:
        for r in claimed_only[:8]:
            print(f"     {r['token']:34s} {r['placements']:5d} placements  [{r['registry']}]")
        if len(claimed_only) > 8:
            print(f"     ... and {len(claimed_only)-8} more")

    print()
    print(f"THE LIST — placed, and outside the DNA system (>= {min_pl} placement{'s' if min_pl != 1 else ''}):")
    print(f"{'plc':>5}  {'token':36s} {'registry':26s} scene")
    shown = untouched_placed if show_all else untouched_placed[:40]
    for r in shown:
        print(f"{r['placements']:5d}  {r['token']:36s} {r['registry']:26s} {r['scene'][:52]}")
    if not show_all and len(untouched_placed) > len(shown):
        print(f"       ... and {len(untouched_placed)-len(shown)} more (--all to list every one)")

    if out_json:
        out_json.parent.mkdir(parents=True, exist_ok=True)
        out_json.write_text(json.dumps({
            "_note": "Four independent questions per registry entry: does it DECLARE dna.axes, "
                     "has the stage-2 runner RESEARCHED it, has it been SWEPT and measured, "
                     "is it PLACED in a map. `untouched_placed` is the unexplored surface — "
                     "artifacts a player meets that the research loop has never touched.",
            "totals": {
                "registry_entries": total,
                "declared": len(declared),
                "placed": len(placed),
                "outside_system": len(untouched),
                "outside_system_placed": len([r for r in untouched if r["placements"] > 0]),
                "declared_but_never_swept": len(claimed_only),
            },
            "untouched_placed": untouched_placed,
            "declared_but_never_swept": claimed_only,
        }, indent=1), encoding="utf-8")
        print(f"\nwrote {out_json.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
