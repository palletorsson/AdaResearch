"""Real-shape grouped rulings, floor precedence, and read-only preview checks."""
from pathlib import Path
import contextlib
import importlib.util
import io
import json
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
spec = importlib.util.spec_from_file_location("museum_order", Path(__file__).with_name("build_spine_artifact_order.py"))
order = importlib.util.module_from_spec(spec)
spec.loader.exec_module(order)


class OrderToolTests(unittest.TestCase):
    def thread(self, placed, roles=None, ruled=None, floor=None, failure=False):
        with patch.object(order, "ROLES", {"roles": {"Room": roles or {}}, "order": {"Room": ruled or {}}}), \
             patch.object(order, "artifacts_in", return_value=placed), \
             patch.object(order.floor_order, "read_room", side_effect=RuntimeError("unavailable") if failure else None,
                          return_value={"floor": floor or []}):
            return order.thread("Room")

    def test_group_order_expands_current_members_and_filters_stale_tokens(self):
        rows = self.thread(["a", "b", "a", "c", "d"],
                           {"a": {"role": "primary", "group": "pair"}, "b": {"role": "primary", "group": "pair"}, "c": "secondary"},
                           {"primary": ["@pair", "missing"], "primary|pair": ["b", "gone", "b"]},
                           ["c", "a", "not_placed"])
        self.assertEqual(rows, [("b", "primary", "ruled"), ("a", "primary", "ruled"),
                                ("c", "secondary", "floor"), ("d", "unruled", "file")])
        self.assertTrue(all(isinstance(role, str) for _, role, _ in rows))
        self.assertEqual(len({token for token, _, _ in rows}), len(rows))

    def test_group_fallback_keeps_current_role_members_only(self):
        rows = self.thread(["a", "b", "c"],
                           {"a": {"role": "primary", "group": "pair"}, "b": {"role": "secondary", "group": "pair"}, "c": {"role": "primary", "group": "pair"}},
                           {"primary": ["@pair"], "primary|pair": ["b", "gone"]}, ["b"])
        self.assertEqual(rows, [("a", "primary", "ruled"), ("c", "primary", "ruled"), ("b", "secondary", "floor")])

    def test_legacy_string_roles_and_untouched_floor_order_are_preserved(self):
        rows = self.thread(["a", "b", "c"], {"a": "primary", "b": "decoration"}, {"primary": ["a"]}, ["c", "b", "a"])
        self.assertEqual(rows, [("a", "primary", "ruled"), ("c", "unruled", "floor"), ("b", "decoration", "floor")])
        rows = self.thread(["a", "b", "c"], {"a": {"role": "primary", "group": "pair"}}, floor=["b", "a"])
        self.assertEqual(rows, [("b", "unruled", "floor"), ("a", "primary", "floor"), ("c", "unruled", "file")])

    def test_floor_failure_retains_every_file_token_once(self):
        self.assertEqual(self.thread(["a", "b", "a"], failure=True), [("a", "unruled", "file"), ("b", "unruled", "file")])

    def test_cell_parser_excludes_empty_cells_and_keeps_placement_suffix_grammar(self):
        with tempfile.TemporaryDirectory() as directory:
            maps = Path(directory)
            (maps / "Room").mkdir()
            (maps / "Room/map_data.json").write_text(json.dumps({"layers": {"interactables": [
                ["", " ", "-", None, "a:90#offset:1,2,3", "b#mode:trace", "a"]]}}), encoding="utf-8")
            with patch.object(order, "MAPS_DIR", maps):
                self.assertEqual(order.artifacts_in("Room"), ["a", "b", "a"])

    def test_grouped_print_preview_cannot_overwrite_existing_manifest(self):
        with tempfile.TemporaryDirectory() as directory:
            repo = Path(directory)
            maps = repo / "maps"
            (maps / "Room").mkdir(parents=True)
            (maps / "Room/map_data.json").write_text(json.dumps({"layers": {"interactables": [["a", "b"]]}}), encoding="utf-8")
            roles = repo / "roles.json"
            roles.write_text(json.dumps({"roles": {"Room": {"a": {"role": "primary", "group": "g"}, "b": "secondary"}},
                                         "order": {"Room": {"primary": ["@g"]}}}), encoding="utf-8")
            manifest = repo / "order.json"
            manifest.write_text("preserve the whole spine", encoding="utf-8")
            capture = io.StringIO()
            with patch.object(order, "REPO", repo), patch.object(order, "MAPS_DIR", maps), \
                 patch.object(order, "ROLES_PATH", roles), patch.object(order, "OUT", manifest), \
                 patch.object(order, "spine_sequences", return_value=["primitives"]), \
                 patch.object(order, "maps_for", return_value=["Room"]), \
                 patch.object(order.floor_order, "read_room", return_value={"floor": ["b", "a"]}), \
                 patch.object(sys, "argv", ["tool", "--seq=primitives", "--print"]), contextlib.redirect_stdout(capture):
                self.assertEqual(order.main(), 0)
            self.assertEqual(manifest.read_text(encoding="utf-8"), "preserve the whole spine")
            self.assertIn("primary", capture.getvalue())
            self.assertIn("PREVIEW", capture.getvalue())


if __name__ == "__main__":
    unittest.main()
