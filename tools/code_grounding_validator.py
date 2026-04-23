#!/usr/bin/env python
"""
code_grounding_validator.py — verify tutorial/technical code blocks cite real GDScript.

The missing feedback signal for text generation. Text generators will happily
invent plausible-sounding function names that compile in the reader's head
but break at paste-and-run. This validator parses every fenced ``gdscript``
block in a map's text, extracts referenced identifiers, and classifies each
one as:

    LOCAL         — declared in this block or an earlier block
    ARTIFACT      — exists in a .gd of an artifact listed in map_data.json
    BUILTIN       — Godot built-in (Node3D, Vector3, TAU, randi, etc.)
    KEYWORD       — GDScript keyword (for, if, func, return, ...)
    UNKNOWN       — not found anywhere; probable hallucination

Output: per-block grounding ratio = resolved / (resolved + unknown), plus
the list of unknowns for investigation.

Usage::

    python tools/code_grounding_validator.py --map Array_Patterns --file tutorial.md
    python tools/code_grounding_validator.py --map Array_Patterns
    python tools/code_grounding_validator.py --path commons/maps/Array_Patterns/tutorial.md
    python tools/code_grounding_validator.py --spine --file tutorial.md
    python tools/code_grounding_validator.py --spine --format json > doc/code_grounding_baseline.json
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
MAPS = REPO / "commons" / "maps"
REGISTRY = REPO / "commons" / "artifacts" / "registry"
SPINE_FILE = MAPS / "curriculum_spine.json"
SEQUENCES_DIR = MAPS / "sequences"

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

# ── Identifier classification vocabulary ─────────────────────────────────

GDSCRIPT_KEYWORDS = {
    "and", "as", "assert", "await", "break", "breakpoint", "class",
    "class_name", "const", "continue", "elif", "else", "enum", "export",
    "extends", "for", "func", "if", "in", "is", "match", "not", "null",
    "or", "pass", "return", "self", "signal", "static", "super", "true",
    "false", "var", "void", "while", "yield", "print", "printerr",
    "printt", "prints", "printraw", "preload", "load",
    # Built-in primitive types
    "int", "bool", "float", "String",
}

# Subset — expand as needed. Types and common globals Godot provides.
GODOT_BUILTINS = {
    # Types
    "Object", "Node", "Node2D", "Node3D", "Control", "CanvasItem",
    "Viewport", "Window", "Resource", "PackedScene", "Script",
    "Vector2", "Vector2i", "Vector3", "Vector3i", "Vector4", "Vector4i",
    "Color", "Rect2", "Rect2i", "Transform2D", "Transform3D", "Basis",
    "Quaternion", "Plane", "AABB", "Projection", "Callable", "Signal",
    "StringName", "NodePath", "RID", "Variant",
    "Array", "Dictionary",
    "PackedByteArray", "PackedInt32Array", "PackedInt64Array",
    "PackedFloat32Array", "PackedFloat64Array", "PackedStringArray",
    "PackedVector2Array", "PackedVector3Array", "PackedColorArray",
    # 3D / mesh / surface
    "MeshInstance3D", "Mesh", "ArrayMesh", "SurfaceTool", "BoxMesh",
    "SphereMesh", "CylinderMesh", "PlaneMesh", "PrimitiveMesh",
    "ImmediateMesh", "MultiMesh", "MultiMeshInstance3D",
    "Camera3D", "DirectionalLight3D", "OmniLight3D", "SpotLight3D",
    "Environment", "WorldEnvironment", "Curve3D", "Path3D", "Skeleton3D",
    "CollisionShape3D", "CollisionShape2D", "RigidBody3D", "StaticBody3D",
    "CharacterBody3D", "Area3D", "RayCast3D",
    # Materials
    "StandardMaterial3D", "ShaderMaterial", "Material", "BaseMaterial3D",
    "ORMMaterial3D", "Shader",
    # Resources / IO
    "FileAccess", "DirAccess", "ResourceLoader", "ResourceSaver",
    "Image", "ImageTexture", "Texture2D", "Texture3D", "CompressedTexture2D",
    "JSON", "XMLParser", "ConfigFile",
    # Math / noise
    "FastNoiseLite", "Noise", "Curve", "Gradient",
    "Time", "Engine", "OS", "ProjectSettings", "Input", "DisplayServer",
    "RenderingServer", "PhysicsServer3D", "AudioServer",
    # Containers
    "Timer", "Tween", "Label", "Label3D", "Button", "HBoxContainer",
    "VBoxContainer", "GridContainer",
    # UI events
    "InputEvent", "InputEventKey", "InputEventMouseButton",
    "InputEventMouseMotion", "InputEventJoypadButton",
    # Refs
    "Ref", "WeakRef", "RefCounted",
    # Functions
    "abs", "absf", "absi", "acos", "asin", "atan", "atan2", "ceil",
    "ceili", "clamp", "clampf", "clampi", "cos", "cosh", "deg_to_rad",
    "rad_to_deg", "exp", "floor", "floori", "fmod", "fposmod", "lerp",
    "log", "max", "maxf", "maxi", "min", "minf", "mini", "pow", "round",
    "roundi", "sign", "signf", "signi", "sin", "sinh", "sqrt", "tan",
    "tanh", "wrapf", "wrapi", "snapped", "snappedf", "snappedi",
    "randf", "randi", "randf_range", "randi_range", "randfn", "randomize",
    "seed", "rand_from_seed", "randf_in_range",
    "str", "str_to_var", "var_to_str", "typeof", "hash", "instance_from_id",
    "is_instance_valid", "is_instance_of", "is_same", "is_equal_approx",
    "is_zero_approx", "is_nan", "is_inf", "is_finite",
    "range", "size", "len", "push_error", "push_warning", "assert",
    "get_node", "get_node_or_null", "has_node", "add_child",
    "remove_child", "queue_free", "free", "duplicate",
    # Common script methods
    "_ready", "_process", "_physics_process", "_input", "_unhandled_input",
    "_draw", "_enter_tree", "_exit_tree", "_init", "_notification",
    # Enums-ish constants
    "PI", "TAU", "INF", "NAN", "true", "false", "null",
    # Additional math helpers commonly used
    "lerpf", "lerpi", "posmod", "remap", "move_toward", "rotate_toward",
    "smoothstep", "ease", "linear_to_db", "db_to_linear",
    "bytes_to_var", "var_to_bytes",
    "push_back", "push_front",
    # RNG
    "RandomNumberGenerator", "rand", "randbytes",
    # Node common properties (frequently used as free identifiers in
    # snippets — harder to tell if they are @onready, self.X, etc. —
    # so we accept them as builtins to reduce false positives)
    "position", "global_position", "rotation", "global_rotation",
    "scale", "transform", "global_transform", "visible", "modulate",
    "material_override", "mesh", "shape", "texture", "name", "owner",
    "is_inside_tree", "set_physics_process", "set_process",
    # Common coroutine-style idioms
    "get_tree", "get_viewport", "get_window", "get_parent", "get_children",
    "create_tween", "interpolate_property", "interpolate_value",
    "tween_property", "tween_method", "tween_callback", "tween_interval",

    # Thread / Dictionary methods (subset)
    "new", "get", "set", "erase", "keys", "values", "has", "clear",
    "append", "append_array", "pop_back", "pop_front", "push_back",
    "push_front", "resize", "sort", "shuffle", "slice", "find",
    "back", "front", "is_empty",
    "distance_to", "distance_squared_to", "normalized", "length",
    "length_squared", "cross", "dot", "rotated", "to_global", "to_local",
    "look_at", "look_at_from_position", "basis", "origin", "x", "y",
    "z", "r", "g", "b", "a",
    "connect", "disconnect", "emit", "emit_signal",
    # Resource loading directives
    "res", "user",
}

# Regex for GDScript identifiers
IDENT_RE = re.compile(r"\b([A-Za-z_][A-Za-z0-9_]*)\b")
FENCE_RE = re.compile(r"```(\w*)\n(.*?)```", re.DOTALL)

# Declaration patterns inside a code block
DECL_PATTERNS = {
    "export": re.compile(r"@export\s+var\s+([A-Za-z_][A-Za-z0-9_]*)"),
    "var": re.compile(r"(?:^|\n)\s*var\s+([A-Za-z_][A-Za-z0-9_]*)"),
    "const": re.compile(r"(?:^|\n)\s*const\s+([A-Za-z_][A-Za-z0-9_]*)"),
    "func": re.compile(r"(?:^|\n)\s*(?:static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)"),
    "class": re.compile(r"(?:^|\n)\s*class(?:_name)?\s+([A-Za-z_][A-Za-z0-9_]*)"),
    "signal": re.compile(r"(?:^|\n)\s*signal\s+([A-Za-z_][A-Za-z0-9_]*)"),
    "enum": re.compile(r"(?:^|\n)\s*enum\s+([A-Za-z_][A-Za-z0-9_]*)"),
    "param": re.compile(r"func\s+\w+\s*\(([^)]*)\)"),
    # `for i in range(10):` → `i` is declared by the for-in statement
    "for_var": re.compile(r"(?:^|\n)\s*for\s+([A-Za-z_][A-Za-z0-9_]*)(?:\s*:\s*[A-Za-z_][A-Za-z0-9_]*)?\s+in\b"),
}


# ── Registry + artifact source extraction ───────────────────────────────

_registry_cache: dict[str, dict[str, Any]] | None = None
_global_classname_cache: set[str] | None = None


def load_global_classnames() -> set[str]:
    """Scan the repo for every `class_name X` declaration. These are
    globally accessible GDScript identifiers regardless of which artifact
    lists them.

    Cached — scans the whole repo once per process (~1-2s)."""
    global _global_classname_cache
    if _global_classname_cache is not None:
        return _global_classname_cache
    out: set[str] = set()
    cname_re = re.compile(r"^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)", re.M)
    # Search GDScript sources in the main code dirs; skip node_modules, .git, etc.
    roots = [REPO / "algorithms", REPO / "commons", REPO / "addons"]
    for root in roots:
        if not root.exists():
            continue
        for p in root.rglob("*.gd"):
            try:
                for m in cname_re.finditer(p.read_text(encoding="utf-8", errors="replace")):
                    out.add(m.group(1))
            except Exception:
                continue
    _global_classname_cache = out
    return out


def load_registry() -> dict[str, dict[str, Any]]:
    """Return { lookup_name → artifact_meta } across all registry JSONs."""
    global _registry_cache
    if _registry_cache is not None:
        return _registry_cache
    out: dict[str, dict[str, Any]] = {}
    for p in REGISTRY.glob("*.json"):
        try:
            data = json.loads(p.read_text(encoding="utf-8"))
        except Exception:
            continue
        arts = data.get("artifacts", data)
        if not isinstance(arts, dict):
            continue
        for name, meta in arts.items():
            if not isinstance(meta, dict):
                continue
            key = meta.get("lookup_name") or name
            out[key] = meta
    _registry_cache = out
    return out


def resolve_gd_path(artifact_meta: dict[str, Any]) -> Path | None:
    """Given registry metadata, find the artifact's .gd source."""
    scene = artifact_meta.get("scene") or artifact_meta.get("tscn")
    if not scene:
        return None
    # Strip res:// prefix
    if scene.startswith("res://"):
        scene = scene[len("res://"):]
    scene_path = REPO / scene
    # Try sibling .gd with same basename
    gd_path = scene_path.with_suffix(".gd")
    if gd_path.exists():
        return gd_path
    # Try same folder, any .gd
    parent = scene_path.parent
    if parent.exists():
        # Prefer a .gd with the same stem
        for candidate in [parent / f"{scene_path.stem}.gd"]:
            if candidate.exists():
                return candidate
    # Some artifacts declare `script` directly
    script = artifact_meta.get("script")
    if script:
        if script.startswith("res://"):
            script = script[len("res://"):]
        p = REPO / script
        if p.exists():
            return p
    return None


