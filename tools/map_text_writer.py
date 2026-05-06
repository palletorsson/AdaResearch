#!/usr/bin/env python3
"""
map_text_writer.py — Writing workflow tool for Ada Research map texts.

Tracks coverage of the four text files (blurb.md, technical.md, critical.md,
summary.md) across all maps, gathers context for writing sessions, and audits
sequences for flow gaps.

Usage:
    python tools/map_text_writer.py status                    # Coverage dashboard
    python tools/map_text_writer.py status --sequence forces  # Per-sequence detail
    python tools/map_text_writer.py next                      # Suggest next sequence
    python tools/map_text_writer.py context <map_name>        # Gather writing context
    python tools/map_text_writer.py audit <sequence>          # Analyze flow gaps
"""

import argparse
import json
import sys
import io
from pathlib import Path
from collections import defaultdict

# Force UTF-8 output on Windows
if sys.stdout.encoding != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent.parent
MAPS_DIR = ROOT / "commons" / "maps"
SEQ_DIR = MAPS_DIR / "sequences"
SPINE_PATH = MAPS_DIR / "curriculum_spine.json"
TEXT_FILES = ["blurb.md", "technical.md", "critical.md", "summary.md"]
SKIP_DIRS = {"sequences", "catalog", "Lab"}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def get_all_map_dirs() -> list[Path]:
    """Return all map directories (folders containing map_data.json)."""
    return sorted(
        d for d in MAPS_DIR.iterdir()
        if d.is_dir() and d.name not in SKIP_DIRS and (d / "map_data.json").exists()
    )


def get_text_coverage(map_dir: Path) -> dict:
    """Check which text files exist and are non-empty for a map."""
    result = {}
    for f in TEXT_FILES:
        p = map_dir / f
        if p.exists() and p.stat().st_size > 10:
            result[f] = True
        else:
            result[f] = False
    return result


def load_all_sequences() -> dict:
    """Load all sequence JSON files, return {seq_id: {name, maps, ...}}."""
    sequences = {}
    for path in sorted(SEQ_DIR.glob("*.json")):
        if path.name == "sequence_index.json":
            continue
        try:
            data = load_json(path)
        except Exception:
            continue
        # Sequence files have different formats — handle both
        if "sequences" in data:
            for seq_id, seq_data in data["sequences"].items():
                maps = seq_data.get("maps", [])
                sequences[seq_id] = {
                    "name": seq_data.get("name", seq_id),
                    "maps": maps,
                    "qfep_term": seq_data.get("qfep_term", ""),
                    "qfep_connection": seq_data.get("qfep_connection", ""),
                    "description": seq_data.get("description", ""),
                    "truth": seq_data.get("truth", ""),
                    "learning_objectives": seq_data.get("learning_objectives", []),
                    "file": str(path.relative_to(ROOT)),
                }
        elif "maps" in data:
            seq_id = path.stem
            sequences[seq_id] = {
                "name": data.get("name", seq_id),
                "maps": data["maps"],
                "qfep_term": data.get("qfep_term", ""),
                "qfep_connection": data.get("qfep_connection", ""),
                "description": data.get("description", ""),
                "truth": data.get("truth", ""),
                "learning_objectives": data.get("learning_objectives", []),
                "file": str(path.relative_to(ROOT)),
            }
    return sequences


def load_spine() -> list[dict]:
    """Load the curriculum spine ordering."""
    if not SPINE_PATH.exists():
        return []
    data = load_json(SPINE_PATH)
    spine = data.get("spine", {}).get("sequences", [])
    return sorted(spine, key=lambda s: s.get("order", 999))


