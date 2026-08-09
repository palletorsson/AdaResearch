# -*- coding: utf-8 -*-
"""artifact_relations.py — for every spine artifact, what is related to it.

Palle wants placement to put down more than one of a thing, and to put down its
RELATIVES — drawn from the DNA galleries. That needs "related" to be a fact
rather than an opinion, and nothing in the project defines it. This does, from
the four signals the registry already carries:

  same DNA AXIS   two artifacts that declare the same axis argue the same thing
                  (godel_statement_plaque.outside and another .outside are kin
                  in a way no tag captures) — the strongest signal, and the one
                  only the promoted 577 can offer
  same CATEGORY   the registry's own grouping, 2355 artifacts carry it
  shared TAGS     Jaccard overlap, 2193 carry them
  same FILE       a registry file is a domain; weakest, used only to break ties

A relative is scored, not declared, and the score is written out beside the
reasons so a wrong pairing can be argued with rather than merely deleted.

DIRECTION MATTERS: the list is keyed by SPINE artifact (the ones actually placed
in the 269 curriculum maps, from spine_artifact_order.json) and ranks candidates
from the DNA galleries. Placement asks "what goes next to THIS", never the
reverse.

    python tools/artifact_relations.py build
    python tools/artifact_relations.py show --of=godel_statement_plaque
"""
import json, argparse, pathlib, sys
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "commons/data/artifact_relations.json"
W_AXIS, W_CATEGORY, W_TAGS, W_FILE = 3.0, 2.0, 2.0, 0.5
TOP_N = 12


def registry():
    reg = {}
    for f in sorted((ROOT / "commons/artifacts/registry").glob("*.json")):
        try:
            d = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        for k, v in (d.get("artifacts", d) or {}).items():
            if isinstance(v, dict):
                reg[k] = dict(v, _file=f.name)
    return reg


def axes_of(v):
    ax = (v.get("dna") or {}).get("axes") or {}
    return set(ax.keys()) if isinstance(ax, dict) else set()


def tags_of(v):
    t = v.get("tags") or []
    return {str(x).lower() for x in t} if isinstance(t, list) else set()


def spine_artifacts():
    """The artifacts actually standing in the 269 curriculum maps, with where."""
    p = ROOT / "commons/data/spine_artifact_order.json"
    if not p.exists():
        return {}
    out = {}
    for i, e in enumerate(json.loads(p.read_text(encoding="utf-8")).get("order", [])):
        lk = e.get("lookup")
        if not lk:
            continue
        out.setdefault(lk, {"lookup": lk, "first_order": i,
                            "sequences": set(), "maps": set()})
        out[lk]["sequences"].add(e.get("sequence", ""))
        out[lk]["maps"].add(e.get("map", ""))
    return out


def score(a, b):
    """Why b is related to a. Reasons are returned with the number so the pairing
    can be argued with."""
    why, s = [], 0.0
    ax = axes_of(a) & axes_of(b)
    if ax:
        s += W_AXIS * len(ax); why.append("axis:" + "+".join(sorted(ax)))
    ca, cb = a.get("category"), b.get("category")
    if ca and ca == cb:
        s += W_CATEGORY; why.append("category:%s" % ca)
    ta, tb = tags_of(a), tags_of(b)
    if ta and tb:
        j = len(ta & tb) / float(len(ta | tb))
        if j > 0:
            s += W_TAGS * j
            why.append("tags:%s" % ",".join(sorted(ta & tb)[:3]))
    if a.get("_file") == b.get("_file"):
        s += W_FILE; why.append("domain:%s" % str(a.get("_file")).replace(".json", ""))
    return s, why


def build():
    reg = registry()
    gallery = {k: v for k, v in reg.items() if axes_of(v)}      # the DNA galleries
    spine = spine_artifacts()
    print("registry %d · dna gallery %d · spine artifacts %d"
          % (len(reg), len(gallery), len(spine)))
    rows, no_kin = {}, 0
    for lk, meta in spine.items():
        a = reg.get(lk)
        if not a:
            continue
        cand = []
        for k, b in gallery.items():
            if k == lk:
                continue
            s, why = score(a, b)
            if s > 0:
                cand.append({"lookup": k, "score": round(s, 2), "why": why,
                             "axes": sorted(axes_of(b))})
        cand.sort(key=lambda c: (-c["score"], c["lookup"]))
        if not cand:
            no_kin += 1
        rows[lk] = {
            "lookup": lk,
            "in_gallery": lk in gallery,
            "category": a.get("category"),
            "axes": sorted(axes_of(a)),
            "sequences": sorted(x for x in meta["sequences"] if x),
            "maps": len(meta["maps"]),
            "first_order": meta["first_order"],
            "related": cand[:TOP_N],
        }
    OUT.write_text(json.dumps({
        "_readme": ("For every artifact standing in the 269 spine maps, the DNA-gallery artifacts "
                    "related to it — so placement can put down a relative, not just a duplicate. "
                    "Related is SCORED from the registry's own signals (shared dna axis 3.0, same "
                    "category 2.0, tag overlap 2.0 x Jaccard, same registry file 0.5) and every "
                    "pairing carries its reasons. A proposal, not a ruling."),
        "weights": {"axis": W_AXIS, "category": W_CATEGORY, "tags": W_TAGS, "file": W_FILE},
        "counts": {"spine_artifacts": len(rows), "dna_gallery": len(gallery),
                   "with_no_relatives": no_kin,
                   "in_gallery_themselves": sum(1 for r in rows.values() if r["in_gallery"])},
        "artifacts": rows}, indent=1), encoding="utf-8")
    print("%d spine artifacts, %d with no relative at all -> %s" % (len(rows), no_kin, OUT))
    strong = sorted(rows.values(), key=lambda r: -(r["related"][0]["score"] if r["related"] else 0))
    print("\nstrongest kinship found:")
    for r in strong[:8]:
        t = r["related"][0]
        print("  %-30s -> %-28s %.1f  %s" % (r["lookup"][:30], t["lookup"][:28], t["score"],
                                             ", ".join(t["why"])[:44]))


def show(of):
    d = json.loads(OUT.read_text(encoding="utf-8"))["artifacts"]
    r = d.get(of)
    if not r:
        print("not a spine artifact: %s" % of); return
    print("%s  (category %s, axes %s, in %d maps)" % (r["lookup"], r["category"],
                                                      r["axes"] or "-", r["maps"]))
    for c in r["related"]:
        print("   %5.1f  %-32s %s" % (c["score"], c["lookup"][:32], ", ".join(c["why"])[:56]))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("stage", choices=["build", "show"])
    ap.add_argument("--of", default="")
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    build() if a.stage == "build" else show(a.of)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
