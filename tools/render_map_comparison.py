#!/usr/bin/env python3
"""For each existing map, render the hand-authored version + an
auto-composed alternative side by side.

Inputs:
    --filter high|mid|fine|all   tier from map_quality.json (default: high)
    --names <a> <b> <c>          override: render only these map names
    --limit <N>                  cap how many to render (default: 100)
    --force                      re-render even if both PNGs already exist

Outputs:
    doc/reports/map_comparisons/<map_name>/
        hand.png              — top-down render of the existing map
        auto.png              — top-down render of the auto-composed alt
        auto/map_data.json    — the auto-composed map data
        meta.json             — { hand_signals, auto_signals, ... }

Run from repo root:
    python tools/render_map_comparison.py --filter high --limit 50
"""
from __future__ import annotations

import argparse
import json
import sys
import traceback
from pathlib import Path

# Re-use the composer module — same renderer, same grammar.
sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_map_from_dressing_rooms as composer  # noqa: E402

REPO = Path(__file__).resolve().parent.parent
MAPS_DIR = REPO / "commons" / "maps"
COMPARISON_DIR = REPO / "doc" / "reports" / "map_comparisons"
AUDIT_PATH = REPO / "doc" / "reports" / "map_quality.json"


def load_audit() -> list[dict]:
    if not AUDIT_PATH.exists():
        print(f"  ! no audit at {AUDIT_PATH} — run tools/map_quality_audit.py first")
        return []
    return json.loads(AUDIT_PATH.read_text(encoding="utf-8"))["audits"]


def collect_artifact_lookups(map_data: dict) -> list[str]:
    interact = map_data.get("layers", {}).get("interactables", [])
    seen: list[str] = []
    seen_set: set[str] = set()
    for row in interact:
        if not isinstance(row, list): continue
        for cell in row:
            if not isinstance(cell, str): continue
            tok = cell.strip()
            if not tok or tok == " ": continue
            lookup = tok.split(":", 1)[0]
            if lookup and lookup not in seen_set:
                seen_set.add(lookup)
                seen.append(lookup)
    return seen


def render_existing(map_name: str, out_png: Path) -> bool:
    """Render an existing hand-authored map as PNG."""
    md_path = MAPS_DIR / map_name / "map_data.json"
    if not md_path.exists(): return False
    try:
        md = json.loads(md_path.read_text(encoding="utf-8", errors="replace"))
    except Exception as e:
        print(f"  ! {map_name}: parse error {e}")
        return False
    return composer.render_png(md, out_png, cell_px=16)


def compose_auto(map_name: str, lookups: list[str], out_dir: Path) -> tuple[bool, dict | None]:
    """Compose an auto alternative using the map's artifact list."""
    if not lookups:
        return False, None
    out_dir.mkdir(parents=True, exist_ok=True)
    # Filter to lookups that have a dressing room; the composer's
    # internal load_room raises if missing. We pre-filter so partial
    # coverage still gives us a comparison.
    valid: list[str] = []
    for lk in lookups:
        if (REPO / "commons" / "artifacts" / "dressing_rooms" / f"{lk}.json").exists():
            valid.append(lk)
    if not valid:
        return False, None
    # Compose into a temporary name, then move outputs into our dir.
    tmp_name = f"_compare_{map_name}"
    try:
        out_path, map_data = composer.compose(tmp_name, valid)
    except Exception as e:
        print(f"  ! {map_name}: compose failed {e}")
        return False, None
    # Move map_data.json + clean up the tmp directory the composer made.
    tmp_dir = MAPS_DIR / tmp_name
    target_json = out_dir / "map_data.json"
    target_json.write_text(json.dumps(map_data, indent=2), encoding="utf-8")
    # Clean up the temp folder the composer wrote into.
    try:
        for f in tmp_dir.iterdir(): f.unlink()
        tmp_dir.rmdir()
    except Exception:
        pass
    return True, map_data


def signals(map_data: dict) -> dict:
    """Compact summary of a map for the comparison meta.json."""
    layers = map_data.get("layers", {})
    structure = layers.get("structure", [])
    interact = layers.get("interactables", [])
    rows = len(structure)
    cols = max((len(r) for r in structure if isinstance(r, list)), default=0)
    walkable = 0
    for row in structure:
        if not isinstance(row, list): continue
        for cell in row:
            try:
                if int(cell) >= 1: walkable += 1
            except Exception:
                pass
    n_arts = 0
    for row in interact:
        if not isinstance(row, list): continue
        for cell in row:
            if isinstance(cell, str) and cell.strip() and cell.strip() != " ":
                n_arts += 1
    return {"rows": rows, "cols": cols, "walkable": walkable, "n_artifacts": n_arts}


