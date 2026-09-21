#!/usr/bin/env python3
"""Compile preassembled Endless Museum hall cartridges.

Examples:
    python tools/em_cartridge.py --map Point_One
    python tools/em_cartridge.py --map Point_Lines --ship
    python tools/em_cartridge.py --check --map Point_One
    python tools/em_cartridge.py --spine --ship
    python tools/em_cartridge.py --spine --check
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
GODOT = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
PLAN = REPO / "ada_run" / "em_plan.json"
INDEX = REPO / "ada_run" / "em_cartridges" / "index.json"
REPORT = REPO / "ada_run" / "em_cartridges" / "spine_report.json"
SPINE = REPO / "commons" / "maps" / "curriculum_spine.json"
SEQUENCES = REPO / "commons" / "maps" / "sequences"
FIXED_SOURCES = [
    PLAN,
    REPO / "ada_run" / "em_bake.json",
    REPO / "ada_run" / "em_overrides.json",
    REPO / "commons" / "data" / "template_patterns.json",
    REPO / "commons" / "data" / "em_layout.json",
    REPO / "commons" / "scenes" / "endless_museum.gd",
    REPO / "commons" / "scenes" / "em" / "em_cartridge.gd",
    REPO / "commons" / "scenes" / "em" / "em_detail.gd",
    REPO / "commons" / "scenes" / "em" / "em_lighting.gd",
]


def plan_row(map_name: str) -> dict:
    if not PLAN.exists():
        return {}
    doc = json.loads(PLAN.read_text(encoding="utf-8"))
    for row in doc.get("plans", []):
        if row.get("map") == map_name:
            return row
        for page in row.get("pages", []):
            if page.get("map") == map_name:
                return {**row, **page}
    return {}


def indexed(map_name: str) -> dict:
    if not INDEX.exists():
        return {}
    try:
        doc = json.loads(INDEX.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return doc.get("entries", {}).get(map_name, {})


def index_document() -> dict:
    if not INDEX.is_file():
        return {"schema": "adaresearch.em_cartridge.v1", "entries": {}}
    return json.loads(INDEX.read_text(encoding="utf-8"))


def write_index_document(doc: dict) -> None:
    temporary = INDEX.with_suffix(".json.tmp")
    temporary.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    temporary.replace(INDEX)


def resource_path(value: str) -> Path:
    return REPO / value.removeprefix("res://")


def entry_complete(entry: dict) -> bool:
    if not entry or not resource_path(str(entry.get("scene", ""))).is_file():
        return False
    content = entry.get("content", [])
    return len(content) == int(entry.get("content_count", -1)) and all(
        resource_path(str(path)).is_file() for path in content
    )


def source_stamp(map_name: str) -> int:
    paths = FIXED_SOURCES + [REPO / "commons" / "maps" / map_name / "map_data.json"]
    return max((int(path.stat().st_mtime) for path in paths if path.is_file()), default=0)


def entry_fresh(map_name: str) -> bool:
    entry = indexed(map_name)
    return entry_complete(entry) and int(entry.get("source_stamp", 0)) >= source_stamp(map_name)


def spine_scope() -> tuple[list[dict], list[dict]]:
    spine_doc = json.loads(SPINE.read_text(encoding="utf-8"))
    sequence_names = [row["name"] for row in spine_doc["spine"]["sequences"]]
    sequence_refs: list[dict] = []
    for sequence in sequence_names:
        path = SEQUENCES / f"{sequence}.json"
        if not path.is_file():
            continue
        doc = json.loads(path.read_text(encoding="utf-8"))
        for map_name in doc.get("sequences", {}).get(sequence, {}).get("maps", []):
            sequence_refs.append({"sequence": sequence, "map": map_name})
    plan_doc = json.loads(PLAN.read_text(encoding="utf-8"))
    plan_halls = {
        row.get("map", ""): row for row in plan_doc.get("plans", [])
        if row.get("sequence") in sequence_names and row.get("map")
    }
    # Preserve the curriculum's sequence order and each sequence's map order;
    # em_plan is negotiation output and is not guaranteed to retain either.
    halls = [
        {"sequence": ref["sequence"], "map": ref["map"],
         "pearl": plan_halls[ref["map"]].get("pearl", "")}
        for ref in sequence_refs if ref["map"] in plan_halls
    ]
    hall_maps = {row["map"] for row in halls}
    missing = [row for row in sequence_refs if row["map"] not in hall_maps]
    return halls, missing


def write_report(report: dict) -> None:
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    temporary = REPORT.with_suffix(".json.tmp")
    temporary.write_text(json.dumps(report, indent=2), encoding="utf-8")
    temporary.replace(REPORT)


def seal_source_stamps(halls: list[dict]) -> bool:
    """Seal a complete pass after its own per-hall bake measurements settle.

    Building a hall may append measurements to the global em_bake.json. Those
    writes affect only that hall's keyed bake row, but advance the file mtime and
    make earlier cartridges look stale. Sealing is allowed only when every
    selected package exists; actual later source edits still advance the mtime
    beyond this final stamp and invalidate cartridges normally.
    """
    doc = index_document()
    entries = doc.get("entries", {})
    if not all(entry_complete(entries.get(row["map"], {})) for row in halls):
        return False
    for row in halls:
        entries[row["map"]]["source_stamp"] = source_stamp(row["map"])
    doc["entries"] = entries
    doc["sealed_at"] = time.strftime("%Y-%m-%dT%H:%M:%S")
    write_index_document(doc)
    return True


def compile_one(map_name: str, chapter: str, timeout: int) -> tuple[bool, float]:
    log = REPO / "ada_run" / "em_cartridge.log"
    cmd = [GODOT, "--headless", "--path", str(REPO), "--xr-mode", "off",
           "--log-file", str(log), "--script",
           "res://commons/testing/compile_em_cartridge.gd", "--",
           f"--cartridge-map={map_name}", f"--cartridge-chapter={chapter}"]
    before = str(indexed(map_name).get("compiled_at", ""))
    started = time.monotonic()
    process = subprocess.Popen(cmd, cwd=REPO, stdout=subprocess.DEVNULL,
                               stderr=subprocess.STDOUT)
    deadline = started + timeout
    completed = False
    while time.monotonic() < deadline:
        entry = indexed(map_name)
        completed = bool(entry) and str(entry.get("compiled_at", "")) != before
        if completed or process.poll() is not None:
            break
        time.sleep(0.1)
    if completed:
        try:
            process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            process.terminate()
            process.wait(timeout=5)
    else:
        if process.poll() is None:
            process.terminate()
            process.wait(timeout=5)
        failures = REPORT.parent / "failures"
        failures.mkdir(parents=True, exist_ok=True)
        if log.is_file():
            shutil.copyfile(log, failures / f"{map_name}.log")
    return completed and entry_complete(indexed(map_name)), time.monotonic() - started


def run_spine(args: argparse.Namespace) -> int:
    halls, missing = spine_scope()
    if args.from_map:
        start = next((i for i, row in enumerate(halls) if row["map"] == args.from_map), -1)
        if start < 0:
            print(f"EM SPINE: --from-map {args.from_map} is not an Endless Museum spine hall")
            return 2
        halls = halls[start:]
    if args.limit > 0:
        halls = halls[:args.limit]
    report = {
        "schema": "adaresearch.em_cartridge_spine_report.v1",
        "spine_sequence_map_refs": len(spine_scope()[0]) + len(missing),
        "museum_halls": len(spine_scope()[0]),
        "selected": len(halls),
        "missing_from_plan": missing,
        "compiled": [], "skipped_fresh": [], "failed": [],
    }
    if args.seal:
        sealed = seal_source_stamps(halls)
        report["sealed"] = sealed
        write_report(report)
        if not sealed:
            print("EM SPINE SEAL: refused — one or more selected hall packages are incomplete")
            return 1
        print(f"EM SPINE SEAL: PASS — {len(halls)} complete hall(s) aligned to the settled bake")
    if args.check:
        for row in halls:
            bucket = "skipped_fresh" if entry_fresh(row["map"]) else "failed"
            report[bucket].append(row)
        write_report(report)
        print(f"EM SPINE CHECK: {len(report['skipped_fresh'])}/{len(halls)} fresh; "
              f"{len(report['failed'])} missing/stale; {len(missing)} sequence maps outside the museum plan")
        return 0 if not report["failed"] else 1
    for i, row in enumerate(halls, start=1):
        map_name, chapter = row["map"], row["sequence"]
        if not args.rebuild and entry_fresh(map_name):
            report["skipped_fresh"].append(row)
            print(f"[{i:03d}/{len(halls):03d}] FRESH {chapter} · {map_name}", flush=True)
        else:
            ok, elapsed = compile_one(map_name, chapter, args.timeout)
            result = {**row, "seconds": round(elapsed, 2)}
            report["compiled" if ok else "failed"].append(result)
            print(f"[{i:03d}/{len(halls):03d}] {'PASS' if ok else 'FAIL'}  "
                  f"{chapter} · {map_name} ({elapsed:.1f}s)", flush=True)
        report["updated_at"] = time.strftime("%Y-%m-%dT%H:%M:%S")
        write_report(report)
    if not report["failed"]:
        report["sealed"] = seal_source_stamps(halls)
        write_report(report)
    if args.ship:
        subprocess.run([sys.executable, str(REPO / "tools" / "em_ship.py")],
                       cwd=REPO, check=True)
    print(f"EM SPINE: {len(report['compiled'])} compiled, "
          f"{len(report['skipped_fresh'])} already fresh, {len(report['failed'])} failed; "
          f"{len(missing)} sequence maps are not Endless Museum plan halls")
    return 0 if not report["failed"] else 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--map", default="Point_One")
    parser.add_argument("--chapter", default="")
    parser.add_argument("--spine", action="store_true",
                        help="compile every Endless Museum hall owned by a spine sequence")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--ship", action="store_true")
    parser.add_argument("--rebuild", action="store_true")
    parser.add_argument("--seal", action="store_true",
                        help="align complete cartridges after per-hall bake enrichment settles")
    parser.add_argument("--from-map", default="")
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--timeout", type=int, default=90)
    args = parser.parse_args()

    if args.spine:
        return run_spine(args)

    row = plan_row(args.map)
    chapter = args.chapter or str(row.get("sequence", "primitives"))
    if args.check:
        entry = indexed(args.map)
        scene = REPO / "ada_run" / "em_cartridges" / Path(entry.get("scene", "")).name
        ok = entry_complete(entry)
        print(f"EM CARTRIDGE: {'PASS' if ok else 'MISSING'} {chapter} · {args.map}"
              + (f" ({int(entry.get('bytes', scene.stat().st_size)) // 1024} KB)" if ok else ""))
        return 0 if ok else 1

    completed, elapsed = compile_one(args.map, chapter, args.timeout)
    if not completed:
        print(f"EM CARTRIDGE: FAIL {args.map} (see ada_run/em_cartridge.log)")
        return 1
    entry = indexed(args.map)
    if not entry:
        print(f"EM CARTRIDGE: FAIL {args.map} produced no index row")
        return 1
    print(f"EM CARTRIDGE: PASS {chapter} · {args.map} -> {entry.get('scene')} ({elapsed:.1f}s)")
    if args.ship:
        subprocess.run([sys.executable, str(REPO / "tools" / "em_ship.py")], cwd=REPO, check=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
