#!/usr/bin/env python3
"""
build_order_policies.py — who decides the order of the walk (unification step 4).

Artifact order in the final space has been implicit and inconsistent:
museum_match deals hero-by-size then walk order, the painter sorts by (z,x),
the endless museum deals the curriculum. None of that was ever DECLARED, so
nothing could be ruled about it and nothing carried provenance.

This makes the order a named policy with a reason per entry:

  spine   the curriculum's own order (the existing manifest, unchanged)
  dig     load-bearing first — the chapter's census speaks before its roster
  size    smallest to largest, so the walk builds instead of opening at its peak
  text    THE ORDER THE WRITING INTRODUCES THEM — first mention, page by page

`text` is the one that was impossible until this week: doc/book/text_mentions.json
(built 2026-08-03) established that 844 artifacts are named in prose, and this
reads the pages again for the OFFSET of each first mention, so the room can be
ordered by the book rather than by the file system. That is the last unclosed
gap between the writing pipeline and the museum pipeline.

Output commons/data/artifact_order_policies.json in the same shape the endless
museum's spine loader already reads, so the engine change is one flag.

  python tools/build_order_policies.py
  python tools/build_order_policies.py --compare     # how much do policies differ?
  python tools/build_order_policies.py --self-test
"""
from __future__ import annotations
import argparse
import glob
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MAPS = REPO / "commons" / "maps"
SPINE_ORDER = REPO / "commons" / "data" / "spine_artifact_order.json"
SIZES = REPO / "commons" / "data" / "artifact_sizes.json"
OUT = REPO / "commons" / "data" / "artifact_order_policies.json"
TEXT_KINDS = ["walked", "tutorial", "critical", "blurb"]


def spine_rows() -> list:
    d = json.loads(SPINE_ORDER.read_text(encoding="utf-8"))
    return list(d.get("order", []))


def registry() -> dict:
    out: dict = {}
    for rp in sorted(glob.glob(str(REPO / "commons" / "artifacts" / "registry" / "*.json"))):
        try:
            d = json.load(open(rp, encoding="utf-8"))
        except Exception:
            continue
        for tok, e in (d.get("artifacts") or {}).items():
            if isinstance(e, dict) and tok not in out:
                out[tok] = e
    return out


def dig_rank() -> dict:
    """token -> (0 load-bearing, 1 promoted, 2 unmentioned), per chapter dig report."""
    rank: dict = {}
    for p in glob.glob(str(REPO / "doc" / "book" / "dig_reports" / "*.md")):
        text = Path(p).read_text(encoding="utf-8", errors="replace")
        m = re.search(r"load-bearing proposal: \*\*(.+?)\*\*", text)
        if m:
            for tok in [a.strip() for a in m.group(1).split(",")]:
                rank[tok] = min(rank.get(tok, 9), 0)
        for tok in re.findall(r"^- \*\*([a-zA-Z0-9_]+)\*\* \(LB", text, re.M):
            rank[tok] = min(rank.get(tok, 9), 1)
    return rank


def size_of(reg: dict, tok: str) -> float:
    e = reg.get(tok) or {}
    fp = (e.get("parameters") or {}).get("footprint") or e.get("footprint")
    if isinstance(fp, list) and fp:
        try:
            return float(max(float(v) for v in fp))
        except Exception:
            pass
    return {"small": 1.0, "medium": 2.0, "large": 3.0, "xl": 4.0}.get(
        str(e.get("size_group", "")).lower(), 1.5)


def first_mentions(tokens: set) -> dict:
    """(map, token) -> character offset of the token's first mention in that map's prose.

    text_mentions.json answers WHETHER the writing names an artifact; the order
    of a walk needs WHERE, so the pages are read again for the offset. Kinds are
    weighted by page: the walked page is the book's own voice and speaks before
    the tutorial, which speaks before the criticism.
    """
    pat = re.compile(r"(?<![A-Za-z0-9_])(" + "|".join(
        re.escape(t) for t in sorted(tokens, key=len, reverse=True)) + r")(?![A-Za-z0-9_])")
    out: dict = {}
    for d in sorted(MAPS.iterdir()):
        if not d.is_dir():
            continue
        for ki, kind in enumerate(TEXT_KINDS):
            p = d / f"{kind}.md"
            if not p.is_file():
                continue
            text = p.read_text(encoding="utf-8", errors="replace")
            for m in pat.finditer(text):
                key = (d.name, m.group(1))
                pos = ki * 1_000_000 + m.start()
                if key not in out or pos < out[key]:
                    out[key] = pos
    return out


