#!/usr/bin/env python3
"""
artifact_impact.py — surface every relation pointing at a single artifact.

Run before any non-trivial edit to a registered artifact. Prints all six
directions of impact in one go so you can see what your change will (or
might) ripple into.

Usage:
    python tools/artifact_impact.py <lookup_name>
    python tools/artifact_impact.py catalyst_foe
    python tools/artifact_impact.py sphere --terse
    python tools/artifact_impact.py origin --json

Directions surfaced:
    1. SPEC          — registry entry (label, scene, tags, qfep_connection)
    2. MAP-ADJACENT  — every map_data.json containing this lookup
    3. SEQUENCE      — sequences whose artifact_groups list this lookup
    4. CAPTURES      — public/artifact-in-map captures (the gallery)
    5. SIEVE PASSES  — any doc/sieve_passes/ doc that mentions this lookup
    6. CODE          — every .gd/.gdshader/.tscn referencing the scene path

Pure read-only — never modifies. Pure stdlib — no deps.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any

# Repo root — assume the script is in <repo>/tools/
REPO = Path(__file__).resolve().parent.parent
ENCYCLOPEDIA = REPO.parent / "ada_encyclopedia"

# ANSI colour helpers — disabled when not a TTY.
USE_COLOR = sys.stdout.isatty() and os.environ.get("NO_COLOR") is None
def c(code: str, s: str) -> str:
    return f"\x1b[{code}m{s}\x1b[0m" if USE_COLOR else s
HEAD = lambda s: c("1;36", s)   # bold cyan
LBL  = lambda s: c("33", s)     # yellow
DIM  = lambda s: c("2", s)      # dim
OK   = lambda s: c("32", s)     # green
WARN = lambda s: c("31", s)     # red


def load_registry() -> dict[str, dict]:
    """Read every commons/artifacts/registry/*.json (skip .bak) and
    flatten into {lookup_name: entry}."""
    out: dict[str, dict] = {}
    reg_dir = REPO / "commons" / "artifacts" / "registry"
    if not reg_dir.exists():
        return out
    for p in reg_dir.glob("*.json"):
        if p.name.endswith(".bak"):
            continue
        try:
            with p.open(encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            continue
        for k, v in (data.get("artifacts") or {}).items():
            if isinstance(v, dict):
                v.setdefault("_registry_file", p.name)
                out[k] = v
    return out


def scan_interactables(layer: Any, lookup: str, hits: list[tuple]) -> None:
    """Walk a map_data interactables layer (2D or 3D nested arrays)
    looking for cells whose first token matches the lookup."""
    if isinstance(layer, list):
        for item in layer:
            scan_interactables(item, lookup, hits)
    elif isinstance(layer, str):
        s = layer.strip()
        if not s or s == " ":
            return
        head = s.split("#")[0].split(":")[0].strip()
        if head == lookup:
            hits.append(s)


def maps_containing(lookup: str) -> list[dict]:
    """For each map_data.json, scan interactables for this lookup.
    Return list of {map_name, raw_tokens, sequences_in_metadata}."""
    out: list[dict] = []
    maps_dir = REPO / "commons" / "maps"
    if not maps_dir.exists():
        return out
    for map_dir in maps_dir.iterdir():
        if not map_dir.is_dir():
            continue
        md = map_dir / "map_data.json"
        if not md.exists():
            continue
        try:
            with md.open(encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            continue
        interact = (data.get("layers") or {}).get("interactables", [])
        tokens: list[str] = []
        scan_interactables(interact, lookup, tokens)
        if tokens:
            out.append({
                "map": map_dir.name,
                "tokens": tokens,
                "lookup_name_in_info": (data.get("map_info") or {}).get("lookup_name", map_dir.name),
            })
    out.sort(key=lambda r: r["map"])
    return out


def sequences_containing(lookup: str) -> list[dict]:
    """Read sequences/*.json and report any sequence whose
    artifact_groups list this lookup."""
    out: list[dict] = []
    seq_dir = REPO / "commons" / "maps" / "sequences"
    if not seq_dir.exists():
        return out
    for p in seq_dir.glob("*.json"):
        try:
            with p.open(encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            continue
        # Some sequence files have `sequences` as a dict-of-named-entries,
        # others have it as a list at the top level. Normalize.
        seqs_raw = data.get("sequences")
        if isinstance(seqs_raw, dict):
            seq_items = list(seqs_raw.items())
        elif isinstance(seqs_raw, list):
            seq_items = [(item.get("name", p.stem) if isinstance(item, dict) else p.stem, item)
                         for item in seqs_raw]
        else:
            seq_items = [(p.stem, data)]  # fallback: top-level sequence
        for sname, sdata in seq_items:
            if not isinstance(sdata, dict):
                continue
            groups = sdata.get("artifact_groups") or []
            hits: list[tuple[str, str]] = []
            for grp in groups:
                if not isinstance(grp, dict):
                    continue
                map_name = grp.get("map", "?")
                for a in grp.get("artifacts", []):
                    head = a.split("#")[0].split(":")[0].strip()
                    if head == lookup:
                        hits.append((map_name, a))
            if hits:
                out.append({
                    "sequence": sname,
                    "file": p.name,
                    "phase": sdata.get("phase"),
                    "qfep_term": sdata.get("qfep_term") or sdata.get("qfep_role"),
                    "hits": hits,
                })
    return out


def captures_in_gallery(lookup: str) -> list[dict]:
    """Look in ada_encyclopedia/public/artifact-in-map/*/<lookup>/*.png."""
    out: list[dict] = []
    base = ENCYCLOPEDIA / "public" / "artifact-in-map"
    if not base.exists():
        return out
    for map_dir in base.iterdir():
        if not map_dir.is_dir():
            continue
        art_dir = map_dir / lookup
        if not art_dir.is_dir():
            continue
        pngs = sorted([p.name for p in art_dir.glob("*.png")])
        if pngs:
            out.append({"map": map_dir.name, "captures": pngs})
    return out


def sieve_passes_mentioning(lookup: str) -> list[str]:
    """Grep doc/sieve_passes/*.md for the lookup name (best-effort)."""
    out: list[str] = []
    sp_dir = REPO / "doc" / "sieve_passes"
    if not sp_dir.exists():
        return out
    pattern = re.compile(rf"\b{re.escape(lookup)}\b")
    for p in sp_dir.glob("*.md"):
        try:
            text = p.read_text(encoding="utf-8")
        except Exception:
            continue
        if pattern.search(text):
            out.append(p.name)
    return sorted(out)


def code_refs(lookup: str, entry: dict) -> list[str]:
    """Find .gd / .tscn / .gdshader files that reference the artifact's
    scene path or the lookup name in a clearly-identifying way.
    Best-effort — uses path-fragment substring match to keep noise low."""
    out: set[str] = set()
    scene = entry.get("scene") or ""
    # Strip res:// prefix for substring match.
    scene_tail = scene.replace("res://", "") if scene else None
    # Pieces to look for in source files:
    needles: list[str] = []
    if scene_tail:
        needles.append(scene_tail)
    # Also look for the lookup name in lookup_name= form (avoid loose grep).
    needles.append(f'"{lookup}"')
    needles.append(f"'{lookup}'")
    exts = {".gd", ".gdshader", ".tscn", ".tres"}
    skip_dirs = {"node_modules", ".git", ".godot", "addons", "tools"}
    for root, dirs, files in os.walk(REPO):
        dirs[:] = [d for d in dirs if d not in skip_dirs]
        # Cap scan depth to avoid hammering huge subtrees.
        if Path(root).relative_to(REPO).parts and Path(root).relative_to(REPO).parts[0] == "commons":
            pass  # allow
        for fn in files:
            if not any(fn.endswith(e) for e in exts):
                continue
            fp = Path(root) / fn
            try:
                # Read just the first 200 KB — enough for tscn/gd headers.
                blob = fp.read_text(encoding="utf-8", errors="ignore")[:200_000]
            except Exception:
                continue
            for n in needles:
                if n and n in blob:
                    out.add(str(fp.relative_to(REPO)).replace("\\", "/"))
                    break
    return sorted(out)


def format_report(lookup: str, opts: argparse.Namespace) -> dict:
    """Compute all six directions and return as a structured dict."""
    reg = load_registry()
    entry = reg.get(lookup)
    return {
        "lookup_name": lookup,
        "spec": entry,
        "maps": maps_containing(lookup),
        "sequences": sequences_containing(lookup),
        "captures": captures_in_gallery(lookup),
        "sieve_passes": sieve_passes_mentioning(lookup),
        "code_refs": [] if opts.terse else code_refs(lookup, entry or {}),
    }


def print_text(rep: dict, terse: bool) -> None:
    lookup = rep["lookup_name"]
    spec = rep["spec"]
    print(HEAD(f"=== " + lookup + " ==="))
    print()

    # 1. SPEC
    print(LBL("1. SPEC"))
    if spec is None:
        print("  " + WARN(f"not in any registry"))
    else:
        print(f"  registry:    {spec.get('_registry_file', '?')}")
        print(f"  label:       {spec.get('name', spec.get('label', '?'))}")
        print(f"  category:    {spec.get('category', '?')}")
        scene = spec.get("scene") or "—"
        print(f"  scene:       {scene}")
        themes = spec.get("dev_themes") or []
        if themes:
            print(f"  dev_themes:  {', '.join(themes)}")
        tags = spec.get("tags") or []
        if tags:
            print(f"  tags:        {', '.join(tags[:10])}{'...' if len(tags) > 10 else ''}")
        seqs = spec.get("map_sequences") or []
        if seqs:
            print(f"  registry_seq:{', '.join(seqs)}")
        if spec.get("qfep_connection"):
            qfep = spec["qfep_connection"]
            if len(qfep) > 100:
                qfep = qfep[:100] + "..."
            print(f"  qfep:        {qfep}")
        desc = spec.get("description") or ""
        if desc and not terse:
            if len(desc) > 200:
                desc = desc[:200] + "..."
            print(f"  description: {desc}")
    print()

    # 2. MAP-ADJACENT
    print(LBL(f"2. MAP-ADJACENT — {len(rep['maps'])} map(s) place this artifact"))
    map_limit = 25 if not terse else 10
    for m in rep["maps"][:map_limit]:
        tokens = m["tokens"]
        token_summary = tokens[0] if len(tokens) == 1 else f"{tokens[0]} (+{len(tokens)-1} more)"
        print(f"  {OK('*')} {m['map']:<40} {DIM(token_summary)}")
    if len(rep["maps"]) > map_limit:
        extra = len(rep["maps"]) - map_limit
        print(f"  {DIM('... +' + str(extra) + ' more maps')}")
    print()

    # 3. SEQUENCE
    print(LBL(f"3. SEQUENCE — {len(rep['sequences'])} sequence(s) list this in artifact_groups"))
    for s in rep["sequences"]:
        phase = f" [{s['phase']}]" if s.get('phase') else ""
        print(f"  {OK('*')} {s['sequence']}{phase}")
        for map_name, raw in s["hits"][:5]:
            print(f"      in {map_name}: {DIM(raw)}")
        if len(s["hits"]) > 5:
            extra = len(s["hits"]) - 5
            print(f"      {DIM('... +' + str(extra) + ' more placements')}")
    print()

    # 4. CAPTURES
    print(LBL(f"4. CAPTURES — /artifact-in-map gallery"))
    if not rep["captures"]:
        print(f"  {DIM('no captures yet')}  — run: batch_capture_via_api.ps1 -Artifacts " + lookup)
    else:
        for c_entry in rep["captures"]:
            joined = ", ".join(c_entry["captures"][:8])
            more = f" (+{len(c_entry['captures'])-8} more)" if len(c_entry["captures"]) > 8 else ""
            print(f"  {OK('*')} {c_entry['map']:<40} {DIM(joined + more)}")
        gallery = f"http://localhost:3003/artifact-in-map#{lookup}"
        print(f"  {DIM('hub:')} {gallery}")
    print()

    # 5. SIEVE PASSES
    print(LBL(f"5. SIEVE — {len(rep['sieve_passes'])} sieve pass(es) mention this"))
    for sp in rep["sieve_passes"]:
        print(f"  {OK('*')} doc/sieve_passes/{sp}")
    if not rep["sieve_passes"]:
        print(f"  {DIM('no sieve passes touching this lookup')}")
    print()

    # 6. CODE REFS
    if not terse:
        print(LBL(f"6. CODE — {len(rep['code_refs'])} file(s) reference this artifact"))
        for path in rep["code_refs"][:30]:
            print(f"  {OK('*')} {path}")
        if len(rep["code_refs"]) > 30:
            extra = len(rep["code_refs"]) - 30
            print(f"  {DIM('... +' + str(extra) + ' more')}")
        print()

    # Summary footer
    print(LBL("SUMMARY"))
    spec_status = "ok" if spec else "NO REGISTRY ENTRY"
    cap_count = sum(len(c['captures']) for c in rep['captures'])
    print(f"  spec: {spec_status} · maps: {len(rep['maps'])} · sequences: {len(rep['sequences'])} ·"
          f" captures: {cap_count} · sieves: {len(rep['sieve_passes'])}")
    if not terse:
        print(f"  code: {len(rep['code_refs'])} refs")


def main() -> int:
    p = argparse.ArgumentParser(description="Six-direction impact report for one artifact lookup.")
    p.add_argument("lookup", help="artifact lookup_name (registry key)")
    p.add_argument("--terse", action="store_true", help="skip code-refs scan and trim verbose fields")
    p.add_argument("--json", action="store_true", help="emit raw JSON instead of formatted text")
    opts = p.parse_args()

    rep = format_report(opts.lookup, opts)

    if opts.json:
        print(json.dumps(rep, indent=2, ensure_ascii=False))
        return 0

    print_text(rep, opts.terse)

    if rep["spec"] is None and not rep["maps"] and not rep["sequences"]:
        return 2  # unknown lookup
    return 0


if __name__ == "__main__":
    sys.exit(main())