def parse_gd_symbols(gd_path: Path) -> dict[str, set[str]]:
    """Parse a .gd file for declared symbols. Return sets by kind."""
    out: dict[str, set[str]] = {
        "funcs": set(),
        "vars": set(),
        "exports": set(),
        "consts": set(),
        "signals": set(),
        "classes": set(),
        "enums": set(),
    }
    try:
        src = gd_path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return out
    key_map = {
        "func": "funcs", "var": "vars", "export": "exports",
        "const": "consts", "signal": "signals",
        "class": "classes", "enum": "enums",
    }
    for name, pattern in DECL_PATTERNS.items():
        if name not in key_map:
            continue  # skip param, for_var — only relevant inside code blocks
        for m in pattern.finditer(src):
            out[key_map[name]].add(m.group(1))
    return out


# ── Map-level context ───────────────────────────────────────────────────

def load_map_artifacts(map_name: str) -> list[str]:
    """Return unique artifact lookup names used in the map."""
    p = MAPS / map_name / "map_data.json"
    if not p.exists():
        return []
    try:
        d = json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return []
    layers = d.get("layers", {})
    inter = layers.get("interactables", [])
    arts: set[str] = set()

    def walk(obj: Any) -> None:
        if isinstance(obj, str):
            s = obj.strip()
            if s and s != "empty" and s != " ":
                arts.add(s.split(":")[0])
        elif isinstance(obj, list):
            for it in obj:
                walk(it)
        elif isinstance(obj, dict):
            for v in obj.values():
                walk(v)

    walk(inter)
    return sorted(arts)


