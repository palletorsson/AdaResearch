"""Propose where each overflowing or floating work could stand on its own floor (Palle, 2026-11-09: "think about what we
can do about it"). Reads the size survey (tools/void_size_survey.py: every work's measured world box) and, for each work
that leaves the building or floats outside it but whose footprint would fit the floor, searches the nearest position
(0.5 m grid, optionally a quarter turn) where its box lies on the 42 x 18 m slab, off the shaft openings, round no
building column, and clear of every other work's measured box. Writes PROPOSALS only - nothing in the tower changes.

    python tools/void_fit_pass.py [--markdown]
Output: ada_run/void-size-survey/fit_pass.json (+ fit_pass.md)."""
import json, math, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "ada_run/void-size-survey"
MARGIN = 0.15


def rects_overlap(a, b, shrink=0.05):
    return a[0] + shrink < b[2] - shrink and b[0] + shrink < a[2] - shrink and a[1] + shrink < b[3] - shrink and b[1] + shrink < a[3] - shrink


def main():
    sys.path.insert(0, str(ROOT / "tools"))
    import void_size_survey as S
    building, floors = S.load()
    report = json.loads((OUT / "report.json").read_text(encoding="utf-8"))
    hw, hd = building["width"] / 2, building["depth"] / 2
    shafts = [(float(s["x"]) - building["shaft_width"] / 2, -building["shaft_depth"] / 2,
               float(s["x"]) + building["shaft_width"] / 2, building["shaft_depth"] / 2) for s in building["shafts"]]
    cw = building["column_width"] / 2
    columns = [(x - cw, z - cw, x + cw, z + cw) for x in building["column_x"] for z in building["column_z"]]
    todo = [r for r in report["overflowing"] if r["fit"] == "move" and any(o.startswith("edge") for o in r["overflow"])]
    todo += [r for r in report.get("displaced", []) if r.get("size") and r["size"][0] <= 2 * hw and r["size"][2] <= 2 * hd]
    proposals, stuck = [], []
    for r in todo:
        f = floors[str(r["floor"])]
        works = {w["id"]: w for w in f["works"]}
        me = works.get(r["id"])
        if not me or not me.get("box"):
            continue
        x0, _, z0, x1, _, z1 = me["box"]
        px, pz = float(me["at"][0]), float(me["at"][1])
        others = [w["box"] for k, w in works.items() if k != r["id"] and w.get("box") and None not in w["box"]
                  and not w.get("extension") and (w["box"][3] - w["box"][0]) < 40 and (w["box"][5] - w["box"][2]) < 16]
        others = [(b[0], b[2], b[3], b[5]) for b in others]
        best = None
        for turn in (0, 90):
            # the box about the mount: a quarter turn swaps its offsets
            ox0, oz0, ox1, oz1 = x0 - px, z0 - pz, x1 - px, z1 - pz
            if turn:
                ox0, oz0, ox1, oz1 = oz0, -ox1, oz1, -ox0
            for ring in range(0, 90):
                found = None
                for dx2 in range(-ring, ring + 1):
                    for dz2 in range(-ring, ring + 1):
                        if max(abs(dx2), abs(dz2)) != ring:
                            continue
                        nx, nz = round(px + dx2 * .5, 2), round(pz + dz2 * .5, 2)
                        rect = (nx + ox0, nz + oz0, nx + ox1, nz + oz1)
                        if rect[0] < -hw + MARGIN or rect[2] > hw - MARGIN or rect[1] < -hd + MARGIN or rect[3] > hd - MARGIN:
                            continue
                        if any(rects_overlap(rect, s, 0.0) for s in shafts) or any(rects_overlap(rect, c, 0.0) for c in columns):
                            continue
                        if any(rects_overlap(rect, o) for o in others):
                            continue
                        d = math.hypot(nx - px, nz - pz) + (1.0 if turn else 0.0)
                        if found is None or d < found[0]:
                            found = (d, nx, nz, turn)
                if found:
                    if best is None or found[0] < best[0]:
                        best = found
                    break
        row = {"floor": r["floor"], "map": r["map"], "id": r["id"], "token": r["token"], "origin": r.get("origin"),
               "why": r.get("displaced") or "; ".join(r["overflow"]), "size": r.get("size"), "from": [px, pz]}
        if best:
            row.update({"to": [best[1], best[2]], "turn": best[3], "moved_m": round(best[0] - (1.0 if best[3] else 0), 2)})
            proposals.append(row)
        else:
            stuck.append(row)
    (OUT / "fit_pass.json").write_text(json.dumps({"proposals": proposals, "no_room_on_its_floor": stuck}, indent=1, ensure_ascii=False), encoding="utf-8")
    md = ["# Fit pass - proposals only", "", "%d works could stand on their own floor if moved; %d find no free spot there." % (len(proposals), len(stuck)), "",
          "| floor | map | work | token | why | from | to | turn | moved m |", "|---|---|---|---|---|---|---|---|---|"]
    for p in proposals:
        md.append("| %d | %s | %s | %s | %s | %s | %s | %s | %s |" % (p["floor"], p["map"], p["id"], p["token"], p["why"][:70], p["from"], p["to"], p["turn"] or "", p["moved_m"]))
    md += ["", "## No free spot on its own floor", "", "| floor | map | work | token | size m | why |", "|---|---|---|---|---|---|"]
    for p in stuck:
        md.append("| %d | %s | %s | %s | %s | %s |" % (p["floor"], p["map"], p["id"], p["token"], p["size"], p["why"][:80]))
    (OUT / "fit_pass.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    print("proposals %d, no room %d" % (len(proposals), len(stuck)))
    if "--markdown" in sys.argv:
        print("\n".join(md))


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf8")
    main()
