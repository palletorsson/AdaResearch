"""furnish_gallery.py — fill an empty champion gallery with a real cast.

The payoff of architecture-first: take an evolved EMPTY gallery (podiums,
vitrines, cabinets, niches waiting) and a CAST of real artifacts, and place
each artifact onto a slot whose footprint fits it — small on plinths, wide on
tables/platforms, flat on walls/vitrines, giants flagged as needing their own
room. Hospitality (signage, infoboards) is kept. Writes a furnished map that
walks.

Footprints are the MEASURED artifact_sizes.json grid_cells (fallback: 1x1).

Usage:
  python tools/furnish_gallery.py --gallery=Gallery_CAP_1 --cast=<a,b,c>
  python tools/furnish_gallery.py --gallery=Gallery_CAP_1 --wings   # the 16
"""
import json
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import staging_beds as sb

WINGS = ["menger_toy", "koch_curve", "cantor_bench", "menger_bench",
         "galton_board", "dice_throw", "coin_toss", "random_number_book_page_1955",
         "newton_cradle", "parametric_pendulum_waves", "mass_spring_bench",
         "exercise_3_15_double_pendulum_vr", "game_of_life_petri", "radiolaria",
         "branching_growth_algorithm", "random_butterflies"]

# slot kind -> capacity class it can host
SLOT_CLASS = {
    "exhibit_podium": "small", "exhibit_vitrine": "wall",
    "plinth_s": "small", "plinth_m": "small", "plinth_l": "medium",
    "hollow_plinth": "small", "dais": "large", "platform": "large",
    "table_2m": "medium", "vitrine_tall": "wall", "cabinet": "wall",
}
CLASS_RANK = {"small": 0, "medium": 1, "large": 2, "wall": 1}
KEEP = ("infoboard", "sign_exit", "sign_fire", "floating_wall")   # hospitality/architecture stays


def footprint(sizes, token):
    e = sizes.get(token)
    if not e:
        return 1.0
    gc = e.get("grid_cells", [1, 1])
    return max(float(gc[0]), float(gc[1]))


def slot_class_of(token):
    if token.startswith("exhibit_furniture#kind:"):
        kind = token.split("kind:")[1].split("#")[0]
        return SLOT_CLASS.get(kind)
    return SLOT_CLASS.get(token.split("#")[0].split(":")[0])


def artifact_class(fp):
    if fp <= 1.2:
        return "small"
    if fp <= 2.5:
        return "medium"
    if fp <= 5.0:
        return "large"
    return "oversize"


def main():
    gallery = None
    cast = None
    for a in sys.argv[1:]:
        if a.startswith("--gallery="):
            gallery = a.split("=", 1)[1]
        elif a.startswith("--cast="):
            cast = [x.strip() for x in a.split("=", 1)[1].split(",") if x.strip()]
        elif a == "--wings":
            cast = WINGS[:]
    if not gallery or not cast:
        print(__doc__)
        sys.exit(1)

    sizes = json.loads((ROOT / "commons/data/artifact_sizes.json").read_text(encoding="utf-8"))["sizes"]
    src = ROOT / "commons/maps" / gallery / "map_data.json"
    d = json.loads(src.read_text(encoding="utf-8"))
    inter = d["layers"]["interactables"]

    # collect the empty slots (skip kept hospitality/architecture)
    slots = []
    for r, row in enumerate(inter):
        for c, cell in enumerate(row):
            tok = str(cell).strip()
            if not tok:
                continue
            if any(k in tok for k in KEEP):
                continue
            cls = slot_class_of(tok)
            if cls:
                slots.append({"r": r, "c": c, "class": cls, "rank": CLASS_RANK[cls]})

    # rank the cast by footprint (biggest first) and slots by capacity
    ranked_cast = sorted(({"tok": t, "fp": footprint(sizes, t),
                           "cls": artifact_class(footprint(sizes, t))} for t in cast),
                         key=lambda x: -x["fp"])
    slots.sort(key=lambda s: -s["rank"])

    placed, oversized, unplaced = [], [], []
    used = [False] * len(slots)
    for a in ranked_cast:
        if a["cls"] == "oversize":
            oversized.append(a)
            continue
        want = CLASS_RANK.get(a["cls"], 0)
        # find the smallest free slot that can still host it (rank >= want)
        best = None
        for i, s in enumerate(slots):
            if used[i] or s["rank"] < want:
                continue
            if best is None or s["rank"] < slots[best]["rank"]:
                best = i
        if best is None:
            unplaced.append(a)
            continue
        used[best] = True
        s = slots[best]
        bed = sb.select_bed(a["tok"])
        # the bed carries the artifact on its surface; wall works face into the room
        rot = ":180" if bed["is_wall"] else ""
        inter[s["r"]][s["c"]] = f"{bed['bed']}{rot}#mount:{a['tok']}"
        placed.append((a["tok"], bed["bed"].split("kind:")[-1].split("#")[0] if "kind:" in bed["bed"] else "podium", a["fp"]))

    # remaining empty slots -> clear back to floor (or leave a podium as apron)
    for i, s in enumerate(slots):
        if not used[i]:
            inter[s["r"]][s["c"]] = " "

    title = f"Furnished_{gallery.replace('Gallery_', '')}"
    d["map_info"]["title"] = title
    d["map_info"]["lookup_name"] = title
    d["map_info"]["name"] = f"Furnished: {gallery}"
    d["map_info"]["description"] = (f"{gallery} furnished with a real cast, matched by measured footprint. "
                                    f"{len(placed)} placed, {len(oversized)} oversized (own room), "
                                    f"{len(unplaced)} unplaced (no fitting slot). Architecture first, collection later.")
    d["map_info"]["furnished_from"] = gallery
    out = ROOT / "commons/maps" / title / "map_data.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(d, indent=1)
    text = re.sub(r'\[\s+((?:"[^"]*",?\s+)+)\]',
                  lambda m: '[' + ', '.join(x.strip().rstrip(',')
                                            for x in m.group(1).split('\n') if x.strip()) + ']', text)
    out.write_text(text, encoding="utf-8")

    print(f"furnished {gallery} -> {title}  ({len(slots)} slots, {len(cast)} cast)")
    print(f"  PLACED {len(placed)}:")
    for tok, cls, fp in placed:
        print(f"    {tok:36s} -> {cls:12s} (fp {fp:.0f})")
    if oversized:
        os_str = ", ".join("%s (%.0f)" % (a["tok"], a["fp"]) for a in oversized)
        print(f"  OVERSIZED (need own room): {os_str}")
    if unplaced:
        print(f"  UNPLACED (no fitting slot free): {', '.join(a['tok'] for a in unplaced)}")


if __name__ == "__main__":
    main()
