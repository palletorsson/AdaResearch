#!/usr/bin/env python3
"""Ship the museum's generated files into the export.

    python tools/em_ship.py

Copies ada_run/{em_plan,em_bake,em_control,em_overrides}.json into
commons/data/museum/ — a folder every export carries (ada_run/ is authoring
ground and exports have excluded it; the Quest 3 walked a plan-less v1 museum
for a day because of that). endless_museum.gd reads ada_run first and falls
back to the shipped copy. em_bake.py runs this at the end; the plan editor
runs it after a save. commons/data/museum/ is gitignored — generated.
"""
import shutil, sys
from pathlib import Path
REPO = Path(__file__).resolve().parent.parent
SRC = REPO / "ada_run"
DST = REPO / "commons" / "data" / "museum"
FILES = ["em_plan.json", "em_bake.json", "em_control.json", "em_overrides.json"]
def main() -> int:
    DST.mkdir(parents=True, exist_ok=True)
    (DST / ".gdignore").unlink(missing_ok=True)   # must NOT be ignored by Godot
    shipped = []
    for f in FILES:
        s = SRC / f
        if s.exists():
            shutil.copyfile(s, DST / f); shipped.append(f"{f} ({s.stat().st_size // 1024} KB)")
        else:
            print(f"  missing: {s}")
    print("EM SHIP: " + ", ".join(shipped) + f" -> {DST.relative_to(REPO)}")
    return 0 if len(shipped) == len(FILES) else 1
if __name__ == "__main__":
    sys.exit(main())
