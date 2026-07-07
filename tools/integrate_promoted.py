"""Integrate a promoted DNA artifact into a curriculum map.

This is step 4 of the four-loop pipeline:
    1. Chamber approves artifacts.
    2. DNA galleries publish parameter sweeps.
    3. Promotion turns a high-rated DNA cell into a runnable artifact at
       commons/primitives/promoted/<gallery>__<entry>/.
    4. INTEGRATION (this tool): places that promoted artifact into the
       interactables layer of a curriculum map.

CLI:
    # Place a promoted artifact in a specific map cell.
    python tools/integrate_promoted.py \\
      --artifact=parametric-mesh-gallery__cylinder_r16 \\
      --map=Gallery_Primitives_1 \\
      --cell=5,17

    # Dry run — print what would change without writing.
    python tools/integrate_promoted.py \\
      --artifact=parametric-mesh-gallery__cylinder_r16 \\
      --map=Gallery_Primitives_1 \\
      --cell=5,17 \\
      --dry-run

    # Suggest target maps + empty cells based on the artifact's source gallery.
    python tools/integrate_promoted.py \\
      --artifact=parametric-mesh-gallery__cylinder_r16 \\
      --suggest

Cell convention:
    --cell=COL,ROW  (matches the encyclopedia map-builder UI: x first, then z/depth).
    Internally the map JSON stores rows as the outer index and cols as the inner
    index, so we translate at the boundary.

Defensive behavior:
    - Refuses to overwrite occupied interactables cells.
    - Refuses to place on void structure cells ("v" or "0"; see _is_walkable_height).
    - Refuses to place out of bounds.
    - Validates that the promoted artifact directory and its meta.json exist
      before touching the target map.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[1]
PROMOTED_DIR = ROOT / "commons" / "primitives" / "promoted"
MAPS_DIR = ROOT / "commons" / "maps"
SEQ_DIR = MAPS_DIR / "sequences"

# Gallery slug → "natural home" sequence id(s).
# These ids must match files in commons/maps/sequences/<id>.json.
# When a gallery's substrate aligns with a sequence's curriculum, that sequence's
# maps are the candidate targets for placing promoted artifacts from that gallery.
GALLERY_SEQUENCES: dict[str, list[str]] = {
    "parametric-mesh-gallery":       ["primitives"],
    "parametric-platonic-gallery":   ["primitives"],
    "parametric-johnson-gallery":    ["primitives"],
    "parametric-prism-gallery":      ["primitives"],
    # Vectors sequence was merged into forces (see commons/maps/sequences/vectors.json).
    # `vectorbasics` doesn't exist as a sequence id; we keep the requested mapping
    # but fall back to `forces` when the id is missing.
    "parametric-coordinate-gallery": ["vectors", "vectorbasics", "forces"],
    "riemann-sum-gallery":           ["change"],
    "tangent-slope-gallery":         ["change"],
    "transform-composition-gallery": ["transformation"],
    # `alternative_geometries` isn't a sequence file; computationalgeometry is the
    # closest fit. We list both — the resolver will quietly drop unknown ids.
    "triangle-table-gallery":        ["alternative_geometries", "computationalgeometry"],
    "halting-bench-gallery":         ["foundationscrisis", "postfoundationscrisis"],
    "cantor-diagonal-gallery":       ["foundationscrisis"],
    "russell-paradox-gallery":       ["foundationscrisis"],
    "complexity-dial-gallery":       ["foundationscrisis"],
    "qfep-balance-gallery":          ["qfeplaboratory"],
    "array-cartridge-gallery":       ["array_tutorial"],
}


# ---------------------------------------------------------------------------
# Loading & validation


def _load_artifact_meta(artifact: str) -> tuple[Path, dict]:
    """Resolve an artifact dir + load its meta. Two valid locations:
       - commons/primitives/promoted/<artifact>/   — from DNA promotion
       - commons/artifacts/<artifact>/             — first-class artifacts
                                                     (workbenches, instruments)

    For first-class artifacts, synthesize a meta from the registry entry so the
    rest of the integrate flow works uniformly.

    Returns (artifact_dir, meta_dict).
    """
    # Try promoted dir first (the original use case)
    artifact_dir = PROMOTED_DIR / artifact
    if artifact_dir.is_dir():
        meta_path = artifact_dir / "meta.json"
        if not meta_path.is_file():
            raise FileNotFoundError(
                f"meta.json missing inside {artifact_dir}\n"
                f"  Every promoted artifact must declare its source gallery + params."
            )
        try:
            meta = json.loads(meta_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            raise ValueError(f"meta.json is not valid JSON: {meta_path}\n  {e}") from e
        return artifact_dir, meta

    # Fall back: first-class artifact under commons/artifacts/
    fc_dir = ROOT / "commons" / "artifacts" / artifact
    if fc_dir.is_dir():
        # Synthesize a meta from registry lookup so downstream code uniform-ish.
        registry_dir = ROOT / "commons" / "artifacts" / "registry"
        entry: dict = {}
        for reg_path in registry_dir.glob("*.json"):
            try:
                reg = json.loads(reg_path.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                continue
            arts = reg.get("artifacts") if isinstance(reg, dict) else None
            if isinstance(arts, dict) and artifact in arts:
                entry = arts[artifact]
                break
        seq = entry.get("sequence") or entry.get("map_sequences", [None])[0]
        meta = {
            "source_gallery": entry.get("category", "first_class"),
            "lookup_name": artifact,
            "rating": {"stars": 5, "verdict": "first_class"},
            "params": {},
            "_first_class": True,
            "_target_sequence": seq,
        }
        return fc_dir, meta

    raise FileNotFoundError(
        f"Artifact not found at either:\n"
        f"  - {PROMOTED_DIR / artifact}\n"
        f"  - {ROOT / 'commons' / 'artifacts' / artifact}\n"
        f"Hint: ls {ROOT / 'commons' / 'artifacts'}/ | grep {artifact.split('_')[0]}"
    )

    # Minimum schema we rely on:
    #   gallery (or source_gallery): slug matching a key in GALLERY_SEQUENCES.
    #   lookup_name (optional): falls back to the directory name.
    # Accept both `gallery` and `source_gallery` — the promotion agent uses
    # the latter, but the schema is loose enough that either is fine.
    if "gallery" not in meta and "source_gallery" not in meta:
        raise ValueError(
            f"meta.json missing required field 'gallery' "
            f"(or 'source_gallery'): {meta_path}\n"
            f"  Expected one of: {sorted(GALLERY_SEQUENCES.keys())}"
        )
    # Normalize so the rest of the code can look at meta['gallery'].
    if "gallery" not in meta:
        meta["gallery"] = meta["source_gallery"]

    return artifact_dir, meta


def _load_map(map_name: str) -> tuple[Path, dict, str]:
    """Load a map's map_data.json. Returns (path, data, raw_text)."""
    map_path = MAPS_DIR / map_name / "map_data.json"
    if not map_path.is_file():
        raise FileNotFoundError(
            f"Map not found: {map_path}\n"
            f"  Hint: ls {MAPS_DIR.relative_to(ROOT)}/ | grep -i {map_name[:10]}"
        )
    raw_text = map_path.read_text(encoding="utf-8")
    try:
        data = json.loads(raw_text)
    except json.JSONDecodeError as e:
        raise ValueError(f"map_data.json invalid JSON: {map_path}\n  {e}") from e
    return map_path, data, raw_text


