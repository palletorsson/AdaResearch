"""Verify the mechanically composed lesson delta in a private Godot/XR Tools copy.

The caller generates assembled.gd from incoming.gd and the displayed operations.
This runner never substitutes expected.gd for that test input.
"""
from pathlib import Path
import hashlib
import json
import os
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
ENGINE = Path(os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"))
SOURCE_FILES = ("commons/maps/Point_One/tutorial.md", "commons/primitives/point/point_condition.gd")
CHECKER_FILES = ("doc/book/course/functional_text/reconstruction.py",)
DEPENDENCY_EXTENSIONS = {".gd", ".tscn", ".tres", ".gdshader"}


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_hashes():
    return {name: sha256(ROOT / name) for name in SOURCE_FILES}


def dependency_hashes(base):
    return {p.relative_to(base).as_posix(): sha256(p)
            for p in sorted((base / "addons/godot-xr-tools").rglob("*"))
            if p.suffix in DEPENDENCY_EXTENSIONS}


def main():
    assembled_path = HERE / "assembled.gd"
    if not assembled_path.exists():
        raise SystemExit("Run the contract composer first: assembled.gd is the required native input.")
    assembled = assembled_path.read_text(encoding="utf-8")
    expected = (HERE / "expected.gd").read_text(encoding="utf-8")
    if assembled != expected:
        raise SystemExit("Composed delta differs from independently authored expected.gd.")
    incoming = (HERE / "incoming.gd").read_text(encoding="utf-8")
    test_files = ("incoming.gd", "expected.gd", "assembled.gd", "verify.gd", "run_checks.py", "contract.json", "tutorial.md")
    test_before = {name: sha256(HERE / name) for name in test_files}
    checker_before = {name: sha256(ROOT / name) for name in CHECKER_FILES}
    work = Path(tempfile.mkdtemp(prefix="ada-lesson-state-chain-"))
    source_before = source_hashes()
    dependencies_before = dependency_hashes(ROOT)
    shutil.copytree(ROOT / "addons/godot-xr-tools", work / "addons/godot-xr-tools")
    copied_dependencies_before = dependency_hashes(work)
    if copied_dependencies_before != dependencies_before:
        raise SystemExit("Private XR Tools copy differs from the repository dependency snapshot")
    project = '''config_version=5
[application]
config/name="Point One to Coordinates isolated delta check"
config/features=PackedStringArray("4.6")
[autoload]
XRToolsUserSettings="*res://addons/godot-xr-tools/user_settings/user_settings.gd"
XRToolsRumbleManager="*res://addons/godot-xr-tools/rumble/rumble_manager.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
'''
    (work / "project.godot").write_text(project, encoding="utf-8")
    # expected.gd is deliberately not copied into the runnable Godot project.
    for name in ("incoming.gd", "assembled.gd", "verify.gd"):
        shutil.copy2(HERE / name, work / name)
    for name, source in (("incoming", incoming), ("assembled", assembled)):
        if source.count("const RADIUS := 0.14") != 1:
            raise SystemExit(f"{name} radius anchor must occur exactly once")
        (work / f"{name}_radius_variant.gd").write_text(
            source.replace("const RADIUS := 0.14", "const RADIUS := 0.3"), encoding="utf-8")
    reparent = "\tbody.reparent(solid)\n"
    if assembled.count(reparent) != 1:
        raise SystemExit("The composed lesson must contain exactly one mesh reparent operation")
    (work / "assembled_missing_reparent.gd").write_text(assembled.replace(reparent, ""), encoding="utf-8")
    native_files = ("incoming.gd", "assembled.gd", "verify.gd", "incoming_radius_variant.gd", "assembled_radius_variant.gd", "assembled_missing_reparent.gd")
    native_before = {name: sha256(work / name) for name in native_files}
    if native_before["assembled.gd"] != test_before["assembled.gd"]:
        raise SystemExit("Native assembled input differs from the captured composition")
    flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
    common = [str(ENGINE), "--headless", "--path", str(work), "--xr-mode", "off", "--audio-driver", "Dummy"]
    runs = []
    stages = (
        ("import", ["--editor", "--import", "--quit"], 0),
        ("positive", ["--script", "res://verify.gd", "--", str(work / "positive.json"), "positive"], 0),
        ("missing_reparent", ["--script", "res://verify.gd", "--", str(work / "missing_reparent.json"), "missing_reparent"], 1),
    )
    for name, arguments, expected_exit in stages:
        try:
            result = subprocess.run(common + arguments, cwd=work, text=True,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                    creationflags=flags, timeout=55, encoding="utf-8", errors="replace")
        except subprocess.TimeoutExpired as error:
            print(f"{name} timed out; private project retained at {work}")
            raise SystemExit(1) from error
        (work / f"{name}.log").write_text(result.stdout, encoding="utf-8")
        engine_error = "SCRIPT ERROR:" in result.stdout or "ERROR:" in result.stdout
        runs.append({"stage": name, "exit_code": result.returncode,
                     "expected_exit_code": expected_exit, "script_or_engine_error": engine_error})
        print(f"{name}: exit={result.returncode} (expected {expected_exit})")
        if result.returncode != expected_exit or engine_error:
            print(result.stdout[-12000:])
            break
    positive_path = work / "positive.json"
    negative_path = work / "missing_reparent.json"
    positive = json.loads(positive_path.read_text(encoding="utf-8")) if positive_path.exists() else {"passed": False, "checks": []}
    negative = json.loads(negative_path.read_text(encoding="utf-8")) if negative_path.exists() else {"passed": None, "checks": []}
    wanted_failure_ids = {
        "missing_reparent/outgoing/mesh_parent",
        "missing_reparent/outgoing/held_mesh_follows",
        "missing_reparent/outgoing/held_alignment",
        "missing_reparent/outgoing/released_alignment",
    }
    observed_failures = set(negative.get("failure_ids", []))
    motion = negative.get("observations", [{}])[0]
    negative_detected = (negative.get("passed") is False and observed_failures == wanted_failure_ids
                         and motion.get("body_moved") is True and motion.get("collider_moved") is True
                         and motion.get("visible_mesh_moved") is False and motion.get("visible_mesh_stayed") is True)
    source_after = source_hashes()
    dependencies_after = dependency_hashes(ROOT)
    copied_dependencies_after = dependency_hashes(work)
    unchanged = source_before == source_after and dependencies_before == dependencies_after
    test_after = {name: sha256(HERE / name) for name in test_files}
    checker_after = {name: sha256(ROOT / name) for name in CHECKER_FILES}
    native_after = {name: sha256(work / name) for name in native_files}
    test_unchanged = (test_before == test_after and checker_before == checker_after
                      and native_before == native_after and copied_dependencies_before == copied_dependencies_after)
    report = {
        "passed": bool(positive.get("passed") and negative_detected and unchanged and test_unchanged and len(runs) == 3
                       and all(run["exit_code"] == run["expected_exit_code"] and not run["script_or_engine_error"] for run in runs)),
        "fixture_status": "Source-bound assumed incoming state ASSEMBLED from Point One excerpts and the small solid branch of point_condition.gd; not an actual learner portfolio, standalone replacement lesson, or modified museum runtime.",
        "native_input": "assembled.gd, generated mechanically by the contract composer; expected.gd only checked for text equality and not loaded by Godot.",
        "scope": positive.get("scope", "Native checks did not finish."),
        "checks": positive["checks"],
        "learner_source_sha256": native_before["assembled.gd"],
        "inputs": {**source_before, **checker_before,
                   **{(HERE / name).relative_to(ROOT).as_posix(): digest for name, digest in test_before.items()}},
        "engine": str(ENGINE),
        "private_project": str(work),
        "runs": runs,
        "composed_equals_independent_expected": assembled == expected,
        "source_sha256": source_before,
        "test_sha256": test_before,
        "native_copy_sha256": native_before,
        "dependencies": copied_dependencies_before,
        "source_and_addon_files_unchanged": unchanged,
        "test_inputs_unchanged_during_execution": test_unchanged,
        "source_runtime_files_modified": not unchanged,
        "positive": positive,
        "negative_control": {"expected_failure_detected": negative_detected,
                             "expected_failure_ids": sorted(wanted_failure_ids),
                             "normal_contract_result": negative},
    }
    (HERE / "report-runtime.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Private project and logs: {work}")
    print(f"Positive checks: {len(positive['checks'])}; missing-reparent failure detected: {negative_detected}; passed: {report['passed']}")
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
