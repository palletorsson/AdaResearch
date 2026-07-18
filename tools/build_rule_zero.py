"""build_rule_zero.py — rule zero: the roster is the chapter's first ruling.

For every spine sequence, assemble the CURRENT map roster (from the sequence
JSON, in file order) and a SUGGESTED roster (slot-grammar assignment), with
every value carrying its provenance (P-9/P-10: ruled > measured > register >
ghost > heuristic — heuristics propose, never bind). Nothing is invented:
slots come from position defaults, look-script registers where they exist,
and conversation ghosts marked as ghosts; heroes come from rulings, dig
load-bearing winners, the heroes register, or cast defaults — each marked.

Output: ada_encyclopedia/public/rule_zero.json for the /rule-zero page.

  python tools/build_rule_zero.py
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPS_DIR = os.path.join(ROOT, "commons", "maps")
OUT = os.path.normpath(os.path.join(
    ROOT, "..", "ada_encyclopedia", "public", "rule_zero.json"))

SLOT_GRAMMAR = ["threshold", "primitive", "walk", "turn", "critical", "world", "close", "seed"]

# Ruled souls (verbatim rulings; the census is blind to these by definition)
RULED_SOULS = {
    "transformation": {"map": "Trans_Pit", "hero": "becoming_catalyst", "ruling": "R-030"},
    "color": {"map": "Color_Nails", "hero": "nail_color_controller (the nails)", "ruling": "L-019"},
}

# Ghost slot tables drafted in conversation (2026-07-18) — proposals, not law
GHOST_SLOTS = {
    "color": {
        "Pattern_Foundry": "threshold", "Color_Rainbow": "primitive",
        "Color_Grid_Pallet": "walk", "Color_Pillar": "walk", "Color_Paint": "walk",
        "Color_Context_Placed": "turn", "Color_Flashlight": "critical",
        "Color_Walls": "world", "Color_Nails": "close", "Chamber_Color": "seed",
    },
}

REGISTER_TO_SLOT = {"arrival": "threshold", "close": "close", "promenade": "walk"}


def seq_maps(sid):
    p = os.path.join(MAPS_DIR, "sequences", f"{sid}.json")
    if not os.path.isfile(p):
        return None, []
    sj = json.load(open(p, encoding="utf-8"))
    seq = sj.get("sequences", {}).get(sid) or next(iter(sj.get("sequences", {}).values()), {})
    maps = seq.get("maps") or seq.get("map_progression") or []
    names = []
    for m in maps:
        if isinstance(m, str):
            names.append(m)
        elif isinstance(m, dict):
            n = m.get("name") or m.get("map")
            if n:
                names.append(n)
    return seq, names


def map_cast(name):
    p = os.path.join(MAPS_DIR, name, "map_data.json")
    if not os.path.isfile(p):
        return None
    try:
        md = json.load(open(p, encoding="utf-8"))
    except Exception:
        return None
    cast = []
    for row in md.get("layers", {}).get("interactables", []):
        for c in (row if isinstance(row, list) else []):
            if c and c != " ":
                cast.append(c.split(":")[0].split("#")[0])
    return sorted(set(cast))


def dig_load_bearing(sid):
    p = os.path.join(ROOT, "doc", "book", "dig_reports", f"{sid}.md")
    if not os.path.isfile(p):
        return None
    text = open(p, encoding="utf-8", errors="replace").read()
    m = re.search(r"load-bearing proposal: \*\*(.+?)\*\*", text)
    return [a.strip() for a in m.group(1).split(",")] if m else []


def look_script(sid):
    p = os.path.join(ROOT, "doc", "book", "look_scripts", f"{sid}.json")
    if not os.path.isfile(p):
        return {}
    try:
        return json.load(open(p, encoding="utf-8")).get("maps", {})
    except Exception:
        return {}


def main():
    spine = json.load(open(os.path.join(MAPS_DIR, "curriculum_spine.json"), encoding="utf-8"))
    heroes = json.load(open(os.path.join(ROOT, "doc", "book", "heroes.json"), encoding="utf-8"))["sequences"]
    out = {"generated": "2026-07-18", "law": "P-9: lead/hero/register; rule zero: the roster",
           "provenance_order": ["ruled", "measured", "register", "ghost", "heuristic"],
           "sequences": []}
    for s in spine["spine"]["sequences"]:
        sid = s["name"]
        seq, names = seq_maps(sid)
        if seq is None:
            continue
        lb = dig_load_bearing(sid)
        script = look_script(sid)
        soul = RULED_SOULS.get(sid)
        ghost = GHOST_SLOTS.get(sid, {})
        hreg = heroes.get(sid, {})
        rows = []
        n = len(names)
        for i, m in enumerate(names):
            cast = map_cast(m)
            d = os.path.join(MAPS_DIR, m)
            # slot: ruled soul > look-script register > ghost > position heuristic
            if soul and m == soul["map"]:
                slot, slot_prov = "close", f"ruled ({soul['ruling']})"
            elif m in script and script[m].get("register") in REGISTER_TO_SLOT:
                slot, slot_prov = REGISTER_TO_SLOT[script[m]["register"]], "register (look script)"
            elif m in ghost:
                slot, slot_prov = ghost[m], "ghost (2026-07-18 draft)"
            elif m.startswith("Chamber_") or m.startswith("Lab"):
                slot, slot_prov = "seed", "heuristic (name)"
            elif i == 0:
                slot, slot_prov = "threshold", "heuristic (position)"
            elif i == n - 1:
                slot, slot_prov = "close", "heuristic (position)"
            else:
                slot, slot_prov = "walk", "heuristic (position)"
            # hero: ruled soul > dig LB in cast > heroes register > cast default
            cur_hero = (hreg.get(m, {}) or {}).get("hero", "")
            if soul and m == soul["map"]:
                hero, hero_prov = soul["hero"], f"ruled ({soul['ruling']})"
            elif lb and cast and any(a in cast for a in lb):
                hero, hero_prov = next(a for a in lb if a in cast), "measured (dig load-bearing)"
            elif cur_hero:
                hero, hero_prov = cur_hero.split("—")[0].strip()[:40], "register (heroes.json)"
            elif cast:
                hero, hero_prov = cast[0], "heuristic (cast default)"
            else:
                hero, hero_prov = "", "none"
            rows.append({
                "map": m, "order": i + 1, "slot": slot, "slot_prov": slot_prov,
                "hero": hero, "hero_prov": hero_prov,
                "cast_n": len(cast) if cast is not None else 0,
                "exists": cast is not None,
                "tutorial": os.path.isfile(os.path.join(d, "tutorial.md")),
                "walked": os.path.isfile(os.path.join(d, "walked.md")),
                "in_register": m in hreg,
                "dug": bool(lb) or None if lb is None else True,
            })
        # suggested order: slot-grammar sort, stable within a slot by current order
        slot_rank = {k: i for i, k in enumerate(SLOT_GRAMMAR)}
        suggested = sorted(rows, key=lambda r: (slot_rank.get(r["slot"], 2), r["order"]))
        out["sequences"].append({
            "id": sid, "order": s.get("order"), "phase": s.get("phase"),
            "qfep_role": s.get("qfep_role"), "truth": seq.get("truth", ""),
            "dug": lb is not None, "soul": soul,
            "n_maps": n,
            "uncovered": [r["map"] for r in rows if not r["in_register"]],
            "current": [r["map"] for r in rows],
            "suggested": [r["map"] for r in suggested],
            "rows": {r["map"]: r for r in rows},
            "reordered": [r["map"] for r in rows] != [r["map"] for r in suggested],
        })
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(out, open(OUT, "w", encoding="utf-8"), indent=1)
    n_seq = len(out["sequences"])
    n_maps = sum(s["n_maps"] for s in out["sequences"])
    n_unc = sum(len(s["uncovered"]) for s in out["sequences"])
    n_dug = sum(1 for s in out["sequences"] if s["dug"])
    print(f"rule_zero.json: {n_seq} sequences, {n_maps} maps, "
          f"{n_unc} uncovered by heroes register, {n_dug} sequences dug -> {OUT}")


if __name__ == "__main__":
    main()