def build_artifact_vocab(map_name: str) -> dict[str, Any]:
    """Union of all symbols declared in the map's artifacts, plus per-artifact."""
    registry = load_registry()
    artifacts = load_map_artifacts(map_name)
    union: set[str] = set()
    per_artifact: dict[str, dict[str, list[str]]] = {}
    resolved: list[str] = []
    unresolved: list[str] = []
    for art_name in artifacts:
        meta = registry.get(art_name)
        if not meta:
            unresolved.append(art_name)
            continue
        gd_path = resolve_gd_path(meta)
        if not gd_path:
            unresolved.append(art_name)
            continue
        syms = parse_gd_symbols(gd_path)
        resolved.append(art_name)
        per_artifact[art_name] = {k: sorted(v) for k, v in syms.items()}
        for kind in ("funcs", "vars", "exports", "consts", "signals",
                     "classes", "enums"):
            union |= syms[kind]
    return {
        "artifacts_total": len(artifacts),
        "artifacts_resolved": resolved,
        "artifacts_unresolved": unresolved,
        "union_symbols": union,
        "per_artifact": per_artifact,
    }


# ── Code-block parser ───────────────────────────────────────────────────

def extract_gdscript_blocks(text: str) -> list[str]:
    return [body for lang, body in FENCE_RE.findall(text)
            if lang.lower() in ("gdscript", "gd", "")]


