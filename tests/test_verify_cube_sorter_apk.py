"""Focused package checks; no Godot runtime or Android SDK required."""

import json
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from tools.verify_cube_sorter_apk import MAP, REGISTRIES, Package, dependency_closure, verify


class CubeSorterPackageTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.assets = {}
        for token, registry in REGISTRIES.items():
            scene = f"commons/artifacts/{token}/{token}.tscn"
            self.write(registry, json.dumps({"artifacts": {token: {"scene": "res://" + scene, "map_ready": True}}}))
            self.write(scene, '[gd_scene format=3]\n')
        row = ["cube_sorting_line:270:0", "prefab_box_library:90:0"] + [f"other_{i}" for i in range(20)]
        self.write(MAP, json.dumps({"map_info": {"metadata": {"n_artifacts": 22}}, "layers": {"interactables": [row]}}))

    def write(self, path, text):
        local = self.root / path
        local.parent.mkdir(parents=True, exist_ok=True)
        local.write_text(text, encoding="utf-8")
        self.assets[path] = text.encode()

    def apk(self):
        path = self.root / "test.apk"
        with zipfile.ZipFile(path, "w") as archive:
            for resource, content in self.assets.items():
                archive.writestr("assets/" + resource, content)
        return path

    def test_scene_remap_target_is_accepted_and_missing_target_fails(self):
        scene = "commons/artifacts/cube_sorting_line/cube_sorting_line.tscn"
        del self.assets[scene]
        target = ".godot/exported/123/cube_sorting_line.scn"
        self.assets[scene + ".remap"] = f'[remap]\npath="res://{target}"'.encode()
        self.assets[target] = b"exported scene"
        self.assertTrue(verify(self.apk(), self.root)["passed"])
        del self.assets[target]
        report = verify(self.apk(), self.root)
        self.assertFalse(report["passed"])
        self.assertIn("missing remap target", {error["error"] for error in report["errors"]})

    def test_new_scene_omitted_while_registry_and_map_ship_is_detected(self):
        del self.assets["commons/artifacts/cube_sorting_line/cube_sorting_line.tscn"]
        report = verify(self.apk(), self.root)
        self.assertTrue(report["map"]["passed"])
        self.assertTrue(all(row["passed"] for row in report["registries"]))
        self.assertFalse(report["passed"])

    def test_inheritance_preload_and_catalog_sources_are_followed(self):
        self.write("entry.gd", 'extends "base.gd"\nconst HELPER = preload("res://helper.gd")\nconst CATALOG = "res://catalog.json"')
        self.write("base.gd", "extends Node\n")
        self.write("helper.gd", "extends Node\n")
        self.write("catalog.json", '{"source":"res://box.tscn"}')
        self.write("box.tscn", "[gd_scene format=3]\n")
        paths, errors = dependency_closure(self.root, {"entry.gd"})
        self.assertEqual(paths, ["base.gd", "box.tscn", "catalog.json", "entry.gd", "helper.gd"])
        self.assertEqual(errors, [])

    def test_stale_placement_configuration_fails(self):
        data = json.loads(self.assets[MAP])
        data["layers"]["interactables"][0][0] = "cube_sorting_line:90:0"
        self.assets[MAP] = json.dumps(data).encode()
        self.assertFalse(verify(self.apk(), self.root)["map"]["passed"])

    def test_registry_must_be_map_ready(self):
        resource = REGISTRIES["cube_sorting_line"]
        data = json.loads(self.assets[resource])
        data["artifacts"]["cube_sorting_line"]["map_ready"] = False
        self.assets[resource] = json.dumps(data).encode()
        self.assertFalse(verify(self.apk(), self.root)["passed"])

    def test_staged_assets_directory_uses_same_namespace(self):
        package = Package(self.root)
        self.addCleanup(package.close)
        self.assertNotIn("error", package.resolve(MAP))


if __name__ == "__main__":
    unittest.main()
