"""Capture current production Flow_Field through the isolated museum helper."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import sys
import time

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[3]
phase = sys.argv[1] if len(sys.argv) > 1 else "before"
if phase not in ("before", "after"):
    raise SystemExit("phase must be before or after")
OUT = BASE / phase
OUT.mkdir(parents=True, exist_ok=True)
SOURCES = [
    "commons/maps/Flow_Field/map_data.json",
    "commons/artifacts/flow_field_painter/flow_field_painter.gd",
    "commons/artifacts/flow_field_painter/shared_field_lesson.gd",
    "commons/artifacts/flow_field_painter/flow_field_painter.tscn",
    "commons/scenes/endless_museum.gd",
    "commons/scenes/em/em_detail.gd",
    "ada_run/em_plan.json",
]
if phase == "after":
    SOURCES.append("commons/artifacts/flow_field_painter/wall_monitor.gd")
def hashes():
    return {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in SOURCES}

before = hashes()
for name in SOURCES:
    target = OUT / "source" / name
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / name, target)
spec = {"phase": phase, "output": "res://" + OUT.relative_to(ROOT).as_posix() + "/"}
spec_path = OUT / "spec.json"
spec_path.write_text(json.dumps(spec, indent=2), encoding="utf-8")
(OUT / "source-manifest.json").write_text(json.dumps(before, indent=2), encoding="utf-8")
command = [sys.executable, "-X", "utf8", str(ROOT / "tools/run_encounter_probe.py"),
           "Flow_Field", "--sequence", "change", "--render", "--spec", str(spec_path),
           "--probe", str(BASE / "probe.gd")]
startup = subprocess.STARTUPINFO()
startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
startup.wShowWindow = subprocess.SW_HIDE
start = time.time()
with (OUT / "runner.log").open("w", encoding="utf-8") as log:
    result = subprocess.run(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                            startupinfo=startup, creationflags=subprocess.CREATE_NO_WINDOW,
                            timeout=190)
runtime = ROOT / "ada_run/encounter_pilot/Flow_Field"
for name in ["engine.log", "stdout.log", "source_manifest.json", "report.json"]:
    if (runtime / name).exists():
        shutil.copy2(runtime / name, OUT / ("museum-" + name))
after = hashes()
record = {"phase": phase, "command": command, "returncode": result.returncode,
          "seconds": time.time() - start, "source_sha256_before": before,
          "source_sha256_after": after, "sources_unchanged_during_run": before == after,
          "scope": "Current real Endless Museum hall; no historical replay. Hidden rendered desktop run; no headset or learner trial."}
(OUT / "run.json").write_text(json.dumps(record, indent=2), encoding="utf-8")
if phase == "after" and (BASE / "before/particles.json").exists() and (OUT / "particles.json").exists():
    old_particles = (BASE / "before/particles.json").read_bytes()
    new_particles = (OUT / "particles.json").read_bytes()
    parity = {"same_seeded_particle_record": old_particles == new_particles,
              "before_sha256": hashlib.sha256(old_particles).hexdigest(),
              "after_sha256": hashlib.sha256(new_particles).hexdigest(),
              "scope": "Identical local simulation state after 120 prescribed 1/60-second steps; museum poses differ."}
    (OUT / "particle-parity.json").write_text(json.dumps(parity, indent=2), encoding="utf-8")
    print(json.dumps(parity))
print(json.dumps(record, indent=2))
print((OUT / "runner.log").read_text(encoding="utf-8", errors="replace")[-2500:])
raise SystemExit(result.returncode if before == after else 2)
