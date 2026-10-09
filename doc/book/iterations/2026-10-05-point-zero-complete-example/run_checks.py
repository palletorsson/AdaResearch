"""Run the Point Zero tutorial listing and its printed edit in a minimal Godot project."""

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
TUTORIAL = ROOT / "commons/maps/Point_Zero/tutorial.md"
PROJECT = '[application]\nconfig/name="Point Zero exact tutorial tests"\n\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def extract(source, name):
    marker = f"<!-- student-code:{name} -->"
    if source.count(marker) != 1:
        raise ValueError(f"Expected exactly one {marker} in {TUTORIAL}")
    match = re.search(re.escape(marker) + r"\s*```gdscript\r?\n(.*?)^```", source, re.M | re.S)
    if not match:
        raise ValueError(f"Missing complete gdscript block after {marker}")
    return match.group(1).encode("utf-8")


def apply_printed_edit(source, repeated):
    start = "<!-- student-edit:read-once -->"
    end = "<!-- /student-edit:read-once -->"
    instruction = 'Move `label.text = str(Engine.get_process_frames())` into `_ready()`, immediately after `add_child(label)`. Delete the now-empty `_process()` function. Keep everything else.'
    if source.count(start) != 1 or source.count(end) != 1:
        raise ValueError("Expected one marked read-once edit in the tutorial")
    match = re.search(re.escape(start) + r"\s*(.*?)\s*" + re.escape(end), source, re.S)
    if not match or match.group(1) != instruction:
        raise ValueError("Printed read-once instruction changed; update the explicit transformation before testing")
    newline = b"\r\n" if b"\r\n" in repeated else b"\n"
    assignment = b"    label.text = str(Engine.get_process_frames())" + newline
    parent = b"    add_child(label)" + newline
    ready = b"func _ready() -> void:" + newline
    process = newline + b"func _process(_delta: float) -> void:" + newline + assignment
    for anchor in (assignment, parent, ready, process):
        if repeated.count(anchor) != 1:
            raise ValueError(f"Printed edit needs a unique source anchor: {anchor!r}")
    if not repeated.endswith(process) or not repeated.index(ready) < repeated.index(parent) < repeated.index(process):
        raise ValueError("Expected the single assignment in _process and add_child in _ready")
    once = repeated.removesuffix(process).replace(parent, parent + assignment, 1)
    evidence = {
        "marker": "student-edit:read-once",
        "instruction": instruction,
        "instruction_sha256": digest(instruction.encode("utf-8")),
        "base_script": "counter.gd",
        "base_sha256": digest(repeated),
        "operation": "Move the unique assignment after the unique add_child(label) in _ready; remove the empty _process function. No other code changes.",
        "result_sha256": digest(once),
    }
    return once, evidence


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
    args = parser.parse_args()
    source_bytes = TUTORIAL.read_bytes()
    source = source_bytes.decode("utf-8")
    repeated = extract(source, "counter.gd")
    once, edit_evidence = apply_printed_edit(source, repeated)
    scripts = {"counter.gd": repeated, "counter_once.gd": once}
    for name, data in scripts.items():
        (HERE / name).write_bytes(data)
    (HERE / "tutorial.source.md").write_bytes(source_bytes)
    verifier = (HERE / "verify.gd").read_bytes()
    mutations = {
        "counter_missing_label.gd": repeated.replace(b"    label = Label3D.new()\n", b""),
        "counter_missing_parent.gd": repeated.replace(b"    add_child(label)\n", b""),
    }
    for name, data in mutations.items():
        if data == repeated:
            raise ValueError(f"Negative mutation did not change the source: {name}")
        (HERE / name).write_bytes(data)
    all_scripts = scripts | mutations
    version = subprocess.run([args.godot, "--version"], capture_output=True, text=True, timeout=20, check=True).stdout.strip()
    report = {
        "started_utc": datetime.now(timezone.utc).isoformat(),
        "godot_executable": str(Path(args.godot).resolve()),
        "godot_version": version,
        "source": {"path": str(TUTORIAL.relative_to(ROOT)), "sha256": digest(source_bytes)},
        "scripts": {name: {"sha256": digest(data), "origin": "verbatim marked tutorial block" if name == "counter.gd" else "mechanical application of the marked printed read-once edit to counter.gd" if name == "counter_once.gd" else "single-line omission from counter.gd"} for name, data in all_scripts.items()},
        "printed_edit": edit_evidence,
        "verifier_sha256": digest(verifier),
        "runner_sha256": digest(Path(__file__).read_bytes()),
        "project_godot_sha256": digest(PROJECT.encode()),
        "isolation": "Temporary minimal Godot project; only the tutorial listing, its declared printed edit, single-line omissions, and verify.gd. No museum code, autoloads, or XR.",
        "cases": [],
    }
    cases = [
        ("repeated", "counter.gd", "repeated", None),
        ("once", "counter_once.gd", "once", None),
        ("missing_label", "counter_missing_label.gd", "repeated", "ready creates Label3D"),
        ("missing_parent", "counter_missing_parent.gd", "repeated", "ready parents Label3D"),
    ]
    with tempfile.TemporaryDirectory(prefix="point-zero-tutorial-") as temporary:
        project = Path(temporary)
        (project / "project.godot").write_text(PROJECT, encoding="utf-8")
        (project / "verify.gd").write_bytes(verifier)
        for name, data in all_scripts.items():
            (project / name).write_bytes(data)
        for name, filename, mode, expected_failure in cases:
            command = [args.godot, "--headless", "--path", str(project), "--script", "res://verify.gd", "--", filename, mode]
            run = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=30)
            log = run.stdout + run.stderr
            (HERE / f"{name}.log").write_text(log, encoding="utf-8")
            assertions = [json.loads(line.removeprefix("ASSERT ")) for line in run.stdout.splitlines() if line.startswith("ASSERT ")]
            results = [json.loads(line.removeprefix("RESULT ")) for line in run.stdout.splitlines() if line.startswith("RESULT ")]
            failures = [item["name"] for item in assertions if not item["passed"]]
            if expected_failure:
                success = run.returncode != 0 and failures == [expected_failure] and not results and f"Assertion failed: {expected_failure}" in log
            else:
                success = run.returncode == 0 and not failures and len(results) == 1 and results[0].get("completed") is True and results[0]["passed"] == len(assertions) and "SCRIPT ERROR" not in log and "ERROR:" not in log
            case = {"name": name, "script": filename, "expected_failure": expected_failure, "exit_code": run.returncode, "success": success, "assertions_passed": sum(item["passed"] for item in assertions), "assertions_failed": len(failures), "assertions": assertions, "result": results, "log": f"{name}.log", "command": command}
            report["cases"].append(case)
            print(f"{name}: {'PASS' if success else 'FAIL'} ({case['assertions_passed']} passed assertions, {len(failures)} failed, exit {run.returncode})")
    report["success"] = all(case["success"] for case in report["cases"])
    report["positive_assertions_passed"] = sum(case["assertions_passed"] for case in report["cases"] if case["expected_failure"] is None)
    report["negative_cases_rejected"] = sum(case["success"] for case in report["cases"] if case["expected_failure"] is not None)
    (HERE / "report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Report: {HERE / 'report.json'}")
    return 0 if report["success"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