def build() -> dict:
    rows = spine_rows()
    reg = registry()
    dr = dig_rank()
    toks = {r["lookup"] for r in rows if "_" in r["lookup"] or r["lookup"] in reg}
    fm = first_mentions({r["lookup"] for r in rows})
    policies: dict = {}

    policies["spine"] = [dict(r, why="curriculum order") for r in rows]

    dig_sorted = sorted(enumerate(rows), key=lambda t: (dr.get(t[1]["lookup"], 2), t[0]))
    policies["dig"] = [dict(r, why=("load-bearing" if dr.get(r["lookup"], 2) == 0
                                    else "promoted from depth" if dr.get(r["lookup"], 2) == 1
                                    else "not named by the dig"))
                       for _, r in dig_sorted]

    size_sorted = sorted(enumerate(rows), key=lambda t: (size_of(reg, t[1]["lookup"]), t[0]))
    policies["size"] = [dict(r, why=f"footprint {size_of(reg, r['lookup']):.1f}")
                        for _, r in size_sorted]

    def text_key(i_row):
        i, r = i_row
        pos = fm.get((r.get("map", ""), r["lookup"]))
        if pos is None:
            # any page at all, else it sinks below everything the writing names
            cands = [v for (mp, tk), v in fm.items() if tk == r["lookup"]]
            pos = min(cands) if cands else 10_000_000
        return (pos, i)
    text_sorted = sorted(enumerate(rows), key=text_key)
    policies["text"] = []
    for i, r in text_sorted:
        pos, _ = text_key((i, r))
        policies["text"].append(dict(r, why=("named in prose" if pos < 10_000_000
                                             else "never named by any text")))

    named = sum(1 for e in policies["text"] if e["why"] == "named in prose")
    return {
        "_readme": "Declared artifact-order policies (unification step 4, "
                   "doc/plans/template_museum_unification.md). Same shape as "
                   "spine_artifact_order.json so the endless museum reads any of them "
                   "with one flag: --em-order=<policy>. Every entry carries WHY it "
                   "sits where it does. Provenance: measured. Regenerate after map, "
                   "dig or writing passes.",
        "generated": "2026-08-04",
        "policies_available": sorted(policies),
        "counts": {k: len(v) for k, v in policies.items()},
        "text_named": named,
        "policies": policies,
    }


def tau(a: list, b: list) -> float:
    """Kendall tau-b over the shared tokens (sampled — 799 items is 319k pairs)."""
    ra = {t: i for i, t in enumerate(a)}
    rb = {t: i for i, t in enumerate(b)}
    common = [t for t in a if t in rb]
    step = max(1, len(common) // 180)
    s = common[::step]
    con = dis = 0
    for i in range(len(s)):
        for j in range(i + 1, len(s)):
            d = (ra[s[i]] - ra[s[j]]) * (rb[s[i]] - rb[s[j]])
            if d > 0:
                con += 1
            elif d < 0:
                dis += 1
    return (con - dis) / (con + dis) if con + dis else 0.0


def compare(payload: dict) -> None:
    pol = payload["policies"]
    names = sorted(pol)
    seqs = {k: [e["lookup"] for e in v] for k, v in pol.items()}
    print("agreement with the curriculum order (Kendall tau, sampled):")
    for n in names:
        if n == "spine":
            continue
        print(f"  spine vs {n:6} tau {tau(seqs['spine'], seqs[n]):+.3f}")
    print("\nthe first eight each policy would deal:")
    for n in names:
        print(f"  {n:6} " + ", ".join(e["lookup"] for e in pol[n][:8]))


def selftest() -> int:
    payload = build()
    pol = payload["policies"]
    ok = []
    ok.append(("A every policy deals the same cast",
               len({len(v) for v in pol.values()}) == 1,
               str({k: len(v) for k, v in pol.items()})))
    ok.append(("B every policy is a permutation, not a filter",
               all({e["lookup"] for e in v} == {e["lookup"] for e in pol["spine"]}
                   for v in pol.values()), "sets equal"))
    ok.append(("C every entry carries a reason",
               all(e.get("why") for v in pol.values() for e in v), "why present"))
    t = tau([e["lookup"] for e in pol["spine"]], [e["lookup"] for e in pol["text"]])
    ok.append(("D text order actually differs from spine", abs(t) < 0.95, f"tau {t:+.3f}"))
    lb = [e for e in pol["dig"][:40] if e["why"] == "load-bearing"]
    ok.append(("E dig puts load-bearing first", len(lb) > 0,
               f"{len(lb)} load-bearing in the first 40"))
    for label, good, detail in ok:
        print(f"  {'PASS' if good else 'FAIL'}  {label}: {detail}")
    n = sum(1 for _, g, _ in ok if g)
    print(f"self-test: {n}/{len(ok)} controls passed")
    return 0 if n == len(ok) else 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--compare", action="store_true")
    ap.add_argument("--self-test", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return selftest()
    payload = build()
    print(f"{len(payload['policies'])} policies over {payload['counts']['spine']} artifacts "
          f"· {payload['text_named']} named in prose")
    if args.compare:
        compare(payload)
    if args.dry_run:
        print("(--dry-run: nothing written)")
        return 0
    OUT.write_text(json.dumps(payload, indent=1), encoding="utf-8")
    print(f"-> {OUT.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
