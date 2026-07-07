"""build_order_mixer.py — merge every artifact order into one mixer JSON.

Per spine sequence, per artifact, a normalized 0..1 position in each lens:

  manual      — doc/book/manual_order.json (the ghost's editorial sort)
  consensus   — three-orders (ped+onto+crit)/3
  pedagogy / ontology / criticality — the three axes
  engine      — Godot docs stage + inheritance depth (construction_edges.json)
  atoms       — atom-ladder construction grade

Missing lens values stay null (the page renormalizes weights per artifact).
Output: <encyclopedia>/public/order-mixer.json  → the /order-mixer page.

Usage: python tools/build_order_mixer.py
"""

import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENC = Path(os.environ.get("ADA_ENCYCLOPEDIA_PATH", ROOT.parent / "ada_encyclopedia"))
MANUAL = ROOT / "doc" / "book" / "manual_order.json"
THREE_ORDERS = ENC / "public" / "three-orders.json"
CONSTRUCTION = ROOT / "doc" / "book" / "construction_edges.json"
OUT = ENC / "public" / "order-mixer.json"


def jload(p):
    return json.loads(Path(p).read_text(encoding="utf-8"))


def minmax(vals):
    xs = [v for v in vals.values() if v is not None]
    if not xs or max(xs) == min(xs):
        return {k: (0.5 if v is not None else None) for k, v in vals.items()}
    lo, hi = min(xs), max(xs)
    return {k: ((v - lo) / (hi - lo) if v is not None else None)
            for k, v in vals.items()}


def main():
    manual = jload(MANUAL)["sequences"]
    orders = {s["seq"]: s for s in jload(THREE_ORDERS).get("sequences", [])}
    nodes = jload(CONSTRUCTION)["nodes"]

    out = {"generated_by": "tools/build_order_mixer.py",
           "lenses": ["manual", "consensus", "pedagogy", "ontology",
                      "criticality", "engine", "atoms"],
           "sequences": {}}

    for seq, entry in manual.items():
        order = entry["order"]
        o = orders.get(seq, {})
        pearls = o.get("pearls", [])
        pos = {ax: {} for ax in ("ped", "onto", "crit")}
        for i, name in enumerate(pearls):
            for ax in pos:
                arr = o.get(ax, [])
                if i < len(arr):
                    pos[ax][name] = arr[i]

        names = list(order)  # the mixer works on the manual set (the chapter's cast)
        n = max(len(names) - 1, 1)
        man = {a: i / n for i, a in enumerate(names)}

        eng_raw, atom_raw = {}, {}
        for a in names:
            b = a.split("#")[0]
            node = nodes.get(b)
            if node and node.get("engine", {}).get("base"):
                e = node["engine"]
                eng_raw[a] = e["stage"] * 100 + e["engine_depth"] + e["script_hops"]
            else:
                eng_raw[a] = None
            atom_raw[a] = node.get("grade") if node else None
        eng = minmax(eng_raw)
        atoms = minmax(atom_raw)

        arts = []
        for a in names:
            b = a.split("#")[0]
            ped = pos["ped"].get(b)
            onto = pos["onto"].get(b)
            crit = pos["crit"].get(b)
            cons = (ped + onto + crit) / 3 if None not in (ped, onto, crit) else None
            arts.append({"name": a, "lenses": {
                "manual": round(man[a], 3),
                "consensus": round(cons, 3) if cons is not None else None,
                "pedagogy": round(ped, 3) if ped is not None else None,
                "ontology": round(onto, 3) if onto is not None else None,
                "criticality": round(crit, 3) if crit is not None else None,
                "engine": round(eng[a], 3) if eng[a] is not None else None,
                "atoms": round(atoms[a], 3) if atoms[a] is not None else None,
            }})
        out["sequences"][seq] = {"arc": entry.get("arc", ""), "artifacts": arts}

    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=1), encoding="utf-8")
    n_art = sum(len(s["artifacts"]) for s in out["sequences"].values())
    print(f"order-mixer: {len(out['sequences'])} sequences, {n_art} artifacts -> {OUT}")


if __name__ == "__main__":
    main()
