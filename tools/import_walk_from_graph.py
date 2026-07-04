#!/usr/bin/env python3
"""import_walk_from_graph.py — turn a /spine-graph export into a chapter's walk.

The excavation plan, made by hand: arrange a sequence's cluster on the spine-graph
workbench (drag artifacts in from the palette, remove them, reorder them), Export,
and feed the export here. The ring becomes the chapter's `walk` override in
doc/tutorial_authored/<seq>.json — the tutorial builder then honors the author's
cut instead of the [:11] formula, and the field journal records the recut trench
on the next build.

Which nodes count as the ring: tier "artifact" nodes whose seq matches, plus any
artifact node parented to the sequence's concept hub (palette additions carry the
seq of their origin, so both routes work). Order = reading order (row, then col)
around the hub — arrange top-to-bottom, left-to-right.

Usage:
  python tools/import_walk_from_graph.py <export.json> --seq=noise          # show the derived walk
  python tools/import_walk_from_graph.py <export.json> --seq=noise --apply  # write the override
"""
from __future__ import annotations

import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUTHORED = os.path.join(REPO, "doc", "tutorial_authored")


def main() -> int:
    args = sys.argv[1:]
    src = next((a for a in args if not a.startswith("--")), None)
    seq = next((a.split("=", 1)[1] for a in args if a.startswith("--seq=")), None)
    apply_ = "--apply" in args
    if not src or not seq:
        print(__doc__)
        return 1
    with open(src, encoding="utf-8") as f:
        data = json.load(f)
    nodes = data if isinstance(data, list) else data.get("nodes") or []
    if not nodes:
        print("!! no nodes in export")
        return 1

    hubs = {n["uid"] for n in nodes if n.get("tier") == "concept" and n.get("seq") == seq}
    ring = [n for n in nodes
            if n.get("tier") not in ("concept", "prop")
            and (n.get("seq") == seq or n.get("parent") in hubs)]
    # reading order around the hub; dedup keeps the first (top-most) placement
    ring.sort(key=lambda n: (n.get("row", 0), n.get("col", 0)))
    walk, seen = [], set()
    for n in ring:
        lk = n.get("lookup")
        if lk and lk not in seen:
            seen.add(lk)
            walk.append(lk)
    if not walk:
        print(f"!! no artifact nodes found for seq '{seq}' "
              f"({len(hubs)} hub(s) matched; {len(nodes)} nodes total)")
        return 1

    print(f"derived walk for {seq} ({len(walk)}):")
    for i, lk in enumerate(walk, 1):
        print(f"  {i:2d}. {lk}" + ("   <- the primitive" if i == 1 else ""))
    if len(walk) > 11:
        print(f"  note: {len(walk)} > 11 — the page grammar keeps the first 11")
    if not apply_:
        print("(dry run — pass --apply to write the override)")
        return 0

    os.makedirs(AUTHORED, exist_ok=True)
    path = os.path.join(AUTHORED, f"{seq}.json")
    overlay = {}
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            overlay = json.load(f)
    overlay["walk"] = walk
    with open(path, "w", encoding="utf-8") as f:
        json.dump(overlay, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print(f"override -> {path}")
    print(f"next: python tools/build_critical_tutorial.py {seq} && python tools/book_drift.py")
    sys.path.insert(0, os.path.join(REPO, "tools"))
    from book_log import log_event
    log_event("draft", f"walk hand-cut from spine-graph: {seq} ({len(walk)} artifacts)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
