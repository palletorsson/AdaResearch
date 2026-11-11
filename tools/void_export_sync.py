#!/usr/bin/env python3
"""Keep the exported Void models in step with commons/void/rooms.json (Palle, 2026-11-11: "we have a godot, three js,
blender, json cross over - where do you work best? ... yes, fix the export first").

The browser editor (ada_encyclopedia /lab-editor) and the Blender add-on (tools/blender/ada_void) draw a floor from
two things: the LIVE layout (rooms.json through /api/void-layout) and the EXPORTED models
(ada_encyclopedia/public/void-models/manifest.json + .glb). A work moved or turned needs no export. A work that is new
on a floor, re-configured, re-scaled, a new wall or route caption, or a prop kind the palette has never seen, does -
and until then the fast eyes show the floor without it (2026-11-11: floor 85 rendered 5 of its 11 works and 1 of its
20 props).

    python tools/void_export_sync.py --check             which floors and prop kinds are stale; exit 1 if any
    python tools/void_export_sync.py                     export every stale floor and every missing prop kind
    python tools/void_export_sync.py --floors=85,90      these floors (stale or not)
    python tools/void_export_sync.py --kinds=a,b         these prop kinds (default: catalogue kinds the manifest lacks)

Floors go through the existing incremental exporter, tools/export_void_floors.py (about 20 s a floor); that exporter
always skips the palette, so prop kinds are exported here: one run of tools/probes/export_void_editor.gd with the
palette on, into a scratch directory, and ONLY the wanted kinds are merged into the public manifest.
Each exported floor is stamped with `record_hash`, the hash of its rooms.json record without positions, facings and
stations; a floor is stale when that hash differs. A floor never stamped is judged by its placement ids and kinds.
"""
from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import sys
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
ROOMS = ROOT / "commons/void/rooms.json"
CATALOG = ROOT / "commons/void/catalog.json"
PUBLIC = Path(os.environ.get("ADA_ENCYCLOPEDIA_ROOT", ROOT.parent / "ada_encyclopedia")) / "public/void-models"
MANIFEST = PUBLIC / "manifest.json"
GODOT = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
LAYOUT_KEYS = ("position", "facing", "station")     # the live layout carries these; the models do not depend on them
CHUNK = 3                                             # floors per run of the incremental exporter: its own limit is 240 s, and
                                                      # six of the dense early floors (10-22) ran past it on 2026-11-11


def record_hash(floor: dict) -> str:
    def strip(row):
        return {k: v for k, v in row.items() if k not in LAYOUT_KEYS}
    body = {k: ([strip(r) for r in v] if k in ("artifacts", "copies", "props") else v) for k, v in floor.items()}
    return hashlib.sha256(json.dumps(body, sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()[:16]


def state() -> tuple:
    rooms = json.loads(ROOMS.read_text(encoding="utf-8"))["floors"]
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))["props"]
    stale = {}
    for i, floor in enumerate(rooms):
        have = manifest["floors"].get(str(i))
        if have is None:
            stale[i] = "not exported"
            continue
        if have.get("map") != floor.get("map"):
            stale[i] = f"exported as {have.get('map')}, now {floor.get('map')}"
            continue
        if have.get("record_hash"):
            if have["record_hash"] != record_hash(floor):
                stale[i] = "its record changed since the export"
            continue
        want = {a["id"]: a["artifact"] for a in floor.get("artifacts", []) + floor.get("copies", [])}
        got = {k: v.get("artifact") for k, v in have.get("artifacts", {}).items()}
        missing = sorted(set(want) - set(got))
        changed = sorted(k for k in want if k in got and got[k] != want[k])
        if missing or changed:
            stale[i] = "; ".join(x for x in (f"{len(missing)} placement(s) without a model: {', '.join(missing[:4])}" if missing else "",
                                             f"{len(changed)} placement(s) of another kind" if changed else "") if x)
    kinds = [k for k in catalog if k not in manifest.get("props", {})]
    return rooms, manifest, stale, kinds


def export_floors(floors: list) -> list:
    """-> the floors that failed. A chunk that fails is retried floor by floor, so one bad floor costs only itself."""
    def run(chunk: list) -> bool:
        out = ROOT / "ada_run/export_sync" / ("floors_" + "_".join(map(str, chunk)))
        try:
            r = subprocess.run([sys.executable, str(ROOT / "tools/export_void_floors.py"), ",".join(map(str, chunk)), str(out)],
                               cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=420)
        except subprocess.TimeoutExpired:
            print(f"  floors {chunk}: timed out", flush=True)
            return False
        tail = r.stdout.strip().splitlines()[-1] if r.stdout.strip() else "(no output)"
        print(f"  floors {chunk}: " + (tail if not r.returncode else "FAILED - " + (r.stdout + r.stderr).strip().splitlines()[-1][:200]), flush=True)
        return r.returncode == 0
    done, failed = [], []
    for n in range(0, len(floors), CHUNK):
        chunk = floors[n:n + CHUNK]
        if run(chunk):
            done += chunk
            continue
        for one in chunk:
            (done if run([one]) else failed).append(one)
    stamp(done)
    return failed


