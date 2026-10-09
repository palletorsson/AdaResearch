"""Verify the mechanically composed line state without changing museum code."""
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
import build_state

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
ENGINE = Path(os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"))
SOURCE_FILES = ("commons/maps/Point_Lines/tutorial.md", "commons/primitives/line/line.gd", "commons/artifacts/line_black_box/line_black_box.gd", "commons/primitives/line/puzzles/parallel_line_puzzle.gd", "commons/primitives/line/puzzles/plus_line_puzzle.gd", "commons/primitives/line/puzzles/cross_line_puzzle.gd")
EXTENSIONS = {".gd", ".tscn", ".tres", ".gdshader"}

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def dependencies(base):
    return {p.relative_to(base).as_posix(): sha(p) for p in sorted((base / "addons/godot-xr-tools").rglob("*")) if p.suffix in EXTENSIONS}

def operational_lines(text):
    return "\n".join(line for line in text.splitlines() if line.strip() and not line.lstrip().startswith("#")).strip()

def native_ids():
    result = ["carry/" + suffix for suffix in ("first_point", "radius", "place", "shared_shape", "two_colliders")]
    for prefix in ("initial", "held_a", "held_b", "vertical", "separated_again", "exercise/parallel", "exercise/plus", "exercise/x", "exercise/x_depth"):
        result.extend(prefix + "/" + suffix for suffix in ("distance", "visible", "segment_endpoints", "mesh_length", "basis"))
    result.extend("coincident/" + suffix for suffix in ("distance", "hidden"))
    for prefix in ("held_a", "held_b"):
        result.extend(prefix + "/" + suffix for suffix in ("near_pickup", "held", "moved", "same_surface", "released"))
    for prefix in ("exercise/parallel", "exercise/plus", "exercise/x", "exercise/x_depth"):
        result.extend(prefix + "/" + suffix for suffix in ("relation", "depth"))
    return sorted(result)

def main():
    build_state.main()
    code = (HERE / "assembled.gd").read_text(encoding="utf-8")
    if code != (HERE / "expected.gd").read_text(encoding="utf-8"):
        raise SystemExit("Composition differs from the reviewed frozen expected target; review before accepting a new state.")
    tutorial = (ROOT / SOURCE_FILES[0]).read_text(encoding="utf-8")
    (HERE / "tutorial.md").write_bytes((ROOT / SOURCE_FILES[0]).read_bytes())
    blocks = [operational_lines(block) for block in re.findall(r"~~~gdscript\s*\n(.*?)\n~~~", tutorial, re.S)]
    contract = json.loads((HERE / "contract.json").read_text(encoding="utf-8"))
    for operation in contract["operations"]:
        if operational_lines(operation["text"]) not in blocks:
            raise SystemExit(f"Printed lesson does not contain exact executable operation: {operation['id']}")
    source_before = {name: sha(ROOT / name) for name in SOURCE_FILES}
    predecessor_before = sha(build_state.PREDECESSOR)
    addon_before = dependencies(ROOT)
    work = Path(tempfile.mkdtemp(prefix="ada-lines-student-"))
    shutil.copytree(ROOT / "addons/godot-xr-tools", work / "addons/godot-xr-tools")
    (work / "project.godot").write_text('''config_version=5
[application]
config/name="Lines learner-state isolated verification"
config/features=PackedStringArray("4.6")
[autoload]
XRToolsUserSettings="*res://addons/godot-xr-tools/user_settings/user_settings.gd"
XRToolsRumbleManager="*res://addons/godot-xr-tools/rumble/rumble_manager.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
''', encoding="utf-8")
    for name in ("assembled.gd", "line_skin.gd", "verify.gd"):
        shutil.copy2(HERE / name, work / name)
    needle = "\tline.show_segment(a, displacement, distance)"
    assert code.count(needle) == 1
    (work / "frozen_segment.gd").write_text(code.replace(needle, "\tif not line.visible:\n\t\tline.show_segment(a, displacement, distance)"), encoding="utf-8")
    arrangements = {
        "parallel": [(-.6,1.12,0),(.6,1.12,0),(-.6,1.62,0),(.6,1.62,0)],
        "plus": [(-.6,1.42,0),(.6,1.42,0),(0,.82,0),(0,2.02,0)],
        "x": [(-.6,.82,0),(.6,2.02,0),(-.6,2.02,0),(.6,.82,0)],
        "x_depth": [(-.6,.82,0),(.6,2.02,0),(-.6,2.02,.2),(.6,.82,.2)],
    }
    exercise_changes = []
    for name, (a,b,c,d) in arrangements.items():
        addition = f'''\tpoint_a.position = Vector3{a}
\tpoint_b.position = Vector3{b}
\tvar c := Vector3{c}
\tvar d := Vector3{d}
\tvar other_line := LineSkin.new()
\tother_line.name = "OtherSegment"
\tadd_child(other_line)
\tother_line.show_segment(c, d - c, (d - c).length())
'''
        variant = code.replace("\tadd_child(line)\n", "\tadd_child(line)\n" + addition)
        (work / f"two_lines_{name}.gd").write_text(variant, encoding="utf-8")
        (HERE / f"two_lines_{name}.gd").write_text(variant, encoding="utf-8", newline="\n")
        exercise_changes.append({"id": name, "kind": "insert_after", "anchor": "\tadd_child(line)\n", "text": addition})
    (HERE / "two-lines-changes.json").write_text(json.dumps(exercise_changes, indent=2) + "\n", encoding="utf-8")
    if operational_lines(exercise_changes[1]["text"]) not in blocks:
        raise SystemExit("Printed plus exercise differs from executable example.")
    test_files = ["incoming.gd", "assembled.gd", "expected.gd", "line_skin.gd", "verify.gd", "run_checks.py", "build_state.py", "contract.json", "brief.json", "two-lines-changes.json", "tutorial.md"] + [f"two_lines_{n}.gd" for n in arrangements]
    relative = HERE.relative_to(ROOT).as_posix()
    contract.update({
        "mode":"continuation", "lesson":SOURCE_FILES[0], "example":relative + "/assembled.gd",
        "host":"Unit-scale Node3D student station in the prepared museum; existing XR hand. Native check uses an isolated unchanged XR Tools copy and synthetic controller.",
        "incoming":{"path":relative + "/incoming.gd", "sha256":predecessor_before, "provenance":"Exact saved historical Coordinates state, whose original Point One input was an explicit assumed reconstruction."},
        "sources":[{"path":name,"sha256":value} for name,value in source_before.items()],
        "checks":[{"id":identifier,"kind":"native"} for identifier in native_ids()],
        "evidence_inputs":[relative + "/" + name for name in test_files],
        "native_report":relative + "/report-runtime.json",
        "expected_target_status":"expected.gd is a reviewed frozen composition target, not an independent implementation or proof of learner comprehension. Native checks and the deliberate failing mutation provide behavioral evidence."
    })
    (HERE / "contract.json").write_text(json.dumps(contract,indent=2)+"\n",encoding="utf-8")
    test_before = {name: sha(HERE / name) for name in test_files}
    flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
    common = [str(ENGINE), "--headless", "--path", str(work), "--xr-mode", "off", "--audio-driver", "Dummy"]
    stages = [("import", ["--editor", "--import", "--quit"], 0), ("positive", ["--script", "res://verify.gd", "--", str(work / "positive.json"), "positive"], 0), ("frozen_segment", ["--script", "res://verify.gd", "--", str(work / "frozen_segment.json"), "frozen_segment"], 1)]
    runs = []
    for name, args, wanted in stages:
        result = subprocess.run(common + args, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, cwd=work, timeout=55, creationflags=flags, encoding="utf-8", errors="replace")
        (HERE / f"{name}.log").write_text(result.stdout, encoding="utf-8")
        bad = "SCRIPT ERROR:" in result.stdout or "ERROR:" in result.stdout
        runs.append({"stage": name, "exit_code": result.returncode, "expected_exit_code": wanted, "script_or_engine_error": bad})
        print(f"{name}: exit {result.returncode}, wanted {wanted}")
        if result.returncode != wanted or bad:
            print(result.stdout[-7000:])
            break
    positive = json.loads((work / "positive.json").read_text()) if (work / "positive.json").exists() else {"passed":False,"checks":[]}
    negative = json.loads((work / "frozen_segment.json").read_text()) if (work / "frozen_segment.json").exists() else {"passed":None,"checks":[],"failure_ids":[]}
    expected_failures = sorted(["coincident/hidden"] + [prefix + "/" + suffix for prefix in ("held_a", "held_b", "vertical", "separated_again") for suffix in ("segment_endpoints", "mesh_length")])
    detected = negative.get("passed") is False and expected_failures == sorted(negative.get("failure_ids", []))
    unchanged = source_before == {name:sha(ROOT / name) for name in SOURCE_FILES} and addon_before == dependencies(ROOT) == dependencies(work) and predecessor_before == sha(build_state.PREDECESSOR)
    stable_tests = test_before == {name:sha(HERE / name) for name in test_files}
    complete = sorted(item["id"] for item in positive["checks"]) == native_ids()
    report = {"passed": bool(positive["passed"] and detected and unchanged and stable_tests and complete and len(runs)==3 and all(run["exit_code"]==run["expected_exit_code"] and not run["script_or_engine_error"] for run in runs)), "scope": positive.get("scope"), "learner_source_sha256": sha(HERE / "assembled.gd"), "incoming_sha256": predecessor_before, "checks": positive["checks"], "positive": positive, "negative_control": {"expected_failure_detected": detected, "expected_failure_ids":expected_failures, "normal_contract_result":negative}, "source_sha256": source_before, "dependencies":addon_before,"test_sha256":test_before,"inputs":{**source_before,**{relative + "/" + name:value for name,value in test_before.items()}},"source_and_addon_files_unchanged":unchanged,"test_inputs_unchanged_during_execution":stable_tests,"printed_operations_match":True,"all_declared_checks_present":complete,"runs":runs,"private_project":str(work)}
    (HERE / "report-runtime.json").write_text(json.dumps(report, indent=2)+"\n",encoding="utf-8")
    (HERE / "next-input.json").write_text(json.dumps({"incoming":{"path":relative + "/assembled.gd","sha256":sha(HERE / "assembled.gd"),"provenance":"Mechanically assembled, source-bound Lines continuation; 70 native checks and a failing frozen-segment control. Original Point One state remains assumed."},"carry":"Two held endpoint bodies and one live relation between their positions. No trace history is retained.","evidence":relative + "/report-runtime.json"},indent=2)+"\n",encoding="utf-8")
    print(f"passed={report['passed']} positive={len(positive['checks'])} negative_detected={detected} work={work}")
    return 0 if report["passed"] else 1

if __name__ == "__main__":
    raise SystemExit(main())
