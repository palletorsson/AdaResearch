"""Editor persistence and compression boundaries, in disposable repositories."""
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import museum_connections as links
import museum_memory as memory
import project_memory


class EditingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.write(links.STATE, {"schema": "museum-connections/1", "revision": 0, "summaries": {}, "threads": {"trace": {"title": "Trace", "summary": "What stays?"}}, "connections": {}, "journal": []})
        self.write(project_memory.SPINE, {"spine": {"sequences": [{"name": "primitives", "order": 1}]}})
        self.write("commons/maps/sequences/primitives.json", {"sequences": {"primitives": {"maps": ["Trace", "Grid"]}}})
        self.source = "commons/maps/Trace/tutorial.md"
        self.write(self.source, "Keep the original.")
        self.edge = {"thread": "trace", "from": "map:Trace", "to": "map:Grid", "relation": "reuses", "status": "documented", "reason": "Keep source; change copy.", "source_paths": [self.source]}

    def write(self, path, data):
        p = self.root / path
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(data if isinstance(data, str) else json.dumps(data), encoding="utf-8")

    def edit(self, action="connection", **kwargs):
        return links.mutate(self.root, {"action": action, "expected_revision": links.read(self.root)["revision"], **kwargs})

    def test_save_reload_history_and_delete_preserve_prior_record(self):
        original = (self.root / links.STATE).read_bytes()
        result = self.edit(record=self.edge)
        record = links.read(self.root)["connections"][result["id"]]
        self.assertEqual(record["reason"], self.edge["reason"])
        history = list((self.root / "doc/book/memory/history").glob("museum-*.json"))
        self.assertEqual(history[0].read_bytes(), original)
        self.edit("delete_connection", id=result["id"])
        state = links.read(self.root)
        self.assertFalse(state["connections"])
        self.assertEqual(state["journal"][-1]["before"], record)

    def test_stale_editor_cannot_overwrite_newer_edit(self):
        self.edit(record=self.edge)
        with self.assertRaises(project_memory.MemoryError) as error:
            links.mutate(self.root, {"action": "thread", "expected_revision": 0, "id": "trace", "record": {"title": "Wrong", "summary": "Old window"}})
        self.assertEqual(error.exception.code, 409)
        self.assertEqual(links.read(self.root)["threads"]["trace"]["title"], "Trace")

    def test_concurrent_saves_have_one_winner(self):
        def edit():
            try:
                links.mutate(self.root, {"action": "connection", "expected_revision": 0, "record": self.edge})
                return "saved"
            except project_memory.MemoryError as e:
                return e.code
        with ThreadPoolExecutor(2) as executor:
            results = list(executor.map(lambda _: edit(), range(2)))
        self.assertEqual(sorted(results, key=str), sorted(["saved", 409], key=str))
        self.assertEqual(links.read(self.root)["revision"], 1)

    def test_proposal_stays_proposal(self):
        result = self.edit(record={**self.edge, "status": "proposed", "source_paths": []})
        enriched = links.enrich(self.root, links.read(self.root), links.addresses(self.root))
        self.assertEqual(enriched["connections"][result["id"]]["status"], "proposed")
        self.assertEqual(enriched["connections"][result["id"]]["freshness"], "unlinked")

    def test_changed_source_stays_stale_after_prose_edit(self):
        result = self.edit(record=self.edge)
        receipt = links.read(self.root)["connections"][result["id"]]["sources"][self.source]
        self.write(self.source, "Original changed.")
        self.edit(id=result["id"], record={**self.edge, "reason": "A changed interpretation."})
        row = links.enrich(self.root, links.read(self.root), links.addresses(self.root))["connections"][result["id"]]
        self.assertEqual(row["freshness"], "recheck")
        self.assertEqual(row["sources"][self.source], receipt)

    def test_removed_hall_is_marked_not_silently_reassigned(self):
        result = self.edit(record=self.edge)
        self.write("commons/maps/sequences/primitives.json", {"sequences": {"primitives": {"maps": ["Trace"]}}})
        row = links.enrich(self.root, links.read(self.root), links.addresses(self.root))["connections"][result["id"]]
        self.assertEqual(row["unavailable"], ["map:Grid"])

    def test_invalid_addresses_types_and_paths_do_not_write(self):
        for wrong in [{"from": "map:Imagined"}, {"to": "map:Trace"}, {"relation": "same-everything"}, {"status": "proven"}, {"thread": "no-thread"}, {"source_paths": ["../../outside.md"]}, {"source_paths": []}]:
            before = (self.root / links.STATE).read_bytes()
            with self.assertRaises(project_memory.MemoryError):
                self.edit(record={**self.edge, **wrong})
            self.assertEqual((self.root / links.STATE).read_bytes(), before)

    def test_duplicate_link_and_nonempty_thread_deletion_are_rejected(self):
        self.edit(record=self.edge)
        with self.assertRaisesRegex(project_memory.MemoryError, "already exists"):
            self.edit(record=self.edge)
        with self.assertRaisesRegex(project_memory.MemoryError, "connections first"):
            self.edit("delete_thread", id="trace")

    def test_sequence_summary_is_editable_without_changing_spine_or_sources(self):
        before = (self.root / project_memory.SPINE).read_bytes()
        self.edit("summary", id="sequence:primitives", record={"summary": "A point becomes a record.", "carry": "Keep the original.", "question": "What is lost?", "source_paths": [self.source]})
        self.assertEqual(links.read(self.root)["summaries"]["sequence:primitives"]["carry"], "Keep the original.")
        self.assertEqual((self.root / project_memory.SPINE).read_bytes(), before)
        self.assertEqual((self.root / self.source).read_text(), "Keep the original.")


class WholeSpineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = Path(__file__).resolve().parents[1]
        cls.data = memory.model(cls.root)

    def test_summaries_cover_live_sequences_and_packet_carries_them(self):
        self.assertEqual(set(self.data["connections"]["summaries"]), {s["id"] for s in self.data["sequences"]})
        packet = memory.packet(self.data, "project")
        self.assertGreater(packet["source_words"], 0)
        for summary in self.data["connections"]["summaries"].values():
            self.assertIn(summary["summary"], packet["text"])

    def test_live_order_excludes_old_storyboard_appendices(self):
        expected = links.route(self.root)
        self.assertEqual([(s["id"],s["halls"]) for s in self.data["sequences"]], [(s["id"],s["halls"]) for s in expected])

    def test_thread_packet_is_typed_and_keeps_source_limits(self):
        packet = memory.packet(self.data, "thread:trace")["text"]
        for value in ("thread:trace", "map:Point_Trace → map:Point_Line_Grid / reuses", "interpretation", "proposed", "sources", "not runtime"):
            self.assertIn(value, packet)
        self.assertNotIn("thread:selection —", packet)
        with self.assertRaises(ValueError):
            memory.packet(self.data, "thread:invented")


if __name__ == "__main__":
    unittest.main()