def _layers(map_data: dict) -> tuple[list, list, list]:
    """Pull the three layers from a map_data dict. Raises if the shape is wrong."""
    layers = map_data.get("layers")
    if not isinstance(layers, dict):
        raise ValueError("map_data has no 'layers' object")
    structure = layers.get("structure")
    utilities = layers.get("utilities")
    interactables = layers.get("interactables")
    for name, layer in [("structure", structure),
                        ("utilities", utilities),
                        ("interactables", interactables)]:
        if not isinstance(layer, list) or not layer or not isinstance(layer[0], list):
            raise ValueError(f"map_data.layers.{name} is missing or not a 2D array")
    return structure, utilities, interactables


def _is_walkable_height(cell: str) -> bool:
    """A structure cell counts as walkable floor when it's a height >= 1.

    Conventions seen across the codebase:
      "0"  — flat ground at level 0 (some maps use 0 as void, others as floor;
             ambiguous on its own, so we treat 0 as "not walkable" to be safe).
      "v"  — explicit void marker.
      "1".."5" — heights, all walkable surfaces.
      Anything else (e.g. "h", combined notations) — treat as not walkable.
    """
    if not isinstance(cell, str):
        return False
    s = cell.strip()
    if s in ("v", "V", "", "0"):
        return False
    if s.isdigit() and 1 <= int(s) <= 9:
        return True
    # Some maps use compound height codes like "1h" or "h:fire"; only the bare
    # digits qualify as definitely-walkable floor.
    return False


