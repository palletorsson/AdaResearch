"""Safety contracts for the one-time archive migration; no project data touched."""
import hashlib
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import repository_cleanup as cleanup


class CleanupTests(unittest.TestCase):
    def test_source_and_text_stay(self):
        for path in ["commons/maps/Point_Trace/tutorial.md", "commons/void/game.gd",
                     "doc/book/course/BRIEF.md", "doc/book/iterations/test/lesson.gd",
                     "doc/book/iterations/test/learner/point_body.gd",
                     "doc/book/iterations/test/DECISIONS.md",
                     "doc/book/iterations/test/learner/LICENSE",
                     "doc/book/iterations/test/learner/font.ttf",
                     "doc/book/iterations/test/learner/hand.res",
                     "doc/book/iterations/test/contract.json"]:
            self.assertIsNone(cleanup.archive_reason(path), path)

    def test_generated_and_copies_move(self):
        for path in ["doc/book/iterations/test/index.html", "output/drive/final.md",
                     "doc/book/iterations/test/before/tutorial.md",
                     "doc/book/iterations/test/before/plan.json",
                     "doc/book/iterations/test/evidence/student/point.gd",
                     "doc/book/iterations/test/report.json",
                     "doc/book/iterations/test/review.zip"]:
            self.assertIsNotNone(cleanup.archive_reason(path), path)

    def test_escape_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(ValueError):
                cleanup.confined(Path(tmp), "../outside")

    def test_long_archive_path(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = cleanup.confined(Path(tmp), "/".join(["nested-copy"] * 24 + ["receipt.json"]))
            path.parent.mkdir(parents=True)
            try:
                path.write_bytes(b"preserved")
                self.assertEqual(path.read_bytes(), b"preserved")
            finally:
                path.unlink(missing_ok=True)
                folder = path.parent
                for _ in range(24):
                    folder.rmdir()
                    folder = folder.parent

    def scenario(self, change_source=False, collision=False):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            root, archive, backup = [base / name for name in ("root", "archive", "backup")]
            for folder in (root, archive, backup):
                folder.mkdir()
            (backup / "snapshot.json").write_text('{"verified":true}')
            source = root / "report.json"
            source.write_bytes(b"original")
            plan = base / "plan.json"
            plan.write_text(json.dumps({"files": [{
                "path": "report.json", "sha256": hashlib.sha256(b"original").hexdigest()
            }]}))
            if change_source:
                source.write_bytes(b"new work")
            if collision:
                (archive / "report.json").write_bytes(b"older archive")
            with patch.multiple(cleanup, ROOT=root, ARCHIVE=archive, BACKUP=backup):
                if change_source or collision:
                    with self.assertRaises(AssertionError):
                        cleanup.migrate(plan, True)
                    self.assertEqual(source.read_bytes(), b"new work" if change_source else b"original")
                else:
                    cleanup.migrate(plan, False)
                    self.assertFalse((archive / "report.json").exists())
                    cleanup.migrate(plan, True)
                    self.assertEqual(source.read_bytes(), b"original")
                    self.assertTrue(os.path.samefile(source, archive / "report.json"))
                    cleanup.migrate(plan, True)
                    cleanup.restore()
                    self.assertEqual(source.read_bytes(), b"original")

    def test_verified_archive_keeps_compatible_path(self):
        self.scenario()

    def test_new_work_is_not_overwritten(self):
        self.scenario(change_source=True)

    def test_archive_collision_is_not_overwritten(self):
        self.scenario(collision=True)


if __name__ == "__main__":
    unittest.main()