def stamp(floors: list) -> None:
    """record_hash on each exported floor, written under the same publication lock the exporter uses"""
    from void_native_slot import acquire_native_slot
    lock = acquire_native_slot("stamp Void models", timeout=30, lock_name="void-model-publication.lock")
    rooms = json.loads(ROOMS.read_text(encoding="utf-8"))["floors"]
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    for i in floors:
        if str(i) in manifest["floors"]:
            manifest["floors"][str(i)]["record_hash"] = record_hash(rooms[i])
    publish(manifest)
    lock.close()


def publish(manifest: dict) -> None:
    manifest["revision"] = hashlib.sha256(json.dumps(manifest).encode()).hexdigest()[:12]
    temporary = MANIFEST.with_suffix(".next.json")
    temporary.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    os.replace(temporary, MANIFEST)


def export_kinds(kinds: list) -> None:
    from generated_storage import model_directory
    from void_native_slot import acquire_native_slot
    from void_trial_runtime import stage_runtime
    out = ROOT / "ada_run/export_sync/palette"
    out.mkdir(parents=True, exist_ok=True)
    staged = model_directory(out / "native-models")
    if staged.exists():
        shutil.rmtree(staged, ignore_errors=True)
    staged.mkdir(parents=True, exist_ok=True)
    slot = acquire_native_slot("Void palette models")
    stage = stage_runtime()
    with (out / "export.log").open("w", encoding="utf-8") as stream:
        r = subprocess.run([GODOT, "--no-window", "--path", str(stage), "--rendering-method", os.environ.get("GODOT_RENDERER", "gl_compatibility"),
                            "--xr-mode", "off", "--script", "res://tools/probes/export_void_editor.gd", "--", "--no-bridges", "--floors=0",
                            "--out=" + str(staged), "--public-base=/void-models"], stdout=stream, stderr=subprocess.STDOUT, timeout=900,
                           creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
    slot.close()
    produced = staged / "manifest.json"
    if not produced.exists():
        raise SystemExit("the palette export wrote no manifest - see " + str(out / "export.log") + f" (exit {r.returncode})")
    new = json.loads(produced.read_text(encoding="utf-8"))
    absent = [k for k in kinds if k not in new.get("props", {})]
    if absent:
        raise SystemExit(f"the palette export has no model for {absent} - see {out / 'export.log'}")
    lock = acquire_native_slot("publish Void palette", timeout=30, lock_name="void-model-publication.lock")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    copied = 0
    for kind in kinds:
        manifest.setdefault("props", {})[kind] = new["props"][kind]
        for source in staged.iterdir():
            if source.is_file() and source.name.startswith("prop-" + kind + "."):
                temporary = PUBLIC / (source.name + "." + uuid.uuid4().hex + ".tmp")
                shutil.copy2(source, temporary)
                os.replace(temporary, PUBLIC / source.name)
                copied += 1
    publish(manifest)
    lock.close()
    print(f"  palette: {len(kinds)} kind(s), {copied} file(s) published")


def main() -> int:
    args = sys.argv[1:]
    rooms, manifest, stale, kinds = state()
    if "--check" in args:
        for i, why in stale.items():
            print(f"floor {i} {rooms[i].get('map')}: {why}")
        if kinds:
            print("prop kinds without a model:", ", ".join(kinds))
        print(f"{len(stale)} stale floor(s), {len(kinds)} prop kind(s) without a model, of {len(rooms)} floors")
        return 1 if stale or kinds else 0
    floors = next(([int(x) for x in a.split("=", 1)[1].split(",") if x] for a in args if a.startswith("--floors=")), sorted(stale))
    wanted = next(([x for x in a.split("=", 1)[1].split(",") if x] for a in args if a.startswith("--kinds=")), kinds)
    if wanted:
        print("prop kinds:", ", ".join(wanted))
        export_kinds(wanted)
    failed = []
    if floors:
        print("floors:", floors, flush=True)
        failed = export_floors(floors)
    rooms, manifest, stale, kinds = state()
    print(f"now {len(stale)} stale floor(s), {len(kinds)} prop kind(s) without a model" + (f"; FAILED to export: {failed}" if failed else ""))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
