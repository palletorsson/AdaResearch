#!/usr/bin/env python3
"""
map_to_spec.py — reverse-engineer a hand-authored map into a generator spec.

Reads commons/maps/<MapName>/map_data.json and writes a JSON spec that
captures WHAT THE MAP IS DOING: signature artifact, constraint cells,
breath zones, implicit style, sequence echoes, density, authorial
annotations already in place.

The spec is meant to round-trip: feed it to a generator and the generator
should reproduce a map similar enough to the original that the silhouette
matches and the pathfinder still passes.

This is the minimum-viable version. Covers:
  - signature artifact (heuristic: the one referenced by intent.md + evolution.json)
  - constraints:   artifacts whose position is load-bearing
  - breath zones:  contiguous empty cells above a size threshold
  - density:       interactable cells / walkable cells
  - echoes:        detected via intent.md cross-sequence mentions
  - annotations:   any @-prefixed utility codes already authored
  - style:         detected via artifact token name patterns

Usage:
    python tools/map_to_spec.py <MapName>
    python tools/map_to_spec.py --all          # dump specs for every map
    python tools/map_to_spec.py <MapName> --check  # round-trip diff
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

REPO = Path(__file__).resolve().parents[1]
MAPS_DIR = REPO / "commons" / "maps"
SPEC_DIR = REPO / "doc" / "specs" / "maps"


# ─────────────────────────────────────────────────────────────
# Loading
# ─────────────────────────────────────────────────────────────

def load_json(path: Path) -> Optional[dict]:
    try:
        with path.open("r", encoding="utf-8") as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError):
        return None


def load_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError:
        return ""


def map_paths(map_name: str) -> Dict[str, Path]:
    d = MAPS_DIR / map_name
    return {
        "dir": d,
        "data": d / "map_data.json",
        "intent": d / "intent.md",
        "evolution": d / "evolution.json",
        "blurb": d / "blurb.md",
        "summary": d / "summary.md",
    }


# ─────────────────────────────────────────────────────────────
# Layer parsing
# ─────────────────────────────────────────────────────────────

def grid_from(data: dict, layer: str) -> List[List[str]]:
    layers = data.get("map_data", data).get("layers", data.get("layers", {}))
    raw = layers.get(layer, [])
    # Normalize to strings
    return [[str(c) for c in row] for row in raw]


def grid_dims(grid: List[List[str]]) -> Tuple[int, int]:
    if not grid:
        return (0, 0)
    return (len(grid[0]), len(grid))  # W, D


def cell_is_empty(cell: str) -> bool:
    s = cell.strip()
    return s == "" or s == " "


def iter_cells(grid: List[List[str]]):
    for z, row in enumerate(grid):
        for x, cell in enumerate(row):
            yield x, z, cell


# ─────────────────────────────────────────────────────────────
# Signature artifact
# ─────────────────────────────────────────────────────────────

def extract_signature(paths: Dict[str, Path]) -> Optional[str]:
    # Prefer evolution.json's declared artifact (that's the close-read anchor)
    evo = load_json(paths["evolution"])
    if evo and isinstance(evo, dict):
        a = evo.get("artifact")
        if a:
            return str(a)
    # Fall back to intent.md key_artifacts first entry
    intent = load_text(paths["intent"])
    if intent:
        m = re.search(r"key[_ ]artifacts?\s*:\s*\[?([^\]\n]+)", intent, re.IGNORECASE)
        if m:
            first = m.group(1).split(",")[0].strip().strip('"').strip("'")
            if first:
                return first
    return None


# ─────────────────────────────────────────────────────────────
# Interactable tokens
# ─────────────────────────────────────────────────────────────

INTERACTABLE_RE = re.compile(r"^([A-Za-z0-9_]+)(?::([^:]*))?(?::([^:]*))?$")

def interactable_tokens(grid: List[List[str]]) -> List[Tuple[int, int, str]]:
    out = []
    for x, z, cell in iter_cells(grid):
        s = cell.strip()
        if not s or s == " ":
            continue
        m = INTERACTABLE_RE.match(s)
        if m:
            out.append((x, z, m.group(1)))
    return out


# ─────────────────────────────────────────────────────────────
# Breath zones
# ─────────────────────────────────────────────────────────────

def flood_fill_empty(structure: List[List[str]], interactables: List[List[str]],
                     start_x: int, start_z: int, visited: Set[Tuple[int, int]]) -> List[Tuple[int, int]]:
    W, D = grid_dims(structure)
    stack = [(start_x, start_z)]
    region = []
    while stack:
        x, z = stack.pop()
        if (x, z) in visited:
            continue
        if x < 0 or z < 0 or x >= W or z >= D:
            continue
        # A cell counts as "empty" if structure is walkable floor (non-zero, non-void)
        # AND the interactable layer is empty/space.
        try:
            s = structure[z][x].strip()
        except IndexError:
            continue
        try:
            i = interactables[z][x].strip()
        except IndexError:
            i = ""
        if s in ("", "0") or i not in ("", " "):
            continue
        visited.add((x, z))
        region.append((x, z))
        stack.extend([(x + 1, z), (x - 1, z), (x, z + 1), (x, z - 1)])
    return region


def detect_breath_zones(structure: List[List[str]], interactables: List[List[str]],
                        min_size: int = 4) -> List[Dict]:
    W, D = grid_dims(structure)
    if W == 0:
        return []
    visited: Set[Tuple[int, int]] = set()
    zones = []
    for z in range(D):
        for x in range(W):
            if (x, z) in visited:
                continue
            region = flood_fill_empty(structure, interactables, x, z, visited)
            if len(region) >= min_size:
                xs = [c[0] for c in region]
                zs = [c[1] for c in region]
                zones.append({
                    "size": len(region),
                    "bounds": {"x": min(xs), "z": min(zs),
                               "w": max(xs) - min(xs) + 1,
                               "d": max(zs) - min(zs) + 1},
                    "centroid": [sum(xs) / len(xs), sum(zs) / len(zs)],
                })
    zones.sort(key=lambda r: -r["size"])
    return zones


# ─────────────────────────────────────────────────────────────
# Authorial annotations already present
# ─────────────────────────────────────────────────────────────

def _parse_annotation(parts: List[str]) -> Dict[str, Any]:
    """
    Parse authorial annotation params. Trailing two numeric parts are W:D.
    First non-numeric param after the code (if any) is the key/token.
      @void            -> footprint 1x1, key None
      @void:3:2        -> footprint 3x2
      @sample:key      -> 1x1, key='key'
      @sample:key:3:3  -> 3x3, key='key'
      @signature:rotation_gimbal -> 1x1, key='rotation_gimbal'
    """
    W, D = 1, 1
    if len(parts) >= 2:
        try:
            w = int(parts[-2]); d = int(parts[-1])
            if w > 0 and d > 0:
                W, D = w, d
        except ValueError:
            pass
    key = None
    for p in parts:
        try:
            int(p)
        except ValueError:
            if p:
                key = p
                break
    return {"footprint": {"w": W, "d": D}, "key": key}


def detect_annotations(utilities: List[List[str]]) -> List[Dict]:
    found = []
    for x, z, cell in iter_cells(utilities):
        s = cell.strip()
        if s.startswith("@"):
            parts = s.split(":")
            code = parts[0]
            params = parts[1:]
            meta = _parse_annotation(params)
            found.append({
                "x": x, "z": z,
                "code": code,
                "params": params,
                "footprint": meta["footprint"],
                "key": meta["key"],
            })
    return found


# ─────────────────────────────────────────────────────────────
# Echoes / style
# ─────────────────────────────────────────────────────────────

SPINE_SEQS = [
    "primitives", "transformation", "color", "forces", "array_tutorial",
    "wavefunctions", "randomness", "noise", "cellularautomata", "fractals",
    "lsystems", "proceduralgeneration", "softbodies", "swarmintelligence",
    "machinelearning", "foundationscrisis", "qfeplaboratory",
    "postfoundationscrisis", "graphtheory",
]

STYLE_MARKERS = {
    "kusama": ["dot", "polkadot", "kusama", "infinity"],
    "rams": ["eurorack", "rack", "braun", "dieter", "knob", "slider_horizontal"],
    "bauhaus": ["bauhaus", "triangle", "circle_square"],
    "escher": ["escher", "penrose", "paradox", "impossible"],
    "pompeii": ["pompeii", "mosaic", "mann", "villa", "fresco"],
}


def detect_echoes(paths: Dict[str, Path], home_seq: str) -> List[str]:
    blurb = load_text(paths["blurb"]).lower()
    intent = load_text(paths["intent"]).lower()
    body = blurb + "\n" + intent
    echoes: List[str] = []
    for seq in SPINE_SEQS:
        if seq == home_seq:
            continue
        if seq in body:
            echoes.append(seq)
    return echoes


def detect_style(tokens: List[str], paths: Dict[str, Path]) -> Optional[str]:
    joined = " ".join(tokens).lower() + " " + load_text(paths["blurb"]).lower()
    scores = {s: sum(joined.count(k) for k in kws) for s, kws in STYLE_MARKERS.items()}
    best = max(scores.items(), key=lambda kv: kv[1])
    return best[0] if best[1] > 0 else None


# ─────────────────────────────────────────────────────────────
# Sequence lookup
# ─────────────────────────────────────────────────────────────

def sequence_of_map(map_name: str) -> Optional[str]:
    sd = MAPS_DIR / "sequences"
    for p in sd.glob("*.json"):
        data = load_json(p)
        if not data:
            continue
        seqs = data.get("sequences", {})
        if not isinstance(seqs, dict):
            continue
        for seq_name, seq_data in seqs.items():
            if not isinstance(seq_data, dict):
                continue
            for m in seq_data.get("maps", []):
                mn = m.get("name") if isinstance(m, dict) else m
                if str(mn) == map_name:
                    return str(seq_name)
    return None


# ─────────────────────────────────────────────────────────────
# Spec build
# ─────────────────────────────────────────────────────────────

def build_spec(map_name: str) -> Optional[dict]:
    paths = map_paths(map_name)
    data = load_json(paths["data"])
    if not data:
        return None

    structure = grid_from(data, "structure")
    utilities = grid_from(data, "utilities")
    interactables = grid_from(data, "interactables")
    W, D = grid_dims(structure)

    tokens = interactable_tokens(interactables)
    walkable = sum(1 for _, _, c in iter_cells(structure) if c.strip() not in ("", "0"))
    density = (len(tokens) / walkable) if walkable else 0.0

    home_seq = sequence_of_map(map_name) or ""
    signature = extract_signature(paths)
    echoes = detect_echoes(paths, home_seq)
    style = detect_style([t for _, _, t in tokens], paths)
    breath = detect_breath_zones(structure, interactables, min_size=6)
    annotations = detect_annotations(utilities)

    # Constraints: every placed artifact's position is a soft constraint,
    # but only the signature (+ any artifact with an existing @must/@signature)
    # is hard. Soft constraints are listed so the solver can weight them.
    hard_constraints = []
    soft_constraints = []
    for x, z, tok in tokens:
        entry = {"x": x, "z": z, "token": tok}
        if tok == signature:
            entry["role"] = "signature"
            hard_constraints.append(entry)
        else:
            soft_constraints.append(entry)

    return {
        "schema": "adaresearch.map_spec.v1",
        "map": map_name,
        "home_sequence": home_seq,
        "dimensions": {"w": W, "d": D},
        "signature": signature,
        "style": style,
        "echoes": echoes,
        "density": round(density, 3),
        "breath_zones": breath,
        "hard_constraints": hard_constraints,
        "soft_constraints": soft_constraints,
        "authorial_annotations": annotations,
        "stats": {
            "artifact_count": len(tokens),
            "walkable_cells": walkable,
            "breath_zone_count": len(breath),
            "unique_tokens": len(set(t for _, _, t in tokens)),
        },
    }


# ─────────────────────────────────────────────────────────────
# Round-trip check (shallow — real generator doesn't exist yet)
# ─────────────────────────────────────────────────────────────

def round_trip_report(spec: dict) -> Dict[str, Any]:
    """
    Without the constraint solver yet, this reports what a generator
    WOULD need to reproduce this map: how many constraints, how much
    freedom, how much authorial intent is declared vs implicit.
    """
    hard = len(spec["hard_constraints"])
    soft = len(spec["soft_constraints"])
    annos = len(spec["authorial_annotations"])
    breath = len(spec["breath_zones"])
    walkable = spec["stats"]["walkable_cells"]
    free_cells = walkable - hard - soft
    return {
        "declared_intent": hard + annos,
        "implicit_intent": soft,
        "free_cells": free_cells,
        "intent_ratio": round((hard + annos) / max(1, hard + soft + annos), 3),
        "verdict": (
            "strongly authored" if (hard + annos) >= 0.5 * (hard + soft + annos)
            else "mostly inferred"
        ),
    }


# ─────────────────────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────────────────────

def write_spec(spec: dict, out_dir: Path) -> Path:
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / f"{spec['map']}.spec.json"
    with path.open("w", encoding="utf-8") as f:
        json.dump(spec, f, indent=2)
    return path


def process(map_name: str, check: bool) -> int:
    spec = build_spec(map_name)
    if not spec:
        print(f"[fail] {map_name}: no map_data.json")
        return 1
    out = write_spec(spec, SPEC_DIR)
    print(f"[ok]  {map_name} -> {out.relative_to(REPO)}")
    if check:
        r = round_trip_report(spec)
        print(f"       intent_ratio={r['intent_ratio']} "
              f"declared={r['declared_intent']} implicit={r['implicit_intent']} "
              f"free_cells={r['free_cells']} verdict='{r['verdict']}'")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("map", nargs="?")
    ap.add_argument("--all", action="store_true", help="process every map")
    ap.add_argument("--check", action="store_true", help="print round-trip report")
    args = ap.parse_args()

    if args.all:
        errors = 0
        names = sorted(p.name for p in MAPS_DIR.iterdir()
                       if p.is_dir() and (p / "map_data.json").exists())
        for n in names:
            errors += process(n, args.check)
        print(f"\nProcessed {len(names)} maps, {errors} errors")
        return 0 if errors == 0 else 1

    if not args.map:
        ap.print_help()
        return 2
    return process(args.map, args.check)


if __name__ == "__main__":
    sys.exit(main())
