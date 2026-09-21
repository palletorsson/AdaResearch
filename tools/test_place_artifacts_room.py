#!/usr/bin/env python3
"""Regression tests for place_artifacts.room_from_map dimension honesty.

The scar (measured 2026-08-27, fixed 2026-08-29): room_from_map read
map_info.dimensions.get("depth", 6), but the map-builder saves {width, height}
and 269 of 2789 saved maps declare a depth that contradicts len(structure).
A 5-row draft became a 6-deep Room, so strategies treated the real border wall
row 4 as interior — under that lie, hybrid/simulated_annealing/stickiness/
colonization all placed artifacts onto row 4 (measured over seeds 0..9), and
place.py rewrote interactables grids at the phantom depth (QFEP_Lambda_Spectrum:
3 artifacts on rows 18-19 of an 18-row map).

The fix: the structure grid is the honest truth; declared depth — or height,
the map-builder's word for the same axis — is trusted only when there is no
structure to read.

Run from tools/:  python -m unittest test_place_artifacts_room -v
"""
from __future__ import annotations

import random
import unittest

from placement_research import Artifact, STRATEGIES
from place_artifacts import grid_dims_from_map, room_from_map


def bordered_map(rows: int, cols: int, dims: dict | None,
                 utilities: list | None = None) -> dict:
    """A real-shaped map: wall ring ("2") around floor ("1"), spawn back-centre,
    teleporter front-centre, empty interactables."""
    structure = ([["2"] * cols]
                 + [["2"] + ["1"] * (cols - 2) + ["2"] for _ in range(rows - 2)]
                 + [["2"] * cols])
    if utilities is None:
        utilities = [["" for _ in range(cols)] for _ in range(rows)]
        utilities[rows - 2][cols // 2] = "sp"
        utilities[1][cols // 2] = "t"
    map_info: dict = {"name": "_test"}
    if dims is not None:
        map_info["dimensions"] = dims
    return {
        "map_info": map_info,
        "layers": {
            "structure": structure,
            "utilities": utilities,
            "interactables": [["" for _ in range(cols)] for _ in range(rows)],
        },
    }


def plain_artifact(name: str) -> Artifact:
    """A registry-free interior artifact: no wall_backing, 1-cell footprint."""
    return Artifact(
        lookup_name=name, footprint_cells=1,
        clearance_front=1, clearance_back=1, clearance_left=1, clearance_right=1,
        player_position="front", wall_backing=False,
        orientation="face_approach", isolation=0,
        cluster_with=[], preferred_zone="any",
    )


class RoomFromMapDimensionTests(unittest.TestCase):
    def test_height_only_dims_match_structure(self) -> None:
        # The map-builder format: {width, height}, no depth key. The old code
        # returned depth 6 here regardless of the map.
        room, _, _ = room_from_map(bordered_map(5, 10, {"width": 10, "height": 5}))
        self.assertEqual((room.width, room.depth), (10, 5))

    def test_missing_dims_fall_back_to_structure(self) -> None:
        room, _, _ = room_from_map(bordered_map(7, 9, dims=None))
        self.assertEqual((room.width, room.depth), (9, 7))

    def test_stale_declared_depth_loses_to_structure(self) -> None:
        # The QFEP_Lambda_Spectrum class: declared depth 20, structure 18 rows.
        # Placements are written INTO the structure grid, so the grid wins.
        md = bordered_map(18, 5, {"width": 5, "depth": 20})
        self.assertEqual(grid_dims_from_map(md), (5, 18))

    def test_height_accepted_as_depth_without_structure(self) -> None:
        md = {"map_info": {"dimensions": {"width": 8, "height": 5}}, "layers": {}}
        self.assertEqual(grid_dims_from_map(md), (8, 5))

    def test_defaults_when_nothing_known(self) -> None:
        self.assertEqual(grid_dims_from_map({"map_info": {}, "layers": {}}), (10, 6))

    def test_anchors_clamped_into_room(self) -> None:
        # Stale maps carry utilities grids longer than the structure; a spawn
        # scanned out there must not leave the honest room.
        rows, cols = 5, 10
        utilities = [["" for _ in range(cols)] for _ in range(8)]
        utilities[7][3] = "sp"
        utilities[6][4] = "t"
        room, _, _ = room_from_map(
            bordered_map(rows, cols, {"width": 10, "height": 5}, utilities=utilities))
        self.assertEqual(room.depth, 5)
        self.assertLessEqual(room.spawn_row, room.depth - 1)
        self.assertLessEqual(room.teleporter_row, room.depth - 1)


class BorderedMapPlacementTests(unittest.TestCase):
    """A bordered NxM map must never receive a placement on row 0, row N-1,
    col 0 or col M-1. This held for every engine below over seeds 0..9 once the
    Room matched the real grid; under the old depth-6 lie the same engines put
    artifacts on the real border row (hybrid seed 1 at (4,1), sim_annealing
    seed 0 at (4,7), ...)."""

    ARTIFACTS = ["alpha", "beta", "gamma"]
    SEEDS = range(10)

    def assert_interior_only(self, rows: int, cols: int, engines: list[str]) -> None:
        for engine in engines:
            self.assertIn(engine, STRATEGIES)
            for seed in self.SEEDS:
                room, _, _ = room_from_map(
                    bordered_map(rows, cols, {"width": cols, "height": rows}))
                self.assertEqual((room.width, room.depth), (cols, rows))
                placements = STRATEGIES[engine](
                    room, [plain_artifact(n) for n in self.ARTIFACTS],
                    random.Random(seed))
                for p in placements:
                    for (r, c) in p.footprint_cells_occupied():
                        self.assertTrue(
                            0 < r < rows - 1 and 0 < c < cols - 1,
                            f"{engine} seed={seed} placed {p.artifact.lookup_name} "
                            f"footprint cell ({r},{c}) on the border of a "
                            f"{rows}x{cols} bordered map")

    def test_no_border_placement_incident_shape_5x10(self) -> None:
        # The measured incident shape: 5 rows, phantom depth 6 made real border
        # row 4 look interior.
        self.assert_interior_only(5, 10, [
            "hybrid", "humanoid_walker", "simulated_annealing",
            "focal_composition", "pacing_arc", "promenade",
            "crystallization", "stickiness", "colonization",
        ])

    def test_no_border_placement_narrow_12x6(self) -> None:
        # focal_composition and pacing_arc place on col 0 of narrow rooms even
        # with an honest Room (measured 2026-08-29) — a strategy trait, not the
        # dims regression — so they are excluded here.
        self.assert_interior_only(12, 6, [
            "hybrid", "humanoid_walker", "simulated_annealing",
            "promenade", "crystallization", "stickiness", "colonization",
        ])


if __name__ == "__main__":
    unittest.main()
