#!/usr/bin/env python3
"""Generate a per-artifact ontological-neighbors JSON for an offline Godot editor to read.

Reads the atlas embeddings (`doc/atlas/artifact_embeddings.npz`: arrays `ids` + `vectors`,
where vectors are L2-normalized so cosine == dot product), builds a lookup_name -> display-name
map from the artifact registries, and for every artifact writes its top-12 nearest neighbors by
cosine similarity to `commons/data/artifact_neighbors.json`.

Output shape:
    { "<lookup>": [ {"id": "<lookup>", "name": "<display>", "sim": <float>}, ... up to 12 ], ... }

Run: python tools/gen_artifact_neighbors.py
"""
import glob
import json
import os

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NPZ_PATH = os.path.join(ROOT, "doc", "atlas", "artifact_embeddings.npz")
REGISTRY_GLOB = os.path.join(ROOT, "commons", "artifacts", "registry", "*.json")
OUT_DIR = os.path.join(ROOT, "commons", "data")
OUT_PATH = os.path.join(OUT_DIR, "artifact_neighbors.json")

TOP_K = 12


def load_display_names():
    """Scan registry JSONs -> {lookup_name: display_name}.

    Each registry file holds entries either under an "artifacts" key or at the root
    (dict-of-entries or list-of-entries). The lookup key is the registry key, or the
    entry's "lookup"/"id"/"name" field; the display name is entry.get("name") with the
    lookup as fallback.
    """
    names = {}
    for path in sorted(glob.glob(REGISTRY_GLOB)):
        try:
            with open(path, "r", encoding="utf-8") as fh:
                data = json.load(fh)
        except (json.JSONDecodeError, OSError):
            continue

        container = data.get("artifacts", data) if isinstance(data, dict) else data

        def register(lookup, entry):
            if not lookup:
                return
            display = None
            if isinstance(entry, dict):
                display = entry.get("name")
            names[str(lookup)] = str(display) if display else str(lookup)

        if isinstance(container, dict):
            for key, entry in container.items():
                lookup = key
                if isinstance(entry, dict):
                    lookup = entry.get("lookup") or entry.get("id") or key
                register(lookup, entry)
        elif isinstance(container, list):
            for entry in container:
                if isinstance(entry, dict):
                    lookup = entry.get("lookup") or entry.get("id") or entry.get("name")
                    register(lookup, entry)
    return names


def main():
    npz = np.load(NPZ_PATH, allow_pickle=True)
    ids = [str(a) for a in npz["ids"]]
    V = np.asarray(npz["vectors"], dtype=np.float32)

    display = load_display_names()

    def name_of(aid):
        return display.get(aid, aid)

    # Full similarity matrix in chunks to keep memory bounded (vectors are L2-normalized
    # so V @ V.T == cosine). For ~2400xD this is small, but chunk anyway for safety.
    n = len(ids)
    out = {}
    chunk = 512
    for start in range(0, n, chunk):
        end = min(start + chunk, n)
        sims = V[start:end] @ V.T  # (chunk, n)
        for row, i in enumerate(range(start, end)):
            scores = sims[row]
            # argsort descending; take a few extra to allow dropping self.
            order = np.argsort(-scores)
            neighbors = []
            for j in order:
                if j == i:
                    continue
                jid = ids[j]
                neighbors.append({
                    "id": jid,
                    "name": name_of(jid),
                    "sim": round(float(scores[j]), 3),
                })
                if len(neighbors) >= TOP_K:
                    break
            out[ids[i]] = neighbors

    os.makedirs(OUT_DIR, exist_ok=True)
    with open(OUT_PATH, "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=1)

    print(f"Wrote {OUT_PATH}")
    print(f"Artifacts (keys): {len(out)}")
    print(f"Registry display names loaded: {len(display)}")

    sample_key = "origin" if "origin" in out else ("point" if "point" in out else next(iter(out)))
    print(f"\nSample neighbors for '{sample_key}' ({name_of(sample_key)}):")
    for nb in out[sample_key]:
        print(f"  {nb['sim']:.3f}  {nb['id']}  ({nb['name']})")


if __name__ == "__main__":
    main()
