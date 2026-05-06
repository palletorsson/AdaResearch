#!/usr/bin/env python
"""
artifact_doc_index.py — ground-truth index of every artifact's documentation.

For each artifact registered in commons/artifacts/registry/*.json:

  1. Resolve the .tscn scene on disk.
  2. Follow the scene's root-node [ext_resource type="Script"] to the actual .gd.
  3. If the script is a known wrapper (SceneInstantiator.gd and similar),
     follow the inner [ext_resource type="PackedScene"] one level deeper.
  4. Parse the full header — collects all `#` comment lines from the top,
     skipping `extends`, `class_name`, `@tool`, `@icon`, `@export*` declarations
     and blank lines. (Fixes the "extractor stops at first non-comment" bug.)
  5. Classify the header: identity | prose | placeholder | none.
  6. Detect atmospheric status (curated list + docstring keyword heuristic).
  7. Emit a JSON index + markdown summary.

Run:
    python tools/artifact_doc_index.py                 # full run → doc/reports/
    python tools/artifact_doc_index.py --token X       # inspect one artifact
    python tools/artifact_doc_index.py --format summary

Zero network, pure regex. Fast on the whole artifact registry.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
REGISTRY = REPO / "commons" / "artifacts" / "registry"
REPORTS = REPO / "doc" / "reports"

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass


# ── Known wrappers (root scripts that instantiate another scene) ────────

WRAPPER_SCRIPTS = {
    "SceneInstantiator.gd",
}

# ── Atmospheric detection ──────────────────────────────────────────────

ATMOSPHERIC_TOKENS = {
    "dark_sphere",
}

# Only treat the keyword as atmospheric when it clearly describes the
# artifact's *role* in the opening description — not when it appears
# incidentally in needs/relationships/essence of a load-bearing artifact.
# Require the marker within the first few comment lines (file-level
# description), not anywhere in the @identity body.
ATMOSPHERIC_FIRST_LINE_MARKERS = (
    "atmospheric ",
    "decorative artifact",
    "ambient decor",
    "purely visual",
    "purely decorative",
    "cosmetic prop",
    "skybox",
)


# ── .tscn parsing ──────────────────────────────────────────────────────

EXT_RESOURCE_RE = re.compile(
    r'\[ext_resource\s+type="([^"]+)"\s+(?:uid="[^"]+"\s+)?path="([^"]+)"\s+id="?([^"\s\]]+)"?'
)
SCRIPT_ASSIGN_RE = re.compile(r'^\s*script\s*=\s*ExtResource\(\s*"?([^")]+)"?\s*\)', re.MULTILINE)
NODE_HEADER_RE = re.compile(r'^\[node\s+name="[^"]+"\s+type="([^"]+)"', re.MULTILINE)


def parse_tscn(tscn_path: Path) -> dict[str, Any]:
    """Return {root_script_path, inner_scenes[], all_scripts[]}."""
    if not tscn_path.exists():
        return {"root_script_path": None, "inner_scenes": [], "all_scripts": []}
    try:
        text = tscn_path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return {"root_script_path": None, "inner_scenes": [], "all_scripts": []}

    # Map ext_resource id -> (type, path)
    resources: dict[str, tuple[str, str]] = {}
    for rtype, path, rid in EXT_RESOURCE_RE.findall(text):
        resources[rid] = (rtype, path)

    # Find first script = ExtResource() assignment (root node's script)
    root_script_path: str | None = None
    m = SCRIPT_ASSIGN_RE.search(text)
    if m:
        rid = m.group(1)
        if rid in resources and resources[rid][0] == "Script":
            root_script_path = resources[rid][1]

    inner_scenes = [p for (t, p) in resources.values() if t == "PackedScene"]
    all_scripts = [p for (t, p) in resources.values() if t == "Script"]

    return {
        "root_script_path": root_script_path,
        "inner_scenes": inner_scenes,
        "all_scripts": all_scripts,
    }


def _find_script_by_basename(scene_dir: Path, basename: str) -> Path | None:
    """Fallback: look for a same-named .gd in the scene's directory."""
    candidate = scene_dir / basename
    if candidate.exists():
        return candidate
    # Case-insensitive match in the same dir
    low = basename.lower()
    for p in scene_dir.glob("*.gd"):
        if p.name.lower() == low:
            return p
    return None


