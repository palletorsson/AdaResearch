"""Capture regressions: structure, literal code, manuscript bytes and backups."""
from contextlib import redirect_stdout
import hashlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import export_book_captures as capture


class BookCaptureTests(unittest.TestCase):
    def test_default_reader_keeps_heading_levels(self):
        source = "# Title\n\n## Encounter\nWords[^note]\n\n[^note]: Note."
        result = capture.clean_text(source, "Example")
        self.assertEqual(result, source.replace("[^note]", "[^Example--note]"))

    def test_nested_headings_do_not_rewrite_code(self):
        source = """# Title
## Encounter
<!-- @artifact -->
Words[^note]
```gdscript
# Code comment
## Another comment
<!-- @literal -->
var value = "[^note]"
```
~~~text
# Literal heading
~~~
### Detail
#hashtag
[^note]: A note.
"""
        result = capture.clean_text(source, "Example", heading_offset=2)
        self.assertTrue(result.startswith("### Title\n#### Encounter"))
        self.assertIn("##### Detail", result)
        self.assertNotIn("<!-- @artifact -->", result)
        self.assertIn('```gdscript\n# Code comment\n## Another comment\n<!-- @literal -->\nvar value = "[^note]"\n```', result)
        self.assertIn("~~~text\n# Literal heading\n~~~", result)
        self.assertIn("#hashtag", result)
        self.assertIn("[^Example--note]: A note.", result)

    def test_export_hierarchy_manifest_and_backup_preserve_source(self):
        with tempfile.TemporaryDirectory(prefix="ada-capture-") as temporary:
            root = Path(temporary)
            maps = root / "commons/maps"
            (maps / "sequences").mkdir(parents=True)
            (maps / "Test_Room").mkdir()
            sequence = maps / "sequences/test.json"
            sequence.write_text(json.dumps({"sequences":{"test":{"maps":["Test_Room"]}}}), encoding="utf-8")
            manuscript = maps / "Test_Room/final.md"
            raw = b"# Chapter\r\n\r\n## Encounter\r\nText.\r\n"
            manuscript.write_bytes(raw)
            output = root / "captures"
            with patch.object(capture, "ROOT", root), patch.object(capture, "MAPS", maps), patch.object(capture, "git_value", return_value="test"), redirect_stdout(io.StringIO()):
                capture.export(["test"], output)
                dest = output / "test/test-book.md"
                first = dest.read_bytes()
                self.assertEqual(manuscript.read_bytes(), raw)
                self.assertIn(b"## Test Room", first)
                self.assertIn(b"### Chapter\n\n#### Encounter", first)
                manifest = json.loads((dest.parent / "test-book.manifest.json").read_text())
                self.assertEqual(manifest["maps"][0]["sha256"], hashlib.sha256(raw).hexdigest())
                self.assertEqual(manifest["output_sha256"], hashlib.sha256(first).hexdigest())
                manuscript.write_bytes(raw + b"Another paragraph.\r\n")
                capture.export(["test"], output)
                backups = list((dest.parent / "history").glob("*.md"))
                self.assertEqual(len(backups), 1)
                self.assertEqual(backups[0].read_bytes(), first)
                self.assertEqual(manuscript.read_bytes(), raw + b"Another paragraph.\r\n")

    def test_missing_hall_does_not_replace_capture(self):
        with tempfile.TemporaryDirectory(prefix="ada-capture-") as temporary:
            root = Path(temporary)
            maps = root / "commons/maps"
            (maps / "sequences").mkdir(parents=True)
            (maps / "sequences/test.json").write_text(json.dumps({"sequences":{"test":{"maps":["Missing"]}}}), encoding="utf-8")
            output = root / "captures"
            (output / "test").mkdir(parents=True)
            dest = output / "test/test-book.md"
            dest.write_text("Previous capture", encoding="utf-8")
            with patch.object(capture, "ROOT", root), patch.object(capture, "MAPS", maps), patch.object(capture, "git_value", return_value="test"):
                with self.assertRaises(FileNotFoundError):
                    capture.export(["test"], output)
            self.assertEqual(dest.read_text(), "Previous capture")


if __name__ == "__main__":
    unittest.main(verbosity=2)
