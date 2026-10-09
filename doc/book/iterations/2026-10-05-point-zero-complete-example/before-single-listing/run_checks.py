"""Run the complete, marked Point Zero tutorial scripts in a minimal Godot project."""

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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
    args = parser.parse_args()
    source_bytes = TUTORIAL.read_bytes()
    source = source_bytes.decode("utf-8")
    scripts = {name: extract(source, name) for name in ("counter.gd", "counter_once.gd")}
    for name, data in scripts.items():
        (HERE / name).write_bytes(data)
    (HERE / "tutorial.source.md").write_bytes(source_bytes)
    verifier = (HERE / "verify.gd").read_bytes()
    repeated = scripts["counter.gd"]
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
        "scripts": {name: {"sha256": digest(data), "origin": "verbatim marked tutorial block" if name in scripts else "single-line omission from counter.gd"} for name, data in all_scripts.items()},
        "verifier_sha256": digest(verifier),
        "runner_sha256": digest(Path(__file__).read_bytes()),
        "project_godot_sha256": digest(PROJECT.encode()),
        "isolation": "Temporary minimal Godot project; only tutorial scripts, declared single-line omissions, and verify.gd. No museum code, autoloads, or XR.",
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