def find_map_in_sequences(map_name: str, sequences: dict) -> list[tuple]:
    """Find which sequences contain a map. Returns [(seq_id, index)]."""
    results = []
    for seq_id, seq_data in sequences.items():
        maps = seq_data.get("maps", [])
        if map_name in maps:
            results.append((seq_id, maps.index(map_name)))
    return results


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def cmd_status(args):
    """Coverage dashboard."""
    all_maps = get_all_map_dirs()
    sequences = load_all_sequences()
    spine = load_spine()
    spine_names = [s["name"] for s in spine]

    # Map name -> coverage
    coverage = {}
    for d in all_maps:
        coverage[d.name] = get_text_coverage(d)

    # Sequence -> map coverage
    seq_map_lookup = {}
    for seq_id, seq_data in sequences.items():
        for m in seq_data["maps"]:
            if m not in seq_map_lookup:
                seq_map_lookup[m] = []
            seq_map_lookup[m].append(seq_id)

    if args.sequence:
        # Detail view for one sequence
        seq_id = args.sequence
        if seq_id not in sequences:
            print(f"Unknown sequence: {seq_id}")
            print(f"Available: {', '.join(sorted(sequences.keys()))}")
            return 1
        seq = sequences[seq_id]
        print(f"\n{'=' * 70}")
        print(f"  {seq['name']}")
        print(f"  QFEP: {seq.get('qfep_term', '?')}  |  Maps: {len(seq['maps'])}")
        print(f"{'=' * 70}\n")
        print(f"  {'Map':<35} {'blurb':>6} {'tech':>6} {'crit':>6} {'summ':>6}")
        print(f"  {'-' * 35} {'-' * 6} {'-' * 6} {'-' * 6} {'-' * 6}")
        total = {f: 0 for f in TEXT_FILES}
        for i, m in enumerate(seq["maps"], 1):
            cov = coverage.get(m, {f: False for f in TEXT_FILES})
            marks = []
            for f in TEXT_FILES:
                has = cov.get(f, False)
                if has:
                    total[f] += 1
                marks.append("  ✓" if has else "  ·")
            status = "".join(f"{mk:>6}" for mk in marks)
            print(f"  {i:2}. {m:<32}{status}")
        n = len(seq["maps"])
        print(f"\n  {'Totals':<35}", end="")
        for f in TEXT_FILES:
            pct = (total[f] / n * 100) if n else 0
            print(f" {total[f]:>2}/{n:<2}", end="")
        print()
        return 0

    # Global summary
    total_maps = len(all_maps)
    counts = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}
    file_counts = {f: 0 for f in TEXT_FILES}
    for d in all_maps:
        cov = coverage[d.name]
        n = sum(1 for v in cov.values() if v)
        counts[n] += 1
        for f, has in cov.items():
            if has:
                file_counts[f] += 1

    print(f"\n{'=' * 60}")
    print(f"  Ada Research Map Text Coverage")
    print(f"{'=' * 60}\n")
    print(f"  Total map folders:   {total_maps}")
    print(f"  Complete (4/4):      {counts[4]}")
    print(f"  Partial (1-3):       {counts[1] + counts[2] + counts[3]}")
    print(f"  Bare (0/4):          {counts[0]}")
    missing = sum((4 - sum(1 for v in coverage[d.name].values() if v)) for d in all_maps)
    print(f"  Files missing:       {missing}")
    print()
    print(f"  {'File':<20} {'Count':>6} {'%':>6}")
    print(f"  {'-' * 20} {'-' * 6} {'-' * 6}")
    for f in TEXT_FILES:
        pct = file_counts[f] / total_maps * 100 if total_maps else 0
        print(f"  {f:<20} {file_counts[f]:>6} {pct:>5.1f}%")

    # Per-sequence summary (spine first, then branches)
    print(f"\n  {'Sequence':<28} {'Maps':>5} {'4/4':>5} {'0/4':>5} {'blurb':>6} {'tech':>6} {'crit':>6} {'summ':>6}")
    print(f"  {'-' * 28} {'-' * 5} {'-' * 5} {'-' * 5} {'-' * 6} {'-' * 6} {'-' * 6} {'-' * 6}")

    def print_seq_row(seq_id):
        seq = sequences[seq_id]
        maps = seq["maps"]
        n = len(maps)
        full = 0
        bare = 0
        fc = {f: 0 for f in TEXT_FILES}
        for m in maps:
            cov = coverage.get(m, {f: False for f in TEXT_FILES})
            c = sum(1 for v in cov.values() if v)
            if c == 4:
                full += 1
            elif c == 0:
                bare += 1
            for f in TEXT_FILES:
                if cov.get(f, False):
                    fc[f] += 1
        is_spine = "● " if seq_id in spine_names else "  "
        label = f"{is_spine}{seq_id}"
        print(f"  {label:<28} {n:>5} {full:>5} {bare:>5}", end="")
        for f in TEXT_FILES:
            print(f" {fc[f]:>5}", end="")
        print()

    # Print spine sequences first
    for s in spine:
        sid = s["name"]
        if sid in sequences:
            print_seq_row(sid)

    # Print remaining (branch) sequences
    for sid in sorted(sequences.keys()):
        if sid not in spine_names:
            print_seq_row(sid)

    return 0


