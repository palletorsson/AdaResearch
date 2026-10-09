"""Extract and execute both complete printed lessons, including their real continuation.

Run: python doc/book/iterations/2026-10-05-points-built-and-carried/run_checks.py
Only generated evidence beneath this iteration and a private temporary project are written.
"""
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
ENGINE = Path(os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"))
SOURCES = {
    "001-point-one": ROOT / "commons/maps/Point_One/tutorial.md",
    "002-point-coordinates": ROOT / "commons/maps/Point_Coordinates/tutorial.md",
}
DEPENDENCY_EXTENSIONS = {".gd", ".tscn", ".tres", ".gdshader"}
VARIANTS = [
    ("001-point-one", "radius-030.gd", "point_one_radius.gd", "const RADIUS := 0.14", "const RADIUS := 0.3"),
    ("001-point-one", "centre-170.gd", "point_one_height.gd", "const CENTRE := Vector3(0, 1.12, 0)", "const CENTRE := Vector3(0, 1.7, 0)"),
    ("001-point-one", "boundary-disabled.gd", "point_one_no_collision.gd", "    boundary.shape = shape\n", "    boundary.shape = shape\n    boundary.disabled = true\n"),
    ("001-point-one", "surface-hidden.gd", "point_one_invisible.gd", "    surface.mesh = sphere\n", "    surface.mesh = sphere\n    surface.visible = false\n"),
    ("002-point-coordinates", "pickup-disabled.gd", "point_coordinates_disabled.gd", "    add_child(point)\n", "    point.enabled = false\n    add_child(point)\n"),
]
OPERATIONS = [
    {"id": "body-reference", "kind": "replace", "before": "var point: StaticBody3D\n", "after": "var point: XRToolsPickable\nvar readout: Label3D\n"},
    {"id": "body-construction", "kind": "replace", "before": "    point = StaticBody3D.new()\n", "after": "    point = XRToolsPickable.new()\n"},
    {"id": "pickup-settings", "kind": "insert_after", "anchor": "    point.position = CENTRE\n", "text": (
        "    point.freeze = true\n"
        "    point.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC\n"
        "    point.release_mode = XRToolsPickable.ReleaseMode.FROZEN\n"
        "    point.ranged_grab_method = XRToolsPickable.RangedMethod.NONE\n"
        "    point.collision_layer = 4\n"
        "    point.collision_mask = 196615\n")},
    {"id": "live-readout", "kind": "insert_after", "anchor": "    add_child(point)\n", "text": (
        "\n    readout = Label3D.new()\n"
        "    readout.position = Vector3(0, 1.6, 0)\n"
        "    readout.font_size = 36\n"
        "    readout.pixel_size = 0.005\n"
        "    add_child(readout)\n"
        "\nfunc _process(_delta: float) -> void:\n"
        "    var world_position := point.global_position\n"
        "    var local_position := to_local(world_position)\n"
        "    readout.text = \"LOCAL \" + str(local_position) + \"\\nWORLD \" + str(world_position)\n")},
]


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def relative(path):
    return path.relative_to(ROOT).as_posix()


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def save_json(path, value):
    write(path, json.dumps(value, indent=2, ensure_ascii=False) + "\n")


def replace_once(code, before, after):
    if code.count(before) != 1:
        raise ValueError(f"Expected one unique edit anchor: {before!r}")
    return code.replace(before, after, 1)


def compose(code):
    for operation in OPERATIONS:
        if operation["kind"] == "replace":
            code = replace_once(code, operation["before"], operation["after"])
        else:
            code = replace_once(code, operation["anchor"], operation["anchor"] + operation["text"])
    return code


def dependency_hashes(base):
    return {p.relative_to(base).as_posix(): sha256(p)
            for p in sorted((base / "addons/godot-xr-tools").rglob("*"))
            if p.is_file() and p.suffix in DEPENDENCY_EXTENSIONS}


def extract():
    code = {}
    for state, source in SOURCES.items():
        tutorial = source.read_text(encoding="utf-8-sig")
        blocks = re.findall(r"<!-- student-code:point\.gd -->\s*```gdscript\n(.*?)^```", tutorial, re.M | re.S)
        if len(blocks) != 1 or tutorial.count("```gdscript") != 1:
            raise ValueError(f"{source}: expected exactly one complete marked script")
        code[state] = blocks[0]
        if not code[state].startswith("extends Node3D\n") or code[state].count("func _ready()") != 1:
            raise ValueError(f"{source}: incomplete or duplicated construction")
        write(HERE / "states" / state / "point.gd", code[state])
        write(HERE / "states" / state / "expected.gd", code[state])
        write(HERE / "states" / state / "tutorial.md", tutorial)
        point_path = HERE / "states" / state / "point.gd"
        save_json(HERE / "states" / state / "next-input.json", {
            "incoming": {"path": relative(point_path), "sha256": sha256(point_path),
                         "provenance": "Exact complete printed student code, verified by this iteration's native runner."}
        })
    assembled = compose(code["001-point-one"])
    if assembled != code["002-point-coordinates"]:
        raise ValueError("Coordinates is not exactly Point One plus the declared edits")
    write(HERE / "states/002-point-coordinates/assembled.gd", assembled)
    for state, filename, _, before, after in VARIANTS:
        write(HERE / "states" / state / "variants" / filename, replace_once(code[state], before, after))
    return code


def main():
    code = extract()
    one = code["001-point-one"]
    coordinates = code["002-point-coordinates"]
    source_before = {relative(p): sha256(p) for p in SOURCES.values()}
    evidence_paths = [HERE / "run_checks.py", HERE / "verify.gd"]
    for state in SOURCES:
        evidence_paths += [HERE / "states" / state / name for name in ("point.gd", "expected.gd", "tutorial.md", "next-input.json")]
    evidence_paths.append(HERE / "states/002-point-coordinates/assembled.gd")
    evidence_paths += [HERE / "states" / state / "variants" / filename for state, filename, *_ in VARIANTS]
    evidence_before = {relative(p): sha256(p) for p in evidence_paths}
    dependencies_before = dependency_hashes(ROOT)
    work = Path(tempfile.mkdtemp(prefix="ada-points-built-carried-"))
    shutil.copytree(ROOT / "addons/godot-xr-tools", work / "addons/godot-xr-tools")
    if dependency_hashes(work) != dependencies_before:
        raise ValueError("Private XR Tools copy is not identical to the repository dependency")
    write(work / "project.godot", '''config_version=5
[application]
config/name="Student-built Point One and Coordinates native checks"
config/features=PackedStringArray("4.6")
[autoload]
XRToolsUserSettings="*res://addons/godot-xr-tools/user_settings/user_settings.gd"
XRToolsRumbleManager="*res://addons/godot-xr-tools/rumble/rumble_manager.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
''')
    native_sources = {
        "point_one.gd": one,
        "point_coordinates.gd": coordinates,
        **{native: (HERE / "states" / state / "variants" / filename).read_text(encoding="utf-8")
           for state, filename, native, *_ in VARIANTS},
        "point_one_missing_mesh.gd": replace_once(one, "    surface.mesh = sphere\n", ""),
        "point_coordinates_local_as_world.gd": replace_once(coordinates, "    var world_position := point.global_position\n", "    var world_position := point.position\n"),
    }
    for name, text in native_sources.items():
        write(work / name, text)
    shutil.copy2(HERE / "verify.gd", work / "verify.gd")
    native_files = [work / name for name in native_sources] + [work / "verify.gd", work / "project.godot"]
    native_before = {p.name: sha256(p) for p in native_files}
    assert native_before["point_one.gd"] == sha256(HERE / "states/001-point-one/point.gd")
    assert native_before["point_coordinates.gd"] == sha256(HERE / "states/002-point-coordinates/point.gd")
    variant_bindings = {}
    for state, filename, native, before, after in VARIANTS:
        published = HERE / "states" / state / "variants" / filename
        assert native_before[native] == sha256(published)
        variant_bindings[relative(published)] = {
            "sha256": sha256(published), "native_filename": native,
            "edit": {"kind": "replace", "before": before, "after": after},
        }
    flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
    common = [str(ENGINE), "--headless", "--path", str(work), "--xr-mode", "off", "--audio-driver", "Dummy"]
    runs = []
    stages = [("import", ["--editor", "--import", "--quit"], 0)]
    stages += [(name, ["--script", "res://verify.gd", "--", str(work / (name + ".json")), name], expected)
               for name, expected in (("positive", 0), ("missing_mesh", 1), ("local_as_world", 1))]
    for name, arguments, expected_exit in stages:
        result = subprocess.run(common + arguments, cwd=work, text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, creationflags=flags, timeout=55,
                                encoding="utf-8", errors="replace")
        write(work / f"{name}.log", result.stdout)
        write(HERE / "logs" / f"{name}.log", result.stdout)
        engine_error = "SCRIPT ERROR:" in result.stdout or "ERROR:" in result.stdout
        runs.append({"stage": name, "exit_code": result.returncode, "expected_exit_code": expected_exit,
                     "script_or_engine_error": engine_error})
        print(f"{name}: exit={result.returncode} (expected {expected_exit})", flush=True)
        if result.returncode != expected_exit or engine_error:
            print(result.stdout[-14000:], flush=True)
            break
    positive_path = work / "positive.json"
    positive = json.loads(positive_path.read_text(encoding="utf-8")) if positive_path.exists() else {"passed": False, "checks": []}
    expected_failures = {
        "missing_mesh": ["point_one/default/visible_sphere"],
        "local_as_world": ["point_coordinates/default/" + suffix for suffix in (
            "initial_readout", "held_readout", "released_readout", "changed_frame_readout", "moved_body_readout")],
    }
    negatives = []
    for name, failure_ids in expected_failures.items():
        path = work / (name + ".json")
        result = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {"passed": None, "checks": []}
        detected = result.get("passed") is False and set(result.get("failure_ids", [])) == set(failure_ids)
        negatives.append({"name": name, "expected_failure_detected": detected,
                          "expected_failure_ids": failure_ids, "normal_contract_result": result})
    source_after = {relative(p): sha256(p) for p in SOURCES.values()}
    evidence_after = {relative(p): sha256(p) for p in evidence_paths}
    unchanged = (source_before == source_after and evidence_before == evidence_after
                 and dependencies_before == dependency_hashes(ROOT) == dependency_hashes(work)
                 and native_before == {p.name: sha256(p) for p in native_files})
    passed = bool(positive.get("passed") and all(x["expected_failure_detected"] for x in negatives)
                  and unchanged and len(runs) == len(stages)
                  and all(x["exit_code"] == x["expected_exit_code"] and not x["script_or_engine_error"] for x in runs))
    scope = positive.get("scope", "Native execution did not finish.")
    inputs = {**source_before, **evidence_before}
    state_reports = {}
    for state, source in SOURCES.items():
        state_dir = HERE / "states" / state
        is_one = state.startswith("001")
        prefix = "point_one/" if is_one else "point_coordinates/"
        checks = [entry for entry in positive["checks"] if entry["id"].startswith(prefix)]
        incoming_path = HERE / "states/001-point-one/point.gd"
        contract = {
            "mode": "build_from_scratch" if is_one else "continuation_complete_script",
            "lesson": relative(state_dir / "tutorial.md"), "example": relative(state_dir / "point.gd"),
            "canonical_lesson": relative(source),
            "host": "Empty Node3D PointStudy in the prepared Day Zero project; configured XR hands are supplied for Coordinates.",
            "incoming": None if is_one else {"path": relative(incoming_path), "sha256": sha256(incoming_path),
                "provenance": "The exact tested, printed Point One script in this same iteration; no museum construction is assumed."},
            "operations": [] if is_one else OPERATIONS,
            "printed_complete_script_equals_native_input": True,
            "exercise_variants": {path: binding for path, binding in variant_bindings.items() if f"/states/{state}/" in path},
            "composed_equals_printed_complete_script": None if is_one else True,
            "sources": [{"path": relative(path), "sha256": sha256(path)} for path in (source, state_dir / "tutorial.md")],
            "evidence_inputs": list(inputs),
            "checks": [{"id": c["id"], "kind": "native", "action": "Execute the exact student code and stated exercise in native Godot.", "expect": c["description"]} for c in checks],
            "native_report": relative(state_dir / "report-runtime.json"),
        }
        save_json(state_dir / "contract.json", contract)
        state_inputs = {**inputs, relative(state_dir / "contract.json"): sha256(state_dir / "contract.json")}
        report = {
            "passed": passed, "learner_source_sha256": sha256(state_dir / "point.gd"),
            "scope": scope, "checks": checks, "inputs": state_inputs, "dependencies": dependencies_before,
            "negative_control": negatives[0 if is_one else 1],
            "engine": str(ENGINE), "engine_version": "4.6.stable", "runs": runs,
            "fixture_status": "The complete printed student script, extracted without edits; variants use only unique declared exercise or negative-control edits.",
            "incoming_sha256": None if is_one else sha256(incoming_path),
            "source_and_test_inputs_unchanged": unchanged,
            "exercise_variants": contract["exercise_variants"],
        }
        save_json(state_dir / "report-runtime.json", report)
        state_reports[state] = {"passed": passed, "check_count": len(checks),
                                "learner_source_sha256": report["learner_source_sha256"],
                                "report": relative(state_dir / "report-runtime.json")}
    report = {
        "passed": passed, "scope": scope, "positive": positive, "negative_controls": negatives,
        "checks": positive["checks"], "states": state_reports, "inputs": inputs,
        "dependencies": dependencies_before, "engine": str(ENGINE), "private_project": str(work),
        "native_copy_sha256": native_before, "runs": runs,
        "source_and_test_inputs_unchanged": unchanged,
        "continuation_composes_exactly": compose(one) == coordinates,
        "exercise_variants": variant_bindings,
    }
    save_json(HERE / "report-runtime.json", report)
    print(f"Private project and logs: {work}", flush=True)
    print(f"Positive assertions: {len(positive['checks'])}; negatives detected: {[x['expected_failure_detected'] for x in negatives]}; passed: {passed}", flush=True)
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
