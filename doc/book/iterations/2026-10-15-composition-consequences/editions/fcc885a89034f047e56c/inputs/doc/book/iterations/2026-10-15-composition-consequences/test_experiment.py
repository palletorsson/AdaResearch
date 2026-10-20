"""Boundary checks; literary effects remain a separate reading question."""
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("experiment", Path(__file__).with_name("build.py"))
experiment = importlib.util.module_from_spec(spec)
spec.loader.exec_module(experiment)
base = experiment.base


class ExperimentBoundaries(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.files = experiment.gather()

    def test_complete_chapters_preserve_other_encounters_and_notes(self):
        outputs, comp, *_ = experiment.assemble(self.files)
        reference = outputs["reference.md"].decode()
        for id in ["repetition", "montage", "recurrence"]:
            body = outputs[id + ".md"].decode()
            self.assertNotEqual(body, reference)
            self.assertEqual(base.MARKER.findall(body), comp["order"])
            for artifact, passage in base.sections(reference).items():
                if artifact != "geiger_counter":
                    self.assertEqual(base.sections(body)[artifact], passage)
            self.assertEqual(body[body.index("[^record]:"):], reference[reference.index("[^record]:"):])

    def test_reference_drift_is_rejected(self):
        files = dict(self.files)
        comp = base.load(files, experiment.COMP + "/map.json")
        files[comp["baseline"]] += b"\nAn unreviewed sentence.\n"
        with self.assertRaisesRegex(AssertionError, "Reference drift"):
            experiment.validate(files)

    def test_receipt_mutation_is_rejected(self):
        files = dict(self.files)
        path = experiment.PILOT + "/candidates/montage.md"
        files[path] = files[path].replace(b"14:29:02", b"14:30:02")
        with self.assertRaisesRegex(AssertionError, "Receipt was changed"):
            experiment.validate(files)

    def test_predicted_effect_cannot_be_installed_as_observed(self):
        files = dict(self.files)
        data = base.load(files, experiment.EXPERIMENT)
        data["candidates"][0]["observed_effect"] = "Reader now understands replay."
        files[experiment.EXPERIMENT] = base.encoded(data)
        with self.assertRaisesRegex(AssertionError, "intention"):
            experiment.validate(files)

    def test_route_drift_still_requires_a_new_plan(self):
        files = dict(self.files)
        comp = base.load(files, experiment.COMP + "/map.json")
        wall = base.load(files, comp["wall"])
        a, b = [wall["order"].index(id) for id in comp["order"][:2]]
        wall["order"][a], wall["order"][b] = wall["order"][b], wall["order"][a]
        files[comp["wall"]] = base.encoded(wall)
        with self.assertRaisesRegex(AssertionError, "Room/Final order"):
            experiment.validate(files)


if __name__ == "__main__":
    unittest.main()