def cmd_next(args):
    """Suggest the next spine sequence to write."""
    sequences = load_all_sequences()
    spine = load_spine()
    all_maps = get_all_map_dirs()
    coverage = {d.name: get_text_coverage(d) for d in all_maps}

    print("\nSpine sequences ranked by writing readiness:\n")
    print(f"  {'#':>2} {'Sequence':<25} {'Phase':<14} {'Maps':>5} {'4/4':>5} {'Need':>5} {'Score':>6}")
    print(f"  {'-' * 2} {'-' * 25} {'-' * 14} {'-' * 5} {'-' * 5} {'-' * 5} {'-' * 6}")

    ranked = []
    for s in spine:
        sid = s["name"]
        if sid not in sequences:
            continue
        seq = sequences[sid]
        maps = seq["maps"]
        n = len(maps)
        full = 0
        partial = 0
        for m in maps:
            cov = coverage.get(m, {f: False for f in TEXT_FILES})
            c = sum(1 for v in cov.values() if v)
            if c == 4:
                full += 1
            elif c > 0:
                partial += 1
        need = n - full
        # Score: sequences with some content are easier (voice is established)
        # but not already done
        if need == 0:
            score = -1  # done
        else:
            score = partial * 10 + (n - need)  # reward partial coverage
        ranked.append((sid, s.get("phase", ""), n, full, need, score))

    ranked.sort(key=lambda x: -x[5])
    for i, (sid, phase, n, full, need, score) in enumerate(ranked, 1):
        status = "DONE" if need == 0 else f"{score:>5}"
        print(f"  {i:>2} {sid:<25} {phase:<14} {n:>5} {full:>5} {need:>5} {status:>6}")

    # Recommend top pick
    top = [r for r in ranked if r[4] > 0]
    if top:
        print(f"\n  → Recommended: {top[0][0]} ({top[0][4]} maps need writing, "
              f"some content already exists to match voice)")
    return 0