def resolve_script_for_scene(
    scene_path: Path, max_depth: int = 2
) -> tuple[Path | None, list[str]]:
    """Follow wrapper chains; return (script_path, wrapper_chain).

    If the declared script path is stale (file moved/renamed) but the
    scene's own directory contains a .gd with the same basename, that
    fallback is used. This catches the common case where scripts have
    been relocated but scene .tscn files still carry stale paths
    (Godot resolves these via UID at runtime; our parser reads text).
    """
    chain: list[str] = []
    current = scene_path
    for _ in range(max_depth):
        info = parse_tscn(current)
        script_rel = info["root_script_path"]
        if not script_rel:
            return None, chain
        script_rel = script_rel.replace("res://", "")
        script_path = REPO / script_rel
        script_name = script_path.name
        if script_name in WRAPPER_SCRIPTS and info["inner_scenes"]:
            chain.append(script_name)
            inner = info["inner_scenes"][0].replace("res://", "")
            current = REPO / inner
            continue
        # If the declared script is missing, try the scene's own dir
        if not script_path.exists():
            fallback = _find_script_by_basename(current.parent, script_name)
            if fallback is not None:
                return fallback, chain
        return script_path, chain
    return None, chain


# ── Header parsing ─────────────────────────────────────────────────────

# Lines we skip over while scanning for comments
SKIPPABLE_RE = re.compile(
    r"^\s*("
    r"extends\s|"
    r"class_name\s|"
    r"@tool\b|"
    r"@icon\b|"
    r"@export\b|"
    r"@onready\b|"
    r"@warning_ignore\b|"
    r"$"  # blank
    r")"
)

COMMENT_RE = re.compile(r"^\s*(#{1,2})\s?(.*)$")
IDENTITY_MARKER_RE = re.compile(r"^\s*#\s*@identity\b", re.MULTILINE)
IDENTITY_FIELD_RE = re.compile(
    r"^\s*#\s*(essence|desire|critical_parameter|triggers|emerges|needs|relationships|truth)\s*:\s*(.+)$",
    re.MULTILINE,
)


@dataclass
class HeaderInfo:
    lines: list[str] = field(default_factory=list)
    kind: str = "none"  # identity | prose | placeholder | none
    identity_fields: dict[str, str] = field(default_factory=dict)


def extract_header(script_path: Path) -> HeaderInfo:
    info = HeaderInfo()
    if not script_path.exists():
        return info
    try:
        text = script_path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return info

    # Collect comment lines from the first ~80 lines, skipping over
    # extends/class_name/@tool/@export/blank. Stop when we hit a func/var/const/signal.
    comment_lines: list[str] = []
    consecutive_code = 0
    for i, raw in enumerate(text.splitlines()[:120]):
        stripped = raw.strip()
        if not stripped:
            consecutive_code = 0
            continue
        if stripped.startswith(("func ", "const ", "signal ", "var ")):
            # Real code started — stop scanning
            break
        m = COMMENT_RE.match(raw)
        if m:
            comment_lines.append(m.group(2).rstrip())
            consecutive_code = 0
            continue
        if SKIPPABLE_RE.match(raw):
            continue
        # Some other non-comment, non-skippable line — give up after a few
        consecutive_code += 1
        if consecutive_code >= 3:
            break

    info.lines = comment_lines

    if not comment_lines:
        info.kind = "none"
        return info

    joined = "\n".join(comment_lines)
    # @identity detection — look for the marker OR the field pattern
    has_identity_marker = "@identity" in joined
    identity_fields = {}
    for field_name, val in IDENTITY_FIELD_RE.findall(
        "\n".join(f"# {l}" for l in comment_lines)
    ):
        identity_fields[field_name] = val.strip()

    if has_identity_marker or len(identity_fields) >= 3:
        info.kind = "identity"
        info.identity_fields = identity_fields
        return info

    # Placeholder detection
    total_chars = sum(len(l) for l in comment_lines)
    stripped_joined = " ".join(l.strip() for l in comment_lines).strip()

    # Just the filename
    stem = script_path.stem
    if stripped_joined.lower() in (
        f"{stem}.gd".lower(),
        stem.lower(),
    ):
        info.kind = "placeholder"
        return info

    # Very short / shebang / metadata only
    if total_chars < 20 and len(comment_lines) <= 2:
        info.kind = "placeholder"
        return info

    info.kind = "prose"
    return info