def process_map(rec: dict, force: bool = False) -> dict:
    """Render hand + compose+render auto for a single map. Returns meta."""
    name = rec["name"]
    out_dir = COMPARISON_DIR / name
    out_dir.mkdir(parents=True, exist_ok=True)
    hand_png = out_dir / "hand.png"
    auto_png = out_dir / "auto.png"
    auto_dir = out_dir / "auto"
    auto_json = auto_dir / "map_data.json"
    meta_path = out_dir / "meta.json"

    if not force and hand_png.exists() and auto_png.exists() and auto_json.exists():
        return {"name": name, "skipped": True}

    md_path = MAPS_DIR / name / "map_data.json"
    try:
        hand_md = json.loads(md_path.read_text(encoding="utf-8", errors="replace"))
    except Exception as e:
        return {"name": name, "error": f"parse: {e}"}

    # 1. Render hand version.
    rendered_hand = render_existing(name, hand_png)
    # 2. Compose + render auto.
    lookups = collect_artifact_lookups(hand_md)
    auto_dir.mkdir(parents=True, exist_ok=True)
    composed_ok, auto_md = compose_auto(name, lookups, auto_dir)
    rendered_auto = False
    if composed_ok and auto_md is not None:
        rendered_auto = composer.render_png(auto_md, auto_png, cell_px=16)

    meta = {
        "name": name,
        "sequence": rec.get("sequence", ""),
        "score": rec.get("score", 0),
        "flags": rec.get("flags", []),
        "hand": signals(hand_md),
        "auto": signals(auto_md) if auto_md else None,
        "n_lookups_input": len(lookups),
        "rendered_hand": rendered_hand,
        "rendered_auto": rendered_auto,
        "composed_ok": composed_ok,
    }
    meta_path.write_text(json.dumps(meta, indent=2), encoding="utf-8")
    return meta


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--filter", default="high",
        choices=["high", "mid", "fine", "all"], help="tier of maps to render")
    p.add_argument("--names", nargs="*", default=None,
        help="explicit map names — overrides --filter")
    p.add_argument("--limit", type=int, default=100,
        help="cap how many to process (0 = no cap)")
    p.add_argument("--force", action="store_true", help="re-render even if outputs exist")
    args = p.parse_args()

    audits = load_audit()
    if not audits:
        return 1
    audit_by_name = {a["name"]: a for a in audits}

    if args.names:
        records = [audit_by_name.get(n, {"name": n, "sequence": "", "score": 0, "flags": []})
                   for n in args.names]
    else:
        if args.filter == "high":
            records = [a for a in audits if a["score"] >= 3]
        elif args.filter == "mid":
            records = [a for a in audits if 1 <= a["score"] < 3]
        elif args.filter == "fine":
            records = [a for a in audits if a["score"] < 1]
        else:
            records = audits
    records.sort(key=lambda a: -a.get("score", 0))
    if args.limit > 0:
        records = records[: args.limit]

    print(f"processing {len(records)} maps")
    COMPARISON_DIR.mkdir(parents=True, exist_ok=True)

    summary = {"ok": 0, "skipped": 0, "errors": 0, "no_lookups": 0, "compose_failed": 0}
    summaries: list[dict] = []
    for i, rec in enumerate(records, 1):
        try:
            meta = process_map(rec, force=args.force)
            if meta.get("skipped"):
                summary["skipped"] += 1
            elif meta.get("error"):
                summary["errors"] += 1
                print(f"  ! {meta['name']}: {meta['error']}")
            else:
                summary["ok"] += 1
                if meta.get("n_lookups_input", 0) == 0:
                    summary["no_lookups"] += 1
                if not meta.get("composed_ok"):
                    summary["compose_failed"] += 1
                summaries.append(meta)
        except Exception as e:
            summary["errors"] += 1
            print(f"  ! {rec.get('name', '?')}: {e}")
            traceback.print_exc()
        if i % 25 == 0:
            print(f"  ...{i}/{len(records)}")

    # Write a top-level index so the encyclopedia can list comparisons.
    index_path = COMPARISON_DIR / "index.json"
    index_path.write_text(json.dumps({
        "generated": "tools/render_map_comparison.py",
        "summary": summary,
        "comparisons": [
            {
                "name": s["name"],
                "sequence": s["sequence"],
                "score": s["score"],
                "rendered_hand": s.get("rendered_hand"),
                "rendered_auto": s.get("rendered_auto"),
                "n_lookups_input": s.get("n_lookups_input", 0),
                "hand_walkable": (s.get("hand") or {}).get("walkable", 0),
                "auto_walkable": (s.get("auto") or {}).get("walkable", 0),
                "hand_artifacts": (s.get("hand") or {}).get("n_artifacts", 0),
                "auto_artifacts": (s.get("auto") or {}).get("n_artifacts", 0),
            }
            for s in summaries
        ],
    }, indent=2), encoding="utf-8")
    print(f"wrote {index_path.relative_to(REPO)}")

    print("\n=== summary ===")
    for k, v in summary.items():
        print(f"  {k:18s} {v}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
