#!/usr/bin/env python3
"""Check the cube sorter and restored library in an exported Godot APK.

Usage: python tools/verify_cube_sorter_apk.py path/to/game.apk --report report.json
The input can also be android/build/src/main/assets for a pre-package check.
This checks package contents against the current checkout, not headset behavior.
"""

from __future__ import annotations

import argparse
import json
import posixpath
import re
import zipfile
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAP = "commons/maps/Point_Animatedcube/map_data.json"
REGISTRIES = {
    "cube_sorting_line": "commons/artifacts/registry/cube_sorting_line.json",
    "prefab_box_library": "commons/artifacts/registry/commons_artifacts.json",
}
TEXT_RESOURCES = {".gd", ".tscn", ".tres", ".json", ".gdshader"}
RESOURCE_LITERAL = re.compile(r'''["'](res://[^"'\r\n]+)["']''')
RELATIVE_LOAD = re.compile(r'''(?:extends|preload\s*\(|load\s*\()\s*["']([^"'\r\n]+)["']''')
REMAP_PATH = re.compile(r'^\s*path(?:\.\w+)?\s*=\s*"res://([^"\r\n]+)"', re.M)


class Package:
    """Read the APK's assets namespace or an already staged assets directory."""

    def __init__(self, path: Path):
        self.path = path
        self.archive = None if path.is_dir() else zipfile.ZipFile(path)

    def read(self, resource: str) -> bytes | None:
        if self.archive:
            try:
                return self.archive.read("assets/" + resource)
            except KeyError:
                return None
        path = self.path / resource
        return path.read_bytes() if path.is_file() else None

    def resolve(self, resource: str) -> dict:
        direct = self.read(resource)
        if direct:
            return {"resource": resource, "packaged_as": resource}
        for suffix in (".remap", ".import"):
            metadata = self.read(resource + suffix)
            if not metadata:
                continue
            targets = REMAP_PATH.findall(metadata.decode("utf-8-sig"))
            present = [target for target in targets if self.read(target)]
            # Texture import files can list several feature variants. At least
            # one must ship; ordinary scene/script remaps name a single target.
            if present:
                return {"resource": resource, "packaged_as": present[0], "via": resource + suffix}
            return {"resource": resource, "error": "missing remap target", "targets": targets}
        return {"resource": resource, "error": "resource absent (including .remap/.import)"}

    def close(self) -> None:
        if self.archive:
            self.archive.close()


def dependency_closure(root: Path, seeds: set[str]) -> tuple[list[str], list[dict]]:
    """Follow literal res:// references and relative extends/load/preload calls.

    This includes shelf catalog sources and scene external resources. Dynamic
    strings and Godot global-class resolution are outside this static check.
    """
    pending = list(seeds)
    seen: set[str] = set()
    errors: list[dict] = []
    while pending:
        resource = pending.pop()
        if resource in seen:
            continue
        seen.add(resource)
        source = root / resource
        if not source.is_file():
            errors.append({"resource": resource, "error": "local dependency missing"})
            continue
        if source.suffix not in TEXT_RESOURCES:
            continue
        text = source.read_text(encoding="utf-8-sig")
        if source.suffix in {".gd", ".gdshader"}:
            text = "\n".join(line for line in text.splitlines() if not line.lstrip().startswith(("#", "//")))
        dependencies = {path.removeprefix("res://") for path in RESOURCE_LITERAL.findall(text)}
        if source.suffix == ".gd":
            for path in RELATIVE_LOAD.findall(text):
                if "://" not in path:
                    dependencies.add(posixpath.normpath(posixpath.join(posixpath.dirname(resource), path)))
        # Directory literals and format strings are not loadable resources.
        pending.extend(path for path in dependencies if posixpath.splitext(path)[1] and "%" not in path)
    return sorted(seen), errors


def placements(document: dict) -> list[dict]:
    return [
        {"x": x, "z": z, "value": cell}
        for z, row in enumerate(document["layers"]["interactables"])
        for x, cell in enumerate(row)
        if cell not in (0, "0", "", None)
    ]


def verify(package_path: Path, root: Path = ROOT) -> dict:
    package = Package(package_path)
    errors: list[dict] = []
    seeds: set[str] = set()
    registry_checks: list[dict] = []
    try:
        for token, resource in REGISTRIES.items():
            expected = json.loads((root / resource).read_text(encoding="utf-8-sig"))["artifacts"][token]
            scene = expected["scene"]
            seeds.add(scene.removeprefix("res://"))
            raw = package.read(resource)
            actual = json.loads(raw.decode("utf-8-sig")).get("artifacts", {}).get(token, {}) if raw else {}
            good = actual.get("scene") == scene and actual.get("map_ready") is True
            check = {"token": token, "registry": resource, "scene": scene, "passed": good}
            registry_checks.append(check)
            if not good:
                errors.append({"resource": resource, "error": "registry entry missing, not map-ready, or scene differs", "token": token})

        # Every sorter source file is required, including a newly added helper
        # that a stale editor filesystem scan might otherwise silently omit.
        for source in (root / "commons/artifacts/cube_sorting_line").iterdir():
            if source.suffix in {".gd", ".tscn"}:
                seeds.add(source.relative_to(root).as_posix())
        required, local_errors = dependency_closure(root, seeds)
        errors.extend(local_errors)
        resources = [package.resolve(resource) for resource in required]
        errors.extend(item for item in resources if "error" in item)

        expected_map = json.loads((root / MAP).read_text(encoding="utf-8-sig"))
        raw_map = package.read(MAP)
        actual_map = json.loads(raw_map.decode("utf-8-sig")) if raw_map else {}
        expected_placements = placements(expected_map)
        actual_placements = placements(actual_map) if actual_map.get("layers", {}).get("interactables") else []
        counts = Counter(str(row["value"]).split(":", 1)[0].split("#", 1)[0] for row in actual_placements)
        map_passed = (
            len(expected_placements) == 22
            and actual_placements == expected_placements
            and counts["cube_sorting_line"] == 1
            and counts["prefab_box_library"] == 1
            and actual_map.get("map_info", {}).get("metadata", {}).get("n_artifacts") == 22
        )
        if not map_passed:
            errors.append({"resource": MAP, "error": "packaged map must match all 22 current placements, including exactly one sorter and one library"})
        return {
            "passed": not errors,
            "package": str(package_path.resolve()),
            "source_root": str(root.resolve()),
            "scope": "Package presence, literal scene/script/catalog dependency closure, both registry entries, and all 22 Animatedcube placements; not a headset runtime test or bytecode freshness check.",
            "registries": registry_checks,
            "map": {"resource": MAP, "passed": map_passed, "placement_count": len(actual_placements), "sorter_count": counts["cube_sorting_line"], "library_count": counts["prefab_box_library"]},
            "resource_count": len(resources),
            "resources": resources,
            "errors": errors,
        }
    finally:
        package.close()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path, help="APK file or staged assets directory")
    parser.add_argument("--report", type=Path, help="save the detailed JSON report")
    args = parser.parse_args()
    try:
        report = verify(args.apk)
    except (OSError, ValueError, KeyError, zipfile.BadZipFile) as error:
        parser.exit(2, f"Cannot verify package: {error}\n")
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"{'PASS' if report['passed'] else 'FAIL'}: {report['resource_count']} resources, {report['map']['placement_count']} map placements, {len(report['errors'])} errors")
    for error in report["errors"]:
        print(f"  {error['resource']}: {error['error']}")
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
