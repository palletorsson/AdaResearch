#!/usr/bin/env python3
"""
check_cabinet_grammar.py — the alignment gate for the cabinet family.

Palle 2026-07-20: "make sure every element in each artifact is aligned in the
right way, it must look consistent."

Consistency can't live in an agent's memory as remembered magic numbers — it
drifts the moment a new artifact is spliced by hand. So it is MEASURED: the
Godot probe instantiates every cabinet artifact, walks its whole node tree,
and evaluates each rule in commons/data/cabinet_grammar.json against actual
transforms and materials. This tool reads that report, prints it, and gates.

  1. probe   godot --path . --xr-mode off --no-window \\
               --script res://commons/testing/probe_cabinet_grammar.gd
  2. gate    python tools/check_cabinet_grammar.py [--strict]

Exit 0 = clean (or advisory-only), 1 = violations with --strict.
Findings also feed the fractal fold, so /api/fractal/grammar reports live
compliance rather than static prose.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
CANON = REPO / "commons" / "data" / "cabinet_grammar.json"
REPORT = REPO / "doc" / "reports" / "cabinet_grammar_report.json"

# Rules that describe a judgement call rather than a defect. They print, they
# don't gate — a heuristic that blocks a commit teaches people to ignore it.
ADVISORY = {"G5-reach", "G6-screen-seated"}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--strict", action="store_true",
                    help="exit 1 on any hard violation")
    ap.add_argument("--json", action="store_true", help="machine output")
    args = ap.parse_args()

    if not REPORT.exists():
        print("no report — run the probe first:")
        print("  godot --path . --xr-mode off --no-window "
              "--script res://commons/testing/probe_cabinet_grammar.gd")
        return 2

    rep = json.loads(REPORT.read_text(encoding="utf-8"))
    canon = json.loads(CANON.read_text(encoding="utf-8"))
    why = {r["id"]: r.get("why", "") for r in canon.get("rules", [])}

    if args.json:
        print(json.dumps(rep, indent=1))
        return 0

    # G8 is a SOURCE-level rule — "does this artifact compose the shared kit?"
    # cannot be measured from geometry, only from the code that made it.
    kit_state: dict[str, bool] = {}
    for m in canon.get("members", []):
        scene = REPO / str(m.get("scene", "")).replace("res://", "")
        gd = scene.with_suffix(".gd")
        # scene and script names do not always match case (DistributionVisualization.gd
        # beside distribution_visualization.tscn), so fall back to the folder.
        candidates = [gd] if gd.exists() else sorted(scene.parent.glob("*.gd"))
        found = False
        for c in candidates:
            try:
                if "HangarKit" in c.read_text(encoding="utf-8"):
                    found = True
                    break
            except Exception:
                continue
        kit_state[m["artifact"]] = found

    hard = 0
    soft = 0
    print(f"\ncabinet grammar — canon v{rep.get('canon_version')} · "
          f"{len(rep.get('artifacts', []))} artifacts\n")
    for a in rep.get("artifacts", []):
        fails = [f for f in a.get("findings", []) if not f.get("ok")]
        on_kit = kit_state.get(a["artifact"], False)
        if not on_kit:
            fails = fails + [{"rule": "G8-composes-kit",
                              "detail": "bespoke geometry — does not compose HangarKit"}]
        mark = "OK  " if not fails else "FAIL"
        print(f"  [{mark}] {a['artifact']:<26} {a['dialect']:<11} "
              f"{a.get('element_count', '?'):>4} elements  "
              f"{'kit' if on_kit else '---'}")
        for f in fails:
            rid = f.get("rule", "?")
            tag = "advisory" if rid in ADVISORY else "VIOLATION"
            if rid in ADVISORY:
                soft += 1
            else:
                hard += 1
            print(f"         {tag:<9} {rid}: {f.get('detail', '')[:150]}")
            if why.get(rid):
                print(f"                   why: {why[rid][:120]}")
    print(f"\n  {hard} hard violation(s), {soft} advisory\n")

    if hard and args.strict:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
