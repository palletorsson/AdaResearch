#!/usr/bin/env python3
"""
Spine Map Workbench
-------------------
Utilities for building and maintaining the playable curriculum spine:
- status/audit of spine sequence coverage
- taxonomy spine-status section generation
- artifact suggestions per sequence
- map scaffolding + optional sequence update

Examples:
  python tools/spine_map_workbench.py status
  python tools/spine_map_workbench.py status --report doc/reports/SPINE_MAP_BUILD_STATUS.md --update-taxonomy doc/TAXONOMY.md
  python tools/spine_map_workbench.py suggest --sequence noise --limit 12
  python tools/spine_map_workbench.py audit-artifacts --report doc/reports/ARTIFACT_REGISTRY_AUDIT.md --json doc/reports/ARTIFACT_REGISTRY_AUDIT.json
  python tools/spine_map_workbench.py scaffold --sequence noise --map Noise_New_01 --auto-artifacts 3 --update-sequence
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SPINE_PATH = ROOT / "commons/maps/curriculum_spine.json"
SEQUENCE_DIR = ROOT / "commons/maps/sequences"
MAP_PROGRESSION_PATH = ROOT / "commons/maps/map_progression.json"
ARTIFACT_REGISTRY_DIR = ROOT / "commons/artifacts/registry"
ARTIFACT_BASE_REGISTRY_PATH = ROOT / "commons/artifacts/grid_artifacts.json"
MAPS_DIR = ROOT / "commons/maps"

TAXONOMY_MARKER_START = "<!-- SPINE_PLAYABLE_STATUS:START -->"
TAXONOMY_MARKER_END = "<!-- SPINE_PLAYABLE_STATUS:END -->"


def _to_bool(value: Any, default: bool) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return value != 0
    if isinstance(value, str):
        text = value.strip().lower()
        if text in {"1", "true", "yes", "y", "on"}:
            return True
        if text in {"0", "false", "no", "n", "off"}:
            return False
    return default


def _normalize_scene_path(scene_path: str) -> str:
    normalized = scene_path.strip()
    if not normalized:
        return ""
    if normalized.startswith("res://"):
        return normalized
    if normalized.startswith(("commons/", "algorithms/", "tools/")):
        return "res://" + normalized.lstrip("/")
    return normalized


def _resolve_res_path(scene_path: str) -> Path | None:
    if not scene_path.startswith("res://"):
        return None
    return ROOT / scene_path[len("res://") :]


def _common_prefix_len(a: str, b: str) -> int:
    i = 0
    while i < len(a) and i < len(b) and a[i] == b[i]:
        i += 1
    return i


def _norm_key(text: str) -> str:
    return "".join(ch for ch in text.lower() if ch.isalnum())


def _metadata_relation_score(sequence_id: str, candidate: str) -> int:
    seq_norm = _norm_key(sequence_id)
    cand_norm = _norm_key(candidate)
    if not seq_norm or not cand_norm:
        return 0
    if seq_norm == cand_norm:
        return 12
    if len(seq_norm) >= 5 and seq_norm in cand_norm:
        return 8
    if len(cand_norm) >= 5 and cand_norm in seq_norm:
        return 8
    if _common_prefix_len(seq_norm, cand_norm) >= 8:
        return 6
    return 0


def read_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        raise RuntimeError(f"Failed to parse JSON: {path.as_posix()} ({exc})") from exc


def write_json(path: Path, data: Any) -> None:
    path.write_text(
        json.dumps(data, indent="\t", ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def rel(path: Path) -> str:
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def normalize_map_name(name: str) -> str:
    return re.sub(r"\s+", "_", name.strip())


def tokens(text: str) -> list[str]:
    return [t for t in re.split(r"[^a-z0-9]+", text.lower()) if t]


def load_spine() -> list[dict[str, Any]]:
    data = read_json(SPINE_PATH)
    spine = data.get("spine", {}).get("sequences", [])
    if not isinstance(spine, list):
        raise RuntimeError("curriculum_spine.json does not contain spine.sequences as a list")
    return sorted(
        [item for item in spine if isinstance(item, dict)],
        key=lambda item: int(item.get("order", 9999)),
    )


def load_sequence_catalog() -> tuple[dict[str, dict[str, Any]], dict[str, Path]]:
    catalog: dict[str, dict[str, Any]] = {}
    source: dict[str, Path] = {}

    if MAP_PROGRESSION_PATH.exists():
        progression = read_json(MAP_PROGRESSION_PATH)
        sequences = progression.get("sequences", {})
        if isinstance(sequences, dict):
            for seq_id, seq_def in sequences.items():
                if isinstance(seq_id, str) and isinstance(seq_def, dict):
                    catalog[seq_id] = seq_def
                    source[seq_id] = MAP_PROGRESSION_PATH

    for seq_file in sorted(SEQUENCE_DIR.glob("*.json")):
        data = read_json(seq_file)
        seqs = data.get("sequences")
        if not isinstance(seqs, dict):
            continue
        for seq_id, seq_def in seqs.items():
            if isinstance(seq_id, str) and isinstance(seq_def, dict):
                catalog[seq_id] = seq_def
                source[seq_id] = seq_file

    return catalog, source


def map_has_data(map_name: str) -> bool:
    return (MAPS_DIR / map_name / "map_data.json").exists()


def _artifact_registry_files() -> list[Path]:
    files: list[Path] = []
    if ARTIFACT_BASE_REGISTRY_PATH.exists():
        files.append(ARTIFACT_BASE_REGISTRY_PATH)
    if ARTIFACT_REGISTRY_DIR.exists():
        files.extend(sorted(ARTIFACT_REGISTRY_DIR.glob("*.json")))
    return files


def load_raw_artifact_entries() -> list[dict[str, Any]]:
    """
    Load raw artifact entries from registries for auditing.
    This keeps unresolved or non-placeable entries so we can report on them.
    """
    entries: list[dict[str, Any]] = []
    for registry_file in _artifact_registry_files():
        data = read_json(registry_file)
        registry = data.get("artifacts", {})
        if not isinstance(registry, dict):
            continue

        for key, value in registry.items():
            if key.startswith("_") and isinstance(value, str):
                continue
            if not isinstance(value, dict):
                entries.append(
                    {
                        "lookup_name": str(key),
                        "source_file": registry_file.name,
                        "issue_non_dict": True,
                    }
                )
                continue

            lookup_name = str(value.get("lookup_name", key)).strip()
            if not lookup_name:
                lookup_name = str(key).strip()

            scene_path_raw = str(value.get("scene", ""))
            scene_path = _normalize_scene_path(scene_path_raw)
            resolved_scene = _resolve_res_path(scene_path) if scene_path else None
            scene_exists = bool(resolved_scene and resolved_scene.exists())

            include_in_maps_raw = value.get(
                "include_in_map_data",
                value.get("map_include", value.get("include_in_maps", None)),
            )
            map_ready_raw = value.get("map_ready", value.get("ready_for_maps", None))
            has_map_sequences_field = ("map_sequences" in value) or ("sequence_targets" in value)
            map_sequences_raw = value.get("map_sequences", value.get("sequence_targets", []))

            map_sequences: list[str] = []
            if isinstance(map_sequences_raw, list):
                map_sequences = [str(s).strip() for s in map_sequences_raw if isinstance(s, str) and str(s).strip()]

            artifact_type = str(value.get("artifact_type", "")).strip().lower()
            source_domain = ""
            if scene_path.startswith("res://algorithms/"):
                source_domain = "algorithms"
            elif scene_path.startswith("res://commons/"):
                source_domain = "commons"

            entries.append(
                {
                    "lookup_name": lookup_name,
                    "source_key": str(key),
                    "source_file": registry_file.name,
                    "scene_path": scene_path,
                    "scene_exists": scene_exists,
                    "artifact_type": artifact_type,
                    "source_domain": source_domain,
                    "sequence": str(value.get("sequence", "")).strip().lower(),
                    "category": str(value.get("category", "")).strip().lower(),
                    "dev_category": str(value.get("dev_category", "")).strip().lower(),
                    "tags": [str(tag).strip().lower() for tag in value.get("tags", []) if isinstance(tag, str)],
                    "include_in_maps_raw": include_in_maps_raw,
                    "include_in_maps": _to_bool(include_in_maps_raw, True),
                    "has_include_in_maps_field": include_in_maps_raw is not None,
                    "map_ready_raw": map_ready_raw,
                    "map_ready": _to_bool(map_ready_raw, True),
                    "has_map_ready_field": map_ready_raw is not None,
                    "map_sequences": map_sequences,
                    "has_map_sequences_field": has_map_sequences_field and isinstance(map_sequences_raw, list),
                }
            )

    return entries


def load_artifacts() -> list[dict[str, Any]]:
    """
    Load map-placeable artifacts from registry JSON.
    Curated behavior:
    - folder path alone is not enough;
    - sequence suggestions come from registry metadata (sequence/category/dev_category/tags/map_sequences);
    - unresolved scenes are excluded from suggestions.
    """
    artifacts: list[dict[str, Any]] = []

    for registry_file in _artifact_registry_files():
        data = read_json(registry_file)
        registry = data.get("artifacts", {})
        if not isinstance(registry, dict):
            continue

        for key, value in registry.items():
            if key.startswith("_") and isinstance(value, str):
                continue
            if not isinstance(value, dict):
                continue

            lookup_name = str(value.get("lookup_name", key)).strip()
            if not lookup_name:
                continue

            include_in_maps = _to_bool(
                value.get("include_in_map_data", value.get("map_include", value.get("include_in_maps", True))),
                True,
            )
            if not include_in_maps:
                continue

            map_ready = _to_bool(value.get("map_ready", value.get("ready_for_maps", True)), True)
            if not map_ready:
                continue

            artifact_type = str(value.get("artifact_type", "")).strip().lower()
            if artifact_type == "placeholder":
                continue

            scene_path = _normalize_scene_path(str(value.get("scene", "")))
            if not scene_path:
                continue
            if not scene_path.startswith("res://"):
                continue
            if not (
                scene_path.startswith("res://commons/")
                or scene_path.startswith("res://algorithms/")
            ):
                continue

            resolved_scene = _resolve_res_path(scene_path)
            if resolved_scene is None or not resolved_scene.exists():
                # keep unresolved scenes out of auto-suggestions
                continue

            tags = [str(tag).strip().lower() for tag in value.get("tags", []) if isinstance(tag, str)]

            map_sequences_raw = value.get("map_sequences", value.get("sequence_targets", []))
            map_sequences = [str(s).strip().lower() for s in map_sequences_raw if isinstance(s, str)] if isinstance(map_sequences_raw, list) else []

            source_domain = "algorithms" if scene_path.startswith("res://algorithms/") else "commons"

            artifacts.append(
                {
                    "lookup_name": lookup_name,
                    "sequence": str(value.get("sequence", "")).strip().lower(),
                    "category": str(value.get("category", "")).strip().lower(),
                    "dev_category": str(value.get("dev_category", "")).strip().lower(),
                    "tags": tags,
                    "description": str(value.get("description", "")).strip().lower(),
                    "map_sequences": map_sequences,
                    "scene_path": scene_path,
                    "source_domain": source_domain,
                    "source_file": registry_file.name,
                }
            )

    return artifacts


def suggest_artifacts(
    sequence_id: str,
    artifacts: list[dict[str, Any]],
    limit: int = 8,
    loose: bool = False,
) -> list[str]:
    """
    Suggest artifacts for a sequence using curated metadata first.
    By default (`loose=False`), suggestions do NOT use broad description/name matching.
    """
    seq_id = sequence_id.lower().strip()
    seq_tokens = tokens(seq_id)
    scored: dict[str, tuple[int, str]] = {}

    for item in artifacts:
        score = 0
        explicit_match = False

        # Strongest: explicit sequence target lists on artifact metadata.
        for target in item.get("map_sequences", []):
            rel_score = _metadata_relation_score(seq_id, str(target))
            if rel_score > 0:
                score = max(score, 40 + rel_score)
                explicit_match = True

        seq_score = _metadata_relation_score(seq_id, str(item.get("sequence", "")))
        if seq_score > 0:
            score += 24 + seq_score
            explicit_match = True

        category_score = _metadata_relation_score(seq_id, str(item.get("category", "")))
        if category_score > 0:
            score += 16 + category_score
            explicit_match = True

        dev_category_score = _metadata_relation_score(seq_id, str(item.get("dev_category", "")))
        if dev_category_score > 0:
            score += 12 + dev_category_score
            explicit_match = True

        best_tag_score = 0
        for tag in item.get("tags", []):
            best_tag_score = max(best_tag_score, _metadata_relation_score(seq_id, str(tag)))
        if best_tag_score > 0:
            score += 8 + best_tag_score
            explicit_match = True

        # Keep algorithm-domain artifacts curated by explicit metadata.
        if item.get("source_domain") == "algorithms" and not explicit_match:
            continue

        # Optional relaxed mode for brainstorming.
        if loose and score <= 0:
            haystack = " ".join(
                [
                    str(item.get("lookup_name", "")),
                    " ".join([str(t) for t in item.get("tags", [])]),
                    str(item.get("description", "")),
                    str(item.get("category", "")),
                    str(item.get("dev_category", "")),
                ]
            )
            for token in seq_tokens:
                if token and token in haystack:
                    score += 1

        if score <= 0:
            continue

        lookup = str(item.get("lookup_name", "")).strip()
        if not lookup:
            continue
        prev = scored.get(lookup)
        if prev is None or score > prev[0]:
            scored[lookup] = (score, str(item.get("source_file", "")))

    ranked = sorted(scored.items(), key=lambda entry: (-entry[1][0], entry[0]))
    return [name for name, _meta in ranked[:limit]]


def build_spine_rows() -> list[dict[str, Any]]:
    spine = load_spine()
    catalog, source = load_sequence_catalog()
    artifacts = load_artifacts()
    rows: list[dict[str, Any]] = []

    for item in spine:
        seq_id = str(item.get("name", "")).strip()
        seq_def = catalog.get(seq_id, {})
        maps = seq_def.get("maps", []) if isinstance(seq_def, dict) else []
        if not isinstance(maps, list):
            maps = []
        maps = [str(m).strip() for m in maps if isinstance(m, str) and str(m).strip()]

        missing = [m for m in maps if not map_has_data(m)]
        existing_count = len(maps) - len(missing)
        first_map = maps[0] if maps else ""

        rows.append(
            {
                "order": int(item.get("order", 9999)),
                "sequence": seq_id,
                "phase": str(item.get("phase", "")),
                "declared_maps": len(maps),
                "existing_maps": existing_count,
                "missing_count": len(missing),
                "missing_maps": missing,
                "first_map": first_map,
                "source": rel(source.get(seq_id, Path("-"))) if seq_id in source else "-",
                "artifact_suggestions": suggest_artifacts(seq_id, artifacts, limit=4),
            }
        )

    return rows


def render_spine_status_markdown(rows: list[dict[str, Any]]) -> str:
    lines = []
    lines.append("## Playable Spine Path (Live Status)")
    lines.append("")
    lines.append("Generated from `commons/maps/curriculum_spine.json` + sequence JSON files.")
    lines.append("Sequence membership is explicit from each sequence JSON `maps[]`; map-name prefixes are ignored.")
    lines.append("Artifact suggestions are metadata-curated from registry fields (`map_sequences`/`sequence`/`category`/`dev_category`/`tags`).")
    lines.append("")
    lines.append("| # | Sequence | Phase | Declared | Existing | Missing | First Map | Suggested Artifacts |")
    lines.append("|---|---|---|---:|---:|---:|---|---|")

    for row in rows:
        first_map = f"`{row['first_map']}`" if row["first_map"] else "-"
        suggestions = ", ".join([f"`{name}`" for name in row["artifact_suggestions"]]) or "-"
        lines.append(
            f"| {row['order']} | `{row['sequence']}` | `{row['phase']}` | "
            f"{row['declared_maps']} | {row['existing_maps']} | {row['missing_count']} | "
            f"{first_map} | {suggestions} |"
        )

    lines.append("")
    lines.append("Use `python tools/spine_map_workbench.py scaffold --sequence <id> --map <Map_Name> --update-sequence` to add missing spine maps quickly.")
    return "\n".join(lines)


def build_artifact_audit(limit: int = 200) -> dict[str, Any]:
    rows = load_raw_artifact_entries()
    total_entries = len(rows)

    non_dict_entries = [r for r in rows if r.get("issue_non_dict")]
    dict_rows = [r for r in rows if not r.get("issue_non_dict")]

    placeholder_entries = [r for r in dict_rows if r.get("artifact_type") == "placeholder"]
    missing_scene_path = [r for r in dict_rows if not str(r.get("scene_path", "")).strip()]
    unsupported_scene_path = [
        r
        for r in dict_rows
        if str(r.get("scene_path", "")).strip()
        and not str(r.get("scene_path", "")).startswith("res://")
    ]
    disallowed_scene_prefix = [
        r
        for r in dict_rows
        if str(r.get("scene_path", "")).startswith("res://")
        and not (
            str(r.get("scene_path", "")).startswith("res://commons/")
            or str(r.get("scene_path", "")).startswith("res://algorithms/")
        )
    ]
    unresolved_scene_files = [
        r
        for r in dict_rows
        if str(r.get("scene_path", "")).startswith("res://")
        and (
            str(r.get("scene_path", "")).startswith("res://commons/")
            or str(r.get("scene_path", "")).startswith("res://algorithms/")
        )
        and not bool(r.get("scene_exists", False))
    ]

    missing_include_flag = [r for r in dict_rows if not bool(r.get("has_include_in_maps_field", False))]
    missing_map_ready_flag = [r for r in dict_rows if not bool(r.get("has_map_ready_field", False))]
    missing_map_sequences = [r for r in dict_rows if not bool(r.get("has_map_sequences_field", False))]
    empty_map_sequences = [
        r for r in dict_rows if bool(r.get("has_map_sequences_field", False)) and len(r.get("map_sequences", [])) == 0
    ]

    # Algorithm artifacts with no explicit sequence metadata are high-risk for accidental leakage.
    algorithm_without_curation = [
        r
        for r in dict_rows
        if r.get("source_domain") == "algorithms"
        and not str(r.get("sequence", "")).strip()
        and not str(r.get("category", "")).strip()
        and not str(r.get("dev_category", "")).strip()
        and len(r.get("map_sequences", [])) == 0
    ]

    return {
        "summary": {
            "total_entries": total_entries,
            "dict_entries": len(dict_rows),
            "non_dict_entries": len(non_dict_entries),
            "placeholder_entries": len(placeholder_entries),
            "missing_scene_path": len(missing_scene_path),
            "unsupported_scene_path": len(unsupported_scene_path),
            "disallowed_scene_prefix": len(disallowed_scene_prefix),
            "unresolved_scene_files": len(unresolved_scene_files),
            "missing_include_in_map_data": len(missing_include_flag),
            "missing_map_ready": len(missing_map_ready_flag),
            "missing_map_sequences_field": len(missing_map_sequences),
            "empty_map_sequences": len(empty_map_sequences),
            "algorithm_without_curation": len(algorithm_without_curation),
        },
        "samples": {
            "non_dict_entries": non_dict_entries[:limit],
            "placeholder_entries": placeholder_entries[:limit],
            "missing_scene_path": missing_scene_path[:limit],
            "unsupported_scene_path": unsupported_scene_path[:limit],
            "disallowed_scene_prefix": disallowed_scene_prefix[:limit],
            "unresolved_scene_files": unresolved_scene_files[:limit],
            "missing_include_in_map_data": missing_include_flag[:limit],
            "missing_map_ready": missing_map_ready_flag[:limit],
            "missing_map_sequences_field": missing_map_sequences[:limit],
            "empty_map_sequences": empty_map_sequences[:limit],
            "algorithm_without_curation": algorithm_without_curation[:limit],
        },
    }


def render_artifact_audit_markdown(audit: dict[str, Any], sample_limit: int = 20) -> str:
    summary = audit.get("summary", {})
    samples = audit.get("samples", {})

    lines: list[str] = []
    lines.append("## Artifact Registry Audit")
    lines.append("")
    lines.append("Checks unresolved scenes, placeholder-backed entries, and curation metadata coverage.")
    lines.append("")
    lines.append("| Metric | Count |")
    lines.append("|---|---:|")
    for key, value in summary.items():
        lines.append(f"| `{key}` | {int(value)} |")
    lines.append("")

    ordered_sections = [
        "unresolved_scene_files",
        "missing_scene_path",
        "unsupported_scene_path",
        "disallowed_scene_prefix",
        "placeholder_entries",
        "algorithm_without_curation",
        "missing_include_in_map_data",
        "missing_map_ready",
        "missing_map_sequences_field",
        "empty_map_sequences",
    ]

    for section in ordered_sections:
        section_rows = samples.get(section, [])
        if not section_rows:
            continue
        lines.append(f"### {section}")
        lines.append("")
        for row in section_rows[:sample_limit]:
            lookup = str(row.get("lookup_name", ""))
            scene = str(row.get("scene_path", ""))
            source_file = str(row.get("source_file", ""))
            bits = [lookup]
            if scene:
                bits.append(scene)
            if source_file:
                bits.append(source_file)
            lines.append(f"- {' | '.join(bits)}")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def upsert_taxonomy_section(taxonomy_path: Path, section_markdown: str) -> None:
    if not taxonomy_path.exists():
        raise RuntimeError(f"Taxonomy file does not exist: {rel(taxonomy_path)}")

    original = taxonomy_path.read_text(encoding="utf-8")
    block = f"{TAXONOMY_MARKER_START}\n{section_markdown}\n{TAXONOMY_MARKER_END}"
    pattern = re.compile(
        re.escape(TAXONOMY_MARKER_START) + r".*?" + re.escape(TAXONOMY_MARKER_END),
        flags=re.DOTALL,
    )

    if TAXONOMY_MARKER_START in original and TAXONOMY_MARKER_END in original:
        updated = pattern.sub(block, original)
    else:
        marker = "\n---\n"
        idx = original.find(marker)
        if idx == -1:
            updated = original.rstrip() + "\n\n" + block + "\n"
        else:
            insertion_point = idx + len(marker)
            updated = original[:insertion_point] + "\n" + block + "\n" + original[insertion_point:]

    taxonomy_path.write_text(updated, encoding="utf-8")


def append_map_to_sequence(sequence_id: str, map_name: str) -> Path | None:
    catalog, source = load_sequence_catalog()
    if sequence_id not in catalog:
        return None

    source_path = source.get(sequence_id)
    if source_path is None:
        return None

    data = read_json(source_path)
    seqs = data.get("sequences", {})
    if not isinstance(seqs, dict) or sequence_id not in seqs:
        return None

    seq = seqs.get(sequence_id)
    if not isinstance(seq, dict):
        return None

    maps = seq.get("maps")
    if not isinstance(maps, list):
        maps = []
        seq["maps"] = maps

    if map_name not in maps:
        maps.append(map_name)
        write_json(source_path, data)

    return source_path


def make_blank_grid(width: int, depth: int, fill: str = " ") -> list[list[str]]:
    return [[fill for _x in range(width)] for _z in range(depth)]


def make_structure_grid(width: int, depth: int) -> list[list[str]]:
    grid = make_blank_grid(width, depth, "1")
    for z in range(depth):
        for x in range(width):
            if z == 0 or z == depth - 1 or x == 0 or x == width - 1:
                grid[z][x] = "2"
    return grid


def place_default_utilities(utilities: list[list[str]]) -> None:
    depth = len(utilities)
    width = len(utilities[0]) if depth else 0
    if depth >= 2 and width >= 2:
        utilities[1][1] = "s"
    if depth >= 3 and width >= 3:
        utilities[depth - 2][width - 2] = "t"


def place_artifacts(interactables: list[list[str]], artifact_names: list[str]) -> None:
    if not interactables or not artifact_names:
        return
    depth = len(interactables)
    width = len(interactables[0])
    z = max(1, min(depth - 2, depth // 2))
    start_x = max(1, (width - len(artifact_names)) // 2)

    for i, name in enumerate(artifact_names):
        x = start_x + i
        if x >= width - 1:
            break
        token = name if ":" in name else f"{name}:0:1"
        interactables[z][x] = token


def build_scaffold_map_data(
    sequence_id: str,
    map_name: str,
    width: int,
    depth: int,
    max_height: int,
    difficulty: str,
    artifacts: list[str],
) -> dict[str, Any]:
    structure = make_structure_grid(width, depth)
    utilities = make_blank_grid(width, depth, " ")
    interactables = make_blank_grid(width, depth, " ")
    place_default_utilities(utilities)
    place_artifacts(interactables, artifacts)

    objective = f"Prototype map for sequence `{sequence_id}`."
    artifact_bullets = [f"`{a}` near center" for a in artifacts] if artifacts else ["Add sequence artifacts."]

    return {
        "map_info": {
            "name": map_name.replace("_", " "),
            "lookup_name": map_name,
            "description": f"Scaffold map for sequence {sequence_id}.",
            "version": "1.0",
            "format": "json",
            "dimensions": {
                "width": width,
                "depth": depth,
                "max_height": max_height,
            },
            "metadata": {
                "difficulty": difficulty,
                "category": sequence_id,
                "estimated_time": "3-5 minutes",
                "learning_objectives": [
                    objective,
                    "Validate map flow and artifact placement.",
                    "Refine layout for sequence pedagogy.",
                ],
            },
        },
        "documentation": {
            "summary": f"{map_name} scaffold",
            "layout": f"{width}x{depth} test room with spawn and teleporter.",
            "objective": objective,
            "key_elements": artifact_bullets,
        },
        "layers": {
            "structure": structure,
            "utilities": utilities,
            "interactables": interactables,
        },
        "utility_definitions": {
            "t": {
                "type": "teleporter",
                "name": "Next",
                "description": "Continue to next map in sequence.",
                "properties": {"action": "next_in_sequence"},
            },
            "s": {
                "properties": {"height": 5.5},
            },
        },
        "lighting": {
            "ambient_color": [0.4, 0.4, 0.5],
            "ambient_energy": 0.6,
        },
        "settings": {
            "cube_size": 1.0,
            "gutter": 0.0,
            "show_grid": True,
            "enable_physics": True,
        },
    }


def write_scaffold_docs(map_dir: Path, map_name: str, sequence_id: str, force: bool) -> None:
    docs = {
        "blurb.md": (
            f"# {map_name}\n\n"
            f"A scaffold map in `{sequence_id}`. Replace this with the poetic entry point for the concept.\n"
        ),
        "summary.md": (
            f"# {map_name} - Summary\n\n"
            f"Prototype layout for `{sequence_id}`.\n"
            f"Document spatial logic, core interaction loop, and sequence connection here.\n"
        ),
        "technical.md": (
            f"# {map_name} - Technical\n\n"
            f"Implementation notes for `{sequence_id}` map construction, artifacts, and utility flow.\n"
        ),
        "critical.md": (
            f"# {map_name} - Critical\n\n"
            f"Describe what this map normalizes, what it excludes, and what alternative computation it can open.\n"
        ),
    }

    for filename, content in docs.items():
        path = map_dir / filename
        if path.exists() and not force:
            continue
        path.write_text(content, encoding="utf-8")


def cmd_status(args: argparse.Namespace) -> int:
    rows = build_spine_rows()
    markdown = render_spine_status_markdown(rows)
    print(markdown)

    if args.report:
        report_path = (ROOT / args.report).resolve() if not Path(args.report).is_absolute() else Path(args.report)
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(markdown + "\n", encoding="utf-8")
        print(f"\nWrote report: {rel(report_path)}")

    if args.update_taxonomy:
        taxonomy_path = (ROOT / args.update_taxonomy).resolve() if not Path(args.update_taxonomy).is_absolute() else Path(args.update_taxonomy)
        upsert_taxonomy_section(taxonomy_path, markdown)
        print(f"Updated taxonomy section: {rel(taxonomy_path)}")

    return 0


def cmd_suggest(args: argparse.Namespace) -> int:
    artifacts = load_artifacts()
    suggestions = suggest_artifacts(args.sequence, artifacts, limit=args.limit, loose=bool(args.loose))
    if not suggestions:
        print(f"No artifact suggestions found for sequence '{args.sequence}'.")
        return 0

    print(f"Artifact suggestions for '{args.sequence}':")
    for item in suggestions:
        print(f"- {item}")
    return 0


def cmd_audit_artifacts(args: argparse.Namespace) -> int:
    audit = build_artifact_audit(limit=max(1, int(args.limit)))
    markdown = render_artifact_audit_markdown(audit, sample_limit=max(1, int(args.sample_limit)))
    print(markdown)

    if args.report:
        report_path = (ROOT / args.report).resolve() if not Path(args.report).is_absolute() else Path(args.report)
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(markdown, encoding="utf-8")
        print(f"Wrote report: {rel(report_path)}")

    if args.json:
        json_path = (ROOT / args.json).resolve() if not Path(args.json).is_absolute() else Path(args.json)
        json_path.parent.mkdir(parents=True, exist_ok=True)
        json_path.write_text(json.dumps(audit, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"Wrote JSON: {rel(json_path)}")

    return 0


def cmd_scaffold(args: argparse.Namespace) -> int:
    sequence_id = args.sequence.strip()
    map_name = normalize_map_name(args.map)
    map_dir = MAPS_DIR / map_name
    map_data_path = map_dir / "map_data.json"

    if map_data_path.exists() and not args.force:
        print(f"Map already exists: {rel(map_data_path)} (use --force to overwrite)")
        return 2

    artifacts = []
    if args.artifacts:
        artifacts = [a.strip() for a in args.artifacts.split(",") if a.strip()]
    elif args.auto_artifacts > 0:
        artifacts = suggest_artifacts(
            sequence_id,
            load_artifacts(),
            limit=args.auto_artifacts,
            loose=bool(args.loose_auto_artifacts),
        )

    map_data = build_scaffold_map_data(
        sequence_id=sequence_id,
        map_name=map_name,
        width=args.width,
        depth=args.depth,
        max_height=args.max_height,
        difficulty=args.difficulty,
        artifacts=artifacts,
    )

    map_dir.mkdir(parents=True, exist_ok=True)
    write_json(map_data_path, map_data)
    write_scaffold_docs(map_dir, map_name, sequence_id, force=args.force)
    print(f"Wrote map scaffold: {rel(map_data_path)}")

    if args.update_sequence:
        source_path = append_map_to_sequence(sequence_id, map_name)
        if source_path is None:
            print(f"Could not update sequence '{sequence_id}' automatically (not found in sequence catalogs).")
            return 3
        print(f"Updated sequence maps in: {rel(source_path)}")

    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Spine map building utilities")
    sub = parser.add_subparsers(dest="command", required=True)

    p_status = sub.add_parser("status", help="Audit playable spine coverage")
    p_status.add_argument("--report", default="", help="Optional markdown output path (e.g. doc/reports/SPINE_MAP_BUILD_STATUS.md)")
    p_status.add_argument("--update-taxonomy", default="", help="Update taxonomy marker section in this file (e.g. doc/TAXONOMY.md)")
    p_status.set_defaults(func=cmd_status)

    p_suggest = sub.add_parser("suggest", help="Suggest artifacts for a sequence")
    p_suggest.add_argument("--sequence", required=True, help="Sequence id")
    p_suggest.add_argument("--limit", type=int, default=12, help="Max suggestions")
    p_suggest.add_argument(
        "--loose",
        action="store_true",
        help="Enable relaxed matching (uses lookup/description token hints).",
    )
    p_suggest.set_defaults(func=cmd_suggest)

    p_audit_artifacts = sub.add_parser("audit-artifacts", help="Audit artifact registry quality and curation metadata")
    p_audit_artifacts.add_argument("--limit", type=int, default=200, help="Max rows to keep per issue class in JSON data")
    p_audit_artifacts.add_argument("--sample-limit", type=int, default=20, help="Max rows shown per section in markdown output")
    p_audit_artifacts.add_argument("--report", default="", help="Optional markdown report path")
    p_audit_artifacts.add_argument("--json", default="", help="Optional JSON output path")
    p_audit_artifacts.set_defaults(func=cmd_audit_artifacts)

    p_scaffold = sub.add_parser("scaffold", help="Create a new scaffold map and optional sequence entry")
    p_scaffold.add_argument("--sequence", required=True, help="Sequence id")
    p_scaffold.add_argument("--map", required=True, help="Map folder name (lookup_name)")
    p_scaffold.add_argument("--width", type=int, default=7, help="Grid width")
    p_scaffold.add_argument("--depth", type=int, default=9, help="Grid depth")
    p_scaffold.add_argument("--max-height", type=int, default=3, help="Max block height")
    p_scaffold.add_argument("--difficulty", default="beginner", help="Difficulty metadata")
    p_scaffold.add_argument("--artifacts", default="", help="Comma-separated artifact lookup names")
    p_scaffold.add_argument("--auto-artifacts", type=int, default=0, help="Auto-suggest N artifacts")
    p_scaffold.add_argument(
        "--loose-auto-artifacts",
        action="store_true",
        help="Use relaxed matching when auto-suggesting artifacts.",
    )
    p_scaffold.add_argument("--update-sequence", action="store_true", help="Append new map to sequence maps[]")
    p_scaffold.add_argument("--force", action="store_true", help="Overwrite map_data/docs if they exist")
    p_scaffold.set_defaults(func=cmd_scaffold)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        return int(args.func(args))
    except RuntimeError as exc:
        print(f"ERROR: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
