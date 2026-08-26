"""build_map_prerequisites.py — what each map NEEDS and what it ADDS.

Palle (2026-08-24): "Put an info board in every passage where we state the
prerequisite of the new addition that the map includes. Show the prerequisite
of each map and show what we are adding."

The currency is artifacts, because that is what the walk actually meets. The
spine manifest (commons/data/spine_artifact_order.json) already records every
artifact's FIRST appearance in spine order, so:

  adds  = artifacts whose first appearance IS this map — the new capacity
  needs = artifacts standing in this map that were introduced EARLIER, with
          the map that introduced them (the prerequisite, named)

A map that only re-uses adds nothing and says so. Chapter rows carry the same
two lists for the halls the museum deals without a map.

  python tools/build_map_prerequisites.py          write commons/data/map_prerequisites.json
  python tools/build_map_prerequisites.py --show Point_Lines
"""
from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
ORDER = ROOT / "commons" / "data" / "spine_artifact_order.json"
SPINE = ROOT / "commons" / "maps" / "curriculum_spine.json"
SEQ_DIR = ROOT / "commons" / "maps" / "sequences"
OUT = ROOT / "commons" / "data" / "map_prerequisites.json"


def map_tokens(name: str) -> list[str]:
    p = ROOT / "commons" / "maps" / name / "map_data.json"
    if not p.exists():
        return []
    md = json.loads(p.read_text(encoding="utf-8"))
    toks, seen = [], set()
    for row in md.get("layers", {}).get("interactables", []):
        for v in row:
            s = str(v).strip()
            if not s:
                continue
            t = s.split("#")[0].split(":")[0]
            if t and t not in seen:
                seen.add(t)
                toks.append(t)
    return toks


def main() -> None:
    order = json.loads(ORDER.read_text(encoding="utf-8"))["order"]
    # first appearance: lookup -> (sequence, map, index)
    first: dict[str, tuple[str, str, int]] = {}
    for i, e in enumerate(order):
        lk = str(e.get("lookup", ""))
        if lk and lk not in first:
            first[lk] = (str(e.get("sequence", "")), str(e.get("map", "")), i)

    spine = json.loads(SPINE.read_text(encoding="utf-8"))["spine"]["sequences"]
    chapters = [str(s.get("name", "")) for s in spine]
    seq_maps: dict[str, list[str]] = {}
    for f in SEQ_DIR.glob("*.json"):
        if ".beats" in f.name:
            continue
        doc = json.loads(f.read_text(encoding="utf-8"))
        ss = doc.get("sequences")
        if isinstance(ss, dict):
            for sid, s in ss.items():
                if isinstance(s, dict) and s.get("maps"):
                    seq_maps[sid] = [str(m) for m in s["maps"]]

    # the walk order of maps, so "earlier" is well defined
    walk: list[tuple[str, str]] = []
    for ch in chapters:
        for m in seq_maps.get(ch, []):
            walk.append((ch, m))
    pos = {m: i for i, (_c, m) in enumerate(walk)}

    maps_out: dict[str, dict] = {}
    for ch, m in walk:
        toks = map_tokens(m)
        adds, needs = [], []
        for t in toks:
            fs, fm, _i = first.get(t, ("", "", -1))
            if fm == m:
                adds.append(t)
            elif fm:
                needs.append({"token": t, "from_map": fm, "from_chapter": fs})
            else:
                # never in the spine manifest: an artifact only this map places
                adds.append(t)
        i = pos[m]
        maps_out[m] = {
            "chapter": ch,
            "index": i,
            "after": walk[i - 1][1] if i > 0 else "",
            "adds": adds,
            "needs": needs,
        }

    chapters_out: dict[str, dict] = {}
    for n, ch in enumerate(chapters):
        ms = seq_maps.get(ch, [])
        ch_adds, ch_needs = [], []
        for m in ms:
            row = maps_out.get(m, {})
            ch_adds += [a for a in row.get("adds", []) if a not in ch_adds]
            for nd in row.get("needs", []):
                if nd["from_chapter"] != ch and nd["token"] not in [x["token"] for x in ch_needs]:
                    ch_needs.append(nd)
        chapters_out[ch] = {
            "order": n + 1,
            "after": chapters[n - 1] if n > 0 else "",
            "maps": ms,
            "adds": ch_adds,
            "needs": ch_needs,
        }

    doc = {
        "_readme": "What each map NEEDS (artifacts introduced earlier, with the map that introduced them) "
                   "and what it ADDS (artifacts whose first spine appearance is this map). Written by "
                   "tools/build_map_prerequisites.py from spine_artifact_order.json; read by the endless "
                   "museum, which hangs it as the prerequisite board in every passage. Regenerate after "
                   "build_spine_artifact_order.py.",
        "maps": maps_out,
        "chapters": chapters_out,
    }
    OUT.write_text(json.dumps(doc, indent=1, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
    n_adds = sum(len(r["adds"]) for r in maps_out.values())
    print("map prerequisites -> %s" % OUT.relative_to(ROOT))
    print("  %d maps, %d chapters, %d additions, %d re-uses" % (
        len(maps_out), len(chapters_out), n_adds,
        sum(len(r["needs"]) for r in maps_out.values())))
    silent = [m for m, r in maps_out.items() if not r["adds"]]
    print("  %d map(s) add nothing new" % len(silent))


if __name__ == "__main__":
    if "--show" in sys.argv:
        name = sys.argv[sys.argv.index("--show") + 1]
        doc = json.loads(OUT.read_text(encoding="utf-8"))
        print(json.dumps(doc["maps"].get(name, {}), indent=1)[:1200])
    else:
        main()