# ── Atmospheric detection ──────────────────────────────────────────────

def is_atmospheric(token: str, header: HeaderInfo) -> tuple[bool, str]:
    if token in ATMOSPHERIC_TOKENS:
        return True, "curated list"
    # Only check the first few header lines (file-level description),
    # not the @identity body which may use the word incidentally.
    head_text = " ".join(header.lines[:4]).lower()
    for kw in ATMOSPHERIC_FIRST_LINE_MARKERS:
        if kw in head_text:
            return True, f"marker: {kw!r} in opening lines"
    return False, ""


# ── Registry walker ───────────────────────────────────────────────────

@dataclass
class ArtifactEntry:
    token: str
    registry: str
    scene_path: str = ""
    scene_exists: bool = False
    script_path: str = ""
    script_exists: bool = False
    wrapper_chain: list[str] = field(default_factory=list)
    header_kind: str = "none"  # identity | prose | registry | placeholder | none
    header_text: str = ""
    header_source: str = ""  # 'script' or 'registry'
    registry_description: str = ""
    identity_fields: dict[str, str] = field(default_factory=dict)
    is_atmospheric: bool = False
    atmospheric_reason: str = ""


def load_registry() -> list[tuple[str, str, dict[str, Any]]]:
    """Return [(registry_filename, lookup_name, raw_entry), ...]."""
    out: list[tuple[str, str, dict[str, Any]]] = []
    for path in sorted(REGISTRY.glob("*.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            continue
        items = (
            data
            if isinstance(data, list)
            else data.get("artifacts", data.get("items", []))
        )
        if isinstance(items, dict):
            items = list(items.values())
        if not isinstance(items, list):
            continue
        for it in items:
            if not isinstance(it, dict):
                continue
            key = it.get("lookup_name") or it.get("name") or it.get("token") or it.get("id")
            if key:
                out.append((path.name, key, it))
    return out


def build_entry(registry_file: str, token: str, raw: dict[str, Any]) -> ArtifactEntry:
    entry = ArtifactEntry(token=token, registry=registry_file)
    # Capture registry-level description early — used as a fallback
    # documentation source when the scene has no script or the script
    # has no header comment. Scriptless scenes are legitimate for
    # pure-visual/prop artifacts whose behaviour is declared at the
    # registry level.
    desc = raw.get("description") or raw.get("summary") or raw.get("blurb") or ""
    if isinstance(desc, str):
        entry.registry_description = desc.strip()

    scene_rel = raw.get("scene_path") or raw.get("scene") or ""
    if not scene_rel:
        _apply_registry_fallback(entry)
        return entry
    scene_rel = scene_rel.replace("res://", "")
    entry.scene_path = scene_rel
    scene_path = REPO / scene_rel
    entry.scene_exists = scene_path.exists()
    if not entry.scene_exists:
        _apply_registry_fallback(entry)
        return entry
    script_path, chain = resolve_script_for_scene(scene_path)
    entry.wrapper_chain = chain
    if script_path is None:
        _apply_registry_fallback(entry)
        entry.is_atmospheric, entry.atmospheric_reason = is_atmospheric(
            token, HeaderInfo(lines=[entry.header_text])
        )
        return entry
    try:
        entry.script_path = str(script_path.relative_to(REPO)).replace("\\", "/")
    except ValueError:
        entry.script_path = str(script_path)
    entry.script_exists = script_path.exists()
    if not entry.script_exists:
        _apply_registry_fallback(entry)
        entry.is_atmospheric, entry.atmospheric_reason = is_atmospheric(
            token, HeaderInfo(lines=[entry.header_text])
        )
        return entry
    header = extract_header(script_path)
    # If the script header is missing or thin, fall back to the registry
    # description. Script docs still take precedence when they exist.
    if header.kind in ("none", "placeholder") and len(entry.registry_description) >= 30:
        entry.header_kind = "registry"
        entry.header_text = entry.registry_description
        entry.header_source = "registry"
    else:
        entry.header_kind = header.kind
        entry.header_text = "\n".join(header.lines)
        entry.header_source = "script" if header.lines else ""
    entry.identity_fields = header.identity_fields
    entry.is_atmospheric, entry.atmospheric_reason = is_atmospheric(token, header)
    return entry


def _apply_registry_fallback(entry: ArtifactEntry) -> None:
    """Populate header from registry description when script is unreachable."""
    if len(entry.registry_description) >= 30:
        entry.header_kind = "registry"
        entry.header_text = entry.registry_description
        entry.header_source = "registry"


def summarize(entries: list[ArtifactEntry]) -> dict[str, Any]:
    total = len(entries)
    kinds = {"identity": 0, "prose": 0, "registry": 0, "placeholder": 0, "none": 0}
    scene_missing = 0
    script_missing = 0
    atmospheric = 0
    wrapped = 0
    by_registry: dict[str, dict[str, int]] = {}
    for e in entries:
        if not e.scene_exists:
            scene_missing += 1
        elif not e.script_exists:
            script_missing += 1
        kinds[e.header_kind] = kinds.get(e.header_kind, 0) + 1
        if e.is_atmospheric:
            atmospheric += 1
        if e.wrapper_chain:
            wrapped += 1
        reg = e.registry
        by_registry.setdefault(
            reg,
            {"total": 0, "identity": 0, "prose": 0, "registry": 0, "placeholder": 0, "none": 0},
        )
        by_registry[reg]["total"] += 1
        by_registry[reg][e.header_kind] = by_registry[reg].get(e.header_kind, 0) + 1
    identity_rate = kinds["identity"] / total if total else 0.0
    documented = kinds["identity"] + kinds["prose"] + kinds["registry"]
    documented_rate = documented / total if total else 0.0
    return {
        "total": total,
        "scene_missing": scene_missing,
        "script_missing": script_missing,
        "header_kinds": kinds,
        "identity_adoption": round(identity_rate, 3),
        "documented_rate": round(documented_rate, 3),
        "atmospheric_count": atmospheric,
        "wrapped_count": wrapped,
        "by_registry": by_registry,
    }


# ── Output ─────────────────────────────────────────────────────────────

def print_markdown(entries: list[ArtifactEntry], summary: dict[str, Any]) -> None:
    k = summary["header_kinds"]
    print("# Artifact Documentation Index\n")
    print(f"- Total artifacts: **{summary['total']}**")
    print(f"- Scene file missing: **{summary['scene_missing']}**")
    print(f"- Script file missing (scene exists): **{summary['script_missing']}**")
    print(f"- `@identity` headers: **{k['identity']}** ({summary['identity_adoption'] * 100:.1f}%)")
    print(f"- Prose headers: **{k['prose']}**")
    print(f"- Registry-description fallback: **{k.get('registry', 0)}**")
    print(f"- Placeholder headers: **{k['placeholder']}**")
    print(f"- No header or registry description: **{k['none']}**")
    print(f"- Documented rate (identity + prose + registry): **{summary['documented_rate'] * 100:.1f}%**")
    print(f"- Atmospheric (filtered from coverage): **{summary['atmospheric_count']}**")
    print(f"- Reached via wrapper chain: **{summary['wrapped_count']}**\n")

    print("## By registry\n")
    print("| Registry | Total | identity | prose | placeholder | none | adoption |")
    print("|---|---:|---:|---:|---:|---:|---:|")
    rows = sorted(summary["by_registry"].items(), key=lambda kv: -kv[1]["total"])
    for name, s in rows:
        t = s["total"]
        rate = s.get("identity", 0) / t if t else 0
        print(
            f"| {name} | {t} | {s.get('identity',0)} | {s.get('prose',0)} "
            f"| {s.get('placeholder',0)} | {s.get('none',0)} | {rate*100:.0f}% |"
        )

    # Placeholder and no-header artifacts — the real worklist
    placeholders = [e for e in entries if e.header_kind == "placeholder"]
    none_headers = [e for e in entries if e.header_kind == "none" and e.script_exists]
    missing_scripts = [e for e in entries if e.scene_exists and not e.script_exists]
    missing_scenes = [e for e in entries if not e.scene_exists]

    if placeholders:
        print(f"\n## Placeholder headers — need real docstrings ({len(placeholders)})\n")
        for e in placeholders[:60]:
            print(f"- `{e.token}` — {e.script_path}")
    if none_headers:
        print(f"\n## No header at all — need docstrings written ({len(none_headers)})\n")
        for e in none_headers[:60]:
            print(f"- `{e.token}` — {e.script_path}")
    if missing_scripts:
        print(f"\n## Scene exists, script missing ({len(missing_scripts)})\n")
        for e in missing_scripts[:40]:
            print(f"- `{e.token}` — scene: {e.scene_path}")
    if missing_scenes:
        print(f"\n## Registered but scene file missing ({len(missing_scenes)})\n")
        for e in missing_scenes[:40]:
            print(f"- `{e.token}` — {e.registry} → {e.scene_path or '(no scene_path)'}")


def print_token_detail(entry: ArtifactEntry) -> None:
    print(f"\n# {entry.token}")
    print(f"  registry: {entry.registry}")
    print(f"  scene: {entry.scene_path} [exists={entry.scene_exists}]")
    print(f"  script: {entry.script_path} [exists={entry.script_exists}]")
    if entry.wrapper_chain:
        print(f"  wrapper_chain: {' → '.join(entry.wrapper_chain)}")
    print(f"  header_kind: {entry.header_kind}")
    if entry.is_atmospheric:
        print(f"  atmospheric: yes ({entry.atmospheric_reason})")
    if entry.identity_fields:
        print(f"  @identity fields: {list(entry.identity_fields.keys())}")
        for k, v in entry.identity_fields.items():
            print(f"    {k}: {v[:100]}")
    if entry.header_text:
        print("  header_text:")
        for l in entry.header_text.splitlines()[:12]:
            print(f"    {l}")


# ── CLI ────────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--token", help="Inspect a single artifact token")
    ap.add_argument(
        "--format",
        choices=["markdown", "json", "summary"],
        default="markdown",
    )
    ap.add_argument("--out-dir", default=str(REPORTS), help="Where to write reports")
    args = ap.parse_args()

    registry = load_registry()

    if args.token:
        matches = [(r, k, raw) for (r, k, raw) in registry if k == args.token]
        if not matches:
            print(f"No artifact with token {args.token!r}", file=sys.stderr)
            return 1
        entry = build_entry(*matches[0])
        if args.format == "json":
            print(json.dumps(asdict(entry), indent=2))
        else:
            print_token_detail(entry)
        return 0

    entries = [build_entry(r, k, raw) for (r, k, raw) in registry]
    summary = summarize(entries)

    if args.format == "summary":
        print(json.dumps(summary, indent=2))
        return 0

    if args.format == "json":
        print(json.dumps({"summary": summary, "entries": [asdict(e) for e in entries]}, indent=2))
        return 0

    # Markdown: also write JSON sidecar for programmatic use
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    json_path = out_dir / "ARTIFACT_DOC_INDEX.json"
    json_path.write_text(
        json.dumps({"summary": summary, "entries": [asdict(e) for e in entries]}, indent=2),
        encoding="utf-8",
    )
    print_markdown(entries, summary)
    print(f"\n_JSON sidecar: {json_path.relative_to(REPO)}_", file=sys.stderr)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
