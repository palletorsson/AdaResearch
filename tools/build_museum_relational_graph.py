#!/usr/bin/env python3
"""Build the endless museum's compact, typed relational graph.

The spine remains the only owner of 1D order. This graph adds branches without
inventing another order:

* related artifacts come from ``artifact_relations.json``;
* DNA runs come from the anchor's declared registry axes;
* synthesis works come from explicit ``[[token]]`` links in the synthesis
  artifact's registry relationship text;
* measured synthesis outcomes come from ``dna_synthesis.json`` and are recorded
  as space demand, not automatically multiplied into 205 six-metre stands.

The output is adjacency-shaped because the planner asks one question repeatedly:
"what belongs to this spine anchor, and what kind of space does it ask for?"
It is deterministic and intentionally compact (indent=1).
"""
from __future__ import annotations

import argparse
import glob
import json
import re
from collections import Counter
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parents[1]
ORDER = REPO / "commons/data/spine_artifact_order.json"
RELATIONS = REPO / "commons/data/artifact_relations.json"
SYNTHESIS = REPO / "commons/data/dna_synthesis.json"
OUT = REPO / "commons/data/museum_relational_graph.json"
SYNTHESIS_GALLERY = REPO / "commons/data/synthesis_gallery.json"

RELATION_RULES = {
    "named": {"grammar": "sightline", "priority": 0},
    "sibling": {"grammar": "even_row", "priority": 1},
    "axis_kin": {"grammar": "adjacent_comparison", "priority": 2},
    "family": {"grammar": "neighbourhood_padding", "priority": 3},
    "co_placed": {"grammar": "nearest_fill", "priority": 4},
}


def _read(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}


def _registry() -> dict[str, dict[str, Any]]:
    out: dict[str, dict[str, Any]] = {}
    for raw in sorted(glob.glob(str(REPO / "commons/artifacts/registry/*.json"))):
        data = _read(Path(raw))
        for token, entry in (data.get("artifacts") or {}).items():
            if isinstance(entry, dict):
                out[token] = entry
    return out


def _footprint(entry: dict[str, Any]) -> list[float]:
    raw = entry.get("footprint_measured") or entry.get("footprint")
    if isinstance(raw, list) and len(raw) >= 2:
        return [float(raw[0]), float(raw[-1])]
    measured = entry.get("measurements") or {}
    cells = measured.get("grid_cells") if isinstance(measured, dict) else None
    if isinstance(cells, list) and len(cells) >= 2:
        return [float(cells[0]), float(cells[1])]
    return [1.0, 1.0]


def _featured_synthesis() -> dict[str, dict[str, Any]]:
    """The five /synthesis-gallery cards from the project-owned manifest."""
    out: dict[str, dict[str, Any]] = {}
    for row in _read(SYNTHESIS_GALLERY).get("entries", []):
        token = str(row.get("token", ""))
        if not token:
            continue
        out[token] = {
            "gallery_id": str(row.get("gallery_id", "")),
            "image": str(row.get("image", "")),
            "config": dict(row.get("config") or {}),
        }
    return out


def _wiki_tokens(text: str) -> list[str]:
    return sorted(set(re.findall(r"\[\[([A-Za-z0-9_]+)(?:\|[^\]]+)?\]\]", text)))


