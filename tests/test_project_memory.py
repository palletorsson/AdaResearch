"""Memory persistence, evidence and handoff contracts, in isolated repositories."""
from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
from threading import Barrier
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import project_memory as memory


class ProjectMemoryTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.write_json(memory.STATE, {"revision": 0})
        self.write(memory.STORYBOARDS + "/BRIEF.md", "# Authored brief\n\nKeep the museum and teach a small useful operation.")
        self.authored = [
            {"sequence": "primitives", "arc": "Points gain positions, relations and records.", "halls": [
                {"id": "Point_Zero", "title": "Once, then again", "storyboard": "Full live Zero paragraph.",
                 "storyboard_short": "Teach initialization. Supply the existing counter. Open: choose the saved change.",
                 "brings": ["running museum"], "learns": ["execution timing"], "supplied": ["counter"],
                 "carries": "execution timing", "artifact_refs": ["counter"], "review_note": "Inspect the counter interface."},
                {"id": "Point_One", "title": "Represent a point", "storyboard": "Full live One paragraph.",
                 "storyboard_short": "Teach a position variable. Open: supply scale or teach it here.",
                 "review_note": "Retain distinct visible and physical boundaries."}]},
            {"sequence": "transformation", "arc": "Known shapes gain motion.", "halls": [
                {"id": "Trans_One", "title": "Move it", "storyboard": "Full live transformation paragraph.",
                 "storyboard_short": "Teach elapsed time. Supply the carrier."}]}]
        self.write_json(memory.STORYBOARDS + "/opening.json", self.authored)
        self.write_json(memory.STORYBOARDS + "/preparation.json", {"title": "Day Zero", "storyboard_short": "Open the working project."})
        sequences = [
            {"id": "primitives", "label": "Primitives", "maps": ["Point_Zero", "Point_One"]},
            {"id": "transformation", "label": "Transformation", "maps": ["Trans_One"]}]
        self.write_json(memory.SPINE, {"spine": {"sequences": [
            {"name": s["id"], "order": i} for i, s in enumerate(sequences)]}})
        for seq in sequences:
            self.write_json(f"commons/maps/sequences/{seq['id']}.json", {
                "sequences": {seq["id"]: {"name": seq["label"], "maps": seq["maps"]}}})
        self.route = {"sequences": sequences, "date": "2026-10-04", "halls": [
            {"id": "Point_Zero", "storyboard": "Old snapshot must not win.",
             "storyboard_short": "Old short snapshot must not win.",
             "images": [{"src": "images/Point_Zero.webp", "label": "counter", "date": "2026-09-21"}]}]}
        self.write_json(memory.ROUTE, self.route)
        self.write(str(Path(memory.ROUTE).parent / "images/Point_Zero.webp"), "fake image")
        self.write("commons/maps/Point_Zero/map_data.json", "{}\n")
        self.write("commons/maps/Point_Zero/tutorial.md", "An existing tutorial.\n")
        self.write("commons/counter.gd", "extends Node\n# first observed version\n")
        self.write("commons/counter.tscn", "[gd_scene format=3]\n")
        self.write("project.godot", "config_version=5\n")
        self.write_json("commons/artifacts/registry/test.json", {
            "artifacts": {"counter": {"scene": "res://commons/counter.tscn", "lookup_name": "counter_alias"}}})

    def write(self, relative, value):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(value, encoding="utf-8")
        return path

    def write_json(self, relative, value):
        return self.write(relative, json.dumps(value, ensure_ascii=False, indent=2) + "\n")

    def read_state(self):
        return json.loads((self.root / memory.STATE).read_text(encoding="utf-8"))

    def change(self, action, **fields):
        return memory.mutate(self.root, dict(action=action, expected_revision=self.read_state()["revision"], **fields))

    def finding(self, **fields):
        value = dict(scope="map:Point_Zero", kind="source", text="Counter callbacks are visible in source.",
                     reason="Keep supplied support distinct.", sequence_effect="Clarifies the first prerequisite.",
                     project_effect="Keeps the working environment explicit.", related_scopes=["sequence:primitives"],
                     source_paths=["commons/counter.gd"], method="Static source inspection", created_by="test reviewer")
        value.update(fields)
        return self.change("finding", finding=value)["findings"][-1]

    def assert_error(self, code, callback, *args, **kwargs):
        with self.assertRaises(memory.MemoryError) as caught:
            callback(*args, **kwargs)
        self.assertEqual(caught.exception.code, code)

    def link_directory(self, link, target):
        """Exercise reparse escapes on Windows even without symlink privilege."""
        try:
            link.symlink_to(target, target_is_directory=True)
        except (OSError, NotImplementedError):
            try:
                import _winapi
                _winapi.CreateJunction(str(target), str(link))
            except (ImportError, AttributeError, OSError) as error:
                self.skipTest(f"Host cannot create directory symlinks or junctions: {error}")
        self.addCleanup(lambda: link.unlink() if link.is_symlink() else link.rmdir())

    def test_live_model_defaults_and_read_only_context(self):
        before = {p.relative_to(self.root): p.read_bytes() for p in self.root.rglob("*") if p.is_file()}
        result = memory.model(self.root)
        self.assertEqual(set(result), {"revision", "updated_at", "core", "scopes", "notes", "findings", "signals", "history", "stats"})
        self.assertEqual(result["core"], {"text": "", "reason": "", "open_question": ""})
        self.assertEqual(result["stats"]["maps"], 3)
        self.assertEqual(result["stats"]["sequences"], 2)
        scopes = {s["id"]: s for s in result["scopes"]}
        self.assertEqual(scopes["map:Point_Zero"]["full"], "Full live Zero paragraph.")
        self.assertEqual(scopes["map:Point_Zero"]["carries"], ["execution timing"])
        self.assertEqual(scopes["map:Point_One"]["artifact_refs"], [])
        self.assertEqual(scopes["map:Point_Zero"]["image"]["path"], str(Path(memory.ROUTE).parent / "images/Point_Zero.webp").replace("\\", "/"))
        self.assertTrue(scopes["map:Point_Zero"]["image"]["label"].startswith("Earlier museum capture:"))
        self.assertNotIn("#", scopes["project"]["summary"])
        self.authored[0]["halls"][0]["storyboard"] = "New live authored text."
        self.write_json(memory.STORYBOARDS + "/opening.json", self.authored)
        self.assertEqual(next(s for s in memory.model(self.root)["scopes"] if s["id"] == "map:Point_Zero")["full"], "New live authored text.")
        after = {p.relative_to(self.root): p.read_bytes() for p in self.root.rglob("*") if p.is_file()}
        changed = {str(p).replace("\\", "/") for p in before if before[p] != after[p]}
        self.assertEqual(changed, {memory.STORYBOARDS + "/opening.json"})
        self.assertEqual(set(before), set(after))

    def test_optional_preparation_and_route_are_not_required(self):
        (self.root / (memory.STORYBOARDS + "/preparation.json")).unlink()
        (self.root / memory.ROUTE).unlink()
        result = memory.model(self.root)
        self.assertEqual(result["stats"]["maps"], 3)
        self.assertNotIn("preparation:day-zero", [s["id"] for s in result["scopes"]])

    def test_core_note_history_roundtrip_preserves_original_bytes_and_other_fields(self):
        state = self.read_state()
        state["notes"] = {"map:Point_Zero": {"summary": "old", "reason": "retained reason", "custom": "retained metadata"}}
        state["custom_state"] = "keep"
        self.write_json(memory.STATE, state)
        original = (self.root / memory.STATE).read_bytes()
        self.change("note", scope="map:Point_Zero", note={"summary": "new"})
        revised = self.read_state()
        self.assertEqual(revised["notes"]["map:Point_Zero"]["reason"], "retained reason")
        self.assertEqual(revised["notes"]["map:Point_Zero"]["custom"], "retained metadata")
        self.assertEqual(revised["custom_state"], "keep")
        snapshot = next((self.root / memory.MEMORY / "history").glob("*.json"))
        self.assertEqual(snapshot.read_bytes(), original)
        self.assertEqual(json.loads(snapshot.read_bytes()), state)
        self.change("core", core={"text": "A working brief", "reason": "Why", "open_question": "Which scope next?"})
        reloaded = memory.model(self.root)
        self.assertEqual(reloaded["revision"], 2)
        self.assertEqual(reloaded["core"]["open_question"], "Which scope next?")
        self.assertEqual([j["action"] for j in reloaded["history"]], ["note", "core"])
        self.assertFalse((self.root / memory.MEMORY / ".writer.lock").exists())
        self.assertEqual(list((self.root / memory.MEMORY).glob(".state-*.tmp")), [])

    def test_stale_and_missing_revision_do_not_write_history(self):
        self.change("core", core={"text": "First writer"})
        before = (self.root / memory.STATE).read_bytes()
        request = {"action": "core", "expected_revision": 0, "core": {"text": "Stale writer"}}
        self.assert_error(409, memory.mutate, self.root, request)
        del request["expected_revision"]
        self.assert_error(400, memory.mutate, self.root, request)
        self.assertEqual((self.root / memory.STATE).read_bytes(), before)
        self.assertEqual(len(list((self.root / memory.MEMORY / "history").glob("*.json"))), 1)

    def test_competing_writers_commit_exactly_once(self):
        barrier = Barrier(2)

        def write_competing(text):
            barrier.wait(timeout=5)
            try:
                result = memory.mutate(self.root, {"action": "core", "expected_revision": 0, "core": {"text": text}})
                return result["revision"]
            except memory.MemoryError as error:
                return error.code

        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(write_competing, ["Writer one", "Writer two"]))
        self.assertEqual(sorted(results), [1, 409])
        self.assertEqual(self.read_state()["revision"], 1)
        self.assertEqual(len(list((self.root / memory.MEMORY / "history").glob("*.json"))), 1)

    def test_existing_lock_is_not_deleted_or_ignored(self):
        lock = self.write(memory.MEMORY + "/.writer.lock", "owner evidence")
        self.assert_error(409, self.change, "core", core={"text": "Rejected"})
        self.assertEqual(lock.read_text(), "owner evidence")
        self.assertEqual(self.read_state()["revision"], 0)

    def test_failed_atomic_replace_preserves_state_and_removes_temporary_file(self):
        before = (self.root / memory.STATE).read_bytes()
        with patch.object(memory.os, "replace", side_effect=OSError("simulated filesystem failure")):
            with self.assertRaises(OSError):
                self.change("core", core={"text": "Will not commit"})
        self.assertEqual((self.root / memory.STATE).read_bytes(), before)
        self.assertEqual(list((self.root / memory.MEMORY).glob(".state-*.tmp")), [])
        self.assertFalse((self.root / memory.MEMORY / ".writer.lock").exists())
        self.assertEqual(next((self.root / memory.MEMORY / "history").glob("*.json")).read_bytes(), before)

    def test_source_and_path_boundaries(self):
        result = memory.source(self.root, "commons/counter.gd")
        self.assertEqual(result["sha256"], hashlib.sha256((self.root / "commons/counter.gd").read_bytes()).hexdigest())
        self.assertIn("extends Node", result["text"])
        self.assertIn("config_version", memory.source(self.root, "project.godot")["text"])
        paths = ["../outside.md", "commons/../secret.md", "/tmp/secret.md", "C:/secret.md", "C:secret.md",
                 "\\\\server\\secret.md", "commons\\..\\secret.md", "commons/test.gd:secret", "commons/NUL.txt",
                 "doc/book/memory/history/old.json", "doc/book/private/secret.md", "commons/.git/config.json",
                 "doc/book/no.exe", "assets/secret.json", "commons/end. /secret.md"]
        for path in paths:
            with self.subTest(path=path):
                self.assert_error(400, memory.source, self.root, path)
        self.assert_error(404, memory.source, self.root, "commons/missing.gd")
        self.write("commons/too-big.md", "x" * (memory.MAX_SOURCE + 1))
        self.assert_error(400, memory.source, self.root, "commons/too-big.md")
        self.write("commons/binary.md", "safe\x00binary")
        self.assert_error(400, memory.source, self.root, "commons/binary.md")

    def test_symlink_escape_and_symlink_to_history_are_rejected(self):
        with tempfile.TemporaryDirectory() as outside:
            external = Path(outside) / "external.md"
            external.write_text("outside", encoding="utf-8")
            link = self.root / "commons/external"
            self.link_directory(link, Path(outside))
            self.assert_error(400, memory.source, self.root, "commons/external/external.md")
            self.assert_error(400, self.finding, source_paths=["commons/external/external.md"])
            history = self.write(memory.MEMORY + "/history/old.json", "{}")
            self.link_directory(self.root / "commons/history", history.parent)
            self.assert_error(400, memory.source, self.root, "commons/history/old.json")

    def test_storage_symlink_cannot_redirect_writes(self):
        directory = self.root / memory.MEMORY
        external = self.root / "kept-memory"
        directory.rename(external)
        self.link_directory(directory, external)
        before = (external / "state.json").read_bytes()
        self.assert_error(400, memory.mutate, self.root, {"action": "core", "expected_revision": 0, "core": {"text": "bad"}})
        self.assertEqual((external / "state.json").read_bytes(), before)

    def test_freshness_review_and_explicit_recheck_preserve_evidence_history(self):
        finding = self.finding()
        identifier = finding["id"]
        old_hash = finding["sources"][0]["sha256"]
        self.assertEqual(finding["status"], "proposed")
        self.assertEqual(finding["freshness"], "current")
        self.write("commons/counter.gd", "extends Node\n# now changed\n")
        stale = memory.model(self.root)
        self.assertEqual(stale["findings"][0]["freshness"], "changed")
        self.assertEqual(stale["stats"]["needs_recheck"], 1)
        self.assertTrue(any(s["kind"] == "source_changed" for s in stale["signals"]))
        self.assert_error(400, self.change, "review", id=identifier, status="accepted", review_note="")
        reviewed = self.change("review", id=identifier, status="accepted", review_note="Editorially retain it; source needs rechecking.")["findings"][0]
        self.assertEqual(reviewed["freshness"], "changed")
        self.assertEqual(reviewed["sources"][0]["sha256"], old_hash)
        self.assert_error(409, self.change, "recheck", id=identifier, review_note="Read the old panel.",
                          current_sources=[{"path": "commons/counter.gd", "sha256": old_hash}])
        new_hash = memory.source(self.root, "commons/counter.gd")["sha256"]
        prior_revision = self.read_state()["revision"]
        updated = self.change("recheck", id=identifier, review_note="Inspected the new source text.",
                              current_sources=[{"path": "commons/counter.gd", "sha256": new_hash}])["findings"][0]
        self.assertEqual(updated["freshness"], "current")
        self.assertEqual(updated["status"], "accepted")
        self.assertEqual(updated["sources"][0]["sha256"], new_hash)
        history_file = next((self.root / memory.MEMORY / "history").glob(f"revision-{prior_revision:08d}-*.json"))
        self.assertEqual(json.loads(history_file.read_text())["findings"][0]["sources"][0]["sha256"], old_hash)
        stored_source = self.read_state()["findings"][0]["sources"][0]
        self.assertEqual(set(stored_source), {"path", "sha256"})

    def test_missing_and_uninspected_sources_are_not_verified(self):
        missing = self.finding(source_paths=["commons/missing.gd"])
        self.assertIsNone(missing["sources"][0]["sha256"])
        self.assertEqual(missing["freshness"], "missing")
        self.assert_error(409, self.change, "recheck", id=missing["id"], review_note="Cannot inspect missing source.",
                          current_sources=[{"path": "commons/missing.gd", "sha256": "a" * 64}])
        self.write("commons/missing.gd", "extends Node")
        self.assertEqual(memory.model(self.root)["findings"][0]["freshness"], "unlinked")
        unlinked = self.finding(source_paths=[])
        self.assertEqual(unlinked["freshness"], "unlinked")
        self.assert_error(400, self.change, "recheck", id=unlinked["id"], review_note="No sources", current_sources=[])

    def test_recheck_requires_every_source_and_rejects_duplicate_entries(self):
        finding = self.finding(source_paths=["commons/counter.gd", "project.godot"])
        sources = [{"path": s["path"], "sha256": s["sha256"]} for s in finding["sources"]]
        for provided in (sources[:1], sources + sources[:1], []):
            with self.subTest(sources=provided):
                self.assert_error(400, self.change, "recheck", id=finding["id"], review_note="Read sources", current_sources=provided)

    def test_unsafe_stored_source_is_a_missing_signal_and_does_not_crash_model(self):
        self.finding()
        state = self.read_state()
        state["findings"][0]["sources"] = [{"path": "../../outside.md", "sha256": "a" * 64}]
        self.write_json(memory.STATE, state)
        result = memory.model(self.root)
        self.assertEqual(result["findings"][0]["freshness"], "missing")
        self.assertTrue(any(s["kind"] == "source_missing" for s in result["signals"]))

    def test_route_spine_and_missing_selected_artifacts_are_coverage_signals(self):
        self.route["sequences"][0]["maps"].reverse()
        self.write_json(memory.ROUTE, self.route)
        self.authored[0]["halls"][0]["artifact_refs"] = ["counter", "missing_artifact"]
        self.write_json(memory.STORYBOARDS + "/opening.json", self.authored)
        (self.root / "commons/counter.tscn").unlink()
        result = memory.model(self.root)
        self.assertTrue(any(s["kind"] == "route_spine_disagreement" for s in result["signals"]))
        self.assertEqual(len([s for s in result["signals"] if s["kind"] == "missing_artifact"]), 2)
        self.assertEqual(result["stats"]["open_questions"], 2)

    def test_live_hall_move_keeps_one_scope_and_authored_text(self):
        self.write_json("commons/maps/sequences/primitives.json", {"sequences": {"primitives": {"maps": ["Point_One"]}}})
        self.write_json("commons/maps/sequences/transformation.json", {"sequences": {"transformation": {"maps": ["Point_Zero", "Trans_One"]}}})
        result = memory.model(self.root)
        halls = [s for s in result["scopes"] if s["id"] == "map:Point_Zero"]
        self.assertEqual(len(halls), 1)
        self.assertEqual(halls[0]["parent"], "sequence:transformation")
        self.assertEqual(halls[0]["full"], "Full live Zero paragraph.")
        self.assertTrue(any(s["kind"] == "storyboard_spine_disagreement" for s in result["signals"]))

    def test_packets_keep_scope_notes_pending_choices_evidence_and_adjacency(self):
        self.change("core", core={"text": "Do small useful constructions.", "reason": "Reuse what exists.", "open_question": "Choose the first study."})
        self.change("note", scope="map:Point_Zero", note={"summary": "Use the existing display.", "reason": "Keep timing visible.", "open_question": "Which readout is enough?"})
        self.finding(kind="question", text="Is the supplied interface available?", source_paths=[])
        dismissed = self.finding(text="Discard this unsupported assertion.")
        self.change("review", id=dismissed["id"], status="dismissed", review_note="No longer relevant.")
        local = memory.packet(self.root, "map:Point_Zero")
        self.assertEqual(local, memory.packet(self.root, "map:Point_Zero"))
        self.assertEqual(local["word_count"], len(local["text"].split()))
        for wanted in ("CONTEXT ONLY", "not implementation permission or proof", "Ancestor arc", "Points gain positions",
                       "map:Point_One", "Which readout is enough?", "Inspect the counter interface.", "Supplied: counter",
                       "Learns: execution timing", "Sequence effect", "Project effect", "Static source inspection", "evidence unlinked"):
            self.assertIn(wanted, local["text"])
        self.assertNotIn("Discard this unsupported assertion", local["text"])
        self.assertNotIn("Full live", local["text"])
        self.assertLess(local["word_count"], 1500)
        sequence = memory.packet(self.root, "sequence:primitives")["text"]
        self.assertIn("Inspect the counter interface.", sequence)
        self.assertIn("supply scale or teach it here", sequence)
        self.assertIn("Retain distinct visible and physical boundaries.", sequence)
        project = memory.packet(self.root, "project")["text"]
        self.assertIn("Known shapes gain motion", project)
        self.assertIn("Detailed hall review notes are not expanded", project)
        self.assertIn("supply scale or teach it here", project)  # Distinct from the hall review note.
        self.assertIn("Which readout is enough?", project)
        self.assertIn("Is the supplied interface available?", project)
        self.assertLess(len(project.split()), 1500)

    def test_packet_does_not_silently_truncate_long_pending_question(self):
        long_question = "pending " * 1450 + "LAST_REQUIRED_CHOICE"
        self.finding(kind="question", text=long_question, source_paths=[])
        self.assertIn("LAST_REQUIRED_CHOICE", memory.packet(self.root, "project")["text"])

    def test_mutation_validation_is_transactional(self):
        invalid = [
            {"action": []},
            {"action": "note", "scope": "map:Unknown", "note": {}},
            {"action": "core", "core": {"text": "x" * (memory.MAX_TEXT + 1)}},
            {"action": "finding", "finding": {"scope": "project", "kind": [], "text": "bad"}},
            {"action": "finding", "finding": {"scope": "project", "kind": "decision", "text": "valid", "related_scopes": ["project"] * 21}},
            {"action": "finding", "finding": {"scope": "project", "kind": "decision", "text": "valid", "source_paths": ["commons/counter.gd", "commons\\counter.gd"]}},
            {"action": "finding", "finding": {"scope": "project", "kind": "source", "text": "valid", "source_paths": ["../escape.md"]}},
        ]
        before = (self.root / memory.STATE).read_bytes()
        for request in invalid:
            with self.subTest(request=request):
                self.assert_error(400, memory.mutate, self.root, dict(request, expected_revision=0))
                self.assertEqual((self.root / memory.STATE).read_bytes(), before)
        self.assertFalse((self.root / memory.MEMORY / "history").exists())

    def test_journal_is_bounded_and_history_retains_previous_journal(self):
        state = self.read_state()
        state["journal"] = [{"at": str(i), "action": "note", "scope": "project", "summary": str(i)} for i in range(40)]
        self.write_json(memory.STATE, state)
        result = self.change("core", core={"text": "updated"})
        self.assertEqual(len(result["history"]), 40)
        self.assertEqual(result["history"][0]["summary"], "1")
        snapshot = next((self.root / memory.MEMORY / "history").glob("*.json"))
        self.assertEqual(json.loads(snapshot.read_text())["journal"][0]["summary"], "0")

    def test_cli_outputs_only_json_and_enforces_input_limit(self):
        command = [sys.executable, str(ROOT / "tools/project_memory.py"), "--root", str(self.root)]
        result = subprocess.run(command + ["model"], input=b"{}", capture_output=True, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)["stats"]["maps"], 3)
        self.assertEqual(result.stderr, b"")
        for raw in (b"[]", b"invalid", b" " * (memory.MAX_INPUT + 1)):
            result = subprocess.run(command + ["model"], input=raw, capture_output=True, check=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(json.loads(result.stdout)["code"], 400)
        result = subprocess.run(command + ["source"], input=b'{"path":"commons/missing.gd"}', capture_output=True, check=False)
        self.assertEqual(json.loads(result.stdout)["code"], 404)


if __name__ == "__main__":
    unittest.main()
