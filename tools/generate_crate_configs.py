#!/usr/bin/env python3
"""Crates & boxes auto-research generator.

Mirrors tools/generate_installation_configs.py: for each family it generates
candidate DNA configs for crate.gd / cardboard_box.gd, scores them, keeps the
best, and writes them (+ a GalleryView manifest) into the encyclopedia gallery
so they render + rate alongside the other auto-research galleries.

Outputs to  ada_encyclopedia/public/crates-boxes-gallery/ :
  <id>.json          one entry  {id,name,description,family,score,scene,dna}
  manifest.json      {version,description,entries:[{id,image,config,notes}]}
  _render_list.txt   "<id>\\t<scene>" lines for the capture loop
"""
from __future__ import annotations
import json, math, random, os, sys

GAL = r"C:\Users\palle\Documents\GitHub\ada_encyclopedia\public\crates-boxes-gallery"
CRATE = "res://commons/artifacts/crate/crate.tscn"
BOX = "res://commons/artifacts/cardboard_box/cardboard_box.tscn"
TECH = "res://commons/artifacts/tech_crate/tech_crate.tscn"

WOOD = {
    "raw pine": ("0.62,0.50,0.34", "0.68,0.55,0.38", "0.30,0.24,0.16"),
    "weathered grey": ("0.50,0.46,0.40", "0.55,0.50,0.43", "0.22,0.20,0.18"),
    "dark walnut": ("0.30,0.22,0.16", "0.34,0.26,0.18", "0.12,0.09,0.07"),
}
WHITE = ("0.86,0.86,0.83", "0.90,0.90,0.87", "0.55,0.55,0.53")
ASPECTS = {
    "cube": (0.72, 0.72, 0.68), "flat": (1.0, 0.72, 0.5),
    "tall": (0.54, 0.54, 0.92), "long": (1.12, 0.62, 0.6),
}
STAMPS = ["ADA-LAB", "FRAGILE", "THIS WAY UP", "STOCK", "HANDLE WITH CARE", "BIO-HAZ"]
KRAFT = ["0.76,0.64,0.45", "0.72,0.60,0.42", "0.80,0.69,0.50"]


def j(v):
    return round(v, 3)


def crate_dna(rng, palette, aspect, planks, brace, stamp, bands, tape):
    pc, pca, sc = palette
    w, d, h = ASPECTS[aspect]
    w *= rng.uniform(0.92, 1.12); d *= rng.uniform(0.92, 1.12); h *= rng.uniform(0.92, 1.12)
    dna = {
        "crate_width": j(w), "crate_depth": j(d), "crate_height": j(h),
        "plank_count": planks, "show_x_brace": brace, "show_stamp": stamp,
        "stamp_label": rng.choice(STAMPS), "plank_color": pc,
        "plank_color_alt": pca, "strip_color": sc,
    }
    if bands:
        dna["band_count"] = rng.choice([2, 3])
    if tape:
        dna["hazard_tape"] = True
    return dna


def fam_wooden(rng):
    wn = rng.choice(list(WOOD))
    return crate_dna(rng, WOOD[wn], rng.choice(list(ASPECTS)), rng.randint(4, 6),
                     rng.random() < 0.6, True, 0, False), "%s crate" % wn.capitalize(), \
        "Plank-clad wooden shipping crate, %s tone, corner battens%s and a stencilled stamp." % (
            wn, ", an X-brace" if True else "")


def fam_white(rng):
    return crate_dna(rng, WHITE, rng.choice(list(ASPECTS)), rng.randint(4, 6),
                     rng.random() < 0.55, True, 0, False), "White shipping crate", \
        "White-painted plank crate (Half-Life-Alyx vocabulary) with battens and a stamp."


def fam_banded(rng):
    wn = rng.choice(list(WOOD))
    return crate_dna(rng, WOOD[wn], rng.choice(["cube", "long", "flat"]), rng.randint(4, 6),
                     False, rng.random() < 0.5, rng.choice([2, 3]), False), "Banded crate (%s)" % wn, \
        "Reinforced crate strapped with dark batten bands instead of an X-brace."


def fam_taped(rng):
    pal = WHITE if rng.random() < 0.4 else WOOD[rng.choice(list(WOOD))]
    return crate_dna(rng, pal, rng.choice(list(ASPECTS)), rng.randint(4, 6),
                     rng.random() < 0.5, rng.random() < 0.6, 0, True), "Hazard-taped crate", \
        "Crate marked with a diagonal red/white hazard-tape stripe across the front."


def fam_box(rng):
    w = j(rng.uniform(0.34, 0.5)); h = j(rng.uniform(0.28, 0.4)); d = j(rng.uniform(0.34, 0.5))
    flap = j(rng.choice([0.0, 0.0, rng.uniform(60, 100)]))
    col = rng.choice(KRAFT)
    dna = {"box_width": w, "box_height": h, "box_depth": d, "flap_open_deg": flap,
           "show_flaps": True, "box_color": col, "interior_color": "0.62,0.52,0.36"}
    state = "sealed" if flap < 5 else "open"
    return dna, "Cardboard box (%s)" % state, \
        "Kraft cardboard box, flaps %s — the crate's lighter disposable cousin." % state, BOX


