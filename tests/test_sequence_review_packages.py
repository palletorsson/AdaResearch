"""Regression: promoted grid utilities must be inspectable in a source handover."""
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import build_sequence_review_packages as packages


class UtilityReadingTests(unittest.TestCase):
    def test_literal_registry_resolves_scenes_and_marks_dynamic_cases(self):
        catalog = packages.utility_registry()
        self.assertEqual(catalog['tc']['scene'], 'res://commons/scenes/mapobjects/transport_cube.tscn')
        self.assertEqual(catalog['sc']['scene'], 'res://commons/scenes/mapobjects/scale_cube.tscn')
        self.assertEqual(catalog['rc']['scene'], 'res://commons/scenes/mapobjects/rotation_cube.tscn')
        self.assertEqual(catalog['wp']['scene'], 'res://commons/scenes/mapobjects/walkableprism.tscn')
        self.assertIsNone(catalog['e']['scene'])
        self.assertIn('special dispatch', catalog['e']['resolution'])

    def test_comments_are_removed_without_damaging_quoted_data(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / 'commons/grid/UtilityRegistry.gd'
            path.parent.mkdir(parents=True)
            path.write_text('''const UTILITY_TYPES = {
    "tc": {"file": "test.tscn", "description": "keep #hash and comma,}",}, # comment
}
const MAP_OBJECTS_PATH = "res://commons/scenes/mapobjects/"
''', encoding='utf-8')
            with patch.object(packages, 'ROOT', root):
                catalog = packages.utility_registry()
            self.assertEqual(catalog['tc']['entry']['description'], 'keep #hash and comma,}')
            self.assertEqual(catalog['tc']['scene'], 'res://commons/scenes/mapobjects/test.tscn')

    def test_nonliteral_registry_is_rejected_instead_of_evaluated(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / 'commons/grid/UtilityRegistry.gd'
            path.parent.mkdir(parents=True)
            path.write_text('const UTILITY_TYPES = build_dynamic_registry()\n', encoding='utf-8')
            with patch.object(packages, 'ROOT', root):
                with self.assertRaises(ValueError):
                    packages.utility_registry()

    def test_real_transformation_export_contains_utility_chain_and_preserves_old_package(self):
        historical = ROOT / 'doc/book/review-packages/2026-09-18/transformation-review.zip'
        old_hash = packages.sha(historical.read_bytes())
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            evidence_path = ROOT / 'doc/space/transformation-experiments-2026-09-16/rotation-body-comparison-checks.json'
            packages.build(output, 'transformation', [evidence_path])
            self.assertTrue((output / '.gdignore').is_file())
            archive = output / 'transformation-review.zip'
            with zipfile.ZipFile(archive) as bundle:
                self.assertIn('.gdignore', bundle.namelist())
                inventory = json.loads(bundle.read('utility-index.json'))
                for code in ('tc', 'sc', 'rc', 'wp'):
                    scene = inventory[code]['scene'].removeprefix('res://')
                    self.assertEqual(bundle.read('sources/' + scene), (ROOT / scene).read_bytes())
                required = [
                    'commons/grid/UtilityRegistry.gd', 'commons/grid/GridUtilitiesComponent.gd',
                    'commons/grid/GridCommon.gd', 'commons/grid/GridStructureComponent.gd',
                    'commons/scenes/endless_museum.gd',
                    'commons/scenes/mapobjects/transport_cube.gd',
                    'commons/scenes/mapobjects/scale_cube.gd',
                    'commons/scenes/mapobjects/rotation_cube.gd',
                    'addons/godot-xr-tools/player/player_body.gd',
                ]
                for path in required:
                    self.assertEqual(bundle.read('sources/' + path), (ROOT / path).read_bytes(), path)
                state = json.loads(bundle.read('state.json'))
                self.assertEqual(len(state['declared_maps']), 7)
                self.assertIn('Not a runnable project', state['primary_source_snapshot']['scope'])
                manifest = json.loads(bundle.read('MANIFEST.json'))
                self.assertEqual(packages.sha(bundle.read('utility-index.json')), manifest['files']['utility-index.json'])
                evidence_name = 'evidence/supplement/' + evidence_path.relative_to(ROOT).as_posix()
                self.assertEqual(bundle.read(evidence_name), evidence_path.read_bytes())
                self.assertEqual(manifest['files'][evidence_name], packages.sha(evidence_path.read_bytes()))
                self.assertIn('does not rerun', bundle.read('evidence/README.md').decode())
            # A rerun cannot mutate the completed output tree or its ZIP.
            new_hash = packages.sha(archive.read_bytes())
            with self.assertRaises(FileExistsError):
                packages.build(output, 'transformation')
            self.assertEqual(packages.sha(archive.read_bytes()), new_hash)
        self.assertEqual(packages.sha(historical.read_bytes()), old_hash)

    def test_retained_zip_is_protected_when_extracted_directory_is_absent(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            archive = output / 'transformation-review.zip'
            archive.write_bytes(b'previous immutable archive')
            with self.assertRaises(FileExistsError):
                packages.build(output, 'transformation')
            self.assertEqual(archive.read_bytes(), b'previous immutable archive')
            self.assertFalse((output / 'transformation').exists())

    def test_publish_rejects_modified_loose_files_before_writing_destination(self):
        for changed in ('review.md', 'MANIFEST.json'):
            with self.subTest(changed=changed), tempfile.TemporaryDirectory() as directory:
                output = Path(directory) / 'output'
                folder = output / 'transformation'
                folder.mkdir(parents=True)
                archive = output / 'transformation-review.zip'
                with zipfile.ZipFile(archive, 'w') as bundle:
                    for name, content in [('review.md', b'captured text'), ('MANIFEST.json', b'{"files":{}}')]:
                        bundle.writestr(name, content)
                        (folder / name).write_bytes(content)
                packages.dump(output / 'index.json', [{'sequence': 'transformation', 'zip': archive.name,
                    'zip_sha256': packages.sha(archive.read_bytes()), 'text': 'transformation/review.md'}])
                (folder / changed).write_bytes(b'edited after capture')
                target = Path(directory) / 'published'
                with self.assertRaisesRegex(ValueError, 'differs from captured archive'):
                    packages.publish(output, target)
                self.assertFalse(target.exists())


if __name__ == '__main__':
    unittest.main()
