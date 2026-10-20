"""Test boundaries that protect evidence, route agreement and retained editions."""
import copy
import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("pilot", Path(__file__).with_name("build.py"))
pilot = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pilot)


class CompositionBoundaries(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.files = pilot.gather()

    def test_candidates_change_only_geiger_opening(self):
        outputs, comp, *_ = pilot.assemble(self.files)
        reference = outputs["reference.md"].decode()
        for candidate in comp["pilot"]["candidate_ids"]:
            body = outputs[candidate + ".md"].decode()
            self.assertNotEqual(reference, body)
            self.assertEqual(pilot.MARKER.findall(reference), pilot.MARKER.findall(body))
            self.assertEqual(reference[reference.index("All 96 detection times"):], body[body.index("All 96 detection times"):])
            for id, passage in pilot.sections(reference).items():
                if id != "geiger_counter":
                    self.assertEqual(passage, pilot.sections(body)[id])

    def test_unknown_relationship_rejected(self):
        files = dict(self.files)
        name = pilot.COMP + "/relationships.json"
        graph = pilot.load(files, name)
        graph["edges"][0]["to"] = "invented_artifact"
        files[name] = pilot.encoded(graph)
        with self.assertRaisesRegex(AssertionError, "endpoint"):
            pilot.validate(files)

    def test_changed_room_order_does_not_silently_rewrite_prose(self):
        files = dict(self.files)
        comp = pilot.load(files, pilot.COMP + "/map.json")
        wall = pilot.load(files, comp["wall"])
        first, second = [wall["order"].index(id) for id in comp["order"][:2]]
        wall["order"][first], wall["order"][second] = wall["order"][second], wall["order"][first]
        files[comp["wall"]] = pilot.encoded(wall)
        with self.assertRaisesRegex(AssertionError, "Room/Final order"):
            pilot.validate(files)

    def test_missing_evidence_locator_rejected(self):
        files = dict(self.files)
        files["commons/artifacts/geiger_counter/geiger_model.gd"] = b"# removed implementation"
        with self.assertRaisesRegex(AssertionError, "Evidence locator"):
            pilot.validate(files)

    def test_retained_corruption_is_detected(self):
        with tempfile.TemporaryDirectory() as temp:
            folder = Path(temp)
            (folder / "inputs").mkdir()
            (folder / "inputs/evidence.txt").write_bytes(b"record")
            (folder / "candidate.md").write_bytes(b"passage")
            manifest = {"inputs": {"evidence.txt": pilot.sha(b"record")}, "outputs": {"candidate.md": pilot.sha(b"passage")}}
            pilot.verify(folder, manifest)
            (folder / "candidate.md").write_bytes(b"silent replacement")
            with self.assertRaisesRegex(AssertionError, "Retained file changed"):
                pilot.verify(folder, manifest)


if __name__ == "__main__":
    unittest.main()
