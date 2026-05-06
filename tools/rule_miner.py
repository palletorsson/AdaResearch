#!/usr/bin/env python
"""
rule_miner.py — reverse-engineer existing map_data.json into a minimal
rule expression (base recipe + @-operators + artifacts with footprints).

For each map:
  1. Score each structure recipe against the observed structure layer.
     Pick the one with the highest match ratio.
  2. Compute residual cells (observed != recipe).
  3. Group adjacent residuals into @-operator rectangles.
  4. Scan interactables for placement + infer footprint from
     surrounding walkable cells.
  5. Emit a YAML description of the map in rule form + residual score.

Output: doc/rule_mining/<map>.yaml per map, plus a sequence summary.

Usage:
  python tools/rule_miner.py --map Point_One
  python tools/rule_miner.py --sequence primitives
  python tools/rule_miner.py --sequence primitives --out-dir doc/rule_mining
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
import structure_recipes  # noqa: E402

# ─── registry reader: spatial_needs.platform ─────────────────────────────
#
# Step 2a consolidation: the old `floats_in_void` tag was read from .gd
# source via regex. Replaced by reading `spatial_needs.platform` from the
# artifact registry JSON — one source of truth. An artifact with
# `platform: "sunken"` in its registry entry has void around it by design;
# rule_miner treats the surrounding cells as design envelope, not residual.

_registry_cache: dict[str, dict] | None = None

def _load_registry() -> dict[str, dict]:
    """Load every artifact from commons/artifacts/registry/*.json into a
    flat {token: entry} dict. Cached for the session."""
    global _registry_cache
    if _registry_cache is not None:
        return _registry_cache
    out: dict[str, dict] = {}
    reg_dir = REPO / "commons" / "artifacts" / "registry"
    if not reg_dir.exists():
        _registry_cache = {}
        return _registry_cache
    for p in reg_dir.glob("*.json"):
        if p.name.endswith(".deprecated"):
            continue
        try:
            txt = p.read_text(encoding="utf-8")
            data = _loose_json_loads(txt)
        except Exception:
            continue
        # Registry format: { "<category>": { "artifacts": { "<token>": {...} } } }
        for _cat, body in (data or {}).items():
            if not isinstance(body, dict):
                continue
            arts = body.get("artifacts") or {}
            if isinstance(arts, dict):
                for token, entry in arts.items():
                    if isinstance(entry, dict):
                        out[token] = entry
    _registry_cache = out
    return out


def artifact_platform(token: str) -> str:
    """Return `spatial_needs.platform` for the artifact, or "" if unset.
    Values: "none" (default), "sunken", "table", "pedestal"."""
    reg = _load_registry()
    entry = reg.get(token) or {}
    sn = entry.get("spatial_needs") or {}
    p = sn.get("platform")
    return str(p) if isinstance(p, str) else ""

MAPS_DIR = REPO / "commons" / "maps"
SEQ_DIR = REPO / "commons" / "maps" / "sequences"
DEFAULT_OUT = REPO / "doc" / "rule_mining"


# ─── loose JSON helpers (tolerate trailing commas) ──────────────────────

def _loose_json_loads(text: str):
    cleaned = re.sub(r",\s*([\]}])", r"\1", text)
    return json.loads(cleaned)


def load_map(map_name: str) -> dict | None:
    p = MAPS_DIR / map_name / "map_data.json"
    if not p.exists():
        return None
    try:
        return _loose_json_loads(p.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"  [WARN] can't parse {map_name}: {e}")
        return None


def load_sequence_maps(seq: str) -> list[str]:
    sp = SEQ_DIR / f"{seq}.json"
    if not sp.exists():
        return []
    data = _loose_json_loads(sp.read_text(encoding="utf-8"))
    return list(data.get("sequences", {}).get(seq, {}).get("maps", []))


# ─── structure scoring ──────────────────────────────────────────────────

def _normalize_cell(v) -> str:
    s = str(v).strip()
    if s == "" or s == "0":
        return "0"
    return s


def structure_grid(data: dict) -> list[list[str]]:
    layers = data.get("layers", {})
    struct = layers.get("structure", [])
    return [[_normalize_cell(c) for c in row] for row in struct]


def try_recipe(name: str, rows: int, cols: int, params: dict | None = None) -> list[list[str]]:
    """Run a structure recipe at the given dimensions and pad/truncate
    to match rows x cols for direct comparison."""
    grid = structure_recipes.build_structure(name, params or {})
    # Recipes return 16x8 by default; adapt
    out: list[list[str]] = []
    for r in range(rows):
        row = []
        for c in range(cols):
            if r < len(grid) and c < len(grid[r]):
                row.append(_normalize_cell(grid[r][c]))
            else:
                row.append("0")
        out.append(row)
    return out


def match_score(observed: list[list[str]], proposed: list[list[str]]) -> float:
    rows = len(observed)
    cols = len(observed[0]) if rows else 0
    if rows == 0 or cols == 0:
        return 0.0
    matches = 0
    total = 0
    for r in range(rows):
        for c in range(cols):
            total += 1
            if r < len(proposed) and c < len(proposed[r]):
                if observed[r][c] == proposed[r][c]:
                    matches += 1
    return matches / total if total else 0.0


def pick_best_recipe(
    observed: list[list[str]],
    ignore_mask: set[tuple[int, int]] | None = None,
) -> tuple[str, float, list[list[str]]]:
    """Pick the recipe whose COMBINED score is highest.

    combined_score = coverage_pct - operator_penalty
      coverage_pct     = % of cells matching observed (ignoring cells in
                         void-envelope design masks — sunken artifacts
                         or gallery sequences)
      operator_penalty = 0.3pt per @-operator needed

    The penalty makes compact representations win ties. The mask makes
    void-around-floating-artifacts invisible to the scorer.
    """
    rows = len(observed)
    cols = len(observed[0]) if rows else 0
    ignore_mask = ignore_mask or set()
    best_name = "flat_corridor"
    best_combined = -1e9
    best_coverage = 0.0
    best_grid: list[list[str]] = []
    # Cache total cells that COUNT (i.e. not in ignore_mask)
    counted = max(1, rows * cols - len([1 for p in ignore_mask
                                         if 0 <= p[0] < rows and 0 <= p[1] < cols]))
    for name in structure_recipes.list_recipes():
        try:
            g = try_recipe(name, rows, cols)
        except Exception:
            continue
        # Match score that ignores masked cells
        matches = 0
        for r in range(rows):
            for c in range(cols):
                if (r, c) in ignore_mask:
                    continue
                if r < len(g) and c < len(g[r]) and g[r][c] == observed[r][c]:
                    matches += 1
        coverage = matches / counted * 100.0
        residuals = residual_cells(observed, g, ignore_mask)
        op_groups = group_residuals(residuals)
        combined = coverage - (len(op_groups) * 0.3)
        if combined > best_combined:
            best_combined = combined
            best_coverage = coverage
            best_name = name
            best_grid = g
    return best_name, best_coverage, best_grid


# ─── residual → operator grouping ───────────────────────────────────────

def residual_cells(
    observed: list[list[str]],
    proposed: list[list[str]],
    ignore_mask: set[tuple[int, int]] | None = None,
) -> list[dict]:
    """Return list of residual cells: {r, c, observed, expected, op_hint}.

    ignore_mask: optional set of (r, c) tuples that should NOT count as
    residuals regardless of deviation. Used to honor void-envelope
    artifacts (sunken platform or gallery sequence) — the void cells
    around them are design, not gap.
    """
    out = []
    ignore_mask = ignore_mask or set()
    for r in range(len(observed)):
        for c in range(len(observed[r])):
            if (r, c) in ignore_mask:
                continue
            exp = proposed[r][c] if r < len(proposed) and c < len(proposed[r]) else "0"
            obs = observed[r][c]
            if obs == exp:
                continue
            # Categorize
            if obs == "0" and exp != "0":
                hint = "@void"
            elif obs == "1" and exp == "0":
                hint = "@floor"
            elif obs.isdigit() and int(obs) >= 2 and exp != obs:
                hint = f"@h:{obs}"
            else:
                hint = f"@h:{obs}" if obs != "0" else "@void"
            out.append({"r": r, "c": c, "observed": obs, "expected": exp, "op_hint": hint})
    return out


_STYLES_CACHE: dict | None = None

def _load_spine_styles() -> dict:
    global _STYLES_CACHE
    if _STYLES_CACHE is not None:
        return _STYLES_CACHE
    p = REPO / "commons" / "maps" / "spine_styles.json"
    if not p.exists():
        _STYLES_CACHE = {}
        return _STYLES_CACHE
    try:
        txt = p.read_text(encoding="utf-8")
        cleaned = re.sub(r",\s*([\]}])", r"\1", txt)
        _STYLES_CACHE = json.loads(cleaned)
    except Exception:
        _STYLES_CACHE = {}
    return _STYLES_CACHE


def sequence_is_gallery(sequence: str | None) -> bool:
    """True if the sequence declares `gallery: true` in spine_styles.json.
    Gallery sequences (e.g. primitives) treat every artifact as living in
    a void envelope — unreachability is design, not bug. Replaces the
    old `default_artifact_tags: ["floats_in_void"]` mechanism."""
    if not sequence:
        return False
    styles = _load_spine_styles()
    seq_entry = styles.get("sequences", {}).get(sequence, {})
    return bool(seq_entry.get("gallery", False))


def void_envelope_mask(data: dict, sequence: str | None = None, radius: int = 2) -> set[tuple[int, int]]:
    """Build a mask of (r, c) cells ignored from residual counting because
    they're inside an artifact's design envelope of surrounding void.

    An artifact has a void envelope when:
      - its registry `spatial_needs.platform == "sunken"` (per-artifact), OR
      - its sequence declares `gallery: true` in spine_styles.json
        (sequence-wide, applies to every placed artifact)

    Previously this read a `floats_in_void` tag from .gd source. Consolidated
    in step 2a: one source of truth per fact, registry + sequence style.
    """
    seq_gallery = sequence_is_gallery(sequence)

    mask: set[tuple[int, int]] = set()
    layers = data.get("layers", {})
    il = layers.get("interactables", [])
    for r in range(len(il)):
        if not isinstance(il[r], list): continue
        for c in range(len(il[r])):
            s = str(il[r][c]).strip()
            if not s or s == " ":
                continue
            token = s.split("#", 1)[0].split(":", 1)[0].strip()
            has_envelope = seq_gallery or (artifact_platform(token) == "sunken")
            if not has_envelope:
                continue
            for dz in range(-radius, radius + 1):
                for dx in range(-radius, radius + 1):
                    mask.add((r + dz, c + dx))
    return mask


# Backward-compat alias (can delete once nothing external calls it)
float_void_mask = void_envelope_mask


def group_residuals(cells: list[dict]) -> list[dict]:
    """Pack residuals into rectangular runs. Greedy: for each cell, try to
    grow a rectangle to the east + south of cells with the same op_hint."""
    if not cells:
        return []
    # Build a lookup
    by_pos: dict[tuple[int, int], dict] = {(c["r"], c["c"]): c for c in cells}
    visited: set[tuple[int, int]] = set()
    groups: list[dict] = []

    def same_hint(a: dict, b: dict) -> bool:
        return a["op_hint"] == b["op_hint"]

    for cell in sorted(cells, key=lambda x: (x["r"], x["c"])):
        key = (cell["r"], cell["c"])
        if key in visited:
            continue
        # Grow east
        w = 1
        while True:
            nxt = (cell["r"], cell["c"] + w)
            if nxt not in by_pos or nxt in visited:
                break
            if not same_hint(by_pos[nxt], cell):
                break
            w += 1
        # Grow south
        d = 1
        while True:
            ok = True
            for dx in range(w):
                pos = (cell["r"] + d, cell["c"] + dx)
                if pos not in by_pos or pos in visited:
                    ok = False; break
                if not same_hint(by_pos[pos], cell):
                    ok = False; break
            if not ok:
                break
            d += 1
        # Mark visited
        for dz in range(d):
            for dx in range(w):
                visited.add((cell["r"] + dz, cell["c"] + dx))
        groups.append({
            "op": cell["op_hint"],
            "r": cell["r"], "c": cell["c"],
            "w": w, "d": d,
        })
    return groups


# ─── artifact inference ─────────────────────────────────────────────────

def infer_artifact_footprint(observed: list[list[str]], r: int, c: int, max_radius: int = 3) -> tuple[int, int]:
    """Estimate footprint from the walkable neighborhood around the
    artifact cell. Walks outward; the footprint is the largest rectangle
    centered on (r, c) that's entirely walkable."""
    rows = len(observed)
    cols = len(observed[0]) if rows else 0
    # Walkable = non-"0"
    def walk(rr, cc):
        return 0 <= rr < rows and 0 <= cc < cols and observed[rr][cc] != "0"
    # Anchor must be walkable
    if not walk(r, c):
        return (1, 1)
    w = 1
    d = 1
    # Grow east/west symmetrically while all cells walkable
    while w < max_radius:
        new_w = w + 2
        half = new_w // 2
        ok = True
        for dz in range(-d // 2, d // 2 + 1):
            for dx in range(-half, half + 1):
                if not walk(r + dz, c + dx):
                    ok = False; break
            if not ok: break
        if not ok: break
        w = new_w
    # Grow north/south similarly
    while d < max_radius:
        new_d = d + 2
        half = new_d // 2
        ok = True
        for dz in range(-half, half + 1):
            for dx in range(-w // 2, w // 2 + 1):
                if not walk(r + dz, c + dx):
                    ok = False; break
            if not ok: break
        if not ok: break
        d = new_d
    return (w, d)


def extract_artifacts(data: dict, observed: list[list[str]]) -> list[dict]:
    layers = data.get("layers", {})
    il = layers.get("interactables", [])
    out = []
    for r in range(len(il)):
        if not isinstance(il[r], list): continue
        for c in range(len(il[r])):
            s = str(il[r][c]).strip()
            if not s or s == " ":
                continue
            parts = s.split("#", 1)
            base = parts[0]
            extra = parts[1] if len(parts) > 1 else ""
            fields = base.split(":")
            token = fields[0]
            rot = fields[1] if len(fields) > 1 else ""
            y_off = fields[2] if len(fields) > 2 else ""
            fp = infer_artifact_footprint(observed, r, c)
            entry = {
                "token": token,
                "at": [c, r],
                "rotation": rot,
                "y_offset": y_off,
                "footprint_inferred": list(fp),
            }
            if extra:
                entry["config"] = "#" + extra
            out.append(entry)
    return out


def extract_utilities(data: dict) -> list[dict]:
    layers = data.get("layers", {})
    ul = layers.get("utilities", [])
    out = []
    for r in range(len(ul)):
        if not isinstance(ul[r], list): continue
        for c in range(len(ul[r])):
            s = str(ul[r][c]).strip()
            if not s or s == " ":
                continue
            token = s.split(":", 1)[0]
            out.append({"token": token, "at": [c, r], "raw": s})
    return out


# ─── report emission ────────────────────────────────────────────────────

def _fmt_operator(g: dict) -> str:
    op = g["op"]
    # Emit W:D footprint only when != 1x1, for readability
    suffix = f":{g['w']}:{g['d']}" if (g["w"] != 1 or g["d"] != 1) else ""
    return f"{op}{suffix} at ({g['c']},{g['r']})"


def build_report(map_name: str, data: dict, sequence: str | None) -> dict:
    observed = structure_grid(data)
    rows = len(observed)
    cols = len(observed[0]) if rows else 0

    # Build the void-envelope mask before scoring. Signals:
    #   - artifact registry `spatial_needs.platform == "sunken"`, OR
    #   - sequence-level `gallery: true` in spine_styles.json
    mask = void_envelope_mask(data, sequence)
    masked_count = len([1 for p in mask if 0 <= p[0] < rows and 0 <= p[1] < cols])

    best_name, best_score, best_grid = pick_best_recipe(observed, mask)
    residuals = residual_cells(observed, best_grid, mask) if best_grid else []
    operators = group_residuals(residuals)
    artifacts = extract_artifacts(data, observed)
    utilities = extract_utilities(data)

    # Denominator excludes masked cells (void envelope: design, not gap)
    counted = max(1, rows * cols - masked_count)
    residual_pct = 100.0 * (1.0 - len(residuals) / counted)

    # Summarize operator kinds
    op_counts: dict[str, int] = {}
    for g in operators:
        op_counts[g["op"]] = op_counts.get(g["op"], 0) + 1

    return {
        "map": map_name,
        "sequence": sequence,
        "dimensions": {"rows": rows, "cols": cols},
        "base_recipe": best_name,
        "base_recipe_match_pct": round(best_score, 1),
        "residual_cells": len(residuals),
        "residual_pct": round(100.0 - residual_pct, 1),
        "vocabulary_coverage_pct": round(residual_pct, 1),
        "cells_masked_void_envelope": masked_count,
        "operator_groups": len(operators),
        "operator_kinds": op_counts,
        "operators_declarative": [_fmt_operator(g) for g in operators],
        "utilities": utilities,
        "artifacts": artifacts,
        "artifact_count": len(artifacts),
    }


def write_yaml_like(path: Path, obj: dict) -> None:
    """Emit YAML-like text without requiring PyYAML. Deterministic.
    Deliberately simple: dicts indented, lists as "- ", strings unquoted
    when safe, scalars as-is."""
    path.parent.mkdir(parents=True, exist_ok=True)
    lines: list[str] = []
    _emit(obj, lines, 0)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _scalar(v) -> str:
    if v is None: return "null"
    if isinstance(v, bool): return "true" if v else "false"
    if isinstance(v, (int, float)): return str(v)
    s = str(v)
    # Quote if contains special YAML chars
    if any(ch in s for ch in [":", "#", "-", "[", "]", "{", "}", ","]):
        return json.dumps(s)
    if s == "":
        return '""'
    return s


def _emit(obj, lines: list[str], indent: int) -> None:
    pad = "  " * indent
    if isinstance(obj, dict):
        for k, v in obj.items():
            if isinstance(v, dict):
                if not v:
                    lines.append(f"{pad}{k}: {{}}")
                else:
                    lines.append(f"{pad}{k}:")
                    _emit(v, lines, indent + 1)
            elif isinstance(v, list):
                if not v:
                    lines.append(f"{pad}{k}: []")
                else:
                    lines.append(f"{pad}{k}:")
                    for item in v:
                        if isinstance(item, (dict, list)):
                            lines.append(f"{pad}  -")
                            _emit(item, lines, indent + 2)
                        else:
                            lines.append(f"{pad}  - {_scalar(item)}")
            else:
                lines.append(f"{pad}{k}: {_scalar(v)}")
    elif isinstance(obj, list):
        for item in obj:
            if isinstance(item, (dict, list)):
                lines.append(f"{pad}-")
                _emit(item, lines, indent + 1)
            else:
                lines.append(f"{pad}- {_scalar(item)}")


# ─── main ───────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", help="mine one map")
    ap.add_argument("--sequence", help="mine all maps in a sequence")
    ap.add_argument("--out-dir", default=str(DEFAULT_OUT))
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    out_root = Path(args.out_dir)

    # Build the map list
    maps: list[tuple[str, str | None]] = []  # (map_name, sequence)
    if args.map:
        maps = [(args.map, args.sequence)]
    elif args.sequence:
        for m in load_sequence_maps(args.sequence):
            maps.append((m, args.sequence))
    else:
        print("Usage: --map NAME or --sequence NAME", file=sys.stderr)
        return 1

    if not maps:
        print("No maps found to mine.", file=sys.stderr)
        return 1

    # Mine each
    reports: list[dict] = []
    print(f"Mining {len(maps)} map(s)...")
    for map_name, seq in maps:
        data = load_map(map_name)
        if not data:
            print(f"  [SKIP] {map_name}")
            continue
        report = build_report(map_name, data, seq)
        reports.append(report)

        out_path = out_root
        if seq:
            out_path = out_path / seq
        out_path = out_path / f"{map_name}.yaml"
        write_yaml_like(out_path, report)

        print(f"  [OK] {map_name:<30s} recipe={report['base_recipe']:<20s} "
              f"coverage={report['vocabulary_coverage_pct']:>5.1f}%  "
              f"ops={report['operator_groups']:<3d} artifacts={report['artifact_count']}")

    # Sequence summary
    if args.sequence and reports:
        summary = {
            "sequence": args.sequence,
            "maps_mined": len(reports),
            "average_coverage_pct": round(
                sum(r["vocabulary_coverage_pct"] for r in reports) / len(reports), 1
            ),
            "recipe_usage": {},
            "total_operator_kinds": {},
            "per_map": [
                {
                    "map": r["map"],
                    "base_recipe": r["base_recipe"],
                    "coverage_pct": r["vocabulary_coverage_pct"],
                    "operators": r["operator_groups"],
                    "artifacts": r["artifact_count"],
                }
                for r in reports
            ],
        }
        for r in reports:
            summary["recipe_usage"][r["base_recipe"]] = summary["recipe_usage"].get(r["base_recipe"], 0) + 1
            for op, n in r["operator_kinds"].items():
                summary["total_operator_kinds"][op] = summary["total_operator_kinds"].get(op, 0) + n

        summary_path = out_root / args.sequence / "_summary.yaml"
        write_yaml_like(summary_path, summary)
        print()
        print(f"Sequence '{args.sequence}' summary:")
        print(f"  average vocabulary coverage: {summary['average_coverage_pct']}%")
        print(f"  recipes used: {summary['recipe_usage']}")
        print(f"  top operator kinds: {dict(sorted(summary['total_operator_kinds'].items(), key=lambda x: -x[1])[:8])}")
        print(f"  report: {summary_path.relative_to(REPO)}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