def _validate_cell(structure: list, interactables: list,
                   col: int, row: int) -> None:
    """Raise ValueError if (col, row) is out of bounds, void, or occupied.

    Tolerant of common project-wide schema drift: the interactables layer is
    often smaller than the structure layer. We pad interactables in-place with
    blank cells so the target cell can be validated against a consistent shape.
    """
    depth = len(structure)
    width = len(structure[0]) if depth else 0
    if not (0 <= row < depth and 0 <= col < width):
        raise ValueError(
            f"Cell ({col},{row}) is out of bounds for {width}x{depth} map"
        )

    # Auto-pad the interactables layer to match structure's shape. Many maps
    # in the codebase have a shorter interactables layer than structure layer;
    # rather than rejecting, we extend with blanks so the integration can land.
    while len(interactables) < depth:
        interactables.append([" "] * width)
    for r_idx in range(len(interactables)):
        while len(interactables[r_idx]) < width:
            interactables[r_idx].append(" ")

    struct_cell = structure[row][col]
    if not _is_walkable_height(struct_cell):
        raise ValueError(
            f"Cell ({col},{row}) is void/non-walkable in structure layer "
            f"(value: {struct_cell!r}). "
            f"Pick a cell with a height '1'..'5'."
        )

    interact_cell = interactables[row][col]
    if interact_cell != " ":
        raise ValueError(
            f"Cell ({col},{row}) already occupied in interactables layer "
            f"(value: {interact_cell!r}). Refusing to overwrite."
        )


# ---------------------------------------------------------------------------
# Sequence lookup


def _sequence_maps(seq_id: str) -> list[str]:
    """Return the list of map names declared by a sequence file. [] if missing."""
    path = SEQ_DIR / f"{seq_id}.json"
    if not path.is_file():
        return []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return []
    seqs = data.get("sequences", {})
    block = seqs.get(seq_id) if isinstance(seqs, dict) else None
    if isinstance(block, dict):
        maps = block.get("maps")
        if isinstance(maps, list):
            return [m for m in maps if isinstance(m, str)]
    return []


def _find_empty_cells(map_name: str, limit: int = 3) -> list[tuple[int, int]]:
    """Return up to `limit` (col, row) cells that are empty & walkable.

    Used by --suggest to give the user concrete placement options without
    making them open the map file themselves.
    """
    try:
        _, data, _ = _load_map(map_name)
        structure, _, interactables = _layers(data)
    except (FileNotFoundError, ValueError):
        return []
    depth = len(structure)
    width = len(structure[0]) if depth else 0
    out: list[tuple[int, int]] = []
    for r in range(depth):
        for c in range(width):
            if c >= len(interactables[r]) or c >= len(structure[r]):
                continue
            if (_is_walkable_height(structure[r][c])
                    and interactables[r][c] == " "):
                out.append((c, r))
                if len(out) >= limit:
                    return out
    return out


def _resolve_lookup_name(artifact_dir: Path, meta: dict) -> str:
    """The token written into the interactables layer.

    Precedence: meta.json's `lookup_name` (if set) → directory name.
    """
    name = meta.get("lookup_name")
    if isinstance(name, str) and name.strip():
        return name.strip()
    return artifact_dir.name


# ---------------------------------------------------------------------------
# Write-back


def _write_map_preserving_format(map_path: Path, updated_data: dict,
                                 raw_text: str) -> None:
    """Write the updated map back to disk, mirroring the original formatting.

    Best-effort indent preservation: if the original file used tab indent at the
    top level (common in this project), we re-emit with tabs; otherwise 2-space.
    Rows of the three layer arrays are re-collapsed onto one line each to keep
    the diff small (matches the existing convention in the codebase). A trailing
    newline is preserved iff the original had one.
    """
    # Sniff indentation off the second non-empty line of the original.
    indent_char = "  "
    for line in raw_text.splitlines():
        if line.startswith("\t"):
            indent_char = "\t"
            break
        if line.startswith("  "):
            indent_char = "  "
            break

    out = json.dumps(updated_data, indent=indent_char, ensure_ascii=False)
    # Collapse rows of layer arrays back to one line apiece. json.dumps with
    # indent expands every list element onto its own line; the existing maps in
    # this codebase keep each row as a single line. We do a textual fixup
    # rather than a custom encoder so we can stay tolerant of nested dicts.
    out = _collapse_layer_rows(out)
    if raw_text.endswith("\n"):
        out += "\n"
    map_path.write_text(out, encoding="utf-8")


