#!/usr/bin/env python3
"""Audit a trimmed Quest APK against a working export and current hall data.

Package checks only. Run native hall and ghost probes before installation too.
"""
from __future__ import annotations

import argparse
import json
import zipfile
from pathlib import Path

from verify_cube_sorter_apk import REMAP_PATH
from verify_prefab_ghost_apk import verify as verify_ghost

ROOT = Path(__file__).resolve().parents[1]
EXCLUDED_TREES = (
    "ada_run/encounter_pilot/", "reports_tmp/", "tmp/", "output/",
    "ada_encyclopedia/", ".codex/", "ada_run/lean-apk/",
    "ada_run/quest-prefab-repair/",
)


def excluded(path: str) -> bool:
    return path.startswith(EXCLUDED_TREES) or path.startswith(".tmp") or "node_modules" in path.split("/")


def apk_name(info: zipfile.ZipInfo) -> str:
    """Android ZIPs may store UTF-8 filenames without setting the UTF-8 flag."""
    if not info.flag_bits & 0x800:
        try:
            return info.filename.encode("cp437").decode("utf-8")
        except UnicodeError:
            pass
    return info.filename


def verify(apk: Path, baseline: Path) -> dict:
    errors = []
    with zipfile.ZipFile(apk) as current, zipfile.ZipFile(baseline) as old:
        entries = {apk_name(i).removeprefix("assets/"): i for i in current.infolist()
                   if i.filename.startswith("assets/") and not i.is_dir()}
        names = set(entries)
        old_names = {apk_name(i).removeprefix("assets/") for i in old.infolist()
                     if i.filename.startswith("assets/") and not i.is_dir()}
        forbidden = sorted(p for p in names if excluded(p))
        errors.extend({"resource": p, "error": "research/development file leaked into export"} for p in forbidden)

        # Imported/generated payload names are checked through their remaps below.
        # Every other previously shipped file stays unless this change explicitly
        # excludes its tree. This also covers dynamic runtime loads and old paths.
        retained = sorted(p for p in old_names if not excluded(p) and not p.startswith(".godot/"))
        missing = [p for p in retained if p not in names]
        errors.extend({"resource": p, "error": "previous runtime resource lost"} for p in missing)

        remaps = sorted(p for p in names if p.endswith((".remap", ".import")))
        for path in remaps:
            metadata = current.read(entries[path]).decode("utf-8-sig")
            targets = REMAP_PATH.findall(metadata)
            if targets and not any(target in names for target in targets):
                errors.append({"resource": path, "error": "no packaged remap/import target", "targets": targets})

        # Compare the actual current text/data, not just the presence of a folder.
        data_paths = set((ROOT / "commons/maps").glob("*/map_data.json"))
        data_paths.update((ROOT / "commons/maps/sequences").glob("*.json"))
        data_paths.update((ROOT / "commons/artifacts/registry").glob("*.json"))
        data_paths.update(ROOT / "commons/data/museum" / name for name in
                          ("em_plan.json", "em_bake.json", "em_overrides.json"))
        for source in sorted(data_paths):
            path = source.relative_to(ROOT).as_posix()
            if path not in names or current.read("assets/" + path) != source.read_bytes():
                errors.append({"resource": path, "error": "hall/sequence/registry data absent or stale"})

        plan = json.loads(current.read("assets/commons/data/museum/em_plan.json"))
        # Kept binary resources may carry references that a source-only scan misses.
        needles = [b"res://" + tree.encode() for tree in EXCLUDED_TREES]
        binary_count = 0
        for path in retained:
            if path not in names or not path.endswith((".scn", ".res", ".gdc")):
                continue
            binary_count += 1
            data = current.read(entries[path])
            for needle in needles:
                if needle in data:
                    errors.append({"resource": path, "error": "retained binary refers to an excluded tree", "tree": needle.decode()})

        groups = {}
        for item in current.infolist():
            key = "/".join(item.filename.split("/")[:2]) if item.filename.startswith("assets/") else item.filename.split("/")[0]
            row = groups.setdefault(key, {"compressed_bytes": 0, "uncompressed_bytes": 0, "files": 0})
            row["compressed_bytes"] += item.compress_size
            row["uncompressed_bytes"] += item.file_size
            row["files"] += 1

    ghost = verify_ghost(apk)
    errors.extend(ghost["errors"])
    return {
        "passed": not errors, "apk": str(apk.resolve()), "baseline": str(baseline.resolve()),
        "bytes": apk.stat().st_size, "baseline_bytes": baseline.stat().st_size,
        "reduction_percent": round(100 * (1 - apk.stat().st_size / baseline.stat().st_size), 2),
        "retained_resource_count": len(retained), "remap_count": len(remaps),
        "binary_reference_checks": binary_count, "current_data_files_checked": len(data_paths),
        "hall_map_count": sum(p.name == "map_data.json" for p in data_paths),
        "plan_chapter_count": len(plan.get("plans", [])),
        "ghost_resource_count": ghost["resource_count"], "forbidden_entries": forbidden,
        "groups": groups, "errors": errors,
        "scope": "Package retention, remap targets, current hall/sequence/registry data, excluded-tree references and prefab/ghost dependencies. Not a walkthrough of every hall, headset interaction or comfort test.",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    result = verify(args.apk, args.baseline)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(f"{'PASS' if result['passed'] else 'FAIL'}: {result['hall_map_count']} maps; "
          f"{result['retained_resource_count']} retained resources; "
          f"{result['remap_count']} remaps; {len(result['errors'])} errors; "
          f"APK smaller by {result['reduction_percent']}%")
    for error in result["errors"][:30]:
        print(error)
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