def extract_declarations(block: str) -> set[str]:
    """Identifiers declared WITHIN a code block (and therefore local).
    Covers var/const/func/class/signal/enum/@export, function params, and
    for-in loop variables."""
    local: set[str] = set()
    for name, pattern in DECL_PATTERNS.items():
        if name == "param":
            for m in pattern.finditer(block):
                params = m.group(1)
                for part in params.split(","):
                    ident = part.strip().split(":")[0].split("=")[0].strip()
                    if ident and IDENT_RE.fullmatch(ident):
                        local.add(ident)
        else:
            for m in pattern.finditer(block):
                local.add(m.group(1))
    # Multi-var unpacking not handled — rare in GDScript
    return local


def strip_strings_and_comments(src: str) -> str:
    """Remove quoted strings and # comments so we don't count identifiers in them."""
    # Remove triple-quoted strings (rare in gdscript but possible)
    src = re.sub(r'"""[\s\S]*?"""', "", src)
    src = re.sub(r"'''[\s\S]*?'''", "", src)
    # Double and single quoted strings on one line
    src = re.sub(r'"(?:\\.|[^"\\])*"', "", src)
    src = re.sub(r"'(?:\\.|[^'\\])*'", "", src)
    # Comments
    src = re.sub(r"#[^\n]*", "", src)
    return src


def extract_references(block: str) -> list[str]:
    """Non-keyword identifiers referenced in a block, excluding property
    access (anything after a `.`). Only the left-most identifier in a dotted
    chain is counted — `WallpaperGroups.Group.P4M` yields just
    `WallpaperGroups`, since `Group` and `P4M` are member accesses we can't
    verify without tracing types."""
    clean = strip_strings_and_comments(block)
    # Walk the stream; skip any identifier immediately preceded by `.`
    refs: list[str] = []
    for m in IDENT_RE.finditer(clean):
        start = m.start()
        # Look back one char for a dot
        if start > 0 and clean[start - 1] == ".":
            continue
        ident = m.group(1)
        if ident not in GDSCRIPT_KEYWORDS:
            refs.append(ident)
    return refs