def _collapse_layer_rows(text: str) -> str:
    """Collapse one-string-per-line layer ROW arrays back to inline form.

    Targets only the inner rows of the three layer 2D arrays — i.e. arrays of
    short strings that sit *inside another array* (preceded by a context line
    of nothing but whitespace + `[` opening the outer array, or a `]` closing
    the previous sibling row). Top-level string lists like `learning_objectives`
    are left alone because they sit on a `"key": [` line.
    """
    import re

    # Two-pass approach:
    #   1. Find every multi-line array of bare double-quoted strings.
    #   2. Only collapse the match if the character that begins the line
    #      preceding the opening `[` is itself a `[` or `,` after a `]` —
    #      i.e. we're inside an outer list. Otherwise we'd flatten arbitrary
    #      object-value string lists.
    pattern = re.compile(
        r'(?P<lead>(?:^|\n)[ \t]*)'             # leading whitespace on line
        r'\[\s*\n'                              # opening [\n
        r'(?P<body>(?:[ \t]+"[^"\n]*",?\s*\n)+) ' # rows  (\n preserved)
        r'[ \t]*\]'                              # closing ]
        , re.MULTILINE
    )
    # Note: the trailing space after the body group is intentional — relaxes
    # below isn't quite right. Use a simpler version:
    pattern = re.compile(
        r'\[\s*\n'                              # opening [\n
        r'(?P<body>(?:[ \t]+"[^"\n]*",?\s*\n)+)' # rows
        r'[ \t]*\]'                              # closing ]
    )

    def _replace(match: 're.Match[str]') -> str:
        start = match.start()
        # Look backwards on the source text for the last non-whitespace
        # character before our match. If it's `[` or `,` we're inside an outer
        # list (i.e. this is a 2D-array row) and should collapse. If it's `:`
        # we're the value of a key — leave alone so e.g. learning_objectives
        # keeps its multi-line shape.
        i = start - 1
        while i >= 0 and text[i] in ' \t\n':
            i -= 1
        if i < 0 or text[i] not in '[,':
            return match.group(0)
        body = match.group('body')
        items = re.findall(r'"([^"\n]*)"', body)
        return '[' + ','.join(f'"{x}"' for x in items) + ']'

    return pattern.sub(_replace, text)


# ---------------------------------------------------------------------------
# Commands


