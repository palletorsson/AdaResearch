#!/usr/bin/env python3
"""Regression tests for artifact-aware Uffizi wall prop placement."""

from __future__ import annotations

import unittest
from collections import Counter

import build_uffizi_prop_placement_pilot as pilot


class UffiziPropPlacementPilotTests(unittest.TestCase):
    def setUp(self) -> None:
        self.map_data, self.clusters = pilot.build_map("Test_Uffizi_Prop_Pilot")
        self.metadata = self.map_data["map_info"]["metadata"]
        self.surfaces = self.metadata["wall_surface_contracts"]

    def surface(self, artifact: str) -> dict:
        return next(item for item in self.surfaces if item["artifact"] == artifact)

    def test_source_architecture_and_artifact_footprints_are_unchanged(self) -> None:
        base = pilot.read_json(pilot.BASE_MAP)
        self.assertEqual(self.map_data["map_info"]["dimensions"], base["map_info"]["dimensions"])
        self.assertEqual(self.map_data["layers"]["structure"], base["layers"]["structure"])
        self.assertEqual(self.map_data["layers"]["footprints"], base["layers"]["footprints"])

    def test_all_ten_bays_receive_principal_wall_contracts_in_main_order(self) -> None:
        assignments = self.metadata["placement_overlay"]
        self.assertEqual(len(self.surfaces), 10)
        self.assertEqual(
            [surface["artifact"] for surface in self.surfaces],
            [assignment["artifact"] for assignment in assignments],
        )

    def test_lambda_keeps_three_by_three_wall_claim_and_uses_side_rails(self) -> None:
        surface = self.surface("lambda_slider")
        claim = surface["artifact_wall_claim_uv_m"]
        self.assertAlmostEqual(claim[2] - claim[0], 3.0)
        self.assertAlmostEqual(claim[3] - claim[1], 3.0)
        support_bands = [
            item["requested_band"]
            for item in surface["accepted"]
            if item["request_id"] in ("lambda_interrupt", "lambda_status")
        ]
        self.assertEqual(support_bands, ["left_rail", "right_rail"])
        for item in surface["accepted"]:
            self.assertFalse(pilot.rect_overlap(item["rect_uv_m"], claim))

    def test_interactive_lambda_control_is_in_reach_band(self) -> None:
        surface = self.surface("lambda_slider")
        button = next(item for item in surface["accepted"] if item["token"] == "emergency_button")
        self.assertTrue(button["interactive"])
        self.assertGreaterEqual(button["origin_uv_m"][1], 0.75)
        self.assertLessEqual(button["origin_uv_m"][1], 1.35)

    def test_shannon_wall_hero_has_three_by_three_protected_claim(self) -> None:
        surface = self.surface("shannon_entropy_meter")
        claim = surface["artifact_wall_claim_uv_m"]
        self.assertAlmostEqual(claim[2] - claim[0], 3.0)
        self.assertAlmostEqual(claim[3] - claim[1], 3.0)
        for item in surface["accepted"]:
            self.assertFalse(pilot.rect_overlap(item["rect_uv_m"], claim))

    def test_platonic_solids_remains_freestanding_and_uses_feature_field(self) -> None:
        assignment = pilot.find_assignment(self.map_data, "platonicsolids")
        surface = self.surface("platonicsolids")
        self.assertEqual(assignment["preferred_mode"], "freestanding")
        self.assertNotIn("artifact_wall_claim_uv_m", surface)
        panel = next(item for item in surface["accepted"] if item["token"] == "station_panel")
        self.assertTrue(pilot.rect_inside(panel["rect_uv_m"], surface["feature_field_uv_m"]))

    def test_every_feature_wall_accepts_one_book_monitor(self) -> None:
        feature_walls = [
            surface for surface in self.surfaces
            if surface["principal_wall_archetype"] == "feature_wall"
        ]
        self.assertEqual(len(feature_walls), 6)
        for surface in feature_walls:
            panels = [item for item in surface["accepted"] if item["role"] == "map_monitor"]
            self.assertEqual(len(panels), 1)
            self.assertTrue(pilot.rect_inside(panels[0]["rect_uv_m"], surface["feature_field_uv_m"]))

    def test_every_principal_wall_has_semantic_exit_safety(self) -> None:
        for surface in self.surfaces:
            accepted = {item["token"]: item for item in surface["accepted"]}
            self.assertIn("exit_sign", accepted)
            self.assertIn("fire_extinguisher", accepted)
            self.assertEqual(accepted["exit_sign"]["requested_band"], "upper_side")
            self.assertEqual(accepted["fire_extinguisher"]["requested_band"], "low_side")
            self.assertLessEqual(accepted["exit_sign"]["anchor_distance_m"], 1.25)
            self.assertLessEqual(accepted["fire_extinguisher"]["anchor_distance_m"], 1.25)

    def test_ideal_feature_wall_stacks_material_in_grounded_corner(self) -> None:
        surface = self.surface("platonicsolids")
        crates = next(item for item in surface["accepted"] if item["token"] == "station_crates")
        self.assertEqual(crates["requested_band"], "floor_corner")
        self.assertEqual(crates["rect_uv_m"][1], 0.0)
        self.assertLessEqual(crates["anchor_distance_m"], 0.75)
        self.assertFalse(pilot.rect_overlap(crates["rect_uv_m"], surface["feature_field_uv_m"]))

    def test_support_props_stay_out_of_middle_feature_field(self) -> None:
        for surface in self.surfaces:
            for item in surface["accepted"]:
                if item["requested_band"] == "feature_field":
                    continue
                self.assertFalse(pilot.rect_overlap(item["rect_uv_m"], surface["feature_field_uv_m"]))

    def test_environmental_neural_room_refuses_monitor_but_keeps_safety_cluster(self) -> None:
        surface = self.surface("neural_network_visualization")
        self.assertEqual(
            sorted(item["token"] for item in surface["accepted"]),
            ["exit_sign", "fire_extinguisher"],
        )
        self.assertEqual(len(surface["rejected"]), 1)
        self.assertIn(
            "artifact_contract_protects_the_full_environment",
            surface["rejected"][0]["reasons"],
        )
        self.assertIsNotNone(surface["cluster"])
        x, z = surface["runtime_anchor_cell"]
        self.assertTrue(self.map_data["layers"]["interactables"][z][x].startswith("cluster:"))

    def test_gradient_room_uses_the_same_protected_environment_contract(self) -> None:
        surface = self.surface("gradient_descent_visualization")
        self.assertEqual(sorted(item["token"] for item in surface["accepted"]), ["exit_sign", "fire_extinguisher"])
        self.assertEqual(len(surface["rejected"]), 1)
        self.assertEqual(surface["rejected"][0]["role"], "map_monitor")

    def test_ten_runtime_clusters_compile_wall_and_ground_props(self) -> None:
        self.assertEqual(len(self.clusters), 10)
        pieces = [piece for cluster in self.clusters.values() for piece in cluster["pieces"]]
        self.assertEqual(len(pieces), 29)
        self.assertTrue(any(piece["wall"] for piece in pieces))
        self.assertTrue(any(not piece["wall"] for piece in pieces))
        self.assertTrue(all(piece["z"] == -0.5 for piece in pieces if piece["wall"]))
        counts = Counter(piece["token"] for piece in pieces)
        self.assertEqual(counts["exit_sign"], 10)
        self.assertEqual(counts["fire_extinguisher"], 10)
        self.assertEqual(counts["station_panel"], 7)
        self.assertEqual(counts["emergency_button"], 1)
        self.assertEqual(counts["station_crates"], 1)

    def test_full_validator_accepts_the_compiled_pilot(self) -> None:
        pilot.validate(self.map_data, self.clusters)


if __name__ == "__main__":
    unittest.main()
