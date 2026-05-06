#!/usr/bin/env python3
"""
auto_research_inventory.py
===========================

Walks algorithms/, commons/artifacts/registry/, and ada_encyclopedia's
public/*-gallery/ manifests. Classifies each artifact on five axes:

  principle  — boolean | grammatical | iterative | stochastic |
               optimization | field | geometric | composition
  time       — static | animated | interactive | stateful
  scale      — specimen | surface | object | room | field | architecture
  tier       — A pure-scene | B param-driven | C config-driven |
               D live-only | E image-only
  state      — galleried | identified | scene-only | folder-only

Emits:
  doc/auto_research_inventory.json  — full structured manifest
  doc/auto_research_inventory.md    — readable report grouped by
                                      principle, with coverage gaps
  ada_encyclopedia/public/research-map/inventory.json  — feed for the
                                                        /research-map page

Usage:
    python tools/auto_research_inventory.py
    python tools/auto_research_inventory.py --topic patterngeneration
"""

from __future__ import annotations
import argparse
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ALGOS = REPO / "algorithms"
REGISTRY = REPO / "commons" / "artifacts" / "registry"
ENC_PUBLIC = REPO.parent / "ada_encyclopedia" / "public"
DOC_OUT = REPO / "doc"
WEB_OUT = ENC_PUBLIC / "research-map"


# ─── Classifier heuristics ─────────────────────────────────────────

# Each entry: (principle, [(weight, regex), ...])
# Discriminating keywords have weight 10–20; common-everywhere ones have 1.
# A signature like OPERATION_SUBTRACTION is unmistakably boolean; "vector"
# alone is not enough to call something geometric (every script uses
# Vector3). Final principle = highest WEIGHTED score; ties broken by
# specificity order in the list below.
PRINCIPLE_KEYWORDS: list[tuple[str, list[tuple[int, str]]]] = [
    ("boolean",     [(20, r"OPERATION_SUBTRACTION"), (20, r"OPERATION_UNION"),
                     (20, r"OPERATION_INTERSECTION"),
                     (8, r"\bCSGSphere3D\b"), (8, r"\bCSGBox3D\b"),
                     (8, r"\bCSGCylinder3D\b"), (8, r"\bCSGTorus3D\b"),
                     (8, r"\bCSGCombiner3D\b"),
                     (4, r"\bcarve\b"), (4, r"_subtract\b")]),
    ("grammatical", [(20, r"l_system|L-system|Lindenmayer"),
                     (15, r"production_rules?"), (15, r"\bgrammar\b"),
                     (15, r"wave_function_collapse|\bWFC\b"),
                     (10, r"\brule_?\d+"), (8, r"_substitut"),
                     (10, r"->.*\["),    # production rule arrows
                     (8, r"\baxiom\b")]),
    ("iterative",   [(20, r"cellular_?automat[ao]n?"),
                     (15, r"reaction_?diffusion"), (15, r"\bgray_?scott"),
                     (15, r"\bturing\b"),
                     (10, r"\bgenerations?\b.*\bgrid\b"),
                     (8, r"_evolve\("), (6, r"_step\(.*delta"),
                     (8, r"_ca_tick"),  (6, r"_simulate\("),
                     (5, r"\bgame_of_life|conway")]),
    ("stochastic",  [(15, r"brownian"), (15, r"random_walk"),
                     (15, r"diffusion_limited"), (12, r"\bperlin\b"),
                     (12, r"\bsimplex\b"),
                     (10, r"FastNoiseLite"), (8, r"\bparticles?\b"),
                     (6, r"RandomNumberGenerator"),
                     (3, r"\brandf\b"), (3, r"\brandi\b")]),
    ("optimization",[(15, r"gradient_descent"), (15, r"backprop"),
                     (12, r"\bneural"), (12, r"\bnetwork\b"),
                     (10, r"machine_learning"),
                     (10, r"\bevolutionary?\b"), (10, r"\bfitness\b"),
                     (10, r"\boptimi[sz]"), (8, r"\bsearch_"),
                     (8, r"a_?star|astar\b"), (8, r"\bdijkstra"),
                     (6, r"\bgenom[ei]"), (6, r"\bcrossover"),
                     (6, r"\bmutation\b")]),
    ("field",       [(20, r"isosurface"), (15, r"marching_cubes"),
                     (15, r"\bSDF\b"),
                     (12, r"distance_field"), (10, r"\bvoronoi\b"),
                     (10, r"shader_param|ShaderMaterial"),
                     (8, r"\bfragment\b"),
                     (8, r"\.gdshader"), (5, r"\buv\b")]),
    ("composition", [(15, r"primitive_stack"), (12, r"\bfacade_"),
                     (10, r"\bcompose\b"), (8, r"\bassembly\b"),
                     (8, r"\bensemble\b"),
                     (6, r"\bunder_plate"),  (6, r"\bwall_grid"),
                     (6, r"\bvertical_stack")]),
    ("geometric",   [(8, r"\btransform_apply\b"),
                     (8, r"axis_angle"), (8, r"\bquaternion\b"),
                     (5, r"\bbasis\b"),
                     (3, r"\bvector_"), (3, r"\bprimitive_"),
                     (3, r"\btransform_")]),
]

