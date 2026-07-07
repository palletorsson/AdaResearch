"""build_artifact_order.py — project the three-orders consensus onto each map's cast.

The old /tutorial walk pages already read their artifacts in the sequence's
pedagogical-ontological-critical CONSENSUS order (three_orders.py ->
three-orders.json), but capped at ~11 pearls. This tool uses the FULL order to
answer a chapter-level question: in what order should a map's artifacts be met?

For every spine sequence (chapter_maps.json keep-list), for every kept map:
  · read the map's cast from map_data.json interactables
  · rank each cast member by its consensus position (ped+onto+crit)/3
  · ranked artifacts first (necklace order), unranked after (cast order) —
    unranked = props/anchors the necklace never scored (dark_sphere, tt, ...)

Output:
  doc/book/artifact_order.json                      (the book's copy)
  <encyclopedia>/public/artifact-order.json          (the web's copy)

Usage:
  python tools/build_artifact_order.py [--seq=<id>]
"""

import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.environ.get(
    "ADA_ENCYCLOPEDIA_PATH",
    os.path.join(os.path.dirname(ROOT), "ada_encyclopedia"),
)
THREE_ORDERS = os.path.join(ENC, "public", "three-orders.json")
CHAPTER_MAPS = os.path.join(ROOT, "doc", "book", "chapter_maps.json")
MAPS_DIR = os.path.join(ROOT, "commons", "maps")
OUT_BOOK = os.path.join(ROOT, "doc", "book", "artifact_order.json")
OUT_WEB = os.path.join(ENC, "public", "artifact-order.json")


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def map_cast(map_name):
    """Ordered cast of a map: interactable tokens minus rotation/offset suffixes."""
    path = os.path.join(MAPS_DIR, map_name, "map_data.json")
    if not os.path.isfile(path):
        return []
    data = load(path)
    layers = data.get("layers", data)
    seen, cast = set(), []
    for row in layers.get("interactables", []):
        for cell in row:
            if not cell or not cell.strip():
                continue
            name = cell.split(":")[0]
            if name.startswith("#"):  # disabled cell
                continue
            if name not in seen:
                seen.add(name)
                cast.append(name)
    return cast


def base_name(token):
    """lab_room#mounted_lab_json -> lab_room (presets rank as their base)."""
    return token.split("#")[0]


def consensus_rank(entry):
    """artifact -> consensus position (ped+onto+crit)/3 for one sequence."""
    pearls = entry.get("pearls", [])
    ped, onto, crit = entry.get("ped", []), entry.get("onto", []), entry.get("crit", [])
    rank = {}
    for i, name in enumerate(pearls):
        vals = [axis[i] for axis in (ped, onto, crit) if i < len(axis)]
        if vals:
            rank[name] = sum(vals) / len(vals)
    return rank


def main():
    only = None
    for arg in sys.argv[1:]:
        if arg.startswith("--seq="):
            only = arg.split("=", 1)[1]

    orders = {s["seq"]: s for s in load(THREE_ORDERS).get("sequences", [])}
    chapters = load(CHAPTER_MAPS)["chapters"]

    out = {"generated_by": "tools/build_artifact_order.py",
           "source": "three-orders.json consensus (ped+onto+crit)/3, full necklace (uncapped)",
           "sequences": {}}

    for seq, ch in chapters.items():
        if only and seq != only:
            continue
        entry = orders.get(seq)
        rank = consensus_rank(entry) if entry else {}
        seq_out = {"necklace": sorted(rank, key=rank.get), "maps": {}}
        for map_name in ch.get("keep", []):
            cast = map_cast(map_name)
            ranked = sorted([a for a in cast if base_name(a) in rank],
                            key=lambda a: rank[base_name(a)])
            unranked = [a for a in cast if base_name(a) not in rank]
            seq_out["maps"][map_name] = {
                "order": ranked + unranked,
                "ranked": len(ranked),
                "unranked": unranked,
            }
        out["sequences"][seq] = seq_out

    for path in (OUT_BOOK, OUT_WEB):
        with open(path, "w", encoding="utf-8") as f:
            json.dump(out, f, ensure_ascii=False, indent=1)

    n_seq = len(out["sequences"])
    n_maps = sum(len(s["maps"]) for s in out["sequences"].values())
    n_ranked = sum(m["ranked"] for s in out["sequences"].values() for m in s["maps"].values())
    n_total = sum(len(m["order"]) for s in out["sequences"].values() for m in s["maps"].values())
    print(f"artifact-order: {n_seq} sequences, {n_maps} maps, "
          f"{n_ranked}/{n_total} artifacts consensus-ranked")
    print(f"  -> {OUT_BOOK}")
    print(f"  -> {OUT_WEB}")


if __name__ == "__main__":
    main()