def build() -> dict[str, Any]:
    registry = _registry()
    order_rows = _read(ORDER).get("order", [])
    relation_rows = _read(RELATIONS).get("artifacts", {})
    verdicts = _read(SYNTHESIS).get("verdicts", {})
    featured = _featured_synthesis()

    order: list[str] = []
    order_meta: dict[str, dict[str, Any]] = {}
    for row in order_rows:
        token = str(row.get("lookup", ""))
        if not token or token in order_meta:
            continue
        order_meta[token] = {
            "index": len(order),
            "sequence": str(row.get("sequence", "")),
            "map": str(row.get("map", "")),
        }
        order.append(token)

    synthesis_sources: dict[str, list[str]] = {}
    for token, entry in registry.items():
        if str(entry.get("artifact_type", "")) != "synthesis" and token not in featured:
            continue
        links = [t for t in _wiki_tokens(str(entry.get("relationships", ""))) if t in registry]
        synthesis_sources[token] = links

    # One canonical owner per synthesis work: its earliest explicitly named
    # source on the spine. Other named sources remain cross-links, but do not
    # cause duplicate placement of the same large work.
    synth_owner: dict[str, str] = {}
    for token, sources in synthesis_sources.items():
        candidates = [s for s in sources if s in order_meta]
        if candidates:
            synth_owner[token] = min(candidates, key=lambda s: order_meta[s]["index"])

    nodes: dict[str, dict[str, Any]] = {}

    def add_node(token: str, kind: str = "artifact", config: dict[str, Any] | None = None) -> None:
        if token in nodes:
            # A token may first appear as somebody else's relative and only
            # later arrive at its own canonical spine position. Canonical
            # membership is stronger and must not depend on traversal order.
            if kind == "spine_artifact":
                nodes[token]["kind"] = kind
            if config:
                nodes[token]["config"] = config
            return
        entry = registry.get(token, {})
        dna = entry.get("dna") or {}
        axes = dna.get("axes") if isinstance(dna, dict) else {}
        if kind not in ("spine_artifact", "synthesis_artifact", "measured_synthesis") and axes:
            kind = "dna_artifact"
        tags = ([str(t) for t in entry.get("tags", [])]
                if isinstance(entry.get("tags"), list) else [])
        nodes[token] = {
            "kind": kind,
            "scene": str(entry.get("scene", "")),
            "category": str(entry.get("category", "")),
            "footprint_xz": _footprint(entry),
            **({"dna_axes": sorted(axes)} if axes else {}),
            **({"galleries": sorted(t for t in tags if "gallery" in t)}
               if any("gallery" in t for t in tags) else {}),
            **({"config": config} if config else {}),
        }

    graph: dict[str, dict[str, Any]] = {}
    edge_counts: Counter[str] = Counter()
    demand_counts: Counter[str] = Counter()

    for anchor in order:
        add_node(anchor, "spine_artifact")
        rel_entry = relation_rows.get(anchor) or {}
        relations: list[dict[str, Any]] = []
        chosen_kinds: set[str] = set()
        chosen = 0
        for rel in rel_entry.get("relations", []):
            token = str(rel.get("token", ""))
            kind = str(rel.get("kind", ""))
            if not token or kind not in RELATION_RULES:
                continue
            add_node(token, "related_artifact")
            auto = chosen < 2 and kind not in chosen_kinds
            if auto:
                chosen += 1
                chosen_kinds.add(kind)
            relations.append({
                "to": token,
                "type": kind,
                "why": str(rel.get("why", "")),
                "evidence": {"placements_together": int(rel.get("placements_together", 0))},
                "space": RELATION_RULES[kind]["grammar"],
                "auto_place": auto,
            })
            edge_counts[kind] += 1
            if auto:
                demand_counts[RELATION_RULES[kind]["grammar"]] += 1

        dna_runs: list[dict[str, Any]] = []
        axes = rel_entry.get("axes") or {}
        if isinstance(axes, dict) and axes:
            # Current museum rule: the widest declared argument gets one wall
            # run. All other axes stay visible in the node, not silently staged.
            axis, values = max(sorted(axes.items()), key=lambda kv: len(kv[1]))
            vals = list(values)[:6]
            if len(vals) >= 2:
                dna_runs.append({
                    "axis": axis,
                    "values": vals,
                    "type": "dna_variant",
                    "space": "wall_series",
                    "auto_place": True,
                    "overflow_values": max(0, len(values) - len(vals)),
                })
                edge_counts["dna_variant"] += len(vals)
                demand_counts["wall_series"] += 1

        synthesis: list[dict[str, Any]] = []
        verdict = verdicts.get(anchor)
        if isinstance(verdict, dict):
            virtual = f"synthesis_stand#subject={anchor}"
            nodes[virtual] = {
                "kind": "measured_synthesis",
                "scene": registry.get("synthesis_stand", {}).get("scene", ""),
                "category": "synthesis",
                "footprint_xz": _footprint(registry.get("synthesis_stand", {})),
                "config": {"subject": anchor, "mode": str(verdict.get("verdict", "auto"))},
            }
            synthesis.append({
                "to": virtual,
                "type": "measured_synthesis",
                "verdict": str(verdict.get("verdict", "")),
                "gallery": str(verdict.get("gallery", "")),
                "space": "culmination_bay",
                "auto_place": False,
                "why": "measured DNA verdict; registered as demand, not multiplied into every chapter",
            })
            edge_counts["measured_synthesis"] += 1
            demand_counts["culmination_bay_pending"] += 1

        for synth, sources in sorted(synthesis_sources.items()):
            if anchor not in sources:
                continue
            add_node(synth, "synthesis_artifact", featured.get(synth, {}).get("config"))
            auto = synth in featured and synth_owner.get(synth) == anchor
            synthesis.append({
                "to": synth,
                "type": "synthesis_outcome",
                "space": "synthesis_bay",
                "auto_place": auto,
                "featured": synth in featured,
                "why": "the synthesis artifact explicitly names this source in its registry relationships",
            })
            edge_counts["synthesis_outcome"] += 1
            if auto:
                demand_counts["synthesis_bay"] += 1

        graph[anchor] = {
            **order_meta[anchor],
            "relations": relations,
            "dna_runs": dna_runs,
            "synthesis": synthesis,
            "space_requests": sum(1 for r in relations if r["auto_place"])
                              + len(dna_runs)
                              + sum(1 for r in synthesis if r["auto_place"]),
        }

    # The relation file predates a fast-moving tail of promoted DNA artifacts.
    # Include every declared family so absence is visible. When its registry
    # relationship text explicitly names a spine artifact, add a provenance-
    # carrying cross-link; do not auto-place it until the normal relation build
    # ranks it against the rest of that anchor's neighbourhood.
    linked_dna: set[str] = set()
    for row in graph.values():
        linked_dna.update(str(r.get("to", "")) for r in row["relations"])
    for token, entry in sorted(registry.items()):
        dna = entry.get("dna") or {}
        axes = dna.get("axes") if isinstance(dna, dict) else {}
        if not axes:
            continue
        add_node(token, "dna_artifact")
        for source in _wiki_tokens(str(entry.get("relationships", ""))):
            if source not in graph:
                continue
            if any(r.get("to") == token for r in graph[source]["relations"]):
                linked_dna.add(token)
                continue
            graph[source]["relations"].append({
                "to": token,
                "type": "registry_named",
                "why": "the DNA artifact's registry relationships explicitly name this spine source",
                "evidence": {"source": "registry.relationships"},
                "space": "sightline_pending",
                "auto_place": False,
            })
            linked_dna.add(token)
            edge_counts["registry_named"] += 1

    dna_tokens = {t for t, n in nodes.items() if n.get("dna_axes")}
    linked_dna.update(t for t in dna_tokens if t in order_meta)

    return {
        "schema": "adaresearch.museum_relational_graph.v1",
        "_readme": ("The canonical spine owns order. Typed branches request space; auto_place "
                    "is a bounded curation decision, while false requests remain visible backlog. "
                    "DNA variants are wall-series demands, not duplicate floor objects."),
        "sources": {
            "order": str(ORDER.relative_to(REPO)).replace("\\", "/"),
            "relations": str(RELATIONS.relative_to(REPO)).replace("\\", "/"),
            "dna_synthesis": str(SYNTHESIS.relative_to(REPO)).replace("\\", "/"),
            "synthesis_gallery": str(SYNTHESIS_GALLERY.relative_to(REPO)).replace("\\", "/"),
        },
        "counts": {
            "spine_nodes": len(order),
            "nodes": len(nodes),
            "edges_by_type": dict(sorted(edge_counts.items())),
            "space_requests_by_grammar": dict(sorted(demand_counts.items())),
            "featured_synthesis": len(featured),
            "featured_synthesis_owned": sum(1 for s in featured if s in synth_owner),
            "dna_artifacts": len(dna_tokens),
            "dna_artifacts_linked": len(dna_tokens & linked_dna),
            "dna_artifacts_unassigned": len(dna_tokens - linked_dna),
        },
        "space_rules": {
            **{k: v["grammar"] for k, v in RELATION_RULES.items()},
            "dna_variant": "wall_series",
            "registry_named": "sightline_pending",
            "synthesis_outcome": "synthesis_bay",
            "measured_synthesis": "culmination_bay_pending",
        },
        "order": order,
        "nodes": nodes,
        "artifacts": graph,
    }