SCALE_KEYWORDS = {
    "room":         ["room_size", "room_height", "wall", "interior", "skyspace", "chamber",
                     "atrium", "corridor", "vault"],
    "architecture": ["cathedral", "tower", "facade", "building"],
    "object":       ["furniture", "lamp", "chair", "table", "pendant", "Vignelli", "Aalto"],
    "field":        ["wallpaper", "tessellat", "tile", "grid_n", "voronoi", "truchet"],
    "surface":      ["shader", "fragment", "wall_grid", "panel"],
    "specimen":     ["specimen", "totem", "stack", "ring", "spike"],
}


# ─── Inventory walker ──────────────────────────────────────────────

def walk_algorithms() -> list[dict]:
    items: list[dict] = []
    if not ALGOS.exists():
        return items
    for topic_dir in sorted(ALGOS.iterdir()):
        if not topic_dir.is_dir():
            continue
        topic = topic_dir.name
        if topic.startswith(".") or topic.startswith("_"):
            continue
        for art_dir in sorted(topic_dir.iterdir()):
            if not art_dir.is_dir():
                continue
            artifact = art_dir.name
            tscn = next(art_dir.glob("*.tscn"), None)
            gd_files = list(art_dir.glob("*.gd"))
            if not tscn and not gd_files:
                continue
            items.append({
                "topic": topic,
                "artifact": artifact,
                "scene": str(tscn.relative_to(REPO)) if tscn else None,
                "gd": [str(f.relative_to(REPO)) for f in gd_files],
            })
    return items


