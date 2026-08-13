#!/usr/bin/env python3
"""Focused behavior tests for placement_negotiator v1."""
from __future__ import annotations

import copy
import unittest

import placement_negotiator as negotiator


class PlacementNegotiatorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        offers = negotiator.load_json(negotiator.DEFAULT_OFFERS)["offers"]
        release_report = negotiator.load_json(negotiator.DEFAULT_RELEASE_REPORT)
        release = (
            release_report["artifacts"]
            + release_report.get("test_candidates", [])
            + release_report.get("wave3_candidates", [])
            + release_report.get("wave4_candidates", [])
        )
        cls.offers = {item["artifact"]: item for item in offers}
        cls.artifacts = {item["lookup_name"]: item for item in release}

    def decide(self, lookup: str, changes: dict | None = None) -> dict:
        offer = copy.deepcopy(self.offers[lookup])
        if changes:
            offer.update(changes)
        return negotiator.negotiate(
            offer,
            negotiator.room_for(lookup),
            self.artifacts[lookup],
        )

    def test_accepts_offer_already_at_preferred_size(self) -> None:
        decision = self.decide("origin", {"room_m": [5, 5, 3]})
        self.assertEqual("accept", decision["decision"])
        self.assertEqual("accepted", decision["status"])

    def test_rotates_to_an_authored_orientation(self) -> None:
        decision = self.decide("origin", {"room_m": [5, 5, 3], "rotation": 45})
        self.assertEqual("rotate", decision["decision"])
        self.assertEqual(0, decision["result"]["rotation"])

    def test_moves_from_an_unsupported_mode(self) -> None:
        decision = self.decide(
            "lambda_slider",
            {"room_m": [3, 3, 3], "mode": "ceiling", "wall_sides": ["north"]},
        )
        self.assertEqual("move", decision["decision"])
        self.assertEqual("against_wall", decision["result"]["mode"])

    def test_rejects_missing_required_wall(self) -> None:
        decision = self.decide(
            "lambda_slider",
            {"room_m": [3, 3, 3], "wall_sides": []},
        )
        self.assertEqual("reject", decision["decision"])
        self.assertEqual("rejected", decision["status"])

    def test_records_soft_compromise_without_failing_hard_zone(self) -> None:
        decision = self.decide(
            "platonicsolids",
            {"room_m": [9, 5, 4], "expansion_directions": []},
        )
        self.assertEqual("accepted", decision["status"])
        self.assertTrue(any(
            trace["outcome"] == "compromised" for trace in decision["rules_used"]
        ))

    def test_accepts_phi_on_a_working_height_host(self) -> None:
        decision = self.decide("phi_slider")
        self.assertEqual("accepted", decision["status"])
        self.assertTrue(any(
            trace["rule"] == "support_surface_height_is_usable"
            and trace["outcome"] == "pass"
            for trace in decision["rules_used"]
        ))

    def test_rejects_phi_when_host_is_too_low(self) -> None:
        decision = self.decide("phi_slider", {"support_surface_height_m": 0.4})
        self.assertEqual("reject", decision["decision"])
        self.assertIn("support surface height is unusable", decision["actions"][0]["reasons"])

    def test_rejects_room_scale_coordinates_in_a_small_offer(self) -> None:
        decision = self.decide(
            "CoordinateSystem3M",
            {"room_m": [7, 7, 6], "expansion_directions": []},
        )
        self.assertEqual("reject", decision["decision"])
        self.assertIn("floorplan cannot supply hard zone", decision["actions"][0]["reasons"])

    def test_rejects_dynamic_field_when_only_emitter_mesh_fits(self) -> None:
        decision = self.decide(
            "floating_sphere_field",
            {"room_m": [3, 3, 4], "expansion_directions": []},
        )
        self.assertEqual("reject", decision["decision"])
        self.assertIn("floorplan cannot supply hard zone", decision["actions"][0]["reasons"])

    def test_records_growth_needed_to_reach_hard_zone(self) -> None:
        decision = self.decide("gradient_descent_visualization")
        self.assertEqual("grow", decision["decision"])
        self.assertEqual([9, 9, 5], decision["result"]["room_m"])
        self.assertTrue(any(
            action["action"] == "grow" and action["to_m"] == [9, 9, 5]
            for action in decision["actions"]
        ))


if __name__ == "__main__":
    unittest.main()