def validate(data: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    order = data.get("order") or []
    graph = data.get("artifacts") or {}
    nodes = data.get("nodes") or {}
    if len(order) != 799:
        errors.append(f"canonical order has {len(order)} nodes, expected 799")
    if len(set(order)) != len(order):
        errors.append("canonical order contains duplicates")
    for anchor in order:
        if anchor not in graph:
            errors.append(f"missing anchor row: {anchor}")
            continue
        for group in ("relations", "synthesis"):
            for edge in graph[anchor].get(group, []):
                if edge.get("to") not in nodes:
                    errors.append(f"orphan edge {anchor} -> {edge.get('to')}")
        for run in graph[anchor].get("dna_runs", []):
            if len(run.get("values", [])) < 2:
                errors.append(f"degenerate DNA run: {anchor}.{run.get('axis')}")
    return errors


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="validate the existing output")
    ap.add_argument("--out", default=str(OUT))
    args = ap.parse_args()
    path = Path(args.out)
    data = _read(path) if args.check else build()
    errors = validate(data)
    if not args.check:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(data, indent=1) + "\n", encoding="utf-8")
    counts = data.get("counts") or {}
    print(f"spine {counts.get('spine_nodes', 0)} · nodes {counts.get('nodes', 0)}")
    print(f"edges {counts.get('edges_by_type', {})}")
    print(f"space {counts.get('space_requests_by_grammar', {})}")
    if errors:
        for error in errors[:30]:
            print(f"ERROR {error}")
        return 1
    print(f"OK {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