def walk_registry() -> dict:
    """Map lookup_name → registry record."""
    out: dict[str, dict] = {}
    if not REGISTRY.exists():
        return out
    for f in REGISTRY.glob("*.json"):
        if f.name.endswith(".bak"):
            continue
        try:
            data = json.loads(f.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        artifacts = data.get("artifacts", {})
        for k, v in artifacts.items():
            if not isinstance(v, dict):
                continue
            v["_registry_file"] = f.name
            out[k] = v
    return out


def walk_galleries() -> tuple[dict, dict]:
    """Two indexes:
       (a) by_id: artifact-name → galleries that have an entry with that id
       (b) by_scene_token: any path-substring → galleries that include
           an entry whose config.json references that substring.

    The second one is what catches things like:
       gallery entry id = 'penrose_iter_5'
       its config has    "scene": "res://algorithms/patterngeneration/penrose_tilings/penrose_tilings.tscn"
       so artifact 'penrose_tilings' under topic 'patterngeneration' is galleried.
    """
    if not ENC_PUBLIC.exists():
        return {}, {}
    by_id: dict[str, list[str]] = defaultdict(list)
    by_scene_token: dict[str, list[str]] = defaultdict(list)
    for gallery_dir in ENC_PUBLIC.glob("*-gallery"):
        manifest = gallery_dir / "manifest.json"
        if not manifest.exists():
            continue
        try:
            m = json.loads(manifest.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        gname = gallery_dir.name
        for entry in m.get("entries", []):
            eid = entry.get("id", "")
            if eid:
                by_id[eid].append(gname)
            # Read entry's config JSON for scene references.
            cfg_rel = entry.get("config")
            if cfg_rel:
                cfg_file = ENC_PUBLIC / cfg_rel.lstrip("/")
                if cfg_file.exists():
                    try:
                        cfg = json.loads(cfg_file.read_text(encoding="utf-8"))
                    except json.JSONDecodeError:
                        cfg = {}
                    scene_str = ""
                    if isinstance(cfg, dict):
                        scene_str = str(cfg.get("scene", ""))
                    if scene_str.startswith("res://algorithms/"):
                        # strip "res://algorithms/<topic>/<artifact>/..."
                        parts = scene_str[len("res://algorithms/"):].split("/")
                        if len(parts) >= 2:
                            tok = f"{parts[0]}/{parts[1]}"
                            if gname not in by_scene_token[tok]:
                                by_scene_token[tok].append(gname)
    return dict(by_id), dict(by_scene_token)


# ─── Classifiers ───────────────────────────────────────────────────

ID_BLOCK_RE = re.compile(r"# essence:\s*(.+?)\n", re.IGNORECASE)
APPLY_CFG_RE = re.compile(r"func\s+apply_grid_config\s*\(", re.IGNORECASE)
EXPORT_RE = re.compile(r"^@export(?:_\w+)?\s+var\s+(\w+)", re.MULTILINE)


def read_concat(gd_paths: list[str]) -> str:
    text_parts: list[str] = []
    for p in gd_paths:
        try:
            text_parts.append((REPO / p).read_text(encoding="utf-8", errors="ignore"))
        except OSError:
            continue
    return "\n".join(text_parts)


def extract_essence(text: str) -> str | None:
    m = ID_BLOCK_RE.search(text)
    return m.group(1).strip() if m else None


def classify_principle(text: str, essence: str | None) -> tuple[str, list[str], dict]:
    """Return (top_principle, ranked_matches, scores_dict).
    Uses weighted regex matches; high-weight terms (e.g. OPERATION_SUBTRACTION)
    dominate over generic ones (e.g. 'vector'). The essence text counts 3×
    because @identity is high-signal."""
    body = text or ""
    ess = essence or ""
    scores: dict[str, int] = {}
    for principle, patterns in PRINCIPLE_KEYWORDS:
        s = 0
        for weight, pat in patterns:
            try:
                s += weight * len(re.findall(pat, body, re.IGNORECASE))
                s += weight * 3 * len(re.findall(pat, ess, re.IGNORECASE))
            except re.error:
                pass
        if s > 0:
            scores[principle] = s
    if not scores:
        return "geometric", [], {}
    matches = sorted(scores, key=lambda k: -scores[k])
    return matches[0], matches, scores


def classify_time(text: str) -> str:
    if not text:
        return "static"
    has_process = bool(re.search(r"func\s+_process\s*\(|func\s+_physics_process\s*\(", text))
    has_timer = bool(re.search(r"\bTimer\b|_timer\s*=", text))
    has_input = bool(re.search(r"input_event|button_pressed|slider_moved|XR.*Tools|xr_pickup", text, re.IGNORECASE))
    has_state = bool(re.search(r"_state\s*=|enum.*State", text))
    if has_input:
        return "interactive"
    if has_process or has_timer:
        return "animated"
    if has_state:
        return "stateful"
    return "static"


def classify_scale(text: str, essence: str | None, topic: str) -> str:
    blob = ((text or "") + " " + (essence or "") + " " + topic).lower()
    for scale, kws in SCALE_KEYWORDS.items():
        for kw in kws:
            if kw.lower() in blob:
                return scale
    return "specimen"


def classify_tier(text: str, has_scene: bool) -> str:
    if not has_scene:
        return "E"
    if APPLY_CFG_RE.search(text or ""):
        # If it reads a config_path → C config-driven; else B param-driven.
        if 'config_path' in (text or ""):
            return "C"
        return "B"
    if re.search(r"XRTools|xr_pickup|XRController", text or "", re.IGNORECASE):
        return "D"
    return "A"


def classify_state(item: dict, essence: str | None, in_galleries: list[str], registered: bool) -> str:
    if in_galleries:
        return "galleried"
    if essence:
        return "identified"
    if item.get("scene"):
        return "scene-only"
    return "folder-only"


# ─── Build inventory ───────────────────────────────────────────────

def build_inventory(only_topic: str | None = None) -> list[dict]:
    algos = walk_algorithms()
    registry = walk_registry()
    by_id, by_scene_token = walk_galleries()

    rows: list[dict] = []
    for item in algos:
        if only_topic and item["topic"] != only_topic:
            continue
        text = read_concat(item["gd"])
        essence = extract_essence(text)
        principle, matches, scores = classify_principle(text, essence)
        # Confidence: 1.0 = top score is much higher than runner-up.
        # 0.0 = top and runner-up tied. Used to surface borderline cases.
        confidence: float = 1.0
        if len(matches) >= 2 and scores[matches[0]] > 0:
            confidence = round(
                1.0 - scores[matches[1]] / scores[matches[0]], 3
            )
        time_b = classify_time(text)
        scale = classify_scale(text, essence, item["topic"])
        tier = classify_tier(text, item.get("scene") is not None)
        # Find galleries via two routes: by id-match, by scene-path-token.
        in_galleries: list[str] = list(by_id.get(item["artifact"], []))
        scene_token = f"{item['topic']}/{item['artifact']}"
        for g in by_scene_token.get(scene_token, []):
            if g not in in_galleries:
                in_galleries.append(g)
        registered = item["artifact"] in registry
        state = classify_state(item, essence, in_galleries, registered)
        exports = re.findall(EXPORT_RE, text)[:8]

        rows.append({
            "topic": item["topic"],
            "artifact": item["artifact"],
            "scene": item["scene"],
            "essence": essence,
            "principle": principle,
            "principle_matches": matches,
            "principle_scores": scores,
            "confidence": confidence,
            "time": time_b,
            "scale": scale,
            "tier": tier,
            "state": state,
            "in_galleries": in_galleries,
            "registered": registered,
            "exports": exports,
        })
    return rows


# ─── Report writers ────────────────────────────────────────────────

def write_json(rows: list[dict]) -> None:
    DOC_OUT.mkdir(parents=True, exist_ok=True)
    out = {
        "schema_version": 1,
        "generated_by": "tools/auto_research_inventory.py",
        "totals": summarize_totals(rows),
        "by_principle": group_count(rows, "principle"),
        "by_time": group_count(rows, "time"),
        "by_scale": group_count(rows, "scale"),
        "by_tier": group_count(rows, "tier"),
        "by_state": group_count(rows, "state"),
        "by_topic": group_count(rows, "topic"),
        "rows": rows,
    }
    (DOC_OUT / "auto_research_inventory.json").write_text(
        json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    # Also feed the encyclopedia.
    WEB_OUT.mkdir(parents=True, exist_ok=True)
    (WEB_OUT / "inventory.json").write_text(
        json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )


def group_count(rows: list[dict], key: str) -> dict:
    c = Counter(r[key] for r in rows)
    return dict(c.most_common())


def summarize_totals(rows: list[dict]) -> dict:
    return {
        "artifacts": len(rows),
        "topics": len({r["topic"] for r in rows}),
        "with_essence": sum(1 for r in rows if r["essence"]),
        "with_scene": sum(1 for r in rows if r["scene"]),
        "galleried": sum(1 for r in rows if r["in_galleries"]),
    }


def write_markdown(rows: list[dict]) -> None:
    DOC_OUT.mkdir(parents=True, exist_ok=True)
    out: list[str] = []
    out.append("# Auto-Research Inventory\n")
    out.append("Generated by `tools/auto_research_inventory.py`. "
               "Classifies every artifact in `algorithms/*/*/` on five axes.\n")
    totals = summarize_totals(rows)
    out.append(f"\n**{totals['artifacts']}** artifacts across **{totals['topics']}** topics.  "
               f"{totals['with_essence']} have @identity essence, "
               f"{totals['galleried']} are in a gallery.\n")

    for axis, label in [
        ("principle", "Generative Principle"),
        ("time", "Time Behavior"),
        ("scale", "Spatial Scale"),
        ("tier", "Auto-Research Tier"),
        ("state", "Curatorial State"),
    ]:
        out.append(f"\n## By {label}\n")
        out.append("| Class | Count |\n|---|---:|\n")
        for k, v in group_count(rows, axis).items():
            out.append(f"| `{k}` | {v} |\n")

    out.append("\n## By Topic × Principle (heat-map)\n")
    by_topic_principle: dict = defaultdict(lambda: defaultdict(int))
    principles_set = set()
    for r in rows:
        by_topic_principle[r["topic"]][r["principle"]] += 1
        principles_set.add(r["principle"])
    principles = sorted(principles_set)
    out.append("| Topic | " + " | ".join(principles) + " |\n")
    out.append("|---" + "|---" * len(principles) + "|\n")
    for topic in sorted(by_topic_principle.keys()):
        row = [topic]
        for p in principles:
            count = by_topic_principle[topic].get(p, 0)
            row.append(str(count) if count else "")
        out.append("| " + " | ".join(row) + " |\n")

    out.append("\n## By Principle\n")
    by_principle: dict = defaultdict(list)
    for r in rows:
        by_principle[r["principle"]].append(r)
    for p in sorted(by_principle.keys()):
        out.append(f"\n### {p} ({len(by_principle[p])})\n\n")
        out.append("| Topic | Artifact | Tier | State | Essence |\n")
        out.append("|---|---|---|---|---|\n")
        for r in sorted(by_principle[p], key=lambda x: (x["topic"], x["artifact"])):
            essence = (r["essence"] or "—")[:80]
            out.append(f"| {r['topic']} | {r['artifact']} | {r['tier']} | {r['state']} | {essence} |\n")

    (DOC_OUT / "auto_research_inventory.md").write_text("".join(out), encoding="utf-8")


# ─── Main ──────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--topic", help="Restrict to one topic dir")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    rows = build_inventory(args.topic)
    write_json(rows)
    write_markdown(rows)

    if not args.quiet:
        totals = summarize_totals(rows)
        print(f"Inventoried {totals['artifacts']} artifacts across {totals['topics']} topics.")
        print(f"  with @identity essence: {totals['with_essence']}")
        print(f"  galleried: {totals['galleried']}")
        print()
        print("By generative principle:")
        for k, v in group_count(rows, "principle").items():
            print(f"  {k:14s} {v}")
        print()
        print("By curatorial state:")
        for k, v in group_count(rows, "state").items():
            print(f"  {k:14s} {v}")
        print()
        print(f"Wrote: doc/auto_research_inventory.json")
        print(f"       doc/auto_research_inventory.md")
        print(f"       ada_encyclopedia/public/research-map/inventory.json")


if __name__ == "__main__":
    main()
