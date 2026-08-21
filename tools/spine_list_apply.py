"""THE SPINE LIST'S PEN (2026-08-21, Palle: "a list of ALL artifacts,
duplicates too, in the artifact order of the grid system spine sequence —
a simple editable list").

Applies /spine-list edits back into the maps: for each change
{map, x, z, was, token} the interactables cell at (x, z) has its NAME part
replaced, keeping the cell's ``:rot:y_offset`` tail exactly as authored.
A ``#suffix`` (artifact-bound config like a mounted lab json) is kept when
the name is unchanged and DROPPED when the name changes — config written
for one artifact must not ride a different one. An empty token clears the
cell. A cell whose current name is not ``was`` is refused by name — the
map moved since the list was read, and a stale list must not write.

Files are rewritten in the compact-rows format (tools/compact_map_json),
never json.dumps — one reformatted map once cost 15,121 lines.

  python tools/spine_list_apply.py --changes <changes.json>
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
from compact_map_json import compact_map  # noqa: E402


def main() -> int:
    if "--changes" not in sys.argv:
        print("usage: spine_list_apply.py --changes <changes.json>")
        return 2
    changes = json.load(open(sys.argv[sys.argv.index("--changes") + 1], encoding="utf-8"))
    by_map: dict[str, list] = {}
    for c in changes:
        by_map.setdefault(str(c.get("map", "")), []).append(c)
    applied = 0
    refused: list[str] = []
    for map_name, cs in sorted(by_map.items()):
        p = ROOT / "commons" / "maps" / map_name / "map_data.json"
        if not p.exists():
            refused.append(f"{map_name}: no map_data.json")
            continue
        d = json.load(open(p, encoding="utf-8"))
        inter = d.get("layers", {}).get("interactables")
        if not isinstance(inter, list):
            refused.append(f"{map_name}: no interactables layer")
            continue
        touched = False
        for c in cs:
            x, z = int(c.get("x", -1)), int(c.get("z", -1))
            if not (0 <= z < len(inter)) or not (0 <= x < len(inter[z])):
                refused.append(f"{map_name} ({x},{z}): outside the grid")
                continue
            raw = str(inter[z][x])
            head = raw.split(":")[0]          # name (+ any #suffix), before rot:y
            colon_tail = raw[len(head):]      # ':rot:y' or ''
            old_name = head.split("#")[0].strip()
            was = str(c.get("was", "")).strip()
            if c.get("add"):
                # a NEW placement: only an empty cell may receive it
                new_name = str(c.get("token", "")).strip()
                if not new_name:
                    refused.append(f"{map_name} ({x},{z}): add with no name")
                    continue
                if old_name:
                    refused.append(f"{map_name} ({x},{z}): the cell holds '{old_name}' — adds land on empty floor only")
                    continue
                inter[z][x] = new_name
                touched = True
                applied += 1
                continue
            if old_name != was:
                refused.append(f"{map_name} ({x},{z}): holds '{old_name}', the list expected '{was}' — re-open the list")
                continue
            new_name = str(c.get("token", "")).strip()
            if new_name == old_name:
                continue
            if not new_name:
                inter[z][x] = " "             # cleared — the cell goes back to floor
            else:
                inter[z][x] = new_name + colon_tail
            touched = True
            applied += 1
        if touched:
            with open(p, "w", encoding="utf-8", newline="\n") as f:
                json.dump(d, f)               # plain write, so compact_map can re-read it
            compacted = compact_map(p)        # BEFORE the truncating reopen, or it reads nothing
            with open(p, "w", encoding="utf-8", newline="\n") as f:
                f.write(compacted)
    print(f"SPINE LIST: {applied} cell(s) written across {len(by_map)} map(s); {len(refused)} refused")
    for r in refused:
        print("  - " + r)
    return 0 if not refused else 1


if __name__ == "__main__":
    sys.exit(main())
