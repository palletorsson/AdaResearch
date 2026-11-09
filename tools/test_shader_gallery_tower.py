"""The shader galleries in the tower wear their consoles' live shaders. Probe: tools/probes/shader_gallery_tower.gd.
Output: ada_run/shader-gallery-tower/checks.json + shader_galleries.json (screens, wearing, unworn titles per floor)."""
import json, os, subprocess, sys
from pathlib import Path
from void_trial_runtime import stage_runtime
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "ada_run/shader-gallery-tower"
OUT.mkdir(parents=True, exist_ok=True)
for stale in ("checks.json", "shader_galleries.json"): (OUT / stale).unlink(missing_ok=True)
stage = stage_runtime()
with (OUT / "engine.log").open("w", encoding="utf8") as log:
    subprocess.run([sys.executable, str(ROOT / "tools/godot_watchdog.py"), "--expect=" + str(OUT), "--grace=360", "--stall=300", "--",
                    os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"), "--log-file", str(OUT / "godot.log"),
                    "--path", str(stage), "--xr-mode", "off", "--rendering-method", "gl_compatibility", "--resolution", "800x500", "--position", "3200,3200",
                    "--script", "res://tools/probes/shader_gallery_tower.gd", "--", "--no-bridges", "--out=" + OUT.as_posix()],
                   stdout=log, stderr=subprocess.STDOUT, timeout=1500)
text = (OUT / "godot.log").read_text(encoding="utf8", errors="replace") if (OUT / "godot.log").exists() else ""
for line in text.splitlines():
    if line.startswith("[void]") or line.startswith("[shader_gallery_tower]"): print(line)
ok = (OUT / "checks.json").exists() and json.loads((OUT / "checks.json").read_text(encoding="utf8"))["passed"]
if (OUT / "shader_galleries.json").exists(): print(json.dumps(json.loads((OUT / "shader_galleries.json").read_text(encoding="utf8")), indent=1)[:1500])
sys.exit(0 if ok else 1)