def cmd_context(args):
    """Gather all context for writing a map's texts."""
    map_name = args.map_name
    map_dir = MAPS_DIR / map_name

    if not map_dir.exists():
        print(f"Map not found: {map_name}")
        return 1

    sequences = load_all_sequences()
    seq_matches = find_map_in_sequences(map_name, sequences)

    print(f"\n{'=' * 70}")
    print(f"  Writing Context: {map_name}")
    print(f"{'=' * 70}\n")

    # 1. Sequence position
    if seq_matches:
        for seq_id, idx in seq_matches:
            seq = sequences[seq_id]
            maps = seq["maps"]
            n = len(maps)
            print(f"  SEQUENCE: {seq['name']} (map {idx + 1} of {n})")
            print(f"  QFEP term: {seq.get('qfep_term', '?')}")
            if seq.get("truth"):
                print(f"  Truth: {seq['truth']}")
            if seq.get("qfep_connection"):
                print(f"  QFEP: {seq['qfep_connection']}")
            print()
            # Prev/next
            if idx > 0:
                print(f"  Previous: {maps[idx - 1]}")
            if idx < n - 1:
                print(f"  Next:     {maps[idx + 1]}")
            print(f"  Full order: {' → '.join(maps)}")
            print()
    else:
        print("  Not found in any sequence.\n")

    # 2. Map info from map_data.json
    map_data_path = map_dir / "map_data.json"
    if map_data_path.exists():
        try:
            data = load_json(map_data_path)
            info = data.get("map_info", {})
            print(f"  MAP INFO:")
            print(f"    Name: {info.get('name', '?')}")
            print(f"    Description: {info.get('description', '?')}")
            dims = info.get("dimensions", {})
            print(f"    Grid: {dims.get('width', '?')} × {dims.get('depth', '?')}, max height {dims.get('max_height', '?')}")
            meta = info.get("metadata", {})
            if meta:
                print(f"    Difficulty: {meta.get('difficulty', '?')}")
                objs = meta.get("learning_objectives", [])
                if objs:
                    print(f"    Objectives: {', '.join(objs[:4])}")
            print()

            # Artifacts from interactables layer
            layers = data.get("layers", {})
            inter = layers.get("interactables", [])
            artifacts = set()
            for row in inter:
                for cell in row:
                    if cell.strip() and cell.strip() != " ":
                        # artifact format: name:rotation:y_offset:scale or just name
                        name = cell.split(":")[0]
                        artifacts.add(name)
            if artifacts:
                print(f"  ARTIFACTS: {', '.join(sorted(artifacts))}")
                print()

            # Utilities
            utils = layers.get("utilities", [])
            util_types = set()
            for row in utils:
                for cell in row:
                    c = cell.strip()
                    if c and c != " ":
                        util_types.add(c)
            if util_types:
                defs = data.get("utility_definitions", {})
                print(f"  UTILITIES: {', '.join(sorted(util_types))}")
                for u in sorted(util_types):
                    if u in defs:
                        d = defs[u]
                        print(f"    {u}: {d.get('type', '?')} — {d.get('name', '')}")
                print()

        except Exception as e:
            print(f"  Error reading map_data.json: {e}\n")

    # 3. Existing text files
    print(f"  EXISTING TEXTS:")
    for f in TEXT_FILES:
        p = map_dir / f
        if p.exists() and p.stat().st_size > 10:
            size = p.stat().st_size
            words = len(p.read_text(encoding="utf-8").split())
            print(f"    ✓ {f} ({words} words)")
        else:
            print(f"    · {f} — MISSING")
    print()

    # 4. Previous map's texts (for continuity)
    if seq_matches:
        seq_id, idx = seq_matches[0]
        if idx > 0:
            prev_name = sequences[seq_id]["maps"][idx - 1]
            prev_dir = MAPS_DIR / prev_name
            print(f"  PREVIOUS MAP TEXTS ({prev_name}):")
            for f in TEXT_FILES:
                p = prev_dir / f
                if p.exists() and p.stat().st_size > 10:
                    text = p.read_text(encoding="utf-8")
                    # Show first ~200 chars as preview
                    preview = text[:200].replace("\n", " ").strip()
                    if len(text) > 200:
                        preview += "..."
                    print(f"    {f}: {preview}")
                else:
                    print(f"    {f}: (missing)")
            print()

    return 0


