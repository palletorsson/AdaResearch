"""Memory failures, not tests of Godot or learner understanding."""
from copy import deepcopy
import hashlib
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import museum_memory as memory


class SourceBoundaryTests(unittest.TestCase):
    def test_changed_and_missing_sources_are_not_current(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            target = root / "commons/maps/Trace/tutorial.md"
            target.parent.mkdir(parents=True)
            target.write_text("Keep original; change copy.", encoding="utf-8")
            receipts = {target.relative_to(root).as_posix(): hashlib.sha256(target.read_bytes()).hexdigest()}
            self.assertEqual(memory.freshness(root, receipts)[0]["status"], "unchanged")
            target.write_text("Change original.", encoding="utf-8")
            self.assertEqual(memory.freshness(root, receipts)[0]["status"], "changed")
            target.unlink()
            self.assertEqual(memory.freshness(root, receipts)[0]["status"], "missing")

    def test_path_escape_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaises(ValueError):
                memory.fingerprint(Path(folder), "../../outside.md")

    def test_subjects_are_explicit_not_inferred_from_code(self):
        self.assertEqual(memory.learning_elements("# Hall\n```gdscript\nfor i in range(5):\n pass\n```"), [])
        self.assertEqual(memory.learning_elements("**Learning elements**\n\n- Pickup\n- Local position\n\n- Unrelated later list"), ["Pickup", "Local position"])
        self.assertEqual(memory.learning_elements("**Learning elements — proposed focus**\n\n*The labels below set the revision focus; the existing lesson still needs alignment.*\n\n- Pickup\n"), ["Pickup"])


class LiveReadOnlyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data = memory.model(Path(__file__).resolve().parents[1])

    def test_every_live_hall_is_addressable(self):
        ids = [h["id"] for h in self.data["halls"]]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual(set(ids), {sid for s in self.data["sequences"] for sid in s["halls"]})
        for hall in self.data["halls"]:
            self.assertIn(hall["id"], memory.packet(self.data, hall["id"])["text"])

    def test_trace_grid_packet_retains_critical_distinctions(self):
        trace = memory.packet(self.data, "map:Point_Trace")["text"]
        grid = memory.packet(self.data, "map:Point_Line_Grid")["text"]
        for distinction in ("PointBody + LineSkin", "local metre", "no timestamps", "same project", "sha256=", "QUESTION:"):
            self.assertIn(distinction, trace)
        for distinction in ("Original positions and archive unchanged", "duplicate nodes, meshes and materials", "No save", "Rounding loses"):
            self.assertIn(distinction, grid)

    def test_old_findings_cannot_lose_their_status_or_evidence(self):
        text = memory.packet(self.data, "map:Point_Trace")["text"]
        for finding in next(h for h in self.data["halls"] if h["id"] == "map:Point_Trace")["findings"]:
            if finding["status"] != "dismissed":
                self.assertIn(finding["freshness"], text)
                for evidence in finding["sources"]:
                    self.assertIn(evidence["path"], text)

    def test_changed_shared_rules_reach_packet(self):
        changed = deepcopy(self.data)
        changed["rule_evidence"][0]["status"] = "changed"
        self.assertIn("RECHECK: shared teaching agreement changed", memory.packet(changed, "map:Point_One")["text"])

    def test_working_edits_reach_the_handoff_without_rewriting_capsules(self):
        changed = deepcopy(self.data)
        changed["core"]["open_question"] = "Compare the next boundary before changing order."
        changed["notes"]["sequence:primitives"] = {"summary": "Keep the point as the carried object."}
        text = memory.packet(changed, "sequence:primitives")["text"]
        self.assertIn("Compare the next boundary", text)
        self.assertIn("Keep the point as the carried object.", text)
        self.assertEqual(changed["halls"], self.data["halls"])

    def test_unknown_address_is_not_a_project_fallback(self):
        with self.assertRaisesRegex(ValueError, "Unknown"):
            memory.packet(self.data, "map:Imagined_Hall")

    def test_nonpilot_is_not_claimed_as_audited(self):
        hall = next(h for h in self.data["halls"] if not h["capsule"])
        text = memory.packet(self.data, hall["id"])["text"]
        self.assertIn("no inspected memory capsule", text)
        self.assertIn("SUBJECTS (verbatim tutorial labels;", text)


if __name__ == "__main__":
    unittest.main()
