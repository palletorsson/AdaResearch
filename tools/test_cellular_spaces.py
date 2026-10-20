"""Validate the exact cellular-space sources in an isolated Godot project."""
from pathlib import Path
import argparse
import json
import os
import shutil
import subprocess
import sys
from evidence_root import evidence_dir

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture", action="store_true")
    args = parser.parse_args()
    output = evidence_dir("cellular-spaces-2026-10-13")
    project = output / "check-project"
    sources = Path("commons/context/cellular_spaces")
    (project / sources).mkdir(parents=True, exist_ok=True)
    for source in (ROOT / sources).iterdir():
        if source.suffix in {".gd", ".tscn", ".gdshader"}:
            shutil.copy2(source, project / sources / source.name)
    for relative in ["commons/context/walkgrids/TopologyManager.gd", "tools/probes/cellular_spaces_test.gd"]:
        target = project / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / relative, target)
    (project / "project.godot").write_text('''config_version=5
[application]
config/name="Cellular interior verification"
run/main_scene="res://commons/context/cellular_spaces/cellular_spaces_preview.tscn"
[display]
window/size/viewport_width=1280
window/size/viewport_height=800
[rendering]
renderer/rendering_method="gl_compatibility"
environment/defaults/default_clear_color=Color(0.06,0.04,0.08,1)
''', encoding="utf-8")
    registry = json.loads((ROOT / "commons/artifacts/registry/cellular_noise_rooms.json").read_text(encoding="utf-8"))
    for entry in registry["artifacts"].values():
        assert (ROOT / entry["scene"].removeprefix("res://")).is_file()
    engine = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
    command = [engine, "--path", str(project), "--xr-mode", "off", "--audio-driver", "Dummy", "--log-file", str(output / "engine.log")]
    if not args.capture:
        command.append("--headless")
    else:
        command += ["--rendering-method", "gl_compatibility", "--position", "80,80"]
    command += ["--script", "res://tools/probes/cellular_spaces_test.gd", "--", str(output)]
    if args.capture:
        command.append("--capture")
    with (output / "stdout.log").open("w", encoding="utf-8") as log:
        run = subprocess.run(command, cwd=project, stdout=log, stderr=subprocess.STDOUT, timeout=180,
                             creationflags=subprocess.CREATE_NO_WINDOW if sys.platform == "win32" else 0)
    log = (output / "engine.log").read_text(encoding="utf-8")
    errors = [line for line in log.splitlines() if "SCRIPT ERROR" in line or "Parse Error" in line or "Shader compilation failed" in line]
    if run.returncode or errors:
        print(log[-14000:])
        raise SystemExit(1)
    result = json.loads((output / "checks.json").read_text(encoding="utf-8"))
    print(json.dumps({"passed": result["passed"], "checks": len(result["checks"]), "observations": result["observations"], "output": str(output)}, indent=2))
    if not result["passed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
