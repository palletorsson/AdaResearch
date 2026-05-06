#!/usr/bin/env python
"""artifact_embed.py — embed every Ada artifact into a vector space.

Walks commons/artifacts/registry/*.json, builds a text "card" per artifact
from its description + dev_themes + family + lookup_name, then TF-IDF +
TruncatedSVD to produce ~128-D embeddings. Local, free, fast (~5s for the
full ~1700 artifact corpus).

Output:
  doc/atlas/artifact_embeddings.npz  — {ids, vectors, families, footprints}
  doc/atlas/artifact_cards.json      — full text cards for inspection / re-embed

Why TF-IDF + SVD instead of sentence-transformers? Torch on this Windows
machine fights with CUDA DLLs and we wanted the atlas tonight, not next
week. The result clusters by shared vocabulary (description + dev_themes
overlap), which is good enough to surface missing edges and mis-homed
artifacts. Upgrade path: swap embed_corpus() for a sentence-transformers
or claude-enriched call once it's installable.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.decomposition import TruncatedSVD
from sklearn.preprocessing import normalize

REPO = Path(__file__).resolve().parent.parent
REGISTRY_DIR = REPO / "commons" / "artifacts" / "registry"
OUT_DIR = REPO / "doc" / "atlas"

# Fields we read off each registry entry to build its text card.
CARD_FIELDS = [
    "description", "dev_themes", "lookup_name", "category", "complexity",
    "map_sequence", "blurb", "intent", "tags",
]


# Registries that aren't artifact records (substrate vectors, panel maps, etc).
SKIP_REGISTRIES = {
    "substrate_vectors",   # weights per artifact, not artifact records
    "vectors",             # ditto
    "vectors_demos",       # ditto
    "panel_bridge",        # 1 entry, internal bridging
    "gallery_preview",     # 1 entry, internal
}


def load_registry_artifacts() -> list[dict]:
    """Walk every registry JSON, yield one dict per artifact with family info."""
    out: list[dict] = []
    for json_path in sorted(REGISTRY_DIR.glob("*.json")):
        family = json_path.stem  # "cellular_automata", "color", etc.
        if family in SKIP_REGISTRIES:
            continue
        try:
            data = json.loads(json_path.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"  skip {json_path.name}: {e}", file=sys.stderr)
            continue
        # Normalise. Three layouts in the wild:
        #   1. {<lookup_name>: <entry_dict>, ...}                       — flat
        #   2. {"artifacts": {<lookup_name>: <entry_dict>}, ...}        — wrapped
        #   3. [<entry_dict>, ...]                                      — list
        # Layouts (2) often also have "registry_info", "_comment", etc. at
        # the top level — those are NOT artifacts and must be ignored.
        if isinstance(data, dict):
            if "artifacts" in data and isinstance(data["artifacts"], (dict, list)):
                inner = data["artifacts"]
                if isinstance(inner, dict):
                    items = list(inner.items())
                else:  # list of dicts under "artifacts"
                    items = [(it.get("lookup_name", f"{family}_{i}"), it)
                             for i, it in enumerate(inner) if isinstance(it, dict)]
            else:
                # Flat layout. Drop top-level metadata keys that aren't artifacts.
                metadata_keys = {"registry_info", "registry_name", "description",
                                 "_comment", "_note", "sequence_mapping"}
                items = [(k, v) for k, v in data.items()
                         if k not in metadata_keys and isinstance(v, dict)]
        elif isinstance(data, list):
            items = [(it.get("lookup_name", f"{family}_{i}"), it)
                     for i, it in enumerate(data) if isinstance(it, dict)]
        else:
            continue
        for lookup_name, entry in items:
            if not isinstance(entry, dict):
                continue
            entry = dict(entry)
            entry.setdefault("lookup_name", lookup_name)
            entry["_family"] = family
            entry["_registry_file"] = json_path.name
            out.append(entry)
    return out


def build_card(entry: dict) -> str:
    """Compose a single string per artifact for TF-IDF to chew on."""
    chunks: list[str] = []
    name = entry.get("lookup_name", "")
    chunks.append(f"name: {name.replace('_', ' ')}")
    chunks.append(f"family: {entry['_family'].replace('_', ' ')}")
    desc = entry.get("description", "")
    if desc and desc != name:
        chunks.append(f"description: {desc}")
    themes = entry.get("dev_themes")
    if isinstance(themes, list) and themes:
        chunks.append(f"themes: {' '.join(t.replace('_', ' ') for t in themes)}")
    cat = entry.get("category", "")
    if cat and cat != "unknown":
        chunks.append(f"category: {cat}")
    cx = entry.get("complexity", "")
    if cx:
        chunks.append(f"complexity: {cx}")
    seq = entry.get("map_sequence", "")
    if seq:
        chunks.append(f"sequence: {seq}")
    blurb = entry.get("blurb", "") or entry.get("intent", "")
    if blurb:
        chunks.append(f"summary: {str(blurb)[:600]}")
    tags = entry.get("tags")
    if isinstance(tags, list) and tags:
        chunks.append(f"tags: {' '.join(str(t) for t in tags)}")
    return " | ".join(chunks)


def embed_corpus(cards: list[str], n_components: int = 128) -> np.ndarray:
    """TF-IDF → TruncatedSVD → L2-normalised dense vectors."""
    print(f"[embed] vectorising {len(cards)} cards via TF-IDF...")
    vec = TfidfVectorizer(
        analyzer="word",
        ngram_range=(1, 2),
        min_df=2,
        max_df=0.85,
        sublinear_tf=True,
        token_pattern=r"(?u)\b[A-Za-z][A-Za-z_-]+\b",
    )
    X = vec.fit_transform(cards)
    print(f"[embed] TF-IDF matrix: {X.shape} (vocabulary {len(vec.vocabulary_)})")
    n_components = min(n_components, X.shape[1] - 1, X.shape[0] - 1)
    print(f"[embed] reducing to {n_components}-D via TruncatedSVD...")
    svd = TruncatedSVD(n_components=n_components, random_state=42)
    Z = svd.fit_transform(X)
    Z = normalize(Z, norm="l2")
    explained = float(np.sum(svd.explained_variance_ratio_))
    print(f"[embed] SVD explained variance: {explained:.3f}")
    return Z


def main():
    ap = argparse.ArgumentParser(description="Embed all Ada artifacts.")
    ap.add_argument("--components", type=int, default=128,
                    help="SVD output dimensionality (default 128)")
    ap.add_argument("--out-dir", default=str(OUT_DIR), type=Path)
    args = ap.parse_args()
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    artifacts = load_registry_artifacts()
    print(f"[embed] loaded {len(artifacts)} artifacts from registries")

    cards = [build_card(a) for a in artifacts]

    # Save cards alongside embeddings so the atlas can show them on hover.
    cards_path = out_dir / "artifact_cards.json"
    cards_payload = [{
        "lookup_name": a.get("lookup_name", ""),
        "family": a["_family"],
        "registry": a["_registry_file"],
        "description": a.get("description", ""),
        "dev_themes": a.get("dev_themes", []),
        "footprint": a.get("footprint", [1.0, 1.0, 1.0]),
        "category": a.get("category", "unknown"),
        "card": cards[i],
    } for i, a in enumerate(artifacts)]
    cards_path.write_text(json.dumps(cards_payload, indent=2, ensure_ascii=False),
                          encoding="utf-8")
    print(f"[embed] wrote {cards_path}")

    Z = embed_corpus(cards, n_components=args.components)

    emb_path = out_dir / "artifact_embeddings.npz"
    np.savez_compressed(
        emb_path,
        ids=np.array([a.get("lookup_name", "") for a in artifacts]),
        families=np.array([a["_family"] for a in artifacts]),
        vectors=Z,
    )
    print(f"[embed] wrote {emb_path}  ({Z.shape})")
    print(f"[embed] done.")


if __name__ == "__main__":
    main()
