from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
FILES = ["commons/primitives/point/point_held.gd", "commons/primitives/point/point_held.tscn", "commons/primitives/point/point_condition.gd", "commons/primitives/point/interactive_point_origin.gd", "commons/maps/Point_Coordinates/map_data.json", "algorithms/vectors/00_coordinates/CoordinateSystem3M.gd", "commons/primitives/point/coordinate_readout.gd"]
def hashes():
    return {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in FILES}

before = hashes()
run = subprocess.run([sys.executable, str(ROOT / "tools/run_encounter_probe.py"), "Point_Coordinates", "--sequence", "primitives", "--render", "--probe", str(HERE / "probe.gd")], cwd=ROOT)
after = hashes()
destination = HERE / "Point_Coordinates"
destination.mkdir(exist_ok=True)
for name in ["report.json", "source_manifest.json", "engine.log", "stdout.log", "coordinate-podium.png", "coordinate-hall.png"]:
    source = ROOT / "ada_run/encounter_pilot/Point_Coordinates" / name
    if source.is_file():
        shutil.copy2(source, destination / name)
(destination / "dependencies.json").write_text(json.dumps({"before": before, "after": after, "stable_during_run": before == after}, indent=2), encoding="utf-8")
raise SystemExit(run.returncode if before == after else 2)