def cmd_suggest(artifact: str) -> int:
    """Print gallery → sequences → maps → suggested empty cells."""
    try:
        artifact_dir, meta = _load_artifact_meta(artifact)
    except (FileNotFoundError, ValueError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 2

    gallery = meta.get("gallery", "<unknown>")
    print(f"Artifact: {artifact}")
    print(f"  Source gallery: {gallery}")
    print(f"  lookup_name:    {_resolve_lookup_name(artifact_dir, meta)}")

    # First-class artifacts (workbenches) carry their target sequence in
    # meta._target_sequence (synthesized from the registry). Use that directly
    # if present; otherwise fall back to GALLERY_SEQUENCES.
    candidate_seqs: list[str] = []
    target_seq = meta.get("_target_sequence")
    if target_seq:
        candidate_seqs = [target_seq]
    else:
        candidate_seqs = GALLERY_SEQUENCES.get(gallery, [])
    if not candidate_seqs:
        print(f"  (no sequence mapping registered for gallery {gallery!r})")
        return 0

    # Filter to sequence ids that actually exist on disk.
    existing_seqs = [s for s in candidate_seqs
                     if (SEQ_DIR / f"{s}.json").is_file()]
    missing_seqs = [s for s in candidate_seqs if s not in existing_seqs]
    print(f"  Natural home sequence(s): {existing_seqs or '(none on disk)'}")
    if missing_seqs:
        print(f"    (skipped — not on disk: {missing_seqs})")

    suggestions: list[tuple[str, str, list[tuple[int, int]]]] = []
    for seq_id in existing_seqs:
        maps = _sequence_maps(seq_id)
        for m in maps:
            empties = _find_empty_cells(m, limit=3)
            if empties:
                suggestions.append((seq_id, m, empties))

    if not suggestions:
        print("  No maps with empty interactable cells found.")
        return 0

    print()
    print("Suggested placements (up to 3 empty cells per map):")
    for seq_id, map_name, empties in suggestions[:15]:
        cells = ", ".join(f"({c},{r})" for c, r in empties)
        print(f"  [{seq_id}] {map_name}  empty cells: {cells}")
    if len(suggestions) > 15:
        print(f"  ... and {len(suggestions) - 15} more maps with empty cells")
    return 0


def cmd_integrate(artifact: str, map_name: str, col: int, row: int,
                  dry_run: bool) -> int:
    """Place artifact into map at (col, row). Returns CLI exit code."""
    try:
        artifact_dir, meta = _load_artifact_meta(artifact)
        map_path, map_data, raw_text = _load_map(map_name)
        structure, _, interactables = _layers(map_data)
        _validate_cell(structure, interactables, col, row)
    except (FileNotFoundError, ValueError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 2

    lookup = _resolve_lookup_name(artifact_dir, meta)
    new_token = f"{lookup}:0:0"

    if dry_run:
        print(f"[dry-run] would place {new_token!r} at "
              f"{map_name}[col={col}, row={row}]")
        print(f"  artifact dir:    {artifact_dir.relative_to(ROOT)}")
        print(f"  source gallery:  {meta.get('gallery')}")
        print(f"  map file:        {map_path.relative_to(ROOT)}")
        print(f"  cell before:     {interactables[row][col]!r}")
        print(f"  cell after:      {new_token!r}")
        return 0

    # Mutate the layer (data is a fresh dict from json.loads, so this is local).
    interactables[row][col] = new_token

    # Bump artifact count metadata if the map tracks it (best-effort, safe).
    metadata = map_data.get("map_info", {}).get("metadata", {})
    if isinstance(metadata, dict) and isinstance(metadata.get("n_artifacts"), int):
        metadata["n_artifacts"] = metadata["n_artifacts"] + 1

    _write_map_preserving_format(map_path, map_data, raw_text)

    print(f"placed {lookup} at {map_name}[{col},{row}] "
          f"— interactables layer updated")
    print(f"  wrote: {map_path.relative_to(ROOT)}")
    return 0


# ---------------------------------------------------------------------------
# CLI plumbing


def _parse_cell(s: str) -> tuple[int, int]:
    parts = s.split(",")
    if len(parts) != 2:
        raise argparse.ArgumentTypeError(
            f"--cell must look like COL,ROW (got {s!r})"
        )
    try:
        return int(parts[0]), int(parts[1])
    except ValueError as e:
        raise argparse.ArgumentTypeError(f"--cell must be two integers: {e}") from e


def main(argv: Iterable[str] | None = None) -> int:
    p = argparse.ArgumentParser(
        description="Integrate a promoted DNA artifact into a curriculum map.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    p.add_argument("--artifact", required=True,
                   help="Promoted artifact directory name "
                        "(e.g. parametric-mesh-gallery__cylinder_r16)")
    p.add_argument("--map", dest="map_name", default=None,
                   help="Target map name (directory under commons/maps/)")
    p.add_argument("--cell", default=None, type=_parse_cell,
                   help="Target cell as COL,ROW (e.g. 5,17)")
    p.add_argument("--dry-run", action="store_true",
                   help="Print what would change without writing")
    p.add_argument("--suggest", action="store_true",
                   help="Print candidate maps + empty cells for this artifact")
    args = p.parse_args(list(argv) if argv is not None else None)

    if args.suggest:
        return cmd_suggest(args.artifact)

    if args.map_name is None or args.cell is None:
        print("error: --map and --cell are required unless --suggest is used.\n"
              "       Run with --suggest first to find candidate placements.",
              file=sys.stderr)
        return 2

    col, row = args.cell
    return cmd_integrate(args.artifact, args.map_name, col, row, args.dry_run)


if __name__ == "__main__":
    sys.exit(main())
