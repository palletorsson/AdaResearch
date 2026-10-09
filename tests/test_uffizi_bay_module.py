import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import build_uffizi_bay_module as bay  # noqa: E402


class UffiziBayModuleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.spec = bay.load_spec()
        cls.module = cls.spec["modules"][bay.MODULE]

    def test_contract_certifies(self):
        report = bay.certify(self.spec)
        self.assertTrue(report["passed"], report)
        self.assertTrue(all(report["checks"].values()))

    def test_two_bay_sockets_meet_without_gap(self):
        length = self.module["cells"][0]
        east_a = -length / 2 + self.module["sockets"]["east"]["at_m"][0]
        west_b = length / 2 + self.module["sockets"]["west"]["at_m"][0]
        self.assertEqual(east_a, west_b)

    def test_generated_maps_are_compact_and_one_metre(self):
        for name in ("Museum_AAA_Uffizi_Bay_V1", "Museum_AAA_Uffizi_Bay_Seam_Test"):
            path = ROOT / "commons/maps" / name / "map_data.json"
            data = json.loads(path.read_text(encoding="utf-8"))
            self.assertEqual(data["settings"]["cube_size"], 1.0)
            self.assertFalse(data["settings"]["show_grid"])
            self.assertNotIn("\n ", path.read_text(encoding="utf-8"))

    def test_feature_and_prop_zones_do_not_compete(self):
        half_feature = self.module["feature_field"]["width_m"] / 2
        for zone in self.module["prop_zones"]:
            self.assertTrue(zone["x_m"][1] <= -half_feature or zone["x_m"][0] >= half_feature)

    def test_navigation_uses_canonical_spawn_and_void_exit(self):
        for name in ("Museum_AAA_Uffizi_Bay_V1", "Museum_AAA_Uffizi_Bay_Seam_Test"):
            data = json.loads((ROOT / "commons/maps" / name / "map_data.json").read_text(encoding="utf-8"))
            self.assertEqual(data["layers"]["utilities"][1][1], "s")
            exit_col = data["map_info"]["dimensions"]["width"] - 2
            self.assertEqual(data["layers"]["utilities"][1][exit_col], "t")
            self.assertEqual(data["layers"]["structure"][1][exit_col], "0")


if __name__ == "__main__":
    unittest.main()