# ── Main scoring ────────────────────────────────────────────────────────

def classify_reference(
    ident: str,
    local: set[str],
    artifact_union: set[str],
    declared_so_far: set[str],
    global_classnames: set[str],
) -> str:
    if ident in declared_so_far:
        return "LOCAL"
    if ident in local:
        return "LOCAL"
    if ident in GODOT_BUILTINS:
        return "BUILTIN"
    if ident in artifact_union:
        return "ARTIFACT"
    if ident in global_classnames:
        return "CLASSNAME"
    return "UNKNOWN"


def score_text(text: str, map_name: str) -> dict[str, Any]:
    blocks = extract_gdscript_blocks(text)
    vocab = build_artifact_vocab(map_name)
    artifact_union: set[str] = vocab["union_symbols"]
    global_classnames = load_global_classnames()

    declared_so_far: set[str] = set()
    per_block: list[dict[str, Any]] = []
    totals = {"LOCAL": 0, "ARTIFACT": 0, "BUILTIN": 0,
              "CLASSNAME": 0, "UNKNOWN": 0}
    unknown_idents: dict[str, int] = {}

    for i, block in enumerate(blocks):
        local = extract_declarations(block)
        refs = extract_references(block)
        block_counts = {"LOCAL": 0, "ARTIFACT": 0, "BUILTIN": 0,
                        "CLASSNAME": 0, "UNKNOWN": 0}
        block_unknowns: list[str] = []
        seen: set[str] = set()
        for r in refs:
            if r in seen:
                continue
            seen.add(r)
            cat = classify_reference(
                r, local, artifact_union, declared_so_far, global_classnames
            )
            block_counts[cat] += 1
            totals[cat] += 1
            if cat == "UNKNOWN":
                block_unknowns.append(r)
                unknown_idents[r] = unknown_idents.get(r, 0) + 1
        # grounding: fraction of non-local refs that resolve anywhere real
        external = (block_counts["ARTIFACT"] + block_counts["BUILTIN"]
                    + block_counts["CLASSNAME"] + block_counts["UNKNOWN"])
        resolved_external = (block_counts["ARTIFACT"] + block_counts["BUILTIN"]
                             + block_counts["CLASSNAME"])
        ground = resolved_external / external if external else 1.0
        per_block.append({
            "block_index": i,
            "lines": len(block.splitlines()),
            "counts": block_counts,
            "unknowns": sorted(set(block_unknowns)),
            "grounding_ratio": round(ground, 3),
        })
        declared_so_far |= local

    total_external = (totals["ARTIFACT"] + totals["BUILTIN"]
                      + totals["CLASSNAME"] + totals["UNKNOWN"])
    overall_ground = ((totals["ARTIFACT"] + totals["BUILTIN"]
                       + totals["CLASSNAME"]) / total_external
                      if total_external else 1.0)

    return {
        "map": map_name,
        "artifacts": vocab["artifacts_resolved"],
        "artifacts_unresolved": vocab["artifacts_unresolved"],
        "artifact_symbol_count": len(artifact_union),
        "blocks": len(blocks),
        "totals": totals,
        "overall_grounding_ratio": round(overall_ground, 3),
        "unknown_identifiers": dict(sorted(unknown_idents.items(),
                                           key=lambda kv: -kv[1])[:30]),
        "per_block": per_block,
    }


# ── Spine walker ────────────────────────────────────────────────────────

def load_spine_map_names() -> list[str]:
    if not SPINE_FILE.exists():
        return []
    spine = json.loads(SPINE_FILE.read_text(encoding="utf-8"))
    names: list[str] = []
    for seq in spine.get("spine", {}).get("sequences", []):
        seq_id = seq.get("name") or seq.get("id")
        if not seq_id:
            continue
        seq_path = SEQUENCES_DIR / f"{seq_id}.json"
        if not seq_path.exists():
            continue
        try:
            data = json.loads(seq_path.read_text(encoding="utf-8"))
        except Exception:
            continue
        seq_data = data.get("sequences", {}).get(seq_id) if isinstance(data.get("sequences"), dict) else data
        maps = seq_data.get("maps", []) if isinstance(seq_data, dict) else []
        for m in maps:
            name = m.get("map") if isinstance(m, dict) else m
            if name and name not in names:
                names.append(name)
    return names


