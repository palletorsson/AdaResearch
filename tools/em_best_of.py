"""em_best_of.py — which artifact is each museum hall's BEST, and is the museum fair?

2026-08-29, Palle: "place the current grid maps in the endless museum with the best
artifact from each map … what are the options to get the right distribution?"

This is the distribution instrument, REPORT-FIRST: it reads the live plan (every
hall is map-authored now — the hall IS its grid map) and assigns each hall one HERO
by a priority ladder, with a museum-wide once-only rule so no token heroes twice.
It mutates nothing; the report is the deliverable, and any later apply step gets
designed against it.

The ladder (first rung that holds, wins):
  1. clicked   — Palle's hero verdicts from the concepts galleries
                 (ada_encyclopedia/public/<seq>-concepts/evals.json, when clicked)
  2. category  — the category-heroes (doc/<seq>_concept_additions.json seats)
  3. applied   — the concept maps' applied tier (doc/<seq>_concept_map.json)
  4. promoted  — registry entries carrying dna.axes (the argued families)
  5. signature — tokens living in exactly ONE map corpus-wide
  6. rarest    — lowest document frequency wins

FURNITURE (df > FURNITURE_DF corpus-wide: curation_station in 360 maps, dark_sphere
in 338 …) can never be a hall's hero; it is listed as supporting cast, and the
report counts its museum-wide pressure so the repeats are loud, not ambient.

  python tools/em_best_of.py            report -> doc/reports/em_best_of.json + table
  python tools/em_best_of.py --chapter=wavefunctions   one chapter's table
"""
from __future__ import annotations

import glob
import json
import os
import pathlib
import sys
from collections import Counter, defaultdict

ROOT = pathlib.Path(__file__).resolve().parents[1]
ENC = pathlib.Path("C:/Users/palle/Documents/GitHub/ada_encyclopedia")
FURNITURE_DF = 20


def corpus_df() -> dict[str, int]:
    tok_maps: dict[str, set] = defaultdict(set)
    for p in glob.glob(str(ROOT / "commons" / "maps" / "*" / "map_data.json")):
        name = os.path.basename(os.path.dirname(p))
        try:
            d = json.load(open(p, encoding="utf-8"))
        except Exception:
            continue
        for row in (d.get("layers") or {}).get("interactables") or []:
            for cell in row:
                c = str(cell).strip()
                if c and c != "0":
                    tok_maps[c.split(":")[0].split("#")[0]].add(name)
    return {t: len(ms) for t, ms in tok_maps.items()}


def clicked_heroes() -> dict[str, str]:
    """token -> gallery, for every hero verdict Palle has clicked."""
    out: dict[str, str] = {}
    for p in glob.glob(str(ENC / "public" / "*-concepts" / "evals.json")):
        gallery = os.path.basename(os.path.dirname(p))
        try:
            d = json.load(open(p, encoding="utf-8"))
        except Exception:
            continue
        rows = d.get("verdicts") or d
        if isinstance(rows, dict):
            for tok, v in rows.items():
                verdict = v.get("verdict") if isinstance(v, dict) else v
                if str(verdict) == "hero":
                    out[str(tok)] = gallery
    return out


def category_heroes() -> set[str]:
    out: set[str] = set()
    for p in glob.glob(str(ROOT / "doc" / "*_concept_additions.json")):
        try:
            d = json.load(open(p, encoding="utf-8"))
        except Exception:
            continue
        for k in d:
            if not k.startswith("_"):
                out.add(k)
    return out


def applied_tier() -> set[str]:
    out: set[str] = set()
    for p in glob.glob(str(ROOT / "doc" / "*_concept_map.json")):
        try:
            d = json.load(open(p, encoding="utf-8"))
        except Exception:
            continue
        for meta in (d.get("concept_meta") or {}).values():
            for t in ((meta.get("tiers") or {}).get("applied") or []):
                out.add(str(t))
    return out


