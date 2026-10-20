"""Open the seed pilot in an isolated copy of the real museum. No live hall edits."""
from pathlib import Path
import argparse
import importlib.util
import json
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--prepare-only", action="store_true")
    args = parser.parse_args()
    # Reuse the maintained snapshot builder, without launching a test run.
    spec = importlib.util.spec_from_file_location("encounter_builder", ROOT / "tools/run_encounter_probe.py")
    builder = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(builder)
    sys.argv = [str(ROOT / "tools/run_encounter_probe.py"), "Random_Definition", "--sequence", "randomness",
        "--render", "--no-bridges", "--prepare-only", "--probe", str(HERE / "runtime/visit.gd"), "--output-tag", "seed-bench-001-visit"]
    builder.main()
    command = json.loads((ROOT / "ada_run/encounter_pilot/Random_Definition/seed-bench-001-visit/command.json").read_text())
    if args.prepare_only:
        return
    command.remove("--no-window")
    log_path = ROOT / "ada_run/encounter_pilot/Random_Definition/seed-bench-001-visit/visit.log"
    with log_path.open("w", encoding="utf-8") as log:
        process = subprocess.Popen(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
            creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
    print(f"Opened museum pilot (process {process.pid}). Five views shown together; F1 reset 42; F2 current views; F3 keep; F5 export; F4 replay.")
    print("Export is in Godot's user data folder as seed-bench-001.json. Close the window when finished.")


if __name__ == "__main__":
    main()
