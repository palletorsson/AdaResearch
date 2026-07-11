#!/usr/bin/env python3
"""Negative tests for hazard-aware pathfinding in map_pathfinder.py.

Three inline map dicts (no files under commons/maps):
  (a) corridor whose ONLY route crosses h:death  -> unreachable
  (b) hazard-free detour around h:fire           -> path avoids the fire cell
  (c) no hazards                                 -> identical to plain BFS

Run: python tools/test_pathfinder_hazards.py
"""

from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from map_pathfinder import MapGraph  # noqa: E402


def make_map(name: str, structure, utilities) -> dict:
    """Build a minimal map_data dict with empty interactables."""
    ints = [[" "] * len(row) for row in structure]
    return {
        "map_info": {"lookup_name": name},
        "layers": {
            "structure": structure,
            "utilities": utilities,
            "interactables": ints,
        },
    }


def plain_bfs_path(graph: MapGraph, target):
    """Reference BFS (the pre-hazard search) for the no-hazard equivalence test."""
    if graph.spawn == target:
        return [graph.spawn]
    parent = {}
    visited = {graph.spawn}
    queue = deque([graph.spawn])
    while queue:
        pos = queue.popleft()
        for nb in graph.neighbors(pos):
            if nb not in visited:
                visited.add(nb)
                parent[nb] = pos
                if nb == target:
                    path = [nb]
                    cur = nb
                    while cur in parent:
                        cur = parent[cur]
                        path.append(cur)
                    path.reverse()
                    return path
                queue.append(nb)
    return None


def test_death_blocks_only_route():
    """(a) 1-wide corridor with h:death in the middle — far end unreachable."""
    data = make_map(
        "Test_Death_Corridor",
        structure=[["1", "1", "1", "1", "1"]],
        utilities=[["s", " ", "h:death", " ", " "]],
    )
    graph = MapGraph(data)
    target = (0, 4)

    assert (0, 2) in graph.death_cells, "h:death cell not parsed as death"
    assert (0, 2) not in graph.walkable, "h:death cell still walkable"

    path = graph.bfs_path(target)
    assert path is None, f"expected NO path through h:death, got {path}"

    reachable = graph.bfs_flood()
    assert target not in reachable, "far end reachable despite h:death block"
    assert reachable == {(0, 0), (0, 1)}, f"unexpected flood: {reachable}"
    print("PASS  (a) h:death blocks the only route — unreachable")


def test_fire_detour_preferred():
    """(b) 2x5 open floor, h:fire on the straight line — path detours around it."""
    data = make_map(
        "Test_Fire_Detour",
        structure=[
            ["1", "1", "1", "1", "1"],
            ["1", "1", "1", "1", "1"],
        ],
        utilities=[
            ["s", " ", "h:fire:20", " ", " "],
            [" ", " ", " ", " ", " "],
        ],
    )
    graph = MapGraph(data)
    target = (0, 4)
    fire = (0, 2)

    assert graph.hazard_kinds.get(fire) == "fire", "h:fire:20 kind not parsed"
    assert fire in graph.walkable, "h:fire cell must stay walkable"

    path = graph.bfs_path(target)
    assert path is not None, "target should be reachable around the fire"
    assert fire not in path, f"path crosses fire cell: {path}"
    # Detour is 2 steps longer than the straight line (4 -> 6 steps)
    assert len(path) - 1 == 6, f"expected 6-step detour, got {len(path) - 1}: {path}"

    reachable = graph.bfs_flood()
    assert fire in reachable, "fire cell should still be reachable (costly, not blocked)"
    print("PASS  (b) h:fire is detoured, not blocked")


def test_no_hazards_unchanged():
    """(c) hazard-free map — search behaves exactly like the old plain BFS."""
    data = make_map(
        "Test_No_Hazards",
        structure=[
            ["1", "1", "1", "1", "1"],
            ["1", "1", "1", "1", "1"],
        ],
        utilities=[
            ["s", " ", " ", " ", " "],
            [" ", " ", " ", " ", " "],
        ],
    )
    graph = MapGraph(data)
    target = (0, 4)

    assert not graph.hazard_kinds, "hazard cells found in hazard-free map"

    path = graph.bfs_path(target)
    ref = plain_bfs_path(graph, target)
    assert path is not None and ref is not None
    assert len(path) == len(ref), f"path length changed: {len(path)} vs BFS {len(ref)}"
    assert len(path) - 1 == 4, f"expected 4-step straight path, got {len(path) - 1}"

    reachable = graph.bfs_flood()
    assert len(reachable) == 10, f"expected all 10 cells reachable, got {len(reachable)}"
    print("PASS  (c) hazard-free map — behavior identical to before")


def test_h_exact_match_no_substring():
    """Guard: only tokens whose FIRST segment is exactly 'h' count as hazards."""
    data = make_map(
        "Test_H_Exact",
        structure=[["1", "1", "1"]],
        utilities=[["s", "hx:fire", "wh:death"]],
    )
    graph = MapGraph(data)
    assert not graph.hazard_kinds, f"substring-matched non-hazard tokens: {graph.hazard_kinds}"
    print("PASS  (d) exact first-segment match — 'hx:'/'wh:' tokens are not hazards")


if __name__ == "__main__":
    test_death_blocks_only_route()
    test_fire_detour_preferred()
    test_no_hazards_unchanged()
    test_h_exact_match_no_substring()
    print("\nAll hazard pathfinder tests passed.")
