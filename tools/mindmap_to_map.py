"""Close the loop: the mind-map's 2D arrangement -> an actual walkable map_data.json.

The /mind-map page lets you project/decide where each concept sits in 2D. This turns that
arrangement into a VR map: the forward (timeline) axis becomes the order the player walks, the
lateral axis becomes left/right placement on the floor. One representative artifact per concept
(keeps it walkable), a full solid floor (guaranteed reachable), spawn at the first concept and
a teleporter at the last. Walk order == mind-map order.

Reads doc/<domain>_mindmap.json (+ doc/<domain>_mindmap_layout.json human overrides). Uses an
existing good map as a template for the non-layer config (settings/lighting/utility defs) so the
output is structurally valid, then replaces the three layers. Writes a NEW map — never edits an
existing one.

Run:  python tools/mindmap_to_map.py transformation [--w=0.0] [--name=MindMap_Transformation]
"""
import json, os, sys, math

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(ROOT, "doc")
MAPS = os.path.join(ROOT, "commons", "maps")
TEMPLATE = os.path.join(MAPS, "Trans_Translation", "map_data.json")
PAGE_W, PAGE_H, CX, TOP = 760.0, 900.0, 380.0, 40.0
TIER_RANK = {"applied": 3, "large": 4, "medium": 2, "small": 1}


def concept_positions(mm, w):
    """Replicate the /mind-map page layout: order column <-> act bands, plus saved overrides."""
    concepts = mm["concepts"]
    overrides = mm.get("layout", {})
    acts, n = [], len(concepts)
    for c in concepts:
        if c["act"] not in acts:
            acts.append(c["act"])
    dy = (PAGE_H - 2 * TOP) / max(1, n - 1)
    bandH = (PAGE_H - 70) / max(1, len(acts))
    actIdx = {a: i for i, a in enumerate(acts)}
    perAct = {a: [] for a in acts}
    for c in concepts:
        perAct[c["act"]].append(c["order"])
    inAct, cntAct = {}, {}
    for a in acts:
        for k, o in enumerate(perAct[a]):
            inAct[o] = k
        cntAct[a] = len(perAct[a])
    pos = {}
    for c in concepts:
        o = c["order"]
        if str(o) in overrides:
            pos[o] = (overrides[str(o)]["x"], overrides[str(o)]["y"])
            continue
        oy = TOP + o * dy
        by = 40 + (actIdx[c["act"]] + 0.5) * bandH
        bx = 80 + ((inAct[o] + 0.5) / cntAct[c["act"]]) * (PAGE_W - 160)
        pos[o] = (CX + (bx - CX) * w, oy + (by - oy) * w)
    return pos


def representative(mm):
    """One artifact per concept_order: recommended first, else biggest tier, else first."""
    by = {}
    for a in mm["artifacts"]:
        by.setdefault(a["concept_order"], []).append(a)
    rep = {}
    for o, arts in by.items():
        arts.sort(key=lambda a: (not a.get("recommended"), -TIER_RANK.get(a["tier"], 0)))
        rep[o] = arts[0]
    return rep


def build(domain, w, name):
    mm = json.load(open(os.path.join(DOC, domain + "_mindmap.json"), encoding="utf-8"))
    lp = os.path.join(DOC, domain + "_mindmap_layout.json")
    if os.path.exists(lp):
        mm["layout"] = json.load(open(lp, encoding="utf-8"))
    concepts = sorted(mm["concepts"], key=lambda c: c["order"])
    pos = concept_positions(mm, w)
    rep = representative(mm)

    # grid: forward axis (order) -> rows, 3 rows per concept; lateral (x) -> 11 cols
    GX = 11
    rows_per = 3
    GZ = 4 + len(concepts) * rows_per
    xs = [pos[c["order"]][0] for c in concepts]
    xlo, xhi = min(xs), max(xs)
    def col(x):
        f = 0.5 if xhi <= xlo else (x - xlo) / (xhi - xlo)
        return max(1, min(GX - 2, int(round(1 + f * (GX - 3)))))

    structure = [["1"] * GX for _ in range(GZ)]
    inter = [[" "] * GX for _ in range(GZ)]
    util = [[" "] * GX for _ in range(GZ)]
    placed = []
    for i, c in enumerate(concepts):
        o = c["order"]
        r = 2 + i * rows_per
        cc = col(pos[o][0])
        if inter[r][cc].strip():  # collision guard
            cc = min(GX - 2, cc + 1)
        art = rep.get(o)
        if art:
            inter[r][cc] = "%s:0:0" % art["lookup"]
            placed.append({"concept": c["key"], "order": o, "lookup": art["lookup"], "row": r, "col": cc})
        if i == 0:
            util[1][1] = "s"                           # explicit start at (1,1) per grid convention
            util[1][2] = "an"                          # info board at entry
        if i == len(concepts) - 1:
            tr = min(GZ - 1, r + 1)
            util[tr][cc] = "t"                         # teleporter at the last concept
            structure[tr][cc] = "0"                    # teleporter sits on void (height 0)

    tpl = json.load(open(TEMPLATE, encoding="utf-8"))
    tpl["layers"] = {"structure": structure, "utilities": util, "interactables": inter}
    tpl["map_info"] = {
        "name": name,
        "description": "Generated from the %s mind-map (w=%.2f): the 2D arrangement of concepts becomes "
                       "the order walked. Spawn at '%s', teleporter at '%s'. One representative artifact per concept."
                       % (domain, w, concepts[0]["key"], concepts[-1]["key"]),
    }
    if "documentation" in tpl:
        tpl["documentation"] = {"source": "tools/mindmap_to_map.py", "domain": domain, "w": w}
    return tpl, placed, (GX, GZ)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    domain = args[0] if args else "transformation"
    w = float(opts.get("w", 0.0))
    name = opts.get("name", "MindMap_" + domain.title().replace("_", ""))
    tpl, placed, (GX, GZ) = build(domain, w, name)
    outdir = os.path.join(MAPS, name)
    os.makedirs(outdir, exist_ok=True)
    import re
    s = json.dumps(tpl, indent=2, ensure_ascii=False)
    # compact-rows: collapse each grid row (an array of short quoted strings) onto one line
    compact = re.sub(r'\[\n\s*((?:"(?:[^"\\]|\\.)*",?\s*)+)\]',
                     lambda m: "[" + " ".join(p.strip() for p in m.group(1).replace("\n", " ").split(",") if p.strip()).replace(" ", ", ").replace(",  ", ", ") + "]",
                     s)
    try:
        json.loads(compact)
    except Exception:
        compact = s  # fall back to standard formatting if the collapse broke JSON
    open(os.path.join(outdir, "map_data.json"), "w", encoding="utf-8").write(compact)
    print("wrote commons/maps/%s/map_data.json  (%dx%d, %d artifacts placed)" % (name, GX, GZ, len(placed)))
    for p in placed:
        print("  %2d  %-26s %-22s  @ (r%d,c%d)" % (p["order"], p["concept"], p["lookup"], p["row"], p["col"]))


if __name__ == "__main__":
    main()
