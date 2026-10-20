"""Check native noise-map placement and the true 3D Voronoi strand geometry."""
from pathlib import Path
import argparse
import os
import shutil
import subprocess
import sys
from evidence_root import evidence_dir

ROOT = Path(__file__).resolve().parents[1]


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture", action="store_true")
    args = parser.parse_args()
    out = evidence_dir("cellular-spaces-2026-10-13")
    isolated = out / "strands-project"
    sources = Path("commons/context/cellular_spaces")
    (isolated / sources).mkdir(parents=True, exist_ok=True)
    for file in (ROOT / sources).iterdir():
        if file.suffix in {".gd", ".tscn", ".gdshader"}:
            shutil.copy2(file, isolated / sources / file.name)
    (isolated / "tools/probes").mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / "tools/probes/voronoi_strands_test.gd", isolated / "tools/probes/voronoi_strands_test.gd")
    shutil.copy2(ROOT / "tools/probes/strand_dynamics_checks.gd", isolated / "tools/probes/strand_dynamics_checks.gd")
    (isolated / "project.godot").write_text('''config_version=5
[application]
config/name="Voronoi strands preview"
run/main_scene="res://commons/context/cellular_spaces/voronoi_strands_preview.tscn"
[display]
window/size/viewport_width=1280
window/size/viewport_height=900
[rendering]
renderer/rendering_method="gl_compatibility"
anti_aliasing/quality/msaa_3d=2
''', encoding="utf-8")
    for name, project in [("voronoi_strands", isolated), ("cellular_noise_maps", ROOT)]:
        engine = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
        command = [engine, "--path", str(project), "--xr-mode", "off", "--audio-driver", "Dummy", "--log-file", str(out / (name + "-engine.log"))]
        command += ["--rendering-method", "gl_compatibility", "--resolution", "1280x900"] if args.capture else ["--headless"]
        command += ["--script", "res://tools/probes/" + name + "_test.gd", "--", str(out)]
        with (out / (name + "-stdout.log")).open("w", encoding="utf-8") as log:
            result = subprocess.run(command, cwd=project, stdout=log, stderr=subprocess.STDOUT, timeout=110,
                                    creationflags=subprocess.CREATE_NO_WINDOW if sys.platform == "win32" else 0)
        text = (out / (name + "-engine.log")).read_text(encoding="utf-8")
        errors = [line for line in text.splitlines() if "SCRIPT ERROR" in line or "Parse Error" in line
                  or (name == "voronoi_strands" and line.startswith("ERROR:"))]
        print("\n".join(line for line in text.splitlines() if "VORONOI_STRANDS:" in line or "CELLULAR_MAPS:" in line))
        if result.returncode or errors:
            print(text[-8000:])
            raise SystemExit(1)
    print("Evidence:", out)


if __name__ == "__main__":
    main()