# ── CLI ─────────────────────────────────────────────────────────────────

def format_table(result: dict[str, Any]) -> str:
    t = result["totals"]
    out = [
        f"{result['map']}  ({result['blocks']} blocks)",
        f"  artifacts:    {len(result['artifacts'])} resolved"
        f" ({len(result['artifacts_unresolved'])} unresolved)"
        f"  ({result['artifact_symbol_count']} symbols)",
        f"  references:   LOCAL={t['LOCAL']}  ARTIFACT={t['ARTIFACT']}"
        f"  CLASSNAME={t['CLASSNAME']}  BUILTIN={t['BUILTIN']}"
        f"  UNKNOWN={t['UNKNOWN']}",
        f"  grounding:    {result['overall_grounding_ratio']:.2f}"
        f"  (resolved external refs / all external refs)",
    ]
    if result["unknown_identifiers"]:
        out.append("  unknowns:")
        for ident, n in list(result["unknown_identifiers"].items())[:12]:
            out.append(f"    {n:>3}x  {ident}")
    return "\n".join(out)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", help="Map name")
    ap.add_argument("--file", default="tutorial.md",
                    help="File role (default tutorial.md)")
    ap.add_argument("--path", help="Absolute or repo-relative path to a .md file")
    ap.add_argument("--spine", action="store_true",
                    help="Walk all spine maps")
    ap.add_argument("--format", choices=["json", "table"], default="table")
    ap.add_argument("--only-unknown", action="store_true",
                    help="With --spine: show only entries with UNKNOWN refs")
    args = ap.parse_args()

    # Single path mode
    if args.path:
        p = Path(args.path)
        if not p.is_absolute():
            p = (REPO / p).resolve()
        # Try to infer map from path: commons/maps/{MapName}/{file}.md
        map_name = p.parent.name
        text = p.read_text(encoding="utf-8", errors="replace")
        result = score_text(text, map_name)
        if args.format == "json":
            print(json.dumps(result, indent=2, default=list))
        else:
            print(format_table(result))
        return 0

    # Single map mode
    if args.map and not args.spine:
        p = MAPS / args.map / args.file
        if not p.exists():
            print(f"{p} not found", file=sys.stderr)
            return 1
        text = p.read_text(encoding="utf-8", errors="replace")
        result = score_text(text, args.map)
        if args.format == "json":
            print(json.dumps(result, indent=2, default=list))
        else:
            print(format_table(result))
        return 0

    # Spine mode
    if args.spine:
        names = load_spine_map_names()
        all_results: list[dict[str, Any]] = []
        agg = {"maps": 0, "with_file": 0, "total_unknowns": 0,
               "total_artifact_refs": 0, "total_builtin_refs": 0,
               "total_classname_refs": 0}
        for m in names:
            p = MAPS / m / args.file
            if not p.exists():
                continue
            agg["with_file"] += 1
            text = p.read_text(encoding="utf-8", errors="replace")
            r = score_text(text, m)
            agg["total_unknowns"] += r["totals"]["UNKNOWN"]
            agg["total_artifact_refs"] += r["totals"]["ARTIFACT"]
            agg["total_builtin_refs"] += r["totals"]["BUILTIN"]
            agg["total_classname_refs"] += r["totals"]["CLASSNAME"]
            all_results.append(r)
        agg["maps"] = len(names)

        if args.format == "json":
            print(json.dumps({"summary": agg, "maps": all_results},
                             indent=2, default=list))
            return 0

        for r in all_results:
            if args.only_unknown and r["totals"]["UNKNOWN"] == 0:
                continue
            print()
            print(format_table(r))
        print(f"\n{'-' * 60}")
        print(f"summary: {agg['with_file']}/{agg['maps']} maps have {args.file}")
        print(f"  total ARTIFACT refs:  {agg['total_artifact_refs']}")
        print(f"  total CLASSNAME refs: {agg['total_classname_refs']}")
        print(f"  total BUILTIN refs:   {agg['total_builtin_refs']}")
        print(f"  total UNKNOWN refs:   {agg['total_unknowns']}")
        return 0

    ap.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
