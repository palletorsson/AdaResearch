"""Extract and test the printed Lines continuation of the current Coordinates state.

Run this file with Python. It writes only this new evidence directory and a private
temporary Godot project; historical lessons, museum code and addons remain unchanged.
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
CANONICAL = ROOT / "commons/maps/Point_Lines/tutorial.md"
COORDINATES = ROOT / "commons/maps/Point_Coordinates/tutorial.md"
PREDECESSOR = ROOT / "doc/book/iterations/2026-10-05-points-built-and-carried/states/002-point-coordinates/point.gd"
PREDECESSOR_REPORT = PREDECESSOR.with_name("report-runtime.json")
SUPPLIED_HELPER = ROOT / "doc/book/iterations/2026-10-05-lines-relation-and-rule/student/line_skin.gd"
ENGINE = Path(os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"))
EXTENSIONS = {".gd", ".tscn", ".tres", ".gdshader"}
OPERATIONS = [
    {"id": "supplied-renderer", "kind": "insert_after", "anchor": "const CENTRE := Vector3(0, 1.12, 0)\n", "text": '\nconst LineSkin = preload("line_skin.gd")\n'},
    {"id": "relation-state", "kind": "insert_after", "anchor": "var readout: Label3D\n", "text": "var point_b: XRToolsPickable\nvar line: MeshInstance3D\nvar distance := 0.0\n"},
    {"id": "second-end-and-segment", "kind": "insert_after", "anchor": "    add_child(readout)\n", "text": (
        "\n    point_b = point.duplicate() as XRToolsPickable\n"
        "    point_b.position = CENTRE + Vector3(1.0, 0, 0)\n"
        "    add_child(point_b)\n"
        "\n    line = LineSkin.new()\n"
        "    add_child(line)\n")},
    {"id": "live-relation", "kind": "insert_after", "anchor": '    readout.text = "LOCAL " + str(local_position) + "\\nWORLD " + str(world_position)\n', "text": (
        "\n    var a := local_position\n"
        "    var b := to_local(point_b.global_position)\n"
        "    var displacement := b - a\n"
        "    distance = displacement.length()\n"
        "    line.show_segment(a, displacement, distance)\n"
        '    readout.text += "\\nDISTANCE " + str(distance)\n')},
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
        raise ValueError("The actual Coordinates predecessor lacks current native verification")
    if incoming != marked_block(COORDINATES.read_text(encoding="utf-8-sig"), "point.gd"):
        raise ValueError("Current printed Coordinates differs from the tested predecessor")
    code = marked_block(tutorial, "line.gd")
    helper = marked_block(tutorial, "line_skin.gd")
    if helper != SUPPLIED_HELPER.read_text(encoding="utf-8-sig"):
        raise ValueError("The printed supplied renderer differs from the unchanged historical helper")
    assembled = compose(incoming, OPERATIONS)
    if assembled != code:
        raise ValueError("Printed Lines is not exactly current Coordinates plus the declared additions")
    for name, text in {"incoming.gd": incoming, "line.gd": code, "assembled.gd": assembled,
                       "expected.gd": code, "line_skin.gd": helper, "tutorial.md": tutorial}.items():
        write(HERE / name, text)
    save_json(HERE / "next-input.json", {"incoming": {"path": relative(HERE / "line.gd"), "sha256": sha(HERE / "line.gd"),
        "provenance": "Complete printed Lines continuation mechanically composed from the exact verified current Coordinates state."},
        "given_files": [{"path": relative(HERE / "line_skin.gd"), "sha256": sha(HERE / "line_skin.gd")}],
        "carry": "The original held point and readout, a duplicated held endpoint, and one live segment/distance relation. No position history."})
    variants = [
        {"id": "vertical", "kind": "replace", "before": "    point_b.position = CENTRE + Vector3(1.0, 0, 0)\n", "after": "    point_b.position = CENTRE + Vector3(0, 1.0, 0)\n"},
        {"id": "coincident", "kind": "replace", "before": "    point_b.position = CENTRE + Vector3(1.0, 0, 0)\n", "after": "    point_b.position = CENTRE\n"},
        {"id": "reverse_direction", "kind": "replace", "before": "    var displacement := b - a\n", "after": "    var displacement := a - b\n"},
    ]
    plus = marked_block(tutorial, "two-lines-plus")
    table = {}
    for line in tutorial.splitlines():
        if re.match(r"\| (Parallel|Plus|X) \|", line):
            name, *cells = [cell.strip() for cell in line.strip("|").split("|")]
            if len(cells) != 4 or any(not re.fullmatch(r"\(-?[0-9.]+, -?[0-9.]+, -?[0-9.]+\)", cell) for cell in cells):
                raise ValueError("Malformed two-line coordinate table")
            table[name.lower()] = cells
    if set(table) != {"parallel", "plus", "x"}:
        raise ValueError("The three printed two-line arrangements are required")
    if "set the Z component of both C and D to `0.2`" not in tutorial:
        raise ValueError("The depth exercise must explicitly state its 0.2 offset")
    table["x_depth"] = table["x"][:2] + [cell[:-3] + "0.2)" for cell in table["x"][2:]]
    pair_changes = []
    for name, cells in table.items():
        variant_addition = plus
        for prefix, old, new in zip(("    point.position = Vector3", "    point_b.position = Vector3", "    var c := Vector3", "    var d := Vector3"), table["plus"], cells):
            variant_addition = replace_once(variant_addition, prefix + old + "\n", prefix + new + "\n")
        operation = {"id": "two_lines_" + name, "kind": "insert_after", "anchor": "    add_child(line)\n", "text": variant_addition}
        pair_changes.append(operation)
        variants.append(operation)
    bindings = {}
    for operation in variants:
        path = HERE / "variants" / (operation["id"] + ".gd")
        write(path, compose(code, [operation]))
        bindings[relative(path)] = {"sha256": sha(path), "native_filename": path.name, "edit": operation}
    save_json(HERE / "two-lines-changes.json", pair_changes)
    save_json(HERE / "exercise-variants.json", bindings)
    return code, bindings


def main():
    code, variants = prepare()
    source_paths = [CANONICAL, COORDINATES, PREDECESSOR, PREDECESSOR_REPORT, SUPPLIED_HELPER]
    evidence_paths = [HERE / name for name in ("run_checks.py", "verify.gd", "incoming.gd", "line.gd", "assembled.gd", "expected.gd",
                                               "line_skin.gd", "tutorial.md", "next-input.json", "two-lines-changes.json", "exercise-variants.json")]
    evidence_paths += [ROOT / path for path in variants]
    inputs_before = {relative(path): sha(path) for path in source_paths + evidence_paths}
    addon_before = dependencies(ROOT)
    work = Path(tempfile.mkdtemp(prefix="ada-lines-carried-point-"))
    shutil.copytree(ROOT / "addons/godot-xr-tools", work / "addons/godot-xr-tools")
    if dependencies(work) != addon_before:
        raise ValueError("Private XR Tools copy differs from the repository dependency snapshot")
    write(work / "project.godot", '''config_version=5
[application]
config/name="Lines from the actual carried point"
config/features=PackedStringArray("4.6")
[autoload]
XRToolsUserSettings="*res://addons/godot-xr-tools/user_settings/user_settings.gd"
XRToolsRumbleManager="*res://addons/godot-xr-tools/rumble/rumble_manager.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
''')
    for name in ("incoming.gd", "line.gd", "line_skin.gd", "verify.gd"):
        shutil.copy2(HERE / name, work / name)
    for path, binding in variants.items():
        shutil.copy2(ROOT / path, work / binding["native_filename"])
        assert sha(work / binding["native_filename"]) == binding["sha256"]
    write(work / "frozen_segment.gd", replace_once(code, "    line.show_segment(a, displacement, distance)\n",
                                                  "    if not line.visible:\n        line.show_segment(a, displacement, distance)\n"))
    write(work / "mixed_frames.gd", replace_once(code, "    var b := to_local(point_b.global_position)\n",
                                                "    var b := point_b.global_position\n"))
    native_paths = list(work.glob("*.gd")) + [work / "project.godot"]
    native_before = {path.name: sha(path) for path in native_paths}
    assert native_before["line.gd"] == sha(HERE / "line.gd")
    assert native_before["incoming.gd"] == sha(PREDECESSOR)
    assert native_before["line_skin.gd"] == sha(HERE / "line_skin.gd")
    flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
    common = [str(ENGINE), "--headless", "--path", str(work), "--xr-mode", "off", "--audio-driver", "Dummy"]
    stages = [("import", ["--editor", "--import", "--quit"], 0)]
    stages += [(name, ["--script", "res://verify.gd", "--", str(work / (name + ".json")), name], expected)
               for name, expected in (("positive", 0), ("frozen_segment", 1), ("mixed_frames", 1))]
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
    active_cases = ["held_a", "held_a/released", "held_b", "held_b/released", "frame", "vertical_live", "separated_again"]
    wanted = {
        "frozen_segment": [case + "/" + suffix for case in active_cases for suffix in ("segment_endpoints", "mesh_length")] + ["coincident_live/hidden"],
        "mixed_frames": [case + "/" + suffix for case in ["initial"] + active_cases for suffix in ("distance", "segment_endpoints", "mesh_length", "readout")]
                        + ["frame/local_stable", "coincident_live/distance", "coincident_live/hidden", "coincident_live/readout"],
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
    complete = len(ids) == 167 and len(set(ids)) == len(ids)
    passed = bool(positive.get("passed") and complete and all(x["expected_failure_detected"] for x in negatives)
                  and unchanged and len(runs) == len(stages)
                  and all(x["exit_code"] == x["expected_exit_code"] and not x["script_or_engine_error"] for x in runs))
    contract = {
        "mode": "continuation_complete_script", "lesson": relative(HERE / "tutorial.md"),
        "canonical_lesson": relative(CANONICAL), "example": relative(HERE / "line.gd"),
        "host": "The existing unit-scale PointStudy station in the prepared XR project; the printed line_skin.gd helper is supplied.",
        "incoming": {"path": relative(HERE / "incoming.gd"), "sha256": sha(PREDECESSOR),
                     "provenance": "The exact current, printed and verified Coordinates point.gd; itself a continuation of the current student-built Point One."},
        "operations": OPERATIONS,
        "given_files": [{"path": "line_skin.gd", "sha256": sha(HERE / "line_skin.gd"), "role": "Complete printed supplied cylinder renderer, unchanged from its original helper."}],
        "sources": [{"path": relative(path), "sha256": sha(path)} for path in source_paths + [HERE / "tutorial.md", HERE / "line_skin.gd"]],
        "checks": [{"id": c["id"], "kind": "native", "action": "Execute the exact continuation or printed exercise in native Godot.", "expect": c["description"]} for c in positive["checks"]],
        "evidence_inputs": list(inputs_before), "exercise_variants": variants,
        "native_report": relative(HERE / "report-runtime.json"),
        "printed_complete_script_equals_native_input": True, "composed_equals_printed_complete_script": True,
        "coordinate_contract": "Both endpoint positions are converted into the station's local frame; the station may translate and rotate but has unit scale.",
    }
    save_json(HERE / "contract.json", contract)
    report = {
        "passed": passed, "scope": positive.get("scope", "Native execution did not finish."),
        "learner_source_sha256": sha(HERE / "line.gd"), "incoming_sha256": sha(PREDECESSOR),
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
