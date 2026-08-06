#!/usr/bin/env python3
"""
synthesize_heroes.py — one synthesized artifact per promoted family, decided by measurement.

THE QUESTION THIS ANSWERS. Promotion turned 355 artifacts into families, and every family
now needs its one best public form: some families have a single variant that is the
strongest statement (a HERO — pin it and stand it up), and some families ARE the statement
(a SERIES — the progression itself is the argument, so the synthesized artifact is the
whole family shown in measured order). Choosing which is which by taste, 355 times, is how
the corpus got 149 descriptions that describe one member of a family. So the verdict is
DERIVED from the per-variant renders the sweeps already produced.

THE MEASURE. For each variant: neutralise the frame against its own corner background (the
critic's fix — tile 1 of every sweep renders at a different tint), then score its departure
from the SHIPPED DEFAULT as the mean over the hottest 5% of differing pixels (the critic's
focus metric, so these numbers are commensurable with every bite report).

THE VERDICT, from the shape of those departures:
  SERIES  — >=3 non-default values whose departures are SPREAD (max >= 2.2x min and
            max >= 10%): the family forms a gradient away from the shipped form, which
            reads as a progression when ordered. Display order: default first, then by
            measured departure ascending. The order is measured, not asserted, and the
            series plaque should say so.
  HERO    — departures are clustered or few: the family is categorical, so the synthesized
            artifact is the single variant with the maximum departure (>= 8%), pinned.
  DEFAULT — nothing departs by 8%: the shipped form IS the argued form. Also an honest
            outcome, and recorded as one, not padded into a fake hero.

Output: commons/data/dna_synthesis.json — read at runtime by the synthesis_stand artifact.

Usage:
  python tools/synthesize_heroes.py                # all swept artifacts, write the data file
  python tools/synthesize_heroes.py --token=X      # explain one verdict
"""
from __future__ import annotations
import json
import sys
import collections
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ENC = REPO.parent / "ada_encyclopedia" / "public"
OUT = REPO / "commons" / "data" / "dna_synthesis.json"

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_dna_declarations import registry  # noqa: E402


def load_neutral(p: Path):
    """Greyscale samples with the frame's own background subtracted (the critic's fix)."""
    from PIL import Image, ImageChops
    im = Image.open(p).convert("RGB")
    bg = im.getpixel((3, 3))
    im = ImageChops.difference(im, Image.new("RGB", im.size, bg))
    return list(im.convert("L").resize((160, 160)).getdata())