def cmd_audit(args):
    """Analyze a sequence for flow gaps and stub maps."""
    seq_name = args.sequence_name
    sequences = load_all_sequences()

    if seq_name not in sequences:
        print(f"Unknown sequence: {seq_name}")
        print(f"Available: {', '.join(sorted(sequences.keys()))}")
        return 1

    seq = sequences[seq_name]
    maps = seq["maps"]
    all_map_dirs = {d.name: d for d in get_all_map_dirs()}

    print(f"\n{'=' * 70}")
    print(f"  Sequence Audit: {seq['name']}")
    print(f"  Maps: {len(maps)}  |  QFEP: {seq.get('qfep_term', '?')}")
    print(f"{'=' * 70}\n")

    solid = []
    stubs = []
    missing_dirs = []

    for i, m in enumerate(maps, 1):
        if m not in all_map_dirs:
            missing_dirs.append((i, m))
            continue

        map_dir = all_map_dirs[m]
        data_path = map_dir / "map_data.json"
        issues = []

        # Check map_data.json quality
        if not data_path.exists():
            issues.append("no map_data.json")
        else:
            try:
                data = load_json(data_path)
                info = data.get("map_info", {})
                dims = info.get("dimensions", {})
                w = dims.get("width", 0)
                d = dims.get("depth", 0)

                # Small grid = likely stub
                if w <= 4 or d <= 4:
                    issues.append(f"tiny grid ({w}×{d})")

                # Check for meaningful artifacts
                layers = data.get("layers", {})
                inter = layers.get("interactables", [])
                artifacts = set()
                for row in inter:
                    for cell in row:
                        c = cell.strip()
                        if c and c != " ":
                            artifacts.add(c.split(":")[0])

                # Filter out dark_sphere (decorative)
                real_artifacts = artifacts - {"dark_sphere"}
                if not real_artifacts:
                    issues.append("no meaningful artifacts")

                # Check description quality
                desc = info.get("description", "")
                if not desc or len(desc) < 20:
                    issues.append("weak/missing description")

            except Exception as e:
                issues.append(f"JSON error: {e}")

        # Check text coverage
        cov = get_text_coverage(map_dir)
        text_count = sum(1 for v in cov.values() if v)

        status = "SOLID" if not issues else "STUB"
        marker = "✓" if status == "SOLID" else "!"

        print(f"  {marker} {i:2}. {m}")
        if issues:
            for iss in issues:
                print(f"       ⚠ {iss}")
        text_marks = " ".join(f for f in TEXT_FILES if cov.get(f))
        missing_marks = " ".join(f for f in TEXT_FILES if not cov.get(f))
        if text_marks:
            print(f"       has: {text_marks}")
        if missing_marks:
            print(f"       needs: {missing_marks}")

        if issues:
            stubs.append((i, m, issues))
        else:
            solid.append((i, m))

    if missing_dirs:
        print(f"\n  MISSING MAP FOLDERS:")
        for i, m in missing_dirs:
            print(f"    {i:2}. {m} — folder does not exist")

    # Summary
    print(f"\n  {'─' * 50}")
    print(f"  Solid maps ready for text: {len(solid)}/{len(maps)}")
    print(f"  Stub maps needing work:    {len(stubs)}/{len(maps)}")
    print(f"  Missing folders:           {len(missing_dirs)}/{len(maps)}")

    # Flow analysis
    if seq.get("learning_objectives"):
        print(f"\n  LEARNING OBJECTIVES:")
        for obj in seq["learning_objectives"]:
            print(f"    • {obj}")

    # Detect gaps in progression
    print(f"\n  FLOW ANALYSIS:")
    print(f"    Map order: {' → '.join(maps)}")
    if stubs:
        stub_positions = [s[0] for s in stubs]
        if stub_positions[0] <= 2:
            print(f"    ⚠ Early maps are stubs — sequence opening is weak")
        if stub_positions[-1] >= len(maps) - 1:
            print(f"    ⚠ Final maps are stubs — sequence ending is weak")
        consecutive = []
        for j in range(len(stub_positions) - 1):
            if stub_positions[j + 1] - stub_positions[j] == 1:
                consecutive.append(stub_positions[j])
        if consecutive:
            print(f"    ⚠ Consecutive stubs at positions {consecutive} — flow breaks")

    print()
    return 0


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Ada Research map text writing workflow tool"
    )
    sub = parser.add_subparsers(dest="command")

    # status
    p_status = sub.add_parser("status", help="Coverage dashboard")
    p_status.add_argument("--sequence", "-s", help="Show detail for one sequence")

    # next
    sub.add_parser("next", help="Suggest next spine sequence to write")

    # context
    p_ctx = sub.add_parser("context", help="Gather writing context for a map")
    p_ctx.add_argument("map_name", help="Map folder name")

    # audit
    p_audit = sub.add_parser("audit", help="Analyze sequence for flow gaps")
    p_audit.add_argument("sequence_name", help="Sequence ID")

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        return 1

    cmds = {
        "status": cmd_status,
        "next": cmd_next,
        "context": cmd_context,
        "audit": cmd_audit,
    }
    return cmds[args.command](args)


if __name__ == "__main__":
    sys.exit(main() or 0)
