#!/usr/bin/env python3
"""Write hand rows into the museum plan — the ONE writer the studio, the plan
editor and the tools share.

    python tools/em_plan_write.py --chapter primitives --pearl point --rows rows.json [--by studio]

rows.json = [ {token, cell:[x,y], rotation, offset:[x,y,z], scale, config:{}, support_height_m,
               token_before, cell_before:[x,y], removed:bool, add:bool}, ... ]

Each row is matched to the pearl's artifact by (token_before|token, cell_before|cell);
`removed` drops it, `add` appends a new hand body, anything else updates. A
changed row is stamped hand:true + ruled:{at, by}. Ints stay ints (Godot's
JSON writes floats, so the studio calls this instead of writing itself).
The shipped copy (commons/data/museum/) follows.
"""
from __future__ import annotations
import argparse, json, subprocess, sys
from datetime import datetime
from pathlib import Path
REPO = Path(__file__).resolve().parent.parent
PLAN = REPO / "ada_run" / "em_plan.json"


def _cell(v):
    return [int(round(float(v[0]))), int(round(float(v[1])))] if isinstance(v, (list, tuple)) and len(v) >= 2 else None


def _tile_size(target: dict):
    t = target.get("tile")
    if isinstance(t, list) and t and isinstance(t[0], list):
        return len(t[0]), len(t)
    room = target.get("room") or {}
    apron = int(target.get("apron", 14))
    return max(1, int(room.get("w", 43)) - 2 * apron), max(1, int(room.get("h", 58)) - 2 * apron)


def normalize(arts: list) -> list:
    """Godot's JSON hands back floats; the plan keeps ints for cells and rotation."""
    for a in arts:
        for k in ("tile_cell", "cell"):
            if isinstance(a.get(k), list) and len(a[k]) >= 2:
                a[k] = [int(round(float(a[k][0]))), int(round(float(a[k][1])))]
        if "rotation" in a:
            a["rotation"] = int(round(float(a["rotation"])))
        if "pearl_index" in a:
            a["pearl_index"] = int(a["pearl_index"])
    return arts


def apply_rows(plan: dict, chapter: str, pearl: str, rows: list, by: str = "studio") -> dict:
    target = None
    for p in plan.get("plans", []):
        if p.get("sequence") == chapter and (pearl == "" or p.get("pearl") == pearl or str(p.get("pearl_index")) == str(pearl)):
            target = p
            break
    if target is None:
        raise SystemExit(f"no plan row for {chapter}/{pearl}")
    apron = int(target.get("apron", 14))
    now = datetime.now().isoformat(timespec="seconds")
    arts = target.setdefault("artifacts", [])
    touched = added = removed = 0
    for r in rows:
        key_tok = r.get("token_before") or r.get("token")
        key_cell = _cell(r.get("cell_before")) or _cell(r.get("cell"))
        cur = next((a for a in arts if a.get("token") == key_tok and _cell(a.get("tile_cell")) == key_cell), None)
        if cur is None and not r.get("add"):
            # the studio's record may not carry the row's cell (a courtyard body
            # stands at a court cell; the row says [-apron,-apron]): a token
            # that occurs ONCE in the pearl is that row
            same = [a for a in arts if a.get("token") == key_tok]
            if len(same) == 1:
                cur = same[0]
        if r.get("removed"):
            if cur is not None:
                arts.remove(cur); removed += 1
            continue
        cell = _cell(r.get("cell")) or (_cell(cur.get("tile_cell")) if cur else [0, 0])
        if cur is None:
            cur = {"token": r.get("token"), "mode": r.get("mode", "freestanding"), "venue": "interior",
                   "support_height_m": float(r.get("support_height_m", 0.0)), "rotation": 0,
                   "relation": {"anchor": r.get("token"), "role": "hand", "kind": "", "rule": "", "why": f"placed by {by}",
                                "walk_kind": "hand", "walk_why": f"placed by {by}", "walk_space": "wall", "pearl": target.get("pearl", "")}}
            arts.append(cur); added += 1
        before = json.dumps(cur, sort_keys=True)
        cur["token"] = str(r.get("token", cur["token"]))
        cur["tile_cell"] = cell
        cur["cell"] = [cell[0] + apron, cell[1] + apron]
        # a body dragged INTO the tile is interior now; one dragged out to a
        # court/porch keeps its venue (the assembler reads the cell)
        tw, th = _tile_size(target)
        if 0 <= cell[0] < tw and 0 <= cell[1] < th and cur.get("venue") in ("courtyard", "porch", "outside"):
            cur["venue"] = "interior"; cur["mode"] = cur.get("mode") or "freestanding"
        if r.get("rotation") is not None:
            cur["rotation"] = int(round(float(r["rotation"]))) % 360
        off = r.get("offset")
        if isinstance(off, list) and any(abs(float(v)) > 1e-6 for v in off):
            cur["offset"] = [round(float(v), 2) for v in off]
        elif "offset" in r:
            cur.pop("offset", None)
        if r.get("scale") is not None:
            if abs(float(r["scale"]) - 1.0) > 1e-6:
                cur["scale"] = round(float(r["scale"]), 3)
            else:
                cur.pop("scale", None)
        if "config" in r:
            if r["config"]:
                cur["config"] = r["config"]
            else:
                cur.pop("config", None)
        if r.get("support_height_m") is not None:
            cur["support_height_m"] = float(r["support_height_m"])
        if r.get("mode"):
            cur["mode"] = str(r["mode"])
        if json.dumps(cur, sort_keys=True) != before:
            cur["hand"] = True
            cur["ruled"] = {"at": now, "by": by}
            touched += 1
    normalize(arts)
    return {"chapter": chapter, "pearl": target.get("pearl"), "rows": len(arts), "touched": touched, "added": added, "removed": removed}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--chapter", required=True)
    ap.add_argument("--pearl", default="")
    ap.add_argument("--rows", required=True, help="json file: a list of row edits")
    ap.add_argument("--by", default="studio")
    ap.add_argument("--replace", action="store_true", help="rows.json IS the pearl's whole artifacts list (undo/redo)")
    ap.add_argument("--no-ship", action="store_true")
    a = ap.parse_args()
    plan = json.loads(PLAN.read_text(encoding="utf-8"))
    rows = json.loads(Path(a.rows).read_text(encoding="utf-8"))
    if a.replace:
        target = next((p for p in plan.get("plans", []) if p.get("sequence") == a.chapter and (a.pearl == "" or p.get("pearl") == a.pearl)), None)
        if target is None:
            raise SystemExit(f"no plan row for {a.chapter}/{a.pearl}")
        target["artifacts"] = normalize(rows)
        res = {"chapter": a.chapter, "pearl": target.get("pearl"), "rows": len(rows), "touched": len(rows), "added": 0, "removed": 0}
    else:
        res = apply_rows(plan, a.chapter, a.pearl, rows, a.by)
    PLAN.write_text(json.dumps(plan, indent=2) + "\n", encoding="utf-8")
    if not a.no_ship:
        subprocess.run([sys.executable, str(REPO / "tools" / "em_ship.py")], cwd=REPO, capture_output=True)
    print(f"EM PLAN WRITE: {res['chapter']}/{res['pearl']} — {res['rows']} rows, {res['touched']} touched, {res['added']} added, {res['removed']} removed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
