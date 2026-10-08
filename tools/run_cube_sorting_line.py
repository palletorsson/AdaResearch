"""Run the cube sorter regression in Godot; optionally render scene evidence.

The regression is a normal scene so project XR autoloads initialize in their
normal order. Evidence follows the shared encyclopedia captures root.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

from evidence_root import evidence_dir

ROOT = Path(__file__).resolve().parents[1]


def isolated_project() -> Path:
    """Reuse assets/cache while keeping autoload writes out of the live museum.

    The checkout's default audio-bus UID is stale on some machines. The isolated
    project uses the same bus by path, without editing the user's project file.
    Retain the tiny launcher checkout for investigating failed native runs.
    """
    work = Path(tempfile.mkdtemp(prefix="ada-cube-sorter-"))
    exclude = {"ada_run", "node_modules", "doc", "tools", "output", "outputs"}
    commands = []
    for source in ROOT.iterdir():
        if not source.is_dir() or source.name.startswith(".") or source.name in exclude:
            continue
        target = work / source.name
        if os.name == "nt":
            quote = lambda path: "'" + str(path).replace("'", "''") + "'"
            commands.append(f"New-Item -ItemType Junction -Path {quote(target)} -Target {quote(source)} | Out-Null")
        else:
            target.symlink_to(source, target_is_directory=True)
    cache = work / ".godot"
    cache.mkdir()
    for name in ("global_script_class_cache.cfg", "uid_cache.bin"):
        if (ROOT / ".godot" / name).exists():
            shutil.copy2(ROOT / ".godot" / name, cache / name)
    imported = ROOT / ".godot/imported"
    if imported.is_dir():
        if os.name == "nt":
            commands.append(f"New-Item -ItemType Junction -Path {quote(cache / 'imported')} -Target {quote(imported)} | Out-Null")
        else:
            (cache / "imported").symlink_to(imported, target_is_directory=True)
    if commands:
        subprocess.run(["powershell", "-NoProfile", "-Command", "\n".join(commands)], check=True,
                       creationflags=subprocess.CREATE_NO_WINDOW)
    (work / "ada_run").mkdir()
    for name in ("icon.png", "default_bus_layout.tres"):
        if (ROOT / name).exists():
            shutil.copy2(ROOT / name, work / name)
    project = (ROOT / "project.godot").read_text(encoding="utf-8-sig")
    project = project.replace('buses/default_bus_layout="uid://rwex60pqapc"',
                              'buses/default_bus_layout="res://default_bus_layout.tres"')
    project = project.replace('config/name="Ada Research Zero One"', f'config/name="{work.name}"')
    (work / "project.godot").write_text(project, encoding="utf-8")
    return work


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--capture", action="store_true", help="Also render three native scene screenshots.")
    parser.add_argument("--timeout", type=int, default=120)
    args = parser.parse_args()
    folder = evidence_dir("cube-sorter-2026-10-05")
    stem = "capture" if args.capture else "regression"
    report_path = folder / f"{stem}.json"
    if report_path.exists():
        report_path.unlink()
    engine = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
    work = isolated_project()
    command = [engine, "--path", str(work), "--xr-mode", "off", "--audio-driver", "Dummy",
               "--fixed-fps", "60", "--log-file", str(folder / f"{stem}-engine.log")]
    if args.capture:
        command += ["--rendering-method", "gl_compatibility", "--position", "-10000,-10000",
                    "--resolution", "1440x960"]
    else:
        command += ["--headless"]
    command += ["res://tests/test_cube_sorting_line.tscn"]
    env = dict(os.environ)
    env["ADA_CUBE_SORTER_REPORT"] = str(report_path)
    env["ADA_CUBE_SORTER_CAPTURE"] = str(folder) if args.capture else ""
    log_path = folder / f"{stem}-stdout.log"
    with log_path.open("w", encoding="utf-8") as log:
        process = subprocess.Popen(command, cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT,
                                   creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        try:
            result = process.wait(timeout=args.timeout)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            result = 124
    output = log_path.read_text(encoding="utf-8", errors="replace")
    failures = [line for line in output.splitlines()
                if line.startswith(("FAIL:", "CUBE SORTER:", "SCRIPT ERROR:", "ERROR:"))]
    print("\n".join(failures))
    if not report_path.is_file():
        print(f"No completed report; exit={result}; log={log_path}")
        return result or 1
    report = json.loads(report_path.read_text(encoding="utf-8"))
    errors = [line for line in output.splitlines() if "SCRIPT ERROR:" in line or line.startswith("ERROR:")]
    report["native_errors"] = errors
    report["isolated_project"] = str(work)
    report["engine_exit"] = result
    report["passed"] = bool(report.get("passed")) and not errors and result == 0
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Cube sorter: {'PASS' if report['passed'] else 'FAIL'}; {len(report['checks'])} checks; {report_path}")
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