TECH_PAL = {
    "graphite": ("0.13,0.14,0.16", "0.09,0.10,0.12", "0.10,0.11,0.13"),
    "gunmetal": ("0.17,0.18,0.21", "0.11,0.12,0.14", "0.13,0.14,0.17"),
    "military tan": ("0.45,0.40,0.30", "0.38,0.34,0.26", "0.42,0.37,0.28"),
    "olive drab": ("0.30,0.33,0.24", "0.24,0.27,0.19", "0.27,0.30,0.22"),
}
TECH_ACCENT = {"orange": "0.95,0.50,0.10", "green": "0.30,0.90,0.40",
               "cyan": "0.30,0.80,0.95", "amber": "0.95,0.72,0.12"}
VENTS = ["x", "fan", "louver"]


def _tech(rng, palname, accname):
    body, panel, lid = TECH_PAL[palname]
    vent = rng.choice(VENTS)
    dna = {
        "crate_width": j(rng.uniform(0.95, 1.3)), "crate_height": j(rng.uniform(0.46, 0.6)),
        "crate_depth": j(rng.uniform(0.52, 0.72)), "bevel": j(rng.uniform(0.05, 0.09)),
        "panel_count": rng.choice([1, 2, 2]), "vent_style": vent,
        "body_color": body, "panel_color": panel, "lid_color": lid,
        "accent_color": TECH_ACCENT[accname], "show_leds": True, "show_handles": rng.random() < 0.85,
        "use_shader": True,
    }
    name = "%s tech crate (%s-vent)" % (palname.capitalize(), vent)
    desc = ("High-tech %s cargo container — beveled armored body, recessed paneling, a recessed "
            "%s vent, %s LED accents and corner latches.") % (palname, vent, accname)
    return dna, name, desc


def fam_tech_dark(rng):
    return _tech(rng, rng.choice(["graphite", "gunmetal"]), rng.choice(["orange", "green", "cyan", "amber"]))


def fam_tech_tan(rng):
    return _tech(rng, rng.choice(["military tan", "olive drab"]), rng.choice(["green", "orange", "amber"]))


FAMILIES = {
    "wooden_crate": (fam_wooden, CRATE), "white_crate": (fam_white, CRATE),
    "banded_crate": (fam_banded, CRATE), "taped_crate": (fam_taped, CRATE),
    "cardboard_box": (fam_box, BOX),
    "tech_dark": (fam_tech_dark, TECH), "tech_tan": (fam_tech_tan, TECH),
}


def score(dna, family):
    s = 100.0
    if "plank_count" in dna:
        s += (4 <= dna["plank_count"] <= 6) * 4.0
        w, h = dna["crate_width"], dna["crate_height"]
        s -= abs((h / max(w, 0.2)) - 0.9) * 6.0   # prefer plausible-ish aspect
        s += dna.get("band_count", 0) * 1.5
        s += 3.0 if dna.get("hazard_tape") else 0.0
        s += 2.0 if dna.get("show_x_brace") else 0.0
    else:
        s += 2.0  # boxes
    return s


def main():
    os.makedirs(GAL, exist_ok=True)
    rng = random.Random(70713)
    entries = []
    render = []
    for fam, (builder, default_scene) in FAMILIES.items():
        cands = []
        for _ in range(8):
            out = builder(rng)
            dna, name, desc = out[0], out[1], out[2]
            scene = out[3] if len(out) > 3 else default_scene
            cands.append((score(dna, fam), dna, name, desc, scene))
        cands.sort(key=lambda c: c[0], reverse=True)
        for rank, (sc, dna, name, desc, scene) in enumerate(cands[:3], 1):
            cid = "crate_%s_%05x" % (fam, rng.randint(0, 1 << 20))
            entry = {"id": cid, "name": name, "description": desc, "family": fam,
                     "score": round(sc, 2), "selection_rank": rank, "scene": scene, "dna": dna}
            json.dump(entry, open(os.path.join(GAL, cid + ".json"), "w", encoding="utf-8"),
                      indent=2, ensure_ascii=False)
            notes = "%s — %s" % (name, desc)
            entries.append({"id": cid, "image": "/crates-boxes-gallery/%s.png" % cid,
                            "config": "/crates-boxes-gallery/%s.json" % cid, "notes": notes})
            render.append("%s\t%s" % (cid, scene))

    json.dump({"version": 1,
               "description": "Crates & boxes auto-research — scored DNA variants of crate.gd / cardboard_box.gd.",
               "entries": entries},
              open(os.path.join(GAL, "manifest.json"), "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    open(os.path.join(GAL, "_render_list.txt"), "w", encoding="utf-8").write("\n".join(render) + "\n")
    if not os.path.exists(os.path.join(GAL, "evals.json")):
        json.dump({}, open(os.path.join(GAL, "evals.json"), "w", encoding="utf-8"))
    print("wrote %d entries across %d families -> %s" % (len(entries), len(FAMILIES), GAL))
    for e in entries:
        print("  ", e["id"], "|", e["notes"][:64])


if __name__ == "__main__":
    sys.exit(main())
