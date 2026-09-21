"""Fixture tests for live membership, drift signals and honest completion state."""
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

try:
    from . import museum_progress as progress
except ImportError:
    import museum_progress as progress


class MuseumProgressTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.write_json("commons/maps/curriculum_spine.json", {
            "spine": {"sequences": [{"name": "later", "order": 2}, {"name": "first", "order": 1}]}})
        self.sequence("first", ["A", "B"])
        self.sequence("later", ["C"])
        for room in ("A", "B", "C"):
            self.map(room, ["a"])
            self.write(f"commons/maps/{room}/blurb.md", f"{room} explores a relation between position and movement.")
        self.write_json("commons/data/artifact_roles.json", {
            "roles": {"A": {"a": "primary"}}, "order": {}, "groups": {}})
        self.write_json("commons/data/spine_briefs.json", {"briefs": {"B": {
            "for": "Compare retained positions.", "claim": "The trace retains earlier positions.",
            "unsure": "Its memory limit is not yet checked."}}})

    def write(self, path, value):
        dest = self.root / path
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(value, encoding="utf-8")

    def write_json(self, path, value):
        self.write(path, json.dumps(value))

    def sequence(self, name, maps):
        self.write_json(f"commons/maps/sequences/{name}.json", {
            "sequences": {name: {"name": name.title(), "maps": maps, "truth": "A source proposition."}}})

    def map(self, room, artifacts, utilities=None):
        self.write_json(f"commons/maps/{room}/map_data.json", {
            "map_info": {"name": room}, "layers": {
                "interactables": [artifacts], "utilities": [utilities or []]}})

    def room(self, payload, room_id="A"):
        return next(room for room in payload["rooms"] if room["id"] == room_id)

    def lobby(self, room="A", **settings):
        path = f"commons/maps/{room}/map_data.json"
        data = json.loads((self.root / path).read_text(encoding="utf-8"))
        data["map_info"]["museum"] = {"lobby": settings}
        self.write_json(path, data)

    def lobby_provider(self):
        self.write("commons/scenes/endless_museum.gd", 'const LOBBY_PIECES := {\n'
                   '    "view": "res://commons/primitives/temporal/animated_folding_past.tscn",\n}\n')
        self.write("commons/primitives/temporal/animated_folding_past.tscn",
                   '[gd_scene format=3]\n[node name="FoldingPast" type="Node3D"]\n')

    def test_live_spine_membership_and_cross_sequence_handoffs(self):
        first = progress.build_progress(self.root)
        self.assertEqual([r["id"] for r in first["rooms"]], ["A", "B", "C"])
        self.assertEqual(self.room(first, "B")["next"], "C")
        self.assertEqual(self.room(first, "C")["previous"], "B")
        # A stale artifact manifest or old outline must not own membership.
        self.write_json("commons/data/spine_artifact_order.json", {"order": [{"map": "B"}]})
        self.write_json("commons/data/completion_outlines/old.json", {"rooms": {"B": {"question": "Old"}}})
        self.sequence("first", ["D", "A"])
        self.map("D", ["new"])
        changed = progress.build_progress(self.root)
        self.assertEqual([r["id"] for r in changed["rooms"]], ["D", "A", "C"])
        self.assertEqual(changed["meta"]["rooms"], 3)
        self.assertEqual(changed["meta"]["orphan_outlines"], ["B"])
        self.assertEqual(self.room(changed)["next"], "C")
        self.assertEqual(self.room(changed, "D")["previous"], None)

    def test_empty_manuscript_is_not_written(self):
        self.write("commons/maps/A/final.md", "# Title only\n\n<!-- @a -->\n   ")
        self.write("commons/maps/B/final.md", "A useful sentence about the experiment.")
        data = progress.build_progress(self.root)
        self.assertTrue(self.room(data)["text"]["exists"])
        self.assertEqual(self.room(data)["text"]["words"], 0)
        self.assertEqual(data["meta"]["written"], 1)
        self.assertIn("empty_text", [i["kind"] for i in self.room(data)["issues"]])
        self.assertEqual(data["meta"]["baseline_ready"], 0)

    def test_grouped_roles_order_and_unruled_inventory(self):
        self.map("A", ["b:90#offset:1,2,3", "a", "c", "other", "b", "-", "", "decor"], ["3t:hello", "t:B"])
        self.write_json("commons/data/artifact_roles.json", {
            "roles": {"A": {"a": "primary", "b": {"role": "primary", "group": "pair"},
                            "c": {"role": "primary", "group": "pair"}, "decor": "decoration", "3t": "secondary"}},
            "order": {"A": {"primary": ["@pair", "a", "gone"], "primary|pair": ["c", "b"]}},
            "groups": {"A": [{"id": "pair", "role": "primary"}]}})
        space = self.room(progress.build_progress(self.root))["space"]
        self.assertEqual(space["primary"], ["c", "b", "a"])
        self.assertEqual(space["secondary"], ["3t"])
        self.assertEqual(space["unruled"], ["other"])
        self.assertEqual(space["placed_count"], 6)
        self.assertEqual(space["exits"], ["B"])
        self.assertNotIn("@pair", space["tokens"])

    def test_removed_artifact_tags_and_valid_utility_tags(self):
        self.map("A", ["a"], ["#3t:room_label"])
        self.write("commons/maps/A/final.md", "<!-- @a -->\nSee a.\n<!-- @3t -->\nRead the sign.\n<!-- @gone -->\nMove it.\n")
        room = self.room(progress.build_progress(self.root))
        self.assertEqual(room["text"]["tags"], ["a", "3t", "gone"])
        self.assertEqual(room["text"]["missing_tags"], ["gone"])
        self.map("A", ["a", "gone"], ["3t:room_label"])
        self.assertEqual(self.room(progress.build_progress(self.root))["text"]["missing_tags"], [])

    def test_opening_lobby_resolves_only_its_generated_text_reference(self):
        self.lobby_provider()
        self.lobby(enabled=True)
        self.write("commons/maps/A/final.md",
                   "<!-- @a -->\nSee a.\n<!-- @folding_past -->\nLook through the window.\n"
                   "<!-- @gone -->\nThis object is still missing.\n")
        room = self.room(progress.build_progress(self.root))
        self.assertEqual(room["text"]["missing_tags"], ["gone"])
        space = room["space"]
        self.assertEqual(space["tokens"], ["a"])
        self.assertEqual(space["placed_count"], 1)
        self.assertEqual(space["primary"], ["a"])
        generated, = space["generated_artifacts"]
        self.assertEqual(generated["token"], "folding_past")
        self.assertEqual(generated["runtime_token"], "lobby:view")
        self.assertEqual(generated["configuration_source"], "commons/maps/A/map_data.json")
        self.assertEqual(generated["configuration"]["with_view"], 1)
        self.assertEqual(generated["status"], "configured")
        self.assertFalse(generated["runtime_verified"])
        self.assertFalse(room["verification"]["baseline_ready"])
        self.assertEqual(room["verification"]["status"], "unverified")

        # A generated reference cannot supply a missing primary/grid encounter.
        self.map("A", [])
        self.lobby(enabled=True)
        self.write_json("commons/data/artifact_roles.json", {"roles": {"A": {"folding_past": "primary"}}})
        empty = self.room(progress.build_progress(self.root))
        self.assertEqual(empty["space"]["placed_count"], 0)
        self.assertEqual(empty["space"]["primary"], [])
        self.assertIn("no_artifacts", [issue["kind"] for issue in empty["issues"]])
        self.assertFalse(empty["verification"]["baseline_ready"])

    def test_generated_lobby_requires_explicit_enabled_map_and_enabled_view(self):
        self.lobby_provider()
        self.write("commons/maps/A/final.md", "<!-- @folding_past -->\nLook through the window.\n")
        self.write_json("commons/data/em_layout.json", {"lobby": {"enabled": True}})
        for settings in ({}, {"enabled": False}, {"enabled": 0.5}, {"enabled": "invalid"},
                         {"enabled": True, "with_view": False}, {"enabled": True, "with_view": 0.5},
                         {"enabled": True, "with_view": None}):
            with self.subTest(settings=settings):
                self.lobby(**settings)
                room = self.room(progress.build_progress(self.root))
                self.assertEqual(room["text"]["missing_tags"], ["folding_past"])
                self.assertEqual(room["space"]["generated_artifacts"], [])
        self.lobby(enabled=True)
        self.write_json("commons/data/em_layout.json", {"lobby": {"with_view": 0}})
        self.assertEqual(self.room(progress.build_progress(self.root))["text"]["missing_tags"], ["folding_past"])
        self.lobby(enabled=True, with_view=1)
        self.assertEqual(self.room(progress.build_progress(self.root))["text"]["missing_tags"], [])

    def test_generated_lobby_requires_current_provider_and_scene(self):
        self.lobby(enabled=True)
        self.write("commons/maps/A/final.md", "<!-- @folding_past -->\nLook through the window.\n")
        for missing in ("commons/scenes/endless_museum.gd",
                        "commons/primitives/temporal/animated_folding_past.tscn"):
            with self.subTest(missing=missing):
                self.lobby_provider()
                (self.root / missing).unlink()
                self.assertEqual(self.room(progress.build_progress(self.root))["text"]["missing_tags"], ["folding_past"])
        self.lobby_provider()
        self.write("commons/scenes/endless_museum.gd",
                   'const LOBBY_PIECES := {\n    "view": "res://different_scene.tscn",\n}\n')
        self.assertEqual(self.room(progress.build_progress(self.root))["text"]["missing_tags"], ["folding_past"])

    def test_generated_lobby_belongs_only_to_first_room_in_live_spine(self):
        self.lobby_provider()
        for room in ("A", "B", "C"):
            self.lobby(room, enabled=True)
            self.write(f"commons/maps/{room}/final.md", "<!-- @folding_past -->\nLook through the window.\n")
        before = progress.build_progress(self.root)
        self.assertEqual(self.room(before, "A")["text"]["missing_tags"], [])
        for room in ("B", "C"):
            self.assertEqual(self.room(before, room)["text"]["missing_tags"], ["folding_past"])
        self.sequence("first", ["B", "A"])
        after = progress.build_progress(self.root)
        self.assertEqual(self.room(after, "B")["text"]["missing_tags"], [])
        self.assertEqual(self.room(after, "A")["text"]["missing_tags"], ["folding_past"])

    def test_generated_reference_changes_invalidate_saved_review(self):
        self.lobby_provider()
        self.lobby(enabled=True)
        self.write("commons/maps/A/final.md", "<!-- @folding_past -->\nLook through the window.\n")
        initial = self.room(progress.build_progress(self.root))
        self.write_json("commons/data/completion_reviews.json", {"rooms": {"A": {
            "reviewer": "Fixture reviewer", "reviewed_at": "2026-09-08", "fingerprint": initial["fingerprint"],
            "evidence": {key: "Recorded fixture observation for " + key for key in progress.EVIDENCE_FIELDS}}}})
        self.assertTrue(self.room(progress.build_progress(self.root))["verification"]["baseline_ready"])
        self.write("commons/primitives/temporal/animated_folding_past.tscn",
                   '[gd_scene format=3]\n[node name="ChangedFoldingPast" type="Node3D"]\n')
        changed = self.room(progress.build_progress(self.root))
        self.assertEqual(changed["text"]["missing_tags"], [])
        self.assertEqual(changed["verification"]["status"], "needs_review")
        self.assertFalse(changed["verification"]["baseline_ready"])

    def test_source_scaffolds_retain_attribution_and_uncertainty(self):
        data = progress.build_progress(self.root)
        b = self.room(data, "B")["outline"]
        self.assertEqual(data["meta"]["outlined"], 0)
        self.assertEqual(data["meta"]["source_scaffolded"], 3)
        self.assertIn("unreviewed", b["ontology"])
        self.assertIn("retains earlier positions", b["ontology"])
        self.assertIn("memory limit", b["limit"])
        self.assertIn("commons/data/spine_briefs.json", b["sources"])
        for room in data["rooms"]:
            self.assertTrue(all(room["outline"][key] for key in progress.OUTLINE_FIELDS))
            self.assertEqual(room["verification"]["status"], "unverified")

    def test_authored_overlay_is_a_proposal_and_preserves_comments(self):
        comment = "The point is the wrong starting question."
        self.write_json("commons/data/spine_briefs.json", {"briefs": {"A": {
            "comment": comment, "commented_at": "2026-09-08", "claim": "A source claim."}}})
        self.write_json("commons/data/completion_outlines/first.json", {
            "_meta": {"sequence": "first", "status": "authored_proposal"}, "rooms": {"A": {
                **{field: "Authored proposal for " + field for field in progress.OUTLINE_FIELDS},
                "question": "What survives a change of frame?", "ontology": "A position requires a frame.",
                "candidate_artifacts": ["not_built"], "sources": ["doc/proposal.md"],
                "open_questions": ["Does the readout follow a changed reference frame?"],
                "status": "verified", "baseline_ready": True,
                "verification": {"status": "verified", "baseline_ready": True}}}})
        data = progress.build_progress(self.root)
        room = self.room(data)
        self.assertEqual(data["meta"]["outlined"], 1)
        self.assertEqual(room["outline"]["status"], "authored_proposal")
        self.assertEqual(room["outline"]["question"], "What survives a change of frame?")
        self.assertIn("commons/data/completion_outlines/first.json", room["outline"]["sources"])
        self.assertEqual(room["verification"]["status"], "unverified")
        self.assertFalse(room["verification"]["baseline_ready"])
        self.assertEqual(room["comment"], comment)
        kinds = [i["kind"] for i in room["issues"]]
        self.assertIn("proposed_artifacts", kinds)
        self.assertIn("user_comment", kinds)
        self.assertIn("authoring_question", kinds)

    def test_partial_authorship_does_not_count_as_complete_outline(self):
        self.write_json("commons/data/completion_outlines/first.json", {"rooms": {"A": {
            "question": "What survives a change of frame?", "status": "authored_proposal"}}})
        data = progress.build_progress(self.root)
        room = self.room(data)
        self.assertEqual(data["meta"]["outlined"], 0)
        self.assertEqual(room["outline"]["status"], "source_scaffold")
        self.assertEqual(room["outline"]["authored_fields"], ["question"])
        self.assertEqual(room["outline"]["question"], "What survives a change of frame?")
        self.assertIn("missing_outline_fields", [i["kind"] for i in room["issues"]])

    def test_review_requires_evidence_and_current_inputs(self):
        self.write("commons/maps/A/final.md", "<!-- @a -->\nChange the value and observe the result.\n")
        self.write_json("commons/artifacts/registry/test.json", {"artifacts": {"a": {"scene": "res://fixtures/a.tscn"}}})
        self.write("fixtures/a.tscn", '[ext_resource type="Script" path="res://fixtures/a.gd" id="1"]')
        self.write("fixtures/a.gd", "extends Node\nvar value = 1\n")
        data = progress.build_progress(self.root)
        record = {"reviewer": "Fixture reviewer", "reviewed_at": "2026-09-08", "fingerprint": self.room(data)["fingerprint"],
                  "evidence": {key: "Recorded fixture observation for " + key for key in progress.EVIDENCE_FIELDS}}
        self.write_json("commons/data/completion_reviews.json", {"rooms": {"A": record}})
        reviewed = self.room(progress.build_progress(self.root))
        self.assertTrue(reviewed["verification"]["baseline_ready"])
        record["evidence"]["behavior"] = ""
        self.write_json("commons/data/completion_reviews.json", {"rooms": {"A": record}})
        self.assertFalse(self.room(progress.build_progress(self.root))["verification"]["baseline_ready"])
        record["evidence"]["behavior"] = "Observed value change."
        self.write_json("commons/data/completion_reviews.json", {"rooms": {"A": record}})
        self.write("fixtures/a.gd", "extends Node\nvar value = 2\n")
        changed = self.room(progress.build_progress(self.root))
        self.assertEqual(changed["verification"]["status"], "needs_review")
        self.assertFalse(changed["verification"]["baseline_ready"])
        self.assertNotEqual(changed["fingerprint"], record["fingerprint"])

    def test_read_only_build_and_explicit_snapshot(self):
        before = {p.relative_to(self.root).as_posix(): p.read_bytes() for p in self.root.rglob("*") if p.is_file()}
        progress.build_progress(self.root)
        after = {p.relative_to(self.root).as_posix(): p.read_bytes() for p in self.root.rglob("*") if p.is_file()}
        self.assertEqual(before, after)
        out = self.root / "report/snapshot.json"
        self.assertEqual(progress.main(["--root", str(self.root), "--out", str(out)]), 0)
        self.assertEqual(json.loads(out.read_text(encoding="utf-8"))["meta"]["rooms"], 3)


if __name__ == "__main__":
    unittest.main()
