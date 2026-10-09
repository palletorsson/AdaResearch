"""Verify the exact printed Trace continuation and both complete printed exercises.

Run with Python. Only this new evidence directory and an isolated temporary Godot
project are written. Earlier evidence, museum programs and XR Tools stay unchanged.
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
ROOT = HERE.parents[4]
CANONICAL = ROOT / "commons/maps/Point_Trace/tutorial.md"
LINES = ROOT / "commons/maps/Point_Lines/tutorial.md"
PREDECESSOR = HERE.parent / "lines/line.gd"
PREDECESSOR_REPORT = PREDECESSOR.with_name("report-runtime.json")
SUPPLIED_HELPER = PREDECESSOR.with_name("line_skin.gd")
ENGINE = Path(os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"))
EXTENSIONS = {".gd", ".tscn", ".tres", ".gdshader"}
OLD_READY = (
    "    point_b = PointBody.new()\n"
    "    point_b.position = CENTRE + Vector3(1.0, 0, 0)\n"
    "    add_child(point_b)\n\n"
    "    line = LineSkin.new()\n"
    "    add_child(line)\n")
OLD_PROCESS = (
    "    var a := local_position\n"
    "    var b := to_local(point_b.global_position)\n"
    "    var displacement := b - a\n"
    "    distance = displacement.length()\n"
    "    line.show_segment(a, displacement, distance)\n"
    '    readout.text += "\\nDISTANCE " + str(distance)\n')
NEW_PROCESS = (
    "    var last := positions[positions.size() - 1]\n"
    "    if (local_position - last).length() >= MIN_SEGMENT_DISTANCE:\n"
    "        positions.append(local_position)\n\n"
    "        for segment in trail.get_children():\n"
    "            segment.queue_free()\n\n"
    "        for i in range(1, positions.size()):\n"
    "            var a := positions[i - 1]\n"
    "            var displacement := positions[i] - a\n"
    "            var segment := LineSkin.new()\n"
    "            trail.add_child(segment)\n"
    "            segment.show_segment(a, displacement, displacement.length())\n\n"
    '    readout.text += "\\nPOINTS " + str(positions.size())\n')
OPERATIONS = [
    {"id": "sampling-distance", "kind": "insert_after", "anchor": "const CENTRE := Vector3(0, 1.12, 0)\n", "text": "const MIN_SEGMENT_DISTANCE := 0.05\n"},
    {"id": "history-state", "kind": "replace", "before": "var point_b: XRToolsPickable\nvar line: MeshInstance3D\nvar distance := 0.0\n", "after": "var positions: Array[Vector3] = []\nvar trail: Node3D\n"},
    {"id": "seed-instead-of-second-end", "kind": "replace", "before": OLD_READY, "after": "    trail = Node3D.new()\n    add_child(trail)\n    positions.append(point.position)\n"},
    {"id": "retain-and-join-neighbours", "kind": "replace", "before": OLD_PROCESS, "after": NEW_PROCESS},
]
VARIANTS = [
    {"id": "threshold_020", "kind": "replace", "before": "const MIN_SEGMENT_DISTANCE := 0.05\n", "after": "const MIN_SEGMENT_DISTANCE := 0.20\n"},
    {"id": "omit_last_pair", "kind": "replace", "before": "        for i in range(1, positions.size()):\n", "after": "        for i in range(1, positions.size() - 1):\n"},
]


def sha(path):
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


def compose(source, operations):
    for operation in operations:
        if operation["kind"] == "replace":
            source = replace_once(source, operation["before"], operation["after"])
        else:
            source = replace_once(source, operation["anchor"], operation["anchor"] + operation["text"])
    return source


def marked_block(tutorial, name):
    blocks = re.findall(r"<!-- student-code:" + re.escape(name) + r" -->\s*```gdscript\n(.*?)^```", tutorial, re.M | re.S)
    if len(blocks) != 1:
        raise ValueError(f"Expected exactly one marked complete block: {name}")
    return blocks[0]


def dependencies(base):
    return {p.relative_to(base).as_posix(): sha(p) for p in sorted((base / "addons/godot-xr-tools").rglob("*"))
            if p.is_file() and p.suffix in EXTENSIONS}


def prepare():
    tutorial = CANONICAL.read_text(encoding="utf-8-sig")
    incoming = PREDECESSOR.read_text(encoding="utf-8-sig")
    predecessor_report = json.loads(PREDECESSOR_REPORT.read_text(encoding="utf-8"))
    if not predecessor_report.get("passed") or predecessor_report.get("learner_source_sha256") != sha(PREDECESSOR):
        raise ValueError("The actual current Lines predecessor lacks matching native verification")
    if incoming != marked_block(LINES.read_text(encoding="utf-8-sig"), "line.gd"):
        raise ValueError("Current printed Lines differs from its tested predecessor")
    code = marked_block(tutorial, "trace.gd")
    point_body = marked_block(tutorial, "point_body.gd")
    if point_body != PREDECESSOR.with_name("point_body.gd").read_text(encoding="utf-8"):
        raise ValueError("Trace must carry the exact verified Lines PointBody class")
    helper = marked_block(tutorial, "line_skin.gd")
    if helper != SUPPLIED_HELPER.read_text(encoding="utf-8-sig"):
        raise ValueError("Printed helper differs from the unchanged supplied Lines renderer")
    assembled = compose(incoming, OPERATIONS)
    if assembled != code:
        raise ValueError("Printed Trace is not exactly current Lines plus the declared edits")
    if "from `0.05` to `0.20`" not in tutorial or "to `range(1, positions.size() - 1)`" not in tutorial:
        raise ValueError("The two executable variations are not the exact exercises stated in the lesson")
    for name, text in {"incoming.gd": incoming, "trace.gd": code, "assembled.gd": assembled,
                       "expected.gd": code, "point_body.gd": point_body, "line_skin.gd": helper, "tutorial.md": tutorial}.items():
        write(HERE / name, text)
    save_json(HERE / "next-input.json", {"incoming": {"path": relative(HERE / "trace.gd"), "sha256": sha(HERE / "trace.gd"),
        "provenance": "The complete printed Trace program, mechanically composed from the verified current Lines program."},
        "given_files": [{"path": relative(HERE / name), "sha256": sha(HERE / name)} for name in ("point_body.gd", "line_skin.gd")],
        "carry": "One original held point, its live readout, an ordered array of retained station-local positions and neighbouring visual segments. Values last for this station instance; no Grid transfer is implemented."})
    bindings = {}
    for operation in VARIANTS:
        path = HERE / "variants" / (operation["id"] + ".gd")
        write(path, compose(code, [operation]))
        bindings[relative(path)] = {"sha256": sha(path), "native_filename": path.name, "edit": operation}
    save_json(HERE / "exercise-variants.json", bindings)
    return code, bindings


def main():
    code, variants = prepare()
    source_paths = [CANONICAL, LINES, PREDECESSOR, PREDECESSOR_REPORT, SUPPLIED_HELPER, PREDECESSOR.with_name("point_body.gd")]
    evidence_paths = [HERE / name for name in ("run_checks.py", "verify.gd", "incoming.gd", "trace.gd", "assembled.gd", "expected.gd",
                                               "point_body.gd", "line_skin.gd", "tutorial.md", "next-input.json", "exercise-variants.json")]
    evidence_paths += [ROOT / path for path in variants]
    inputs_before = {relative(path): sha(path) for path in source_paths + evidence_paths}
    addon_before = dependencies(ROOT)
    work = Path(tempfile.mkdtemp(prefix="ada-trace-carried-point-"))
    shutil.copytree(ROOT / "addons/godot-xr-tools", work / "addons/godot-xr-tools")
    if dependencies(work) != addon_before:
        raise ValueError("Private XR Tools copy differs from the repository dependency snapshot")
    write(work / "project.godot", '''config_version=5
[application]
config/name="Trace the original carried point"
config/features=PackedStringArray("4.6")
[autoload]
XRToolsUserSettings="*res://addons/godot-xr-tools/user_settings/user_settings.gd"
XRToolsRumbleManager="*res://addons/godot-xr-tools/rumble/rumble_manager.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
''')
    for name in ("incoming.gd", "trace.gd", "point_body.gd", "line_skin.gd", "verify.gd"):
        shutil.copy2(HERE / name, work / name)
    for path, binding in variants.items():
        shutil.copy2(ROOT / path, work / binding["native_filename"])
        assert sha(work / binding["native_filename"]) == binding["sha256"]
    write(work / "gate_removed.gd", replace_once(code, "    if (local_position - last).length() >= MIN_SEGMENT_DISTANCE:\n", "    if true:\n"))
    write(work / "wrong_neighbours.gd", replace_once(code, "            var a := positions[i - 1]\n", "            var a := positions[0]\n"))
    native_paths = list(work.glob("*.gd")) + [work / "project.godot"]
    native_before = {path.name: sha(path) for path in native_paths}
    assert native_before["trace.gd"] == sha(HERE / "trace.gd")
    assert native_before["incoming.gd"] == sha(PREDECESSOR)
    assert native_before["line_skin.gd"] == sha(HERE / "line_skin.gd")
    flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
    common = [str(ENGINE), "--headless", "--path", str(work), "--xr-mode", "off", "--audio-driver", "Dummy"]
    stages = [("import", ["--editor", "--import", "--quit"], 0)]
    stages += [(name, ["--script", "res://verify.gd", "--", str(work / (name + ".json")), name], expected)
               for name, expected in (("positive", 0), ("gate_removed", 1), ("wrong_neighbours", 1))]
    runs = []
    for name, arguments, expected_exit in stages:
        result = subprocess.run(common + arguments, cwd=work, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                creationflags=flags, timeout=55, encoding="utf-8", errors="replace")
        write(work / (name + ".log"), result.stdout)
        write(HERE / "logs" / (name + ".log"), result.stdout)
        engine_error = "SCRIPT ERROR:" in result.stdout or "ERROR:" in result.stdout
        runs.append({"stage": name, "exit_code": result.returncode, "expected_exit_code": expected_exit, "script_or_engine_error": engine_error})
        print(f"{name}: exit={result.returncode} (expected {expected_exit})", flush=True)
        if result.returncode != expected_exit or engine_error:
            print(result.stdout[-12000:], flush=True)
            break
    def result_for(name):
        path = work / (name + ".json")
        return json.loads(path.read_text(encoding="utf-8")) if path.exists() else {"passed": None, "checks": [], "failure_ids": []}
    positive = result_for("positive")
    phases = ["seed", "sample/step_0.02", "sample/step_0.04", "sample/step_0.06", "pause", "route/point_3", "route/point_4", "route/point_5", "released", "resumed", "changed_frame", "new_instance"]
    wanted = {
        "gate_removed": [phase + "/" + suffix for phase in phases for suffix in ("retained_count", "retained_values", "segment_count", "neighbour_endpoints", "readout")]
                        + ["pause/no_growth", "release/history_stays", "resume/keeps_history"],
        "wrong_neighbours": [phase + "/neighbour_endpoints" for phase in ("route/point_3", "route/point_4", "route/point_5", "released", "resumed", "changed_frame")],
    }
    negatives = []
    for name, expected in wanted.items():
        result = result_for(name)
        detected = result.get("passed") is False and set(result.get("failure_ids", [])) == set(expected)
        negatives.append({"name": name, "expected_failure_detected": detected,
                          "expected_failure_ids": sorted(expected), "normal_contract_result": result})
    unchanged = (inputs_before == {relative(path): sha(path) for path in source_paths + evidence_paths}
                 and addon_before == dependencies(ROOT) == dependencies(work)
                 and native_before == {path.name: sha(path) for path in native_paths})
    ids = [entry["id"] for entry in positive["checks"]]
    complete = len(ids) == 124 and len(set(ids)) == len(ids)
    passed = bool(positive.get("passed") and complete and all(x["expected_failure_detected"] for x in negatives)
                  and unchanged and len(runs) == len(stages)
                  and all(x["exit_code"] == x["expected_exit_code"] and not x["script_or_engine_error"] for x in runs))
    contract = {
        "mode": "continuation_complete_script", "lesson": relative(HERE / "tutorial.md"),
        "canonical_lesson": relative(CANONICAL), "example": relative(HERE / "trace.gd"),
        "host": "The existing unit-scale PointStudy station in the prepared XR project; the full printed Lines renderer remains supplied.",
        "incoming": {"path": relative(HERE / "incoming.gd"), "sha256": sha(PREDECESSOR),
                     "provenance": "The exact current, printed and verified Lines state, descended from student-built Point One and Coordinates."},
        "operations": OPERATIONS,
        "given_files": [{"path": "line_skin.gd", "sha256": sha(HERE / "line_skin.gd"), "role": "Complete printed supplied renderer, byte-identical to Lines."},
                        {"path": "point_body.gd", "sha256": sha(HERE / "point_body.gd"), "role": "Learner's PointBody class carried unchanged from Lines; printed in full."}],
        "sources": [{"path": relative(path), "sha256": sha(path)} for path in source_paths + [HERE / "tutorial.md", HERE / "line_skin.gd"]],
        "checks": [{"id": c["id"], "kind": "native", "action": "Execute the exact Trace continuation or printed exercise in native Godot.", "expect": c["description"]} for c in positive["checks"]],
        "evidence_inputs": list(inputs_before), "exercise_variants": variants,
        "native_report": relative(HERE / "report-runtime.json"),
        "printed_complete_script_equals_native_input": True, "composed_equals_printed_complete_script": True,
        "coordinate_contract": "Retained Vector3 values belong to the unit-scale station's local frame. The array lives in the running station only, with no timestamps, saved file or Grid transfer.",
    }
    save_json(HERE / "contract.json", contract)
    report = {
        "passed": passed, "scope": positive.get("scope", "Native execution did not finish."),
        "learner_source_sha256": sha(HERE / "trace.gd"), "incoming_sha256": sha(PREDECESSOR),
        "checks": positive["checks"], "positive": positive,
        "negative_control": negatives[0], "negative_controls": negatives,
        "inputs": {**inputs_before, relative(HERE / "contract.json"): sha(HERE / "contract.json")},
        "dependencies": addon_before, "exercise_variants": variants, "native_copy_sha256": native_before,
        "source_and_test_inputs_unchanged": unchanged, "all_declared_checks_present": complete,
        "continuation_composes_exactly": True, "supplied_helper_unchanged_and_printed": True,
        "runs": runs, "engine": str(ENGINE), "private_project": str(work),
    }
    save_json(HERE / "report-runtime.json", report)
    print(f"Private native project: {work}", flush=True)
    print(f"Passed={passed}; positive checks={len(ids)}; complete={complete}; negative controls={[x['expected_failure_detected'] for x in negatives]}", flush=True)
    for entry in negatives:
        if not entry["expected_failure_detected"]:
            print(f"{entry['name']} failures: {entry['normal_contract_result'].get('failure_ids', [])}", flush=True)
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
