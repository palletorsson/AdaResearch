#!/usr/bin/env python
"""atlas_stub_proposer.py — for each stub map (≤N artifacts), use the
embedding atlas to propose nearest-cousin artifacts that would anchor it.

The map has 1-2 artifacts. The atlas has 1709 artifacts in semantic space.
For each existing artifact in the stub, find its top-K nearest neighbours
that aren't already in the map. The union of those neighbours = the
suggested anchoring queue.

Output:
  doc/atlas/stub_proposals.json — per-stub-map proposed artifact additions

This is the placement proposer in its smallest form. Doesn't write any
map_data.json edits; only generates an inspection-ready queue. The
human reviews + accepts + the next session applies.

Usage:
  python tools/atlas_stub_proposer.py
  python tools/atlas_stub_proposer.py --max-arts 3 --neighbours 5
  python tools/atlas_stub_proposer.py --sequence joints
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

import numpy as np

REPO = Path(__file__).resolve().parent.parent
EMBED_DIR = REPO / "doc" / "atlas"
MAPS_DIR = REPO / "commons" / "maps"
SEQUENCES_DIR = REPO / "commons" / "maps" / "sequences"

OUT = EMBED_DIR / "stub_proposals.json"

# Late-spine sequences (defined in EDGES_OF_ALGORITHM.md as edge homes).
LATE_SPINE_SEQUENCES = {
    "foundationscrisis", "searchpathfinding", "machinelearning",
    "criticalalgorithms", "postfoundationscrisis", "bodyprogression",
    "joints", "qfeplaboratory",
}

# Cross-cutting UI that shouldn't count as "anchoring artifacts".
INFRASTRUCTURE_ARTIFACTS = {
    "tt", "code_display", "science_screen", "ca_screen", "clipboard",
    "vr_map_loader_kiosk", "monitorsystem", "catalyst_target",
    "catalyst_pedestal", "spawn_marker", "fps_counter", "menu_panel",
}


def extract_artifacts_from_map(map_dir: Path) -> list[str]:
    p = map_dir / "map_data.json"
    if not p.exists():
        return []
    try:
        d = json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return []
    inter = d.get("layers", {}).get("interactables", [])
    arts = set()
    for row in inter:
        if not isinstance(row, list):
            continue
        for cell in row:
            if isinstance(cell, str):
                cell = cell.strip()
                if cell and cell != " ":
                    base = cell.split(":")[0]
                    if base and not base.isdigit():
                        arts.add(base)
    return sorted(arts)


def load_sequence_maps() -> dict[str, list[str]]:
    out: dict[str, list[str]] = {}
    for path in sorted(SEQUENCES_DIR.glob("*.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            continue
        seqs = data.get("sequences")
        if not isinstance(seqs, dict):
            seqs = {path.stem: data}
        for seq_name, seq_data in seqs.items():
            if not isinstance(seq_data, dict):
                continue
            maps = seq_data.get("maps", []) or seq_data.get("map_order", [])
            names = [m if isinstance(m, str) else m.get("lookup_name", m.get("name", "")) for m in maps]
            names = [n for n in names if n]
            if names:
                out[seq_name] = names
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--max-arts", type=int, default=2,
                    help="A map is considered a stub if it has ≤ this many "
                         "non-infrastructure artifacts (default 2)")
    ap.add_argument("--neighbours", type=int, default=6,
                    help="Top-K nearest atlas neighbours per existing artifact (default 6)")
    ap.add_argument("--sequence", help="Restrict to one sequence")
    args = ap.parse_args()

    if not (EMBED_DIR / "artifact_embeddings.npz").exists():
        print("ERROR: run tools/artifact_embed.py first")
        sys.exit(1)

    npz = np.load(EMBED_DIR / "artifact_embeddings.npz", allow_pickle=True)
    ids: list[str] = list(npz["ids"])
    families: list[str] = list(npz["families"])
    vectors: np.ndarray = npz["vectors"]   # already L2-normalised
    art_index = {name: i for i, name in enumerate(ids)}

    seq_maps = load_sequence_maps()
    target_seqs = ([args.sequence] if args.sequence
                    else sorted(LATE_SPINE_SEQUENCES & set(seq_maps.keys())))

    proposals: dict[str, list[dict]] = {}

    for seq_name in target_seqs:
        for map_name in seq_maps.get(seq_name, []):
            map_dir = MAPS_DIR / map_name
            if not map_dir.exists():
                continue
            arts = extract_artifacts_from_map(map_dir)
            arts_meaningful = [a for a in arts if a not in INFRASTRUCTURE_ARTIFACTS]
            if len(arts_meaningful) > args.max_arts:
                continue  # not a stub

            existing_in_atlas = [a for a in arts_meaningful if a in art_index]
            if not existing_in_atlas:
                # No anchor to propose from. Note it but skip.
                proposals.setdefault(seq_name, []).append({
                    "map": map_name,
                    "existing": arts_meaningful,
                    "note": "no existing artifacts in atlas — cannot propose neighbours",
                    "proposals": [],
                })
                continue

            # For each existing artifact, find its top-K atlas neighbours.
            existing_set = set(arts_meaningful)
            cousin_scores: dict[str, dict] = {}  # candidate id → {sim, src}
            for anchor in existing_in_atlas:
                anchor_vec = vectors[art_index[anchor]]
                sims = vectors @ anchor_vec
                # Sort descending; skip self + already-present + infrastructure.
                top = np.argsort(-sims)
                taken = 0
                for j in top:
                    if taken >= args.neighbours:
                        break
                    cand = ids[j]
                    if cand == anchor or cand in existing_set:
                        continue
                    if cand in INFRASTRUCTURE_ARTIFACTS:
                        continue
                    if cand in cousin_scores:
                        # Already proposed by another anchor — boost score.
                        cousin_scores[cand]["sim"] = max(cousin_scores[cand]["sim"], float(sims[j]))
                        cousin_scores[cand]["src"].append(anchor)
                    else:
                        cousin_scores[cand] = {
                            "sim": float(sims[j]),
                            "family": families[j],
                            "src": [anchor],
                        }
                    taken += 1

            # Rank proposals by sim descending; cap at 8.
            ranked = sorted(cousin_scores.items(), key=lambda kv: -kv[1]["sim"])[:8]
            proposals.setdefault(seq_name, []).append({
                "map": map_name,
                "existing": arts_meaningful,
                "proposals": [
                    {
                        "id": cand,
                        "family": data["family"],
                        "sim": round(data["sim"], 3),
                        "anchor": data["src"][0],
                    }
                    for cand, data in ranked
                ],
            })

    OUT.write_text(json.dumps({"sequences": proposals}, indent=2), encoding="utf-8")

    # Console report.
    print("═" * 78)
    print(" STUB-MAP ANCHORING PROPOSALS")
    print("═" * 78)
    total_stubs = 0
    for seq_name, stubs in proposals.items():
        if not stubs:
            continue
        print(f"\n {seq_name}  ({len(stubs)} stub maps)")
        print(" " + "─" * 76)
        for stub in stubs:
            total_stubs += 1
            print(f"  {stub['map']}")
            print(f"     existing: {stub['existing']}")
            if not stub.get("proposals"):
                print(f"     {stub.get('note', '(no proposals)')}")
                continue
            print(f"     propose:")
            for p in stub["proposals"][:6]:
                print(f"        {p['id']:<36} ({p['family']:<20})  sim {p['sim']:.3f}")
    print()
    print(f" {total_stubs} stub maps proposed across {len(proposals)} sequences")
    print(f" wrote {OUT.relative_to(REPO)}")


if __name__ == "__main__":
    main()
