#!/usr/bin/env python3
"""FOLD THE WALK'S RULINGS INTO THE PLAN — one channel, three doors.

    python tools/em_fold_overrides.py            # fold + clear + ship
    python tools/em_fold_overrides.py --dry      # say what would fold

Palle, 2026-08-20: "if we make changes in the endless museum desktop can we have
them be direct like in the hall?"

The walking editor (TAB in the desktop museum) autosaves rulings to
ada_run/em_overrides.json within 0.6 s — instant in 3D, but a THIRD channel:
invisible to /halls and /lines, and never part of the plan's hand rows. This
tool folds each ruling into the plan as a HAND ROW (em_plan_write's semantics,
by "walk"), where it survives regenerations like any hand fact, shows in
/halls, and ships to the headset. Folded rulings leave the overrides file;
un-foldable ones (no plan row found) stay, and are said.

  ruling                          -> hand row
  offset / rotation on a body     -> offset / rotation at its plan cell
  remove: true                    -> removed: true
  swap_to: other                  -> removed old + add other at the same cell
  text (a showing's caption)      -> left in overrides (showings are dressing)
"""
from __future__ import annotations
import json, subprocess, sys
from pathlib import Path
REPO = Path(__file__).resolve().parent.parent
OV = REPO / "ada_run" / "em_overrides.json"
PLAN = REPO / "ada_run" / "em_plan.json"
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")


def main() -> int:
    dry = "--dry" in sys.argv
    if not OV.exists():
        print("no overrides file — nothing to fold"); return 0
    doc = json.loads(OV.read_text(encoding="utf-8"))
    rulings = doc.get("overrides", doc if isinstance(doc, list) else [])
    if not rulings:
        print("no rulings — nothing to fold"); return 0
    plan = json.loads(PLAN.read_text(encoding="utf-8"))
    # (chapter, token) -> (pearl, tile_cell)
    where: dict = {}
    for row in plan.get("plans", []):
        ch = row.get("sequence", "")
        for a in row.get("artifacts", []):
            key = (ch, a.get("token", ""))
            if key not in where and a.get("tile_cell"):
                where[key] = (row.get("pearl", ""), a["tile_cell"])
    by_pearl: dict = {}
    kept, folded = [], 0
    for r in rulings:
        ch = str(r.get("chapter", ""))
        tok = str(r.get("token", ""))
        hit = where.get((ch, tok))
        if hit is None or not hit[0] or str(r.get("text", "")):
            kept.append(r)                      # showings' captions and orphans stay
            continue
        pearl, plan_cell = hit
        # the ruling's own `to` cell is where the WALK moved the body; the plan's
        # cell is only the fallback for pose-only rulings
        to = r.get("to") or r.get("_rebound")
        cell = [int(to[0]), int(to[1])] if isinstance(to, list) and len(to) >= 2 else list(plan_cell)
        row: dict = {"token": tok, "cell": cell, "cell_before": list(plan_cell)}
        if r.get("remove"):
            row["removed"] = True
        else:
            if r.get("offset"):
                row["offset"] = list(r["offset"])
            if float(r.get("rotation", 0.0)) != 0.0:
                row["rotation"] = int(round(float(r["rotation"])))
            if r.get("scale") not in (None, 1, 1.0):
                row["scale"] = float(r["scale"])
        rows = by_pearl.setdefault((ch, pearl), [])
        rows.append(row)
        swap = str(r.get("swap_to", ""))
        if swap:
            row["removed"] = True
            rows.append({"token": swap, "cell": list(cell), "add": True})
        folded += 1
    for (ch, pearl), rows in by_pearl.items():
        print(f"  {ch}/{pearl}: {len(rows)} row(s)" + ("" if not dry else "  [dry]"))
        if dry:
            continue
        tmp = REPO / "ada_run" / "_fold_rows.json"
        tmp.write_text(json.dumps(rows), encoding="utf-8")
        subprocess.run([sys.executable, str(REPO / "tools" / "em_plan_write.py"),
                        "--chapter", ch, "--pearl", pearl, "--rows", str(tmp), "--by", "walk"],
                       cwd=REPO, check=False)
        tmp.unlink(missing_ok=True)
    if not dry:
        doc2 = dict(doc) if isinstance(doc, dict) else {}
        doc2["overrides"] = kept
        OV.write_text(json.dumps(doc2, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
        subprocess.run([sys.executable, str(REPO / "tools" / "em_ship.py")], cwd=REPO, check=False)
    print(f"FOLD: {folded} ruling(s) -> plan hand rows (by walk), {len(kept)} kept in overrides"
          + (" [dry — nothing written]" if dry else ""))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
