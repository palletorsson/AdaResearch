"""Run scoped real-museum evidence; never edits the live museum's output files.

python doc/book/iterations/2026-10-05-museum-three-points-and-future/run_probe.py Point_One --render
python doc/book/iterations/2026-10-05-museum-three-points-and-future/run_probe.py Point_Lines --render
"""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("room", choices=["Point_One", "Point_Lines", "Point_Coordinates"])
    parser.add_argument("--render", action="store_true")
    args = parser.parse_args()
    dependencies = [ROOT / "commons/scenes/endless_museum.gd",
                    ROOT / "commons/scenes/em/em_detail.gd",
                    ROOT / "commons/scenes/em/em_identity.gd",
                    ROOT / "commons/primitives/point/point_condition.gd",
                    ROOT / "commons/primitives/point/point_sun_switch.gd",
                    ROOT / f"commons/maps/{args.room}/map_data.json",
                    HERE / "probe.gd", Path(__file__).resolve()]
    dependencies += list((ROOT / "commons/font").rglob("*Cormorant*"))
    def fingerprint():
        return {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                for p in dependencies if p.is_file()}
    before = fingerprint()
    command = [sys.executable, str(ROOT / "tools/run_encounter_probe.py"), args.room,
               "--sequence", "primitives", "--probe", str(HERE / "probe.gd")]
    if args.render:
        command.append("--render")
    started = time.time()
    completed = subprocess.run(command, cwd=ROOT, check=False)
    run = ROOT / "ada_run/encounter_pilot" / args.room
    destination = HERE / args.room
    destination.mkdir(exist_ok=True)
    after = fingerprint()
    (destination / "probe-dependencies.json").write_text(json.dumps({
        "before": before, "after": after, "stable_during_run": before == after,
        "scope": "Real museum dependencies read before and after the run; no headset validation."
    }, indent=2), encoding="utf-8")
    for name in ["report.json", "source_manifest.json", "engine.log", "stdout.log",
                 "museum-lettering.png", "three-podiums.png", "future-sphere.png"]:
        source = run / name
        if source.is_file() and source.stat().st_mtime >= started and (args.render or source.suffix != ".png"):
            shutil.copy2(source, destination / name)
    report_file = run / "report.json"
    if report_file.is_file() and report_file.stat().st_mtime >= started:
        report = json.loads(report_file.read_text(encoding="utf-8"))
        print(f"{args.room}: {len(report.get('checks', []))} checks; passed={report.get('passed')}")
    else:
        (destination / "runner-failure.json").write_text(json.dumps({"exit_code": completed.returncode,
            "scope": "No fresh runtime report was produced. Earlier evidence in this folder does not apply to this run."}), encoding="utf-8")
    print(destination)
    return completed.returncode if before == after else 2


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    raise SystemExit(main())