def promoted() -> set[str]:
    out: set[str] = set()
    for p in glob.glob(str(ROOT / "commons" / "artifacts" / "registry" / "*.json")):
        try:
            d = json.load(open(p, encoding="utf-8"))
        except Exception:
            continue
        arts = d.get("artifacts") or {}
        if isinstance(arts, dict):
            for tok, e in arts.items():
                if isinstance(e, dict) and (e.get("dna") or {}).get("axes"):
                    out.add(tok)
        # older list-shaped registries
        if isinstance(arts, list):
            for e in arts:
                if isinstance(e, dict) and (e.get("dna") or {}).get("axes"):
                    out.add(str(e.get("lookup_name") or ""))
    return out


def main() -> int:
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--chapter="):
            only = a.split("=", 1)[1]

    plan = json.load(open(ROOT / "ada_run" / "em_plan.json", encoding="utf-8"))
    rows = [r for r in plan["plans"] if not only or r.get("sequence") == only]

    df = corpus_df()
    clicked = clicked_heroes()
    cat = category_heroes()
    app = applied_tier()
    promo = promoted()

    def rung(tok: str) -> tuple[int, str]:
        if tok in clicked:
            return (0, "clicked")
        if tok in cat:
            return (1, "category")
        if tok in app:
            return (2, "applied")
        if tok in promo:
            return (3, "promoted")
        if df.get(tok, 999) == 1:
            return (4, "signature")
        return (5, "rarest")

    used: set[str] = set()
    halls = []
    furniture_pressure: Counter = Counter()
    tier_census: Counter = Counter()
    flagged = []
    for r in rows:
        toks = []
        seen_local = set()
        for a in r.get("artifacts") or []:
            t = a.get("token")
            if t and t not in seen_local:
                seen_local.add(t)
                toks.append(t)
        furn = [t for t in toks if df.get(t, 0) > FURNITURE_DF]
        for t in furn:
            furniture_pressure[t] += 1
        cand = [t for t in toks if t not in furn]
        cand.sort(key=lambda t: (rung(t)[0], df.get(t, 999), t))
        hero = next((t for t in cand if t not in used), None)
        why = rung(hero)[1] if hero else ""
        if hero:
            used.add(hero)
            tier_census[why] += 1
        else:
            flagged.append((r["sequence"], r["pearl"], r.get("map", "")))
        halls.append({
            "sequence": r["sequence"], "pearl": r["pearl"], "map": r.get("map", ""),
            "hero": hero, "hero_by": why, "hero_df": df.get(hero, 0) if hero else 0,
            "cast": [t for t in cand if t != hero],
            "furniture": furn,
        })

    report = {
        "_generated_by": "tools/em_best_of.py (report only, mutates nothing)",
        "halls": halls,
        "stats": {
            "halls": len(halls),
            "heroes_assigned": sum(1 for h in halls if h["hero"]),
            "distinct_heroes": len(used),
            "hero_by": dict(tier_census),
            "halls_without_hero": len(flagged),
            "furniture_pressure_top": furniture_pressure.most_common(10),
            "clicked_available": len(clicked),
        },
    }
    outp = ROOT / "doc" / "reports" / "em_best_of.json"
    outp.parent.mkdir(parents=True, exist_ok=True)
    outp.write_text(json.dumps(report, indent=1, ensure_ascii=False), encoding="utf-8")

    cur = None
    for h in halls:
        if h["sequence"] != cur:
            cur = h["sequence"]
            print("\n== " + cur + " ==")
        print("  %-34s hero: %-38s [%s df=%d]  cast=%d furn=%d"
              % (h["map"], h["hero"] or "— NONE (all used/furniture)", h["hero_by"],
                 h["hero_df"], len(h["cast"]), len(h["furniture"])))
    s = report["stats"]
    print("\nhalls %d | heroes %d (all distinct: %s) | by rung %s | no-hero %d | clicks available %d"
          % (s["halls"], s["heroes_assigned"], s["heroes_assigned"] == s["distinct_heroes"],
             s["hero_by"], s["halls_without_hero"], s["clicked_available"]))
    print("furniture pressure:", s["furniture_pressure_top"][:5])
    print("\nreport -> doc/reports/em_best_of.json")
    if flagged:
        print("NO-HERO halls (need a distinctive body):")
        for seq, pearl, m in flagged:
            print("  %s / %s (%s)" % (seq, pearl, m))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
