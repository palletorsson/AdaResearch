#!/usr/bin/env python3
"""Regression tests for the architecture-first Uffizi cohort."""

from __future__ import annotations

import unittest

import build_uffizi_footprint_cohort as cohort


class UffiziFootprintCohortTests(unittest.TestCase):
    def setUp(self) -> None:
        self.map_data, self.base_offer = cohort.build_map("Test_Uffizi_Cohort")
        self.assignments = self.map_data["map_info"]["metadata"]["placement_overlay"]

    def by_name(self, artifact: str) -> dict:
        return next(a for a in self.assignments if a["artifact"] == artifact)

    def test_pass_one_is_ten_identical_artifact_independent_bays(self) -> None:
        geometry = self.base_offer["geometry"]
        self.assertEqual([geometry["width"], geometry["depth"]], [15, 85])
        self.assertEqual(len(geometry["bays"]), 10)
        self.assertTrue(all(bay["room_width"] == 8 for bay in geometry["bays"]))
        self.assertTrue(all(bay["depth"] == 7 for bay in geometry["bays"]))

    def test_only_requesting_bays_expand_westward(self) -> None:
        expected = {
            "origin": 8,
            "lambda_slider": 8,
            "phi_slider": 8,
            "platonicsolids": 11,
            "random_walk_leash": 8,
            "shannon_entropy_meter": 8,
            "harmonic_distance_table": 8,
            "pattern_loom": 8,
            "gradient_descent_visualization": 13,
            "neural_network_visualization": 14,
        }
        actual = {a["artifact"]: a["derived_offer_m"][0] for a in self.assignments}
        self.assertEqual(actual, expected)

    def test_only_long_artifacts_lengthen_the_spine(self) -> None:
        self.assertEqual(self.by_name("pattern_loom")["derived_offer_m"][1], 8)
        self.assertEqual(self.by_name("gradient_descent_visualization")["derived_offer_m"][1], 13)
        for assignment in self.assignments:
            if assignment["artifact"] not in {"pattern_loom", "gradient_descent_visualization"}:
                self.assertEqual(assignment["derived_offer_m"][1], 7)
        self.assertEqual(self.map_data["map_info"]["dimensions"]["depth"], 92)

    def test_clear_spine_has_no_artifact_claims(self) -> None:
        footprints = self.map_data["layers"]["footprints"]
        interactables = self.map_data["layers"]["interactables"]
        architecture = self.map_data["map_info"]["metadata"]["architecture_contract"]
        room_width = architecture["derived_dimensions_m"][0] - 7
        geometry = cohort.plan_geometry(
            room_width,
            [a["derived_offer_m"][1] for a in self.assignments],
            [a["derived_offer_m"][0] for a in self.assignments],
        )
        for z in range(geometry["bays"][-1]["partition"] + 1):
            for x in range(geometry["clear_spine_x0"], geometry["clear_spine_x1"] + 1):
                self.assertEqual(footprints[z][x], "")
                self.assertEqual(interactables[z][x], " ")

    def test_support_contracts_raise_exact_anchor_tile(self) -> None:
        structure = self.map_data["layers"]["structure"]
        for artifact in ("origin", "phi_slider", "platonicsolids", "harmonic_distance_table"):
            assignment = self.by_name(artifact)
            x, z = assignment["anchor"]
            self.assertEqual(structure[z][x], "2", artifact)

    def test_wall_contracts_keep_north_partition_support(self) -> None:
        structure = self.map_data["layers"]["structure"]
        for artifact in ("lambda_slider", "shannon_entropy_meter"):
            assignment = self.by_name(artifact)
            x, z = assignment["anchor"]
            self.assertEqual(structure[z - 1][x], "4", artifact)

    def test_full_contract_validator_accepts_generated_map(self) -> None:
        cohort.validate_contracts(self.map_data)


if __name__ == "__main__":
    unittest.main()