def focus(a, b) -> float:
    """Mean over the hottest 5% of differing pixels, 0..1 — the critic's metric."""
    if not a or len(a) != len(b):
        return 0.0
    d = sorted((abs(x - y) for x, y in zip(a, b)), reverse=True)
    top = max(1, len(d) // 20)
    return sum(d[:top]) / (255.0 * top)


def collect() -> dict:
    """prop -> {gallery, entries:[{id, dna, path}]} keeping the largest variant set."""
    best: dict = {}
    for mf in ENC.glob("*/manifest.json"):
        try:
            d = json.loads(mf.read_text(encoding="utf-8"))
        except Exception:
            continue
        slug = mf.parent.name
        by = collections.defaultdict(list)
        for e in d.get("entries", []):
            if isinstance(e, dict) and e.get("dna") and e.get("prop"):
                p = mf.parent / (str(e.get("image", "")).split("/")[-1] or (e["id"] + ".png"))
                if p.exists():
                    by[e["prop"]].append({"id": e["id"], "dna": e["dna"], "path": p})
        for prop, es in by.items():
            if prop not in best or len(es) > len(best[prop]["entries"]):
                best[prop] = {"gallery": slug, "entries": es}
    return best


def defaults_for(prop: str, reg: dict) -> dict:
    e = reg.get(prop)
    if not e:
        return {}
    axes = ((e[0].get("dna") or {}).get("axes") or {})
    # apply_dna_block puts the export default first in every declared list.
    return {ax: str(vals[0]) for ax, vals in axes.items() if vals}


def verdict_for(prop: str, info: dict, reg: dict) -> dict | None:
    entries = info["entries"]
    defaults = defaults_for(prop, reg)
    if not defaults:
        return None
    def key(dna):  # normalised param tuple restricted to declared axes
        return tuple(sorted((k, str(v)) for k, v in dna.items() if k in defaults))
    base = None
    for e in entries:
        if all(str(e["dna"].get(k, defaults[k])) == v for k, v in defaults.items()):
            base = e
            break
    if base is None:
        return {"prop": prop, "verdict": "unmeasured", "note": "default variant absent from sweep",
                "gallery": info["gallery"]}
    base_img = load_neutral(base["path"])
    scored = []
    for e in entries:
        if key(e["dna"]) == key(base["dna"]):
            continue
        scored.append({"dna": {k: str(v) for k, v in e["dna"].items() if k in defaults},
                       "focus": round(focus(base_img, load_neutral(e["path"])), 4)})
    if not scored:
        return {"prop": prop, "verdict": "unmeasured", "note": "single variant",
                "gallery": info["gallery"]}
    scored.sort(key=lambda s: s["focus"])
    top = scored[-1]

    # SERIES test on each single axis: variants differing from the default in that axis alone.
    series_axis, series_vals = None, None
    for ax, dv in defaults.items():
        singles = [s for s in scored
                   if s["dna"].get(ax, dv) != dv
                   and all(s["dna"].get(k, defaults[k]) == defaults[k]
                           for k in defaults if k != ax)]
        if len(singles) >= 3:
            fs = [s["focus"] for s in singles]
            if max(fs) >= 0.10 and min(fs) > 0 and max(fs) / max(min(fs), 1e-6) >= 2.2:
                series_axis = ax
                series_vals = [dv] + [s["dna"][ax] for s in sorted(singles, key=lambda s: s["focus"])]
                break
    if series_axis:
        return {"prop": prop, "verdict": "series", "axis": series_axis,
                "order": series_vals, "span": [scored[0]["focus"], top["focus"]],
                "gallery": info["gallery"], "evidence": scored[-6:]}
    if top["focus"] >= 0.08:
        return {"prop": prop, "verdict": "hero", "hero": top["dna"],
                "score": top["focus"], "gallery": info["gallery"], "evidence": scored[-4:]}
    return {"prop": prop, "verdict": "default", "score": top["focus"],
            "gallery": info["gallery"]}


def main() -> int:
    only = ""
    for a in sys.argv[1:]:
        if a.startswith("--token="):
            only = a.split("=", 1)[1]
    reg = registry()
    data = collect()
    out, counts = {}, collections.Counter()
    for prop, info in sorted(data.items()):
        if only and prop != only:
            continue
        v = verdict_for(prop, info, reg)
        if v is None:
            counts["no_declaration"] += 1
            continue
        counts[v["verdict"]] += 1
        out[prop] = v
        if only:
            print(json.dumps(v, indent=1))
    if not only:
        OUT.write_text(json.dumps({
            "_note": "Per promoted family: is its best public form one pinned variant (hero), "
                     "the whole family in measured order (series), or the shipped default? "
                     "Derived from the swept renders with the critic's focus metric; "
                     "regenerate with tools/synthesize_heroes.py after any re-sweep.",
            "verdicts": out,
        }, indent=1), encoding="utf-8")
        print(f"{len(out)} families judged -> {OUT.relative_to(REPO)}")
        for k, n in counts.most_common():
            print(f"  {k:12s} {n}")
        heroes = sorted((v for v in out.values() if v["verdict"] == "hero"),
                        key=lambda v: -v["score"])[:8]
        series = sorted((v for v in out.values() if v["verdict"] == "series"),
                        key=lambda v: -v["span"][1])[:8]
        print("\nstrongest heroes:")
        for v in heroes:
            print(f"  {v['prop']:32s} {v['score']*100:5.1f}%  " +
                  " ".join(f"{k}={x}" for k, x in v["hero"].items()))
        print("strongest series:")
        for v in series:
            print(f"  {v['prop']:32s} span {v['span'][0]*100:.1f}-{v['span'][1]*100:.1f}%  "
                  f"{v['axis']}: {' -> '.join(v['order'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
