#!/usr/bin/env python
"""
artifact_weight_audit.py -- scan artifact scripts for patterns that spawn
heavy sub-scenes, large field grids, or multi-meter-extent geometry.

Flags candidates for the "corridor_incompatible" spine_hints tag.
Run before generating corridors to avoid runtime surprises.

Usage:
    python tools/artifact_weight_audit.py
    python tools/artifact_weight_audit.py --sequence primitives
    python tools/artifact_weight_audit.py --json
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SCAN_DIRS = [REPO / "commons", REPO / "algorithms"]
MAPS_DIR = REPO / "commons" / "maps"
SEQ_DIR = REPO / "commons" / "maps" / "sequences"

# Heuristics — each is a regex that flags a potential corridor-intrusion pattern.
# Tuple: (pattern, weight, reason).
HEAVY_PATTERNS = [
    (re.compile(r"MarchingCubes|GyroidField|VoxelChunk|voxel_chunk"), 5, "marching-cubes / voxel field"),
    (re.compile(r"RhizomaticMaze|RhizomaticMazeSpace|organic.{0,10}maze", re.IGNORECASE), 5, "rhizomatic maze generator"),
    (re.compile(r"TerrainGenerator|TerrainDemo|terrain_chunk"), 4, "terrain generator"),
    (re.compile(r"Non.?Euclidean|NonEuclideanSpace"), 4, "non-euclidean space"),
    (re.compile(r"portal_count\s*:\s*int\s*=\s*(\d+)"), 0, "multi-portal array"),
    (re.compile(r"for\s+\w+\s+in\s+range\(.*count.*\).*duplicate\(\)", re.DOTALL), 3, "duplicate in loop"),
    (re.compile(r"\btrack_length\s*:\s*float\s*=\s*([4-9]|\d{2,})"), 3, "track_length >= 4m"),
    (re.compile(r"RhizomaticMazeSpace|MazeGenerator"), 5, "maze generator"),
    (re.compile(r"library_rack|LibraryRack"), 3, "library_rack (~14m tall)"),
    (re.compile(r"PipeLayout|BigPipe_"), 3, "pipe system (multi-segment)"),
    (re.compile(r"tile_count|grid_size\s*:\s*int\s*=\s*(1[0-9]|[2-9][0-9])"), 3, "large grid_size default"),
    (re.compile(r"add_child.*for.*range\(1[0-9]\)", re.DOTALL), 3, "spawn 10+ children"),
    (re.compile(r"spawn_count\s*:\s*int\s*=\s*(1[0-9]|[2-9]\d)"), 3, "spawn_count >= 10"),
]


def scan_gd_files() -> list[Path]:
    out: list[Path] = []
    for root in SCAN_DIRS:
        if not root.exists():
            continue
        for p in root.rglob("*.gd"):
            if "android" in p.parts or "_staging" in p.parts:
                continue
            if not p.with_suffix(".tscn").exists():
                continue
            out.append(p)
    return out


def analyze(gd_path: Path) -> dict:
    try:
        txt = gd_path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return {"token": gd_path.stem, "path": str(gd_path), "hits": [], "score": 0}
    hits: list[tuple[int, str]] = []
    for rx, weight, reason in HEAVY_PATTERNS:
        m = rx.search(txt)
        if m:
            w = weight
            if weight == 0 and m.groups():
                # portal_count: int = N  → weight scales with N
                try:
                    n = int(m.group(1))
                    w = 0 if n <= 3 else min(5, n // 4)
                    reason = f"portal_count = {n}"
                except Exception:
                    pass
            if w > 0:
                hits.append((w, reason))
    # Already-tagged?
    already_tagged = bool(re.search(r'"corridor_incompatible"|"oversized"', txt))
    score = sum(w for (w, _) in hits)
    return {
        "token": gd_path.stem,
        "path": str(gd_path.relative_to(REPO)).replace("\\", "/"),
        "hits": [{"weight": w, "reason": r} for (w, r) in hits],
        "score": score,
        "already_tagged": already_tagged,
    }


def _loose_json_loads(text: str):
    """Tolerate trailing commas in sequence/map JSON files."""
    cleaned = re.sub(r",\s*([\]}])", r"\1", text)
    return json.loads(cleaned)


def sequence_tokens(seq: str) -> set[str]:
    sp = SEQ_DIR / f"{seq}.json"
    if not sp.exists():
        return set()
    data = _loose_json_loads(sp.read_text(encoding="utf-8"))
    entry = data.get("sequences", {}).get(seq, {})
    toks: set[str] = set()
    for m in entry.get("maps", []):
        mp = MAPS_DIR / m / "map_data.json"
        if not mp.exists():
            continue
        try:
            mdata = _loose_json_loads(mp.read_text(encoding="utf-8"))
        except Exception:
            continue
        for row in mdata.get("layers", {}).get("interactables", []):
            if not isinstance(row, list):
                continue
            for cell in row:
                s = str(cell).strip()
                if not s:
                    continue
                token = s.split("#", 1)[0].split(":", 1)[0].strip()
                if token:
                    toks.add(token)
    return toks


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sequence", help="only flag artifacts used by this sequence")
    ap.add_argument("--threshold", type=int, default=3, help="min score to flag")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    filter_tokens: set[str] | None = sequence_tokens(args.sequence) if args.sequence else None

    reports = []
    for gd in scan_gd_files():
        token = gd.stem
        if filter_tokens is not None and token not in filter_tokens:
            continue
        r = analyze(gd)
        if r["score"] >= args.threshold:
            reports.append(r)

    reports.sort(key=lambda r: (-r["score"], r["token"]))

    if args.json:
        print(json.dumps({"reports": reports, "threshold": args.threshold}, indent=2))
        return 0

    header = f"Artifact weight audit (threshold={args.threshold})"
    if args.sequence:
        header += f"  --  sequence '{args.sequence}'"
    print(header)
    print("-" * 72)
    for r in reports:
        tag = "[TAGGED]" if r["already_tagged"] else "[NEW]   "
        print(f"  {tag} score={r['score']:>2}  {r['token']:<36s} {r['path']}")
        for h in r["hits"]:
            print(f"             +{h['weight']}  {h['reason']}")
    print()
    flagged = sum(1 for r in reports if not r["already_tagged"])
    tagged = sum(1 for r in reports if r["already_tagged"])
    print(f"Total: {len(reports)} flagged   [{flagged} NEW, {tagged} already tagged]")
    return 0


if __name__ == "__main__":
    sys.exit(main())
