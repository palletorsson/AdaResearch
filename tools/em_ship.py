#!/usr/bin/env python3
"""Ship the museum's generated files into the export.

    python tools/em_ship.py

Copies ada_run/{em_plan,em_bake,em_control,em_overrides}.json and the compiled
em_cartridges/ directory into commons/data/museum/ — a folder every export carries (ada_run/ is authoring
ground and exports have excluded it; the Quest 3 walked a plan-less v1 museum
for a day because of that). endless_museum.gd reads ada_run first and falls
back to the shipped copy. em_bake.py runs this at the end; the plan editor
runs it after a save. commons/data/museum/ is gitignored — generated.
"""
import json, shutil, sys
from pathlib import Path
REPO = Path(__file__).resolve().parent.parent
SRC = REPO / "ada_run"
DST = REPO / "commons" / "data" / "museum"
# em_layout_walk.json rides along because the museum READS it now, not only
# writes it: a crossing seams itself against the next hall's first row, and the
# record is the only thing that knows what the next hall IS (em_plan.json's row
# order disagrees with the engine's own walk on 9 of 134 crossings). Without it
# on the headset every crossing falls back to the old chicane and the seam is a
# desktop-only feature nobody can see in VR.
FILES = ["em_plan.json", "em_bake.json", "em_control.json", "em_overrides.json",
         "em_layout_walk.json"]
EXTRA = {"trunk_branches.json": REPO / "commons" / "data" / "trunk_branches.json"}   # the pearls + their speak
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
    for name, src in EXTRA.items():
        if src.exists():
            shutil.copyfile(src, DST / name); shipped.append(f"{name} ({src.stat().st_size // 1024} KB)")
    cartridges = SRC / "em_cartridges"
    if cartridges.exists():
        cartridge_dst = DST / "cartridges"
        if cartridge_dst.exists():
            shutil.rmtree(cartridge_dst)
        cartridge_dst.mkdir(parents=True)
        index_src = cartridges / "index.json"
        referenced = {"index.json"}
        entries = {}
        if index_src.exists():
            index_doc = json.loads(index_src.read_text(encoding="utf-8"))
            entries = index_doc.get("entries", {})
            for row in entries.values():
                referenced.add(Path(row.get("scene", "")).name)
                referenced.update(Path(p).name for p in row.get("content", []))
        for name in sorted(referenced):
            src = cartridges / name
            if src.is_file():
                shutil.copyfile(src, cartridge_dst / name)
        scenes = list(cartridge_dst.glob("*.scn"))
        size = sum(p.stat().st_size for p in scenes)
        shipped.append(f"cartridges ({len(entries)} hall(s), {len(scenes)} package(s), {size // 1024} KB)")
    print("EM SHIP: " + ", ".join(shipped) + f" -> {DST.relative_to(REPO)}")
    return 0 if all((SRC / name).exists() for name in FILES) else 1
if __name__ == "__main__":
    sys.exit(main())
