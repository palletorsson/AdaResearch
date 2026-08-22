"""migrate_rulings_to_maps.py — ONE-TIME: encode the pre-one-truth rulings into the maps.

Under ONE TRUTH, authored halls take no in-hall cell rulings and no artifact
rulings — the map alone authors them. The curator's existing rulings (39 wall
cells, 22 artifact moves, made before map-encoding existed) would silently go
idle. This migrates them INTO the maps, mirroring exactly what the museum's
rebind did at build: walls write structure "2"/"1"; a move finds its token's
nearest occurrence (<= 8 cells from the ruling's from) and moves it to `to`
when the target is free. Migrated rows leave em_overrides; refused rows stay
and are reported. Backups beside every file it touches.

  python tools/migrate_rulings_to_maps.py            # dry run
  python tools/migrate_rulings_to_maps.py --write
"""
from __future__ import annotations

import json
import pathlib
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
OVR = ROOT / "ada_run" / "em_overrides.json"
DECL = ROOT / "commons" / "data" / "map_authored.json"

def main() -> None:
    write = "--write" in sys.argv
    decl = json.loads(DECL.read_text(encoding="utf-8"))
    pearl_to_map: dict[str, str] = {}
    for chapter, maps in decl.items():
        if chapter.startswith("_") or not isinstance(maps, list):
            continue
        for m in maps:
            pearl_to_map[str(m).replace("_", " ").lower()] = str(m)
    ovr = json.loads(OVR.read_text(encoding="utf-8"))
    rows = ovr["overrides"]
    docs: dict[str, dict] = {}
    def map_doc(name: str) -> dict:
        if name not in docs:
            docs[name] = json.loads((ROOT / "commons" / "maps" / name / "map_data.json").read_text(encoding="utf-8"))
        return docs[name]

    keep, walls, moves, refused = [], 0, 0, []
    for o in rows:
        kind = o.get("kind")
        if kind == "cell" and str(o.get("pearl", "")) in pearl_to_map and int(o.get("from", [0, -1])[1]) >= 0:
            name = pearl_to_map[str(o["pearl"])]
            struct = map_doc(name)["layers"]["structure"]
            x, z = int(o["from"][0]), int(o["from"][1])
            if 0 <= z < len(struct) and 0 <= x < len(struct[z]):
                struct[z][x] = "2" if str(o.get("value", "1")) == "4" else "1"
                walls += 1
                print(f"  wall  {name} [{x},{z}] <- {'WALL' if o.get('value') == '4' else 'floor'}")
                continue
            refused.append((o, "off the map"))
            keep.append(o)
            continue
        if kind is None and not o.get("add") and isinstance(o.get("to"), list):
            tok = str(o.get("token", ""))
            fr = [int(v) for v in o.get("from", [0, 0])]
            to = [int(v) for v in o["to"]]
            placed = False
            for pearl, name in pearl_to_map.items():
                inter = map_doc(name)["layers"]["interactables"]
                best, bd = None, 9
                for r, row_ in enumerate(inter):
                    for c, v in enumerate(row_):
                        if str(v).strip().split("#")[0].split(":")[0] == tok:
                            d = abs(c - fr[0]) + abs(r - fr[1])
                            if d < bd:
                                bd, best = d, (c, r)
                if best is None:
                    continue
                tc, tr = to[0], to[1]
                if not (0 <= tr < len(inter) and 0 <= tc < len(inter[tr])):
                    refused.append((o, "target off the map")); break
                if (tc, tr) != best and str(inter[tr][tc]).strip():
                    refused.append((o, "target occupied")); break
                tok_full = inter[best[1]][best[0]]
                inter[best[1]][best[0]] = " "
                inter[tr][tc] = tok_full
                moves += 1
                print(f"  move  {name} {tok}: [{best[0]},{best[1]}] -> [{tc},{tr}]  (ruling from {fr}, d={bd})")
                placed = True
                break
            if placed:
                continue
            if not any(o is r0 for r0, _ in refused):
                refused.append((o, "token not found near the ruling"))
            keep.append(o)
            continue
        keep.append(o)

    print(f"\nmigrated: {walls} wall cell(s), {moves} move(s); kept {len(keep)} row(s); refused {len(refused)}")
    for o, why in refused:
        print(f"  ! {o.get('token', o.get('kind'))} {o.get('from')} -> {why}")
    if not write:
        print("(dry run — --write to encode)")
        return
    for name, doc in docs.items():
        path = ROOT / "commons" / "maps" / name / "map_data.json"
        shutil.copyfile(path, path.with_suffix(".json.premigrate"))
        path.write_text(json.dumps(doc), encoding="utf-8")
        subprocess.run([sys.executable, str(ROOT / "tools" / "compact_map_json.py"), str(path)], cwd=ROOT)
    shutil.copyfile(OVR, OVR.with_suffix(".json.premigrate"))
    ovr["overrides"] = keep
    OVR.write_text(json.dumps(ovr, indent="\t"), encoding="utf-8")
    subprocess.run([sys.executable, str(ROOT / "tools" / "em_ship.py")], cwd=ROOT)
    print("ENCODED — backups: *.premigrate")

if __name__ == "__main__":
    main()
