"""Check the reconstruction in a private copy of the installed XR Tools addon."""
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


def main():
    work = Path(tempfile.mkdtemp(prefix="ada-point-reconstruction-"))
    shutil.copytree(ROOT / "addons/godot-xr-tools", work / "addons/godot-xr-tools")
    project = '''config_version=5
[application]
config/name="Point reconstruction isolated check"
config/features=PackedStringArray("4.6")
[autoload]
XRToolsUserSettings="*res://addons/godot-xr-tools/user_settings/user_settings.gd"
XRToolsRumbleManager="*res://addons/godot-xr-tools/rumble/rumble_manager.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
'''
    (work / "project.godot").write_text(project, encoding="utf-8")
    for name in ("point.gd", "verify.gd"):
        shutil.copy2(HERE / name, work / name)
    source = (HERE / "point.gd").read_text(encoding="utf-8")
    assert source.count("const RADIUS := 0.07") == 1
    (work / "point_radius_variant.gd").write_text(
        source.replace("const RADIUS := 0.07", "const RADIUS := 0.14"), encoding="utf-8")
    flags = subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0
    common = [str(ENGINE), "--headless", "--path", str(work), "--xr-mode", "off", "--audio-driver", "Dummy"]
    runs = []
    for name, arguments in (
        ("import", ["--editor", "--import", "--quit"]),
        ("runtime", ["--script", "res://verify.gd", "--", str(work / "runtime.json")]),
    ):
        try:
            result = subprocess.run(common + arguments, cwd=work, text=True,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                    creationflags=flags, timeout=55, encoding="utf-8", errors="replace")
        except subprocess.TimeoutExpired as error:
            print(f"{name} timed out; private project retained at {work}")
            raise SystemExit(1) from error
        (work / f"{name}.log").write_text(result.stdout, encoding="utf-8")
        runs.append({"stage": name, "exit_code": result.returncode,
                     "script_or_engine_error": "SCRIPT ERROR:" in result.stdout or "ERROR:" in result.stdout})
        print(f"{name}: exit={result.returncode}")
        if result.returncode or runs[-1]["script_or_engine_error"]:
            print(result.stdout[-12000:])
            break
    report_path = work / "runtime.json"
    report = json.loads(report_path.read_text(encoding="utf-8")) if report_path.exists() else {"passed": False, "checks": []}
    report.update({"engine": str(ENGINE), "private_project": str(work), "runs": runs,
                   "learner_source_sha256": hashlib.sha256((work / "point.gd").read_bytes()).hexdigest(),
                   "dependencies": {p.relative_to(work).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                                    for p in (work / "addons/godot-xr-tools").rglob("*")
                                    if p.suffix in (".gd", ".tscn", ".tres", ".gdshader")},
                   "source_runtime_files_modified": False})
    report["passed"] = bool(report["passed"] and len(runs) == 2 and all(
        run["exit_code"] == 0 and not run["script_or_engine_error"] for run in runs))
    (HERE / "report-runtime.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Private project and logs: {work}")
    print(f"Checks: {len(report['checks'])}; passed: {report['passed']}")
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
