#!/usr/bin/env python3
from __future__ import annotations

import unittest

import dedicated_world_register as worlds


class DedicatedWorldRegisterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.register = worlds.build_register()

    def test_current_refusal_tail_is_explicit(self) -> None:
        summary = self.register["summary"]
        self.assertEqual(29, summary["chapter_occurrences"])
        self.assertEqual(28, summary["artifacts"])
        self.assertEqual(21, summary["site_families"])
        self.assertEqual(7, summary["aliases_collapsed"])

    def test_long_thin_work_is_not_misclassified_as_a_world(self) -> None:
        tokens = {a["token"] for a in self.register["artifacts"]}
        self.assertNotIn("laser_measure", tokens)
        self.assertNotIn("combine_portals", tokens)
        self.assertIn("mc_cave", tokens)

    def test_scene_aliases_share_one_site(self) -> None:
        family = next(s for s in self.register["sites"]
                      if "mc_cave" in s["members"])
        self.assertEqual(["marchingcubes_cave", "mc_cave"], family["members"])
        physarum = next(s for s in self.register["sites"]
                        if "PhysarumColony" in s["members"])
        self.assertEqual({"PhysarumColony", "physarum_colony"},
                         set(physarum["members"]))

    def test_site_envelope_covers_every_member_plus_apron(self) -> None:
        by_token = {a["token"]: a for a in self.register["artifacts"]}
        for site in self.register["sites"]:
            self.assertIsNone(site["site_contract"]["formula"])
            self.assertTrue(site["site_contract"]["continuous_player_route_required"])
            for token in site["members"]:
                member = by_token[token]
                for axis in (0, 1):
                    self.assertGreaterEqual(site["site_envelope_m"][axis],
                                            member["site_envelope_m"][axis])

    def test_every_site_id_is_stable_and_unique(self) -> None:
        ids = [s["site_id"] for s in self.register["sites"]]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertTrue(all(i.startswith("world-") for i in ids))


if __name__ == "__main__":
    unittest.main()
