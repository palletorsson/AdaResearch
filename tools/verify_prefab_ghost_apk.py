#!/usr/bin/env python3
"""Check the prefab experiment and ghost dependencies before installing a Quest APK.

Usage: python tools/verify_prefab_ghost_apk.py game.apk --report report.json
Also accepts android/build/src/main/assets (or another unpacked assets directory).
"""
from __future__ import annotations

import argparse
import json
import zipfile
from pathlib import Path

from verify_cube_sorter_apk import Package, dependency_closure, placements

ROOT = Path(__file__).resolve().parents[1]
MAP = "commons/maps/Random_Entropy/map_data.json"
REGISTRY = "commons/artifacts/registry/prefab_disorder.json"
FOLDERS = ("commons/artifacts/prefab_disorder", "commons/ghost_students")
# The bench constructs these paths at runtime; literal-dependency scanning alone
# cannot discover them. Keep this list aligned with prefab_disorder.gd SOURCES.
SOURCES = ("cardboard_box", "computer_monitor", "lab_stool", "microscope")
TEXTS = tuple(f"commons/maps/Random_Entropy/{name}.md" for name in ("tutorial", "final"))


def verify(path: Path) -> dict:
    seeds = {f"commons/artifacts/{item}/{item}.tscn" for item in SOURCES}
    for folder in FOLDERS:
        seeds.update(p.relative_to(ROOT).as_posix() for p in (ROOT / folder).iterdir()
                     if p.suffix in {".gd", ".tscn"})
    required, errors = dependency_closure(ROOT, seeds)
    package = Package(path)
    try:
        resources = [package.resolve(resource) for resource in required]
        errors.extend(item for item in resources if "error" in item)
        # Check the actual placement and text the ghost quotes, as well as code.
        data_checks = []
        for resource in (MAP, REGISTRY, *TEXTS):
            expected = (ROOT / resource).read_bytes()
            actual = package.read(resource)
            passed = actual == expected
            data_checks.append({"resource": resource, "matches_checkout": passed})
            if not passed:
                errors.append({"resource": resource, "error": "packaged data missing or differs from checkout"})
        raw = package.read(MAP)
        rows = placements(json.loads(raw.decode("utf-8-sig"))) if raw else []
        bench = [row for row in rows if str(row["value"]).split(":", 1)[0].split("#", 1)[0] == "prefab_disorder"]
        if len(bench) != 1:
            errors.append({"resource": MAP, "error": "expected exactly one prefab_disorder placement"})
        return {
            "passed": not errors,
            "package": str(path.resolve()),
            "scope": "Resource and remap dependency presence, dynamic prefab sources, current map/registry/tutorial/final. Not bytecode freshness, headset visibility or VR interaction verification.",
            "resource_count": len(resources), "resources": resources,
            "data_checks": data_checks, "placement": bench, "errors": errors,
        }
    finally:
        package.close()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    try:
        report = verify(args.apk)
    except (OSError, ValueError, KeyError, zipfile.BadZipFile) as error:
        parser.exit(2, f"Cannot verify package: {error}\n")
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"{'PASS' if report['passed'] else 'FAIL'}: {report['resource_count']} resources, {len(report['errors'])} errors")
    for error in report["errors"]:
        print(f"  {error['resource']}: {error['error']}")
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
