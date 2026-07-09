"""curate_gallery.py — the loop closed: brief -> evolved room -> furnished argument.

#12 of the backlog. One command turns a curatorial brief + a taste + a cast
into a walkable exhibition:

  1. EVOLVE a champion gallery for the chosen taste (capacity/drama/intimacy),
     picking the champion whose slot count best fits the cast.
  2. FURNISH it: match each artifact to a slot its measured footprint fits
     (small->plinths, wide->table/platform, flat->wall/vitrine); giants get
     flagged for their own room; hospitality (signage/infoboards) kept.
  3. RECORD the decision: curation.json travels with the map — brief, taste,
     the champion genome, every footprint match, the oversized and unplaced,
     the sieve pass. The argument is legible after the fact.

This is Work Package 3 in one call: architecture, then collection, both
auto-generated, both measured, the human ruling on top.

Usage:
  python tools/curate_gallery.py --id=randomness_edge --taste=intimacy \\
      --brief="From a fair coin to the incompressible" \\
      --cast=coin_toss,dice_throw,galton_board,shannon_entropy_meter,entropy_jar,dark_sphere
"""
import json
import random
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import gallery_evolve as ge
import furnish_gallery as fg

SEED = 461


def main():
    ex_id = taste = brief = None
    cast = []
    for a in sys.argv[1:]:
        if a.startswith("--id="):
            ex_id = a.split("=", 1)[1]
        elif a.startswith("--taste="):
            taste = a.split("=", 1)[1]
        elif a.startswith("--brief="):
            brief = a.split("=", 1)[1]
        elif a.startswith("--cast="):
            cast = [x.strip() for x in a.split("=", 1)[1].split(",") if x.strip()]
    if not (ex_id and taste and brief and cast):
        print(__doc__)
        sys.exit(1)
    if taste not in ("capacity", "drama", "intimacy"):
        print("taste must be capacity | drama | intimacy")
        sys.exit(1)

    sizes = json.loads((ROOT / "commons/data/artifact_sizes.json").read_text(encoding="utf-8"))["sizes"]

    # ── 1. evolve a champion for the taste; pick the best-fitting by slots ───
    print(f"evolving a {taste} room for {len(cast)} works...")
    champs, history = ge.evolve(taste, random.Random(SEED))
    # champs = [(fitness, genome, measure)]; want enough slots, else the biggest
    need = len(cast)
    fitting = [c for c in champs if c[2]["slots"] >= need]
    chosen = min(fitting, key=lambda c: c[2]["slots"]) if fitting \
        else max(champs, key=lambda c: c[2]["slots"])
    fit, genome, measure = chosen
    print(f"  champion: {genome['form']}/{genome['podium_motif']}/{genome['light']} "
          f"({measure['slots']} slots, reach {measure['reach_frac']}, order {measure.get('order_score')})")

    title = f"Curated_{''.join(w.capitalize() for w in ex_id.split('_'))}"
    data, slots = ge.compile_gallery(genome, title.replace("Curated_", ""))
    inter = data["layers"]["interactables"]

    # ── 2. furnish: footprint-matched placement onto the empty slots ─────────
    empty = []
    for r, row in enumerate(inter):
        for c, cell in enumerate(row):
            tok = str(cell).strip()
            if not tok or any(k in tok for k in fg.KEEP):
                continue
            cls = fg.slot_class_of(tok)
            if cls:
                empty.append({"r": r, "c": c, "class": cls, "rank": fg.CLASS_RANK[cls]})
    ranked = sorted(({"tok": t, "fp": fg.footprint(sizes, t),
                      "cls": fg.artifact_class(fg.footprint(sizes, t))} for t in cast),
                    key=lambda x: -x["fp"])
    empty.sort(key=lambda s: -s["rank"])
    used = [False] * len(empty)
    placed, oversized, unplaced = [], [], []
    for a in ranked:
        if a["cls"] == "oversize":
            oversized.append(a)
            continue
        want = fg.CLASS_RANK.get(a["cls"], 0)
        best = None
        for i, s in enumerate(empty):
            if used[i] or s["rank"] < want:
                continue
            if best is None or s["rank"] < empty[best]["rank"]:
                best = i
        if best is None:
            unplaced.append(a)
            continue
        used[best] = True
        s = empty[best]
        inter[s["r"]][s["c"]] = a["tok"]
        placed.append({"artifact": a["tok"], "slot": s["class"], "fp": round(a["fp"], 1)})
    for i, s in enumerate(empty):
        if not used[i]:
            inter[s["r"]][s["c"]] = " "

    # ── 3. write the map + the decision record ──────────────────────────────
    data["map_info"]["title"] = title
    data["map_info"]["lookup_name"] = title
    data["map_info"]["name"] = f"Curated: {brief}"
    data["map_info"]["description"] = (f"{brief} — a {taste} room evolved to fit the cast, then furnished by "
                                       f"footprint. {len(placed)} placed, {len(oversized)} oversized (own room), "
                                       f"{len(unplaced)} unplaced. Curator loop closed.")
    data["map_info"]["curation"] = f"doc/exhibitions/{ex_id}/curation.json"
    out = ROOT / "commons/maps" / title / "map_data.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(data, indent=1)
    text = re.sub(r'\[\s+((?:"[^"]*",?\s+)+)\]',
                  lambda m: '[' + ', '.join(x.strip().rstrip(',')
                                            for x in m.group(1).split('\n') if x.strip()) + ']', text)
    out.write_text(text, encoding="utf-8")

    record = {
        "generated_by": "tools/curate_gallery.py", "id": ex_id, "brief": brief,
        "taste": taste, "map": title,
        "champion": {"genome": genome, "fitness": round(fit, 2),
                     "measure": {k: measure[k] for k in
                                 ("slots", "reach_frac", "approach_frac", "detour", "order_score")}},
        "placed": placed, "oversized": [a["tok"] for a in oversized],
        "unplaced": [a["tok"] for a in unplaced],
        "learning_curve": [h["best"] for h in history],
        "sieve": {
            "thickens": "the collection gets a room whose walk was measured, not guessed",
            "forecloses": "one taste chosen; the other two rooms this cast could have lived in are foregone",
            "dark_spot": "the oversized works (own room) and the unplaced (no fitting slot) — what the "
                         "footprints could not seat here",
        },
    }
    rec_path = ROOT / "doc/exhibitions" / ex_id / "curation.json"
    rec_path.parent.mkdir(parents=True, exist_ok=True)
    rec_path.write_text(json.dumps(record, indent=1), encoding="utf-8")

    print(f"\ncurated -> {title}")
    print(f"  PLACED {len(placed)}:")
    for p in placed:
        print(f"    {p['artifact']:34s} -> {p['slot']:10s} (fp {p['fp']})")
    if oversized:
        print(f"  OVERSIZED (own room): {', '.join(a['tok'] for a in oversized)}")
    if unplaced:
        print(f"  UNPLACED: {', '.join(a['tok'] for a in unplaced)}")
    print(f"  decision record -> {rec_path}")


if __name__ == "__main__":
    main()
