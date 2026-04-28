#!/usr/bin/env python
"""artifact_atlas.py — project artifact embeddings to 2D and render the atlas.

Reads doc/atlas/artifact_embeddings.npz and:
  1. Embeds each of the 13 edges (A-M) using the SAME TF-IDF pipeline so
     edges live in the same space as artifacts. Each edge's "card" is its
     section text from doc/EDGES_OF_ALGORITHM.md.
  2. Assigns every artifact to its closest edge by cosine similarity.
  3. Counts artifacts per edge → MISSING report.
  4. Projects all 528 artifacts + 13 edge anchors to 2D via PCA.
  5. Renders an SVG atlas: artifacts as coloured dots (by family), edges
     as labelled crosshairs (with count + "missing" if zero anchors).
  6. Writes JSON report:
       doc/atlas/atlas_report.json     — counts, missing edges, top-N per edge

Output:
  doc/atlas/atlas.svg
  doc/atlas/atlas_report.json
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

import numpy as np
from sklearn.decomposition import PCA, TruncatedSVD
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import normalize

REPO = Path(__file__).resolve().parent.parent
EMBED_DIR = REPO / "doc" / "atlas"
EDGES_DOC = REPO / "doc" / "EDGES_OF_ALGORITHM.md"
SVG_PATH = EMBED_DIR / "atlas.svg"
REPORT_PATH = EMBED_DIR / "atlas_report.json"

EDGE_LETTERS = list("ABCDEFGHIJKLM")

# Fixed colour per family. Falls back to a hash colour for any registry not
# in this list — keeps the atlas legible.
FAMILY_COLORS = {
    "primitives":             "#7a7a7a",
    "color":                  "#d8a04b",
    "cellular_automata":      "#3da3a3",
    "fractals":               "#7148a8",
    "lsystems":               "#5fa14a",
    "randomness":             "#b94a4a",
    "machinelearning":        "#3b6cb0",
    "machinelearning_extra":  "#3b6cb0",
    "physics_simulation":     "#9b6f3a",
    "wavefunctions":          "#c557a3",
    "transforms":             "#aa6a3b",
    "topology":               "#5a8a52",
    "lab":                    "#90786b",
    "qfep":                   "#d23b6e",
    "hazards":                "#d65a3a",
    "computational_biology":  "#4ba17b",
    "neuroscience":           "#7c3aa1",
    "alternative_geometries": "#43678f",
    "datastructures":         "#9b9032",
    "foundations":            "#2b6788",
    "isosurfaces":            "#cf8a3d",
    "parametric":             "#a04a87",
    "grammar_systems":        "#3aa180",
    "mesh_grammar":           "#cc5040",
    "living_paper":           "#83b54d",
    "nature_system":          "#3da353",
    "grid2d":                 "#7d8b91",
    "grid3d":                 "#56666b",
    "panel_bridge":           "#999999",
    "gallery_preview":        "#bbbbbb",
    "furniture":              "#856b48",
    "arrays":                 "#5b8089",
    "bar_array":              "#5b8089",
    "chaos":                  "#a83a3a",
    "algorithms_misc":        "#7d7d7d",
    "commons_artifacts":      "#666666",
}


def family_color(family: str) -> str:
    if family in FAMILY_COLORS:
        return FAMILY_COLORS[family]
    h = hash(family) & 0xFFFFFF
    return f"#{h:06x}"


def extract_edge_section(edge_letter: str) -> str:
    raw = EDGES_DOC.read_text(encoding="utf-8")
    pattern = rf"^## {re.escape(edge_letter)}\.\s.*?(?=^## [A-M]\.|\Z)"
    m = re.search(pattern, raw, re.MULTILINE | re.DOTALL)
    return m.group(0).strip() if m else ""


def load_artifact_data() -> tuple[np.ndarray, np.ndarray, np.ndarray, list[dict]]:
    npz = np.load(EMBED_DIR / "artifact_embeddings.npz", allow_pickle=True)
    cards = json.loads((EMBED_DIR / "artifact_cards.json").read_text(encoding="utf-8"))
    return npz["ids"], npz["families"], npz["vectors"], cards


def main():
    ap = argparse.ArgumentParser(description="Project artifact embeddings to 2D atlas.")
    ap.add_argument("--width", type=int, default=1600)
    ap.add_argument("--height", type=int, default=1000)
    args = ap.parse_args()

    ids, families, vectors, cards = load_artifact_data()
    print(f"[atlas] loaded {len(ids)} artifact embeddings ({vectors.shape})")

    # ── 1. Re-embed edges in the SAME TF-IDF space ──────────────────────
    # We re-fit on the union of artifact cards + edge texts so the two live
    # in one vocabulary and SVD basis. This is small enough (~13 extra
    # rows) that re-fitting is cheap.
    all_cards: list[str] = [c["card"] for c in cards]
    edge_cards: list[str] = []
    for L in EDGE_LETTERS:
        section = extract_edge_section(L)
        if not section:
            edge_cards.append(f"edge {L}")
            continue
        # Strip markdown headers so they don't dominate TF-IDF.
        clean = re.sub(r"^#+\s.*$", "", section, flags=re.MULTILINE)
        edge_cards.append(f"edge {L} | " + clean[:1500])

    vec = TfidfVectorizer(
        analyzer="word", ngram_range=(1, 2), min_df=2, max_df=0.85,
        sublinear_tf=True,
        token_pattern=r"(?u)\b[A-Za-z][A-Za-z_-]+\b",
    )
    X = vec.fit_transform(all_cards + edge_cards)
    n_components = min(128, X.shape[1] - 1, X.shape[0] - 1)
    svd = TruncatedSVD(n_components=n_components, random_state=42)
    Z = normalize(svd.fit_transform(X), norm="l2")
    art_vec = Z[:len(all_cards)]
    edge_vec = Z[len(all_cards):]
    print(f"[atlas] joint embedding: {Z.shape}, SVD var={svd.explained_variance_ratio_.sum():.3f}")

    # ── 2. Cosine similarity → assign each artifact to closest edge ─────
    # Vectors are L2-normalised so dot product == cosine similarity.
    sim = art_vec @ edge_vec.T  # (N_artifacts, 13)
    closest_edge_idx = np.argmax(sim, axis=1)
    closest_edge_score = np.max(sim, axis=1)

    # ── 3. Counts per edge + MISSING ────────────────────────────────────
    edge_counts: dict[str, int] = {L: 0 for L in EDGE_LETTERS}
    edge_top_artifacts: dict[str, list[tuple[str, float]]] = {L: [] for L in EDGE_LETTERS}
    edge_assignment: list[str] = []
    for i, ei in enumerate(closest_edge_idx):
        L = EDGE_LETTERS[ei]
        edge_assignment.append(L)
        edge_counts[L] += 1
        edge_top_artifacts[L].append((ids[i], float(closest_edge_score[i])))
    for L in EDGE_LETTERS:
        edge_top_artifacts[L].sort(key=lambda x: -x[1])
        edge_top_artifacts[L] = edge_top_artifacts[L][:8]

    # ── 4. Project to 2D and 3D ─────────────────────────────────────────
    pca = PCA(n_components=2, random_state=42)
    XY = pca.fit_transform(np.vstack([art_vec, edge_vec]))
    art_xy = XY[:len(all_cards)]
    edge_xy = XY[len(all_cards):]

    pca3 = PCA(n_components=3, random_state=42)
    XYZ = pca3.fit_transform(np.vstack([art_vec, edge_vec]))
    art_xyz = XYZ[:len(all_cards)]
    edge_xyz = XYZ[len(all_cards):]
    # Normalise to canvas — leave 8% margin on each side.
    all_xy = XY
    mins = all_xy.min(axis=0)
    maxs = all_xy.max(axis=0)
    span = (maxs - mins).clip(min=1e-6)
    margin_x = args.width * 0.06
    margin_y = args.height * 0.06
    inner_w = args.width - 2 * margin_x
    inner_h = args.height - 2 * margin_y

    def to_canvas(p):
        x = margin_x + (p[0] - mins[0]) / span[0] * inner_w
        # Flip Y so PCA up = canvas up.
        y = args.height - margin_y - (p[1] - mins[1]) / span[1] * inner_h
        return x, y

    # ── 5. SVG render ───────────────────────────────────────────────────
    svg_parts: list[str] = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{args.width}" height="{args.height}" viewBox="0 0 {args.width} {args.height}">',
        '<style>',
        '.artifact { stroke: #1a1a1a; stroke-width: 0.5; opacity: 0.9; }',
        '.artifact:hover { stroke: #fff; stroke-width: 1.5; opacity: 1.0; }',
        '.edge-anchor { fill: #fff; stroke: #d23b6e; stroke-width: 2; }',
        '.edge-missing { fill: none; stroke: #d23b6e; stroke-width: 1.5; stroke-dasharray: 4 3; opacity: 0.6; }',
        '.edge-label { font: bold 14px ui-sans-serif, system-ui; fill: #d23b6e; pointer-events: none; }',
        '.edge-count { font: 11px ui-monospace, monospace; fill: #aaa; pointer-events: none; }',
        '.title { font: bold 18px ui-sans-serif, system-ui; fill: #eee; }',
        '.subtitle { font: 12px ui-sans-serif, system-ui; fill: #888; }',
        '</style>',
        f'<rect width="{args.width}" height="{args.height}" fill="#1a1a1f"/>',
        f'<text class="title" x="{margin_x}" y="{margin_y * 0.55}">'
        f'Ada artifact atlas — {len(all_cards)} artifacts, 13 edges, semantic projection</text>',
        f'<text class="subtitle" x="{margin_x}" y="{margin_y * 0.85}">'
        'TF-IDF + TruncatedSVD; PCA to 2D. Dot colour = registry family. '
        'Crosshair = edge anchor; dashed crosshair = MISSING (no artifact closest to this edge).</text>',
    ]

    # Artifacts as dots.
    for i, (x_norm, y_norm) in enumerate(art_xy):
        x, y = to_canvas((x_norm, y_norm))
        f = families[i] if i < len(families) else "unknown"
        c = family_color(str(f))
        title = f"{ids[i]} | family={f} | edge={edge_assignment[i]} (sim={closest_edge_score[i]:.2f})"
        svg_parts.append(
            f'<circle class="artifact" cx="{x:.1f}" cy="{y:.1f}" r="3.2" fill="{c}">'
            f'<title>{title}</title></circle>'
        )

    # Edge anchors.
    for ei, L in enumerate(EDGE_LETTERS):
        x, y = to_canvas(edge_xy[ei])
        cnt = edge_counts[L]
        klass = "edge-missing" if cnt == 0 else "edge-anchor"
        # Crosshair.
        svg_parts.append(
            f'<g class="{klass}">'
            f'  <line x1="{x-12}" y1="{y}" x2="{x+12}" y2="{y}"/>'
            f'  <line x1="{x}" y1="{y-12}" x2="{x}" y2="{y+12}"/>'
            f'  <circle cx="{x}" cy="{y}" r="6" fill="none"/>'
            f'</g>'
            f'<text class="edge-label" x="{x+10}" y="{y-10}">{L}</text>'
            f'<text class="edge-count" x="{x+10}" y="{y+8}">'
            f'{"MISSING" if cnt == 0 else f"{cnt} arts"}</text>'
        )

    # Family legend (bottom-right).
    legend_x = args.width - 220
    legend_y = args.height - 20 - len(FAMILY_COLORS) * 12
    used_families = sorted(set(str(f) for f in families))
    legend_y = args.height - 20 - len(used_families) * 12
    svg_parts.append(f'<g><text class="subtitle" x="{legend_x}" y="{legend_y - 6}">Families</text>')
    for i, f in enumerate(used_families):
        c = family_color(f)
        ly = legend_y + i * 12
        svg_parts.append(
            f'<circle cx="{legend_x + 4}" cy="{ly + 4}" r="4" fill="{c}"/>'
            f'<text class="subtitle" x="{legend_x + 14}" y="{ly + 7}">{f}</text>'
        )
    svg_parts.append('</g>')
    svg_parts.append('</svg>')

    SVG_PATH.write_text("\n".join(svg_parts), encoding="utf-8")
    print(f"[atlas] wrote {SVG_PATH}")

    # ── 5b. 3D coords JSON for the interactive viewer ───────────────────
    # Normalise XYZ to roughly [-1, 1] so the viewer doesn't have to.
    xyz_all = np.vstack([art_xyz, edge_xyz])
    centre = xyz_all.mean(axis=0)
    xyz_all_centred = xyz_all - centre
    scale = float(np.max(np.abs(xyz_all_centred))) or 1.0
    art_xyz_norm = (art_xyz - centre) / scale
    edge_xyz_norm = (edge_xyz - centre) / scale

    atlas_3d = {
        "artifacts": [
            {
                "id": str(ids[i]),
                "family": str(families[i]),
                "edge": edge_assignment[i],
                "sim": round(float(closest_edge_score[i]), 3),
                "x": round(float(art_xyz_norm[i, 0]), 4),
                "y": round(float(art_xyz_norm[i, 1]), 4),
                "z": round(float(art_xyz_norm[i, 2]), 4),
            }
            for i in range(len(ids))
        ],
        "edges": [
            {
                "letter": L,
                "count": int(edge_counts[L]),
                "x": round(float(edge_xyz_norm[i, 0]), 4),
                "y": round(float(edge_xyz_norm[i, 1]), 4),
                "z": round(float(edge_xyz_norm[i, 2]), 4),
            }
            for i, L in enumerate(EDGE_LETTERS)
        ],
        "family_colors": {f: family_color(f) for f in used_families},
    }
    (EMBED_DIR / "atlas_3d.json").write_text(
        json.dumps(atlas_3d, separators=(",", ":")),
        encoding="utf-8",
    )
    print(f"[atlas] wrote {EMBED_DIR / 'atlas_3d.json'}")

    # ── 6. JSON report ──────────────────────────────────────────────────
    report = {
        "n_artifacts": int(len(ids)),
        "n_families": int(len(used_families)),
        "n_edges": len(EDGE_LETTERS),
        "edge_counts": edge_counts,
        "missing_edges": [L for L, c in edge_counts.items() if c == 0],
        "thin_edges": [L for L, c in edge_counts.items() if 0 < c < 5],
        "edge_top_artifacts": {
            L: [{"id": str(name), "sim": round(s, 3)} for name, s in entries]
            for L, entries in edge_top_artifacts.items()
        },
        "family_counts": {f: int(np.sum(families == f)) for f in used_families},
    }
    REPORT_PATH.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"[atlas] wrote {REPORT_PATH}")

    # ── Console summary ─────────────────────────────────────────────────
    print()
    print("EDGE COVERAGE:")
    for L in EDGE_LETTERS:
        c = edge_counts[L]
        flag = " ← MISSING" if c == 0 else (" ← thin" if c < 5 else "")
        top = edge_top_artifacts[L]
        examples = ", ".join(name for name, _ in top[:3]) if top else "(none)"
        print(f"  {L}  {c:>3} artifacts{flag}  | {examples}")
    print()
    if report["missing_edges"]:
        print(f"  MISSING: edges with zero anchor artifacts → {report['missing_edges']}")
    if report["thin_edges"]:
        print(f"  THIN:    edges with <5 anchor artifacts → {report['thin_edges']}")


if __name__ == "__main__":
    main()
