#!/usr/bin/env python
"""atlas_sequence_alignment.py — does each sequence's actual map content match
its declared edge journey?

Answers the heavy question: *what does the atlas mean for sequences and maps?*

For every sequence:
  1. Look up the edges it claims to teach (from EDGES_OF_ALGORITHM.md
     "Sequence home." lines).
  2. Walk every map in the sequence. Extract the artifacts placed in each.
  3. Compute the map's centroid in embedding space (mean of artifact vectors).
  4. Find the edge nearest to that centroid in the same projection.
  5. Score: does the map's centroid-edge match any of the sequence's declared
     edges?

Outputs:
  doc/atlas/sequence_alignment.json   — per-sequence + per-map alignment data
  doc/atlas/mishomed_artifacts.json   — artifacts whose edge cluster differs
                                          from their map's sequence intent

Console summary:
  scoreboard of sequences by alignment %, list of maps that drift, top-N
  mis-homed artifacts.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path

import numpy as np

REPO = Path(__file__).resolve().parent.parent
EMBED_DIR = REPO / "doc" / "atlas"
EDGES_DOC = REPO / "doc" / "EDGES_OF_ALGORITHM.md"
SEQUENCES_DIR = REPO / "commons" / "maps" / "sequences"
MAPS_DIR = REPO / "commons" / "maps"

OUT_ALIGNMENT = EMBED_DIR / "sequence_alignment.json"
OUT_MISHOMED = EMBED_DIR / "mishomed_artifacts.json"

EDGE_LETTERS = list("ABCDEFGHIJKLM")

# Cross-cutting UI / infrastructure artifacts that appear in many maps
# regardless of edge intent. They pollute alignment scoring because they
# carry vocabulary about "panel", "display", "tutorial", etc. that lands
# on edges (often M for tutorial text) unrelated to the map's teaching.
# Excluded from per-map centroid + mis-home counts but still kept in the
# atlas projection.
INFRASTRUCTURE_ARTIFACTS = {
    "tt",                       # tutorial-text panel
    "code_display",
    "science_screen",
    "ca_screen",
    "clipboard",
    "vr_map_loader_kiosk",
    "monitorsystem",
    "catalyst_target",
    "catalyst_pedestal",
    "spawn_marker",
    "fps_counter",
    "menu_panel",
}


def load_edge_sequence_homes() -> dict[str, list[str]]:
    """Parse EDGES_OF_ALGORITHM.md → {edge_letter: [sequence_name, ...]}."""
    raw = EDGES_DOC.read_text(encoding="utf-8")
    out: dict[str, list[str]] = {}
    pattern = re.compile(
        r"^## ([A-M])\..*?\*\*Sequence home\.\*\*\s*(.+?)$",
        re.MULTILINE | re.DOTALL,
    )
    for m in pattern.finditer(raw):
        letter = m.group(1)
        line = m.group(2).split("\n")[0]
        # Lines like "`foundationscrisis`." or "`a` / `b`, paired with X."
        homes = re.findall(r"`([a-z_]+)`", line)
        out[letter] = homes
    return out


def edges_for_sequence(edge_homes: dict[str, list[str]]) -> dict[str, list[str]]:
    """Invert: {sequence_name: [edge_letter, ...]}."""
    out: dict[str, list[str]] = defaultdict(list)
    for letter, homes in edge_homes.items():
        for h in homes:
            if letter not in out[h]:
                out[h].append(letter)
    return dict(out)


def load_sequence_map_lists() -> dict[str, list[str]]:
    """Read every sequence JSON; return {sequence_name: [map_lookup_name, ...]}."""
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
            map_names = [
                m if isinstance(m, str) else m.get("lookup_name", m.get("name", ""))
                for m in maps
            ]
            map_names = [n for n in map_names if n]
            if map_names:
                out[seq_name] = map_names
    return out


def extract_artifacts_from_map(map_dir: Path) -> list[str]:
    """Parse map_data.json's interactables grid for artifact lookup_names."""
    md_path = map_dir / "map_data.json"
    if not md_path.exists():
        return []
    try:
        data = json.loads(md_path.read_text(encoding="utf-8"))
    except Exception:
        return []
    inter = data.get("layers", {}).get("interactables", [])
    arts = set()
    for row in inter:
        if not isinstance(row, list):
            continue
        for cell in row:
            if isinstance(cell, str):
                cell = cell.strip()
                if not cell or cell == " ":
                    continue
                base = cell.split(":")[0]
                if base and not base.isdigit():
                    arts.add(base)
    return sorted(arts)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sequences", nargs="*",
                    help="Restrict to specific sequence names; default = all.")
    args = ap.parse_args()

    if not (EMBED_DIR / "artifact_embeddings.npz").exists():
        print("ERROR: run tools/artifact_embed.py first")
        sys.exit(1)

    # Load embeddings + edge assignments from atlas_report.
    npz = np.load(EMBED_DIR / "artifact_embeddings.npz", allow_pickle=True)
    art_ids: list[str] = list(npz["ids"])
    art_vec: np.ndarray = npz["vectors"]
    art_index = {name: i for i, name in enumerate(art_ids)}

    # Re-derive edge anchors in the same TF-IDF+SVD space the atlas used.
    # Easier: reuse the saved per-artifact edge assignment from atlas_report.
    if not (EMBED_DIR / "atlas_report.json").exists():
        print("ERROR: run tools/artifact_atlas.py first to produce atlas_report.json")
        sys.exit(1)
    atlas_report = json.loads((EMBED_DIR / "atlas_report.json").read_text(encoding="utf-8"))
    # We need per-artifact edge — recompute here using the same projection
    # logic. Easier path: re-import the atlas script's logic. Cheaper still:
    # rerun a tiny subset from saved data.
    # For simplicity and accuracy, re-derive using the embeddings we already
    # have and the edge anchors we'll re-embed cheaply.

    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.decomposition import TruncatedSVD
    from sklearn.preprocessing import normalize

    cards = json.loads((EMBED_DIR / "artifact_cards.json").read_text(encoding="utf-8"))
    all_cards = [c["card"] for c in cards]
    edge_cards = []
    for L in EDGE_LETTERS:
        section_pattern = rf"^## {re.escape(L)}\.\s.*?(?=^## [A-M]\.|\Z)"
        m = re.search(section_pattern, EDGES_DOC.read_text(encoding="utf-8"),
                      re.MULTILINE | re.DOTALL)
        section = m.group(0) if m else f"edge {L}"
        edge_cards.append(f"edge {L} | " + re.sub(r"^#+\s.*$", "", section,
                                                   flags=re.MULTILINE)[:1500])
    vec = TfidfVectorizer(analyzer="word", ngram_range=(1, 2), min_df=2,
                          max_df=0.85, sublinear_tf=True,
                          token_pattern=r"(?u)\b[A-Za-z][A-Za-z_-]+\b")
    X = vec.fit_transform(all_cards + edge_cards)
    n_components = min(128, X.shape[1] - 1, X.shape[0] - 1)
    svd = TruncatedSVD(n_components=n_components, random_state=42)
    Z = normalize(svd.fit_transform(X), norm="l2")
    art_vec_joint = Z[:len(all_cards)]
    edge_vec_joint = Z[len(all_cards):]
    sim = art_vec_joint @ edge_vec_joint.T  # cosine
    art_edge_idx = np.argmax(sim, axis=1)
    art_to_edge = {art_ids[i]: EDGE_LETTERS[art_edge_idx[i]] for i in range(len(art_ids))}

    edge_homes = load_edge_sequence_homes()
    seq_to_edges = edges_for_sequence(edge_homes)
    seq_to_maps = load_sequence_map_lists()
    print(f"[align] {len(seq_to_maps)} sequences, "
          f"{len(seq_to_edges)} have declared edges in EDGES_OF_ALGORITHM.md")

    target_seqs = args.sequences or sorted(seq_to_edges.keys())

    # Per-sequence + per-map alignment.
    sequence_results = {}
    mishomed: list[dict] = []

    for seq_name in target_seqs:
        declared_edges = seq_to_edges.get(seq_name, [])
        if not declared_edges:
            continue
        maps = seq_to_maps.get(seq_name, [])
        map_results = []
        seq_centroids = []
        seq_aligned_count = 0
        seq_total_count = 0

        for map_name in maps:
            map_dir = MAPS_DIR / map_name
            if not map_dir.exists():
                continue
            arts = extract_artifacts_from_map(map_dir)
            # Keep only artifacts we have embeddings for AND that aren't
            # cross-cutting infrastructure (UI / scaffold).
            arts_in_atlas = [
                a for a in arts
                if a in art_index and a not in INFRASTRUCTURE_ARTIFACTS
            ]
            if not arts_in_atlas:
                map_results.append({
                    "map": map_name, "artifacts": arts,
                    "in_atlas": 0,
                    "centroid_edge": None,
                    "aligned": False,
                    "note": "no artifacts found in atlas embeddings",
                })
                continue
            # Map centroid in joint-projection space.
            indices = [art_index[a] for a in arts_in_atlas]
            centroid = np.mean(art_vec_joint[indices], axis=0)
            centroid /= max(np.linalg.norm(centroid), 1e-9)
            sim_to_edges = centroid @ edge_vec_joint.T
            best_edge_idx = int(np.argmax(sim_to_edges))
            best_edge = EDGE_LETTERS[best_edge_idx]
            best_sim = float(sim_to_edges[best_edge_idx])
            aligned = best_edge in declared_edges
            seq_centroids.append(centroid)
            seq_total_count += 1
            if aligned:
                seq_aligned_count += 1
            # Per-artifact edge assignment within this map.
            artifact_edges = [
                {"id": a, "edge": art_to_edge[a],
                 "in_target": art_to_edge[a] in declared_edges}
                for a in arts_in_atlas
            ]
            map_results.append({
                "map": map_name,
                "n_artifacts_total": len(arts),
                "n_artifacts_in_atlas": len(arts_in_atlas),
                "centroid_edge": best_edge,
                "centroid_sim": round(best_sim, 3),
                "aligned": aligned,
                "declared_edges": declared_edges,
                "artifact_edges": artifact_edges,
            })
            # Mis-homed artifacts: artifact's edge ≠ any declared edge for the
            # sequence its map sits in.
            for ae in artifact_edges:
                if not ae["in_target"]:
                    mishomed.append({
                        "artifact": ae["id"],
                        "artifact_edge": ae["edge"],
                        "map": map_name,
                        "sequence": seq_name,
                        "sequence_edges": declared_edges,
                    })

        # Sequence-level centroid + alignment %.
        seq_pct = (seq_aligned_count / seq_total_count * 100
                   if seq_total_count > 0 else 0.0)
        if seq_centroids:
            seq_centroid = np.mean(seq_centroids, axis=0)
            seq_centroid /= max(np.linalg.norm(seq_centroid), 1e-9)
            seq_sim = seq_centroid @ edge_vec_joint.T
            seq_centroid_edge = EDGE_LETTERS[int(np.argmax(seq_sim))]
        else:
            seq_centroid_edge = None
        sequence_results[seq_name] = {
            "declared_edges": declared_edges,
            "n_maps": len(maps),
            "n_maps_evaluated": seq_total_count,
            "alignment_pct": round(seq_pct, 1),
            "sequence_centroid_edge": seq_centroid_edge,
            "centroid_in_target": (seq_centroid_edge in declared_edges
                                   if seq_centroid_edge else False),
            "maps": map_results,
        }

    OUT_ALIGNMENT.write_text(
        json.dumps({"sequences": sequence_results}, indent=2),
        encoding="utf-8")
    OUT_MISHOMED.write_text(
        json.dumps({"count": len(mishomed), "items": mishomed[:200]}, indent=2),
        encoding="utf-8")

    # Console scoreboard.
    print()
    print("═" * 78)
    print(" SEQUENCE ALIGNMENT — does each sequence teach the edges it claims?")
    print("═" * 78)
    print(f" {'sequence':<26} {'declared':<12} {'centroid':<10}"
          f"{'alignment':<12} {'maps'}")
    print(" " + "─" * 76)
    for seq_name in sorted(sequence_results.keys(),
                            key=lambda s: sequence_results[s]["alignment_pct"]):
        r = sequence_results[seq_name]
        decl = ",".join(r["declared_edges"])
        cent = r["sequence_centroid_edge"] or "-"
        cent_marker = " ✓" if r["centroid_in_target"] else " ✗"
        align = f"{r['alignment_pct']:.0f}%"
        print(f" {seq_name:<26} {decl:<12} {cent}{cent_marker:<8}"
              f"{align:<12} {r['n_maps_evaluated']}/{r['n_maps']}")
    print(" " + "─" * 76)
    print()
    print(f" Mis-homed artifacts: {len(mishomed)} (artifact's cluster ≠ map's sequence)")
    if mishomed:
        # Top mis-homed targets.
        from collections import Counter
        c = Counter((m["sequence"], m["artifact_edge"]) for m in mishomed)
        for (seq, edge), n in c.most_common(10):
            print(f"  {seq:<26} → {n:>3} artifacts cluster on edge {edge}")
    print()
    print(f" Wrote {OUT_ALIGNMENT.relative_to(REPO)}")
    print(f" Wrote {OUT_MISHOMED.relative_to(REPO)}")


if __name__ == "__main__":
    main()
