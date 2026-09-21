"""Fixtures for evidence freshness, live reuse and complete planning coverage."""
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

try:
    from . import museum_actions as actions
except ImportError:
    import museum_actions as actions


class MuseumActionsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "repo"
        self.root.mkdir()
        self.digest = self.write("fixtures/source.txt", "Current source evidence.")
        self.rooms = [self.room("A", "first", 1, ["x", "y"]), self.room("B", "first", 2, ["y", "z"]),
                      self.room("C", "second", 3, ["z"])]

    def room(self, room_id, sequence, index, tokens):
        return {"id": room_id, "name": "Room " + room_id, "sequence": sequence, "index": index,
                "text": {"exists": True, "words": 30, "missing_tags": []},
                "space": {"tokens": tokens, "primary": tokens[:1], "placed_count": len(tokens)},
                "outline": {"status": "authored_proposal", "question": "What changes?", "experiment": "Move a point.",
                            "observe": "Compare the positions.", "limit": "Which movement does the readout omit?"},
                "verification": {"baseline_ready": False}, "issues": [], "next_action": "Inspect the encounter."}

    def write(self, relative, contents):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents, encoding="utf-8")
        return hashlib.sha256(path.read_bytes()).hexdigest()

    def save(self, entries):
        self.write(actions.ACTION_PATH, json.dumps({"actions": entries}))

    def proposal(self, **changes):
        entry = {"id": "inspect-a", "room_id": "A", "title": "Check the moving point", "stage": "proposal",
                 "status": "ready", "priority": 1, "why": "The readout may omit movement.",
                 "next_step": "Move the point twice.", "done_when": ["One observation recorded."],
                 "registers": ["space", "book"], "critical_question": "What is omitted?",
                 "evidence": [{"path": "fixtures/source.txt", "sha256": self.digest}],
                 "dependencies": [], "reuse": {"principle": "Retain a visible trace.", "mechanism": "Point trace.",
                 "tokens": ["x", "y", "absent"], "method_rooms": [{"id": "B", "reason": "Another room."},
                 {"id": "C", "reason": "Different relation."}], "second_room": "C", "second_test": "Compare settings.",
                 "limits": ["No behavior tested yet."], "lesson_ids": []}}
        entry.update(changes)
        return entry

    def curated(self, output):
        return next(action for action in output["actions"] if action["kind"] == "curated")

    def test_current_hash_preserves_ready_and_never_completes(self):
        digest = self.write("fixtures/a.gd", "var value = 1\n")
        self.save([self.proposal(evidence=[{"path": "fixtures/a.gd", "sha256": digest}])])
        item = self.curated(actions.build_work_queue(self.root, self.rooms))
        self.assertEqual(item["status"], "ready")
        self.assertEqual(item["stage"], "proposal")
        self.assertEqual(item["evidence"], [{"path": "fixtures/a.gd", "changed": False, "missing": False}])

    def test_changed_source_requires_recheck(self):
        digest = self.write("fixtures/a.gd", "var value = 1\n")
        self.save([self.proposal(evidence=[{"path": "fixtures/a.gd", "sha256": digest}])])
        self.write("fixtures/a.gd", "var value = 2\n")
        output = actions.build_work_queue(self.root, self.rooms)
        item = self.curated(output)
        self.assertEqual(item["status"], "recheck")
        self.assertTrue(item["evidence"][0]["changed"])
        self.assertFalse(item["evidence"][0]["missing"])
        self.assertEqual(output["actions"][0]["kind"], "scaffold")

    def test_missing_source_and_nonready_states(self):
        self.save([self.proposal(evidence=[{"path": "missing.gd", "sha256": "0" * 64}])])
        item = self.curated(actions.build_work_queue(self.root, self.rooms))
        self.assertEqual(item["status"], "recheck")
        self.assertTrue(item["evidence"][0]["missing"])
        for status in ("blocked", "deferred", "closed"):
            self.save([self.proposal(status=status, evidence=[{"path": "missing.gd", "sha256": "0" * 64}])])
            self.assertEqual(self.curated(actions.build_work_queue(self.root, self.rooms))["status"], status)

    def test_ready_curated_proposal_without_evidence_requires_recheck(self):
        self.save([self.proposal(evidence=[])])
        item = self.curated(actions.build_work_queue(self.root, self.rooms))
        self.assertEqual(item["status"], "recheck")
        self.assertIn("No source evidence", item["source_note"])

    def test_evidence_cannot_escape_repository(self):
        outside = self.root.parent / "outside.txt"
        outside.write_text("outside content", encoding="utf-8")
        digest = hashlib.sha256(outside.read_bytes()).hexdigest()
        self.save([self.proposal(evidence=[{"path": "../outside.txt", "sha256": digest},
                                          {"path": str(outside), "sha256": digest}])])
        item = self.curated(actions.build_work_queue(self.root, self.rooms))
        self.assertEqual(item["status"], "recheck")
        self.assertTrue(all(row["reason"] == "outside_repository" for row in item["evidence"]))
        self.assertTrue(all(row["missing"] for row in item["evidence"]))

    def test_shared_tokens_are_exact_and_methods_join_only_live_rooms(self):
        proposal = self.proposal()
        proposal["reuse"]["method_rooms"] += [{"id": "obsolete", "reason": "Removed"}, {"id": "A", "reason": "Self"}]
        self.save([proposal])
        reuse = self.curated(actions.build_work_queue(self.root, self.rooms))["reuse"]
        self.assertEqual(reuse["shared_rooms"], [{"id": "B", "name": "Room B", "sequence": "first", "tokens": ["y"]}])
        self.assertEqual(reuse["method_rooms"], [{"id": "C", "name": "Room C", "sequence": "second", "reason": "Different relation."}])
        # Moving the shared token changes the derived candidates immediately.
        self.rooms[1]["space"]["tokens"] = ["z"]
        updated = self.curated(actions.build_work_queue(self.root, self.rooms))["reuse"]
        self.assertEqual(updated["shared_rooms"], [])
        self.assertEqual([row["id"] for row in updated["method_rooms"]], ["B", "C"])

    def test_removed_rooms_do_not_receive_or_remain_recommendations(self):
        self.save([self.proposal(room_id="obsolete", id="old"), self.proposal()])
        live = self.rooms[:2]
        output = actions.build_work_queue(self.root, live)
        self.assertNotIn("old", [row["id"] for row in output["actions"]])
        reuse = self.curated(output)["reuse"]
        self.assertIsNone(reuse["second_room"])
        self.assertEqual(reuse["method_rooms"], [])
        self.assertEqual({row["room_id"] for row in output["actions"]}, {"A", "B"})

    def test_closed_or_deferred_action_retains_record_and_offers_next_room_task(self):
        for status in ("closed", "deferred"):
            self.save([self.proposal(status=status)])
            output = actions.build_work_queue(self.root, self.rooms)
            room_actions = [item for item in output["actions"] if item["room_id"] == "A"]
            self.assertEqual([item["kind"] for item in room_actions], ["scaffold", "curated"])
            self.assertEqual(room_actions[1]["status"], status)
            self.assertFalse(self.rooms[0]["verification"]["baseline_ready"])
        # Optional development of an already reviewed room follows unfinished rooms.
        self.rooms[0]["verification"]["baseline_ready"] = True
        output = actions.build_work_queue(self.root, self.rooms)
        scaffolds = [item for item in output["actions"] if item["kind"] == "scaffold"]
        self.assertEqual([item["room_id"] for item in scaffolds], ["B", "C", "A"])

    def test_removing_token_from_pilot_removes_exact_reuse_claim(self):
        self.save([self.proposal()])
        before = self.curated(actions.build_work_queue(self.root, self.rooms))["reuse"]
        self.assertEqual(before["shared_rooms"][0]["tokens"], ["y"])
        self.rooms[0]["space"]["tokens"] = ["x"]
        after = self.curated(actions.build_work_queue(self.root, self.rooms))["reuse"]
        self.assertEqual(after["tokens"], ["x", "y", "absent"])
        self.assertEqual(after["shared_rooms"], [])
        self.assertEqual([item["id"] for item in after["method_rooms"]], ["B", "C"])

    def test_fallback_covers_every_other_sequence_and_preserves_live_order(self):
        self.save([self.proposal()])
        self.rooms[1]["outline"]["status"] = "source_scaffold"
        self.rooms[2]["text"] = {"exists": False, "words": 0, "missing_tags": []}
        output = actions.build_work_queue(self.root, list(reversed(self.rooms)))
        self.assertEqual([(row["room_id"], row["kind"]) for row in output["actions"]],
                         [("A", "curated"), ("B", "scaffold"), ("C", "scaffold")])
        self.assertIn("outline", output["actions"][1]["title"])
        self.assertIn("Draft the opening", output["actions"][2]["title"])
        self.assertEqual(output["actions"][2]["sequence"], "second")
        self.assertEqual(output["lesson_path"], "doc/curation_lessons.json")

    def test_scaffold_reuse_requires_current_primary_tokens(self):
        self.rooms[0]["space"]["primary"] = ["gone"]
        self.rooms[0]["verification"]["baseline_ready"] = True
        output = actions.build_work_queue(self.root, self.rooms)
        item = next(item for item in output["actions"] if item["room_id"] == "A")
        self.assertEqual(item["reuse"]["tokens"], [])
        self.assertEqual(item["reuse"]["shared_rooms"], [])
        self.assertEqual(item["reuse"]["mechanism"], "")
        self.assertIn("optional variation", item["title"])

    def test_iteration_observations_do_not_accept_rooms_or_close_actions(self):
        self.save([self.proposal(observations=[{"observed": "Isolated engine check passed."}])])
        before = deepcopy(self.rooms)
        report = {"items": [{"id": 1, "status": "checked"}], "lessons": [], "next_action": "Walk with a learner."}
        path = self.root / actions.ITERATION_PATH
        path.write_text(json.dumps(report), encoding="utf-8")
        output = actions.build_work_queue(self.root, self.rooms)
        self.assertEqual(output["iteration"], report)
        self.assertEqual(self.curated(output)["status"], "ready")
        self.assertEqual(self.curated(output)["observations"][0]["observed"], "Isolated engine check passed.")
        self.assertEqual(self.rooms, before)
        path.unlink()
        self.assertNotIn("iteration", actions.build_work_queue(self.root, self.rooms))

    def test_no_writes_or_mutation_of_room_inputs(self):
        self.save([self.proposal()])
        originals = deepcopy(self.rooms)
        before = {path.relative_to(self.root).as_posix(): path.read_bytes() for path in self.root.rglob("*") if path.is_file()}
        actions.build_work_queue(self.root, self.rooms)
        after = {path.relative_to(self.root).as_posix(): path.read_bytes() for path in self.root.rglob("*") if path.is_file()}
        self.assertEqual(originals, self.rooms)
        self.assertEqual(before, after)


if __name__ == "__main__":
    unittest.main()
