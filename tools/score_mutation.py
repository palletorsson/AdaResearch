#!/usr/bin/env python3
"""score_mutation.py — measure a MUTANT against its PARENT, which is the control.

Waves 2-24 built SYNTHESES: one new artifact from two or more sources, scored by ranking its
own pairs against each other. That has no external reference. If a synthesis measures 3% on
its closest pair, 3% of what? The only answer available was "of its own other pairs".

A MUTATION is different in the one way that matters. It has ONE parent and ONE changed gene,
so the parent is a control and the comparison is PAIRED: the same axis value, rendered by two
artifacts that differ in exactly one respect. That licenses claims the synthesis form cannot
make — above all the negative one. Wave 22 could only say "this axis measures 4.37%, which
looks weak"; a knockout can say "with the gene disabled the axis stops varying, and with it
present it varies by X" — an INERT verdict earned by INTERVENTION rather than by observation
from one standpoint.

THREE READINGS, and they answer different questions:

  drift    per value, parent frame vs mutant frame. How far the mutation moved each rung.
           A mutation that claims to touch only one rung must leave the others near zero —
           this is the specificity check, and it is the one most likely to fail quietly.
  spread   within each artifact, how much its own axis varies across values. A KNOCKOUT
           should show parent spread high and mutant spread ~0. An ENHANCEMENT the reverse.
  rescue   for a mutation that restores something (splitting an all-rungs value, repairing a
           dead default), whether the rung that was flat in the parent now moves.

WHY THE PAIRED FORM IS WORTH THE TROUBLE. Everything this programme has learned about its own
instruments came from a number that turned out to be about the rig: depth at sin(0.26) = 0.257,
a colour axis invisible to luminance, a subject at 2.26% of frame after a fit-by-diagonal, a
count metric that cannot rank a colour axis. A PAIRED difference cancels all of them. Parent and
mutant are shot from the same standpoint at the same framing with the same metric, so whatever
the rig does badly, it does identically to both — and the difference is about the gene.

Usage:
  python tools/score_mutation.py --parent=<token> --mutant=<token> --axis=<name> [--slug=<dir>]
  python tools/score_mutation.py --parent=<token> --mutant=<token> --axis=<name> --kind=knockout

Reads frames from ada_encyclopedia/public/<slug>/ (defaults to searching every gallery dir).
Writes doc/reports/mutation_<parent>__<mutant>.json
"""
from __future__ import annotations
import json, pathlib, sys, collections

REPO = pathlib.Path(__file__).resolve().parents[1]
REG = REPO / "commons" / "artifacts" / "registry"
ENC = REPO.parent / "ada_encyclopedia"


def load_entries() -> dict:
    out = {}
    for f in REG.glob("*.json"):
        try:
            d = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        for t, e in (d.get("artifacts") or {}).items():
            out[t] = e
    return out


def frames_for(tok: str, slug: str | None) -> dict:
    """value-tuple -> png path, for every rendered variant of a token."""
    pub = ENC / "public"
    roots = [pub / slug] if slug else [p for p in pub.iterdir() if p.is_dir()]
    out = {}
    for root in roots:
        if not root.is_dir():
            continue
        for p in root.glob(f"{tok}__*.png"):
            key = tuple(sorted(p.stem.split("__")[1:]))
            out.setdefault(key, p)
    return out


def luma_delta(a: pathlib.Path, b: pathlib.Path) -> tuple:
    """(mean |luma delta| %, share of pixels moving more than 12/255 %)."""
    from PIL import Image, ImageChops
    ia, ib = Image.open(a).convert("L"), Image.open(b).convert("L")
    if ia.size != ib.size:
        ib = ib.resize(ia.size)
    d = list(ImageChops.difference(ia, ib).getdata())
    n = len(d)
    return (100.0 * (sum(d) / n) / 255.0, 100.0 * sum(1 for v in d if v > 12) / n)


def axis_values(entry: dict, axis: str) -> list:
    spec = ((entry.get("dna") or {}).get("axes") or {}).get(axis)
    vals = spec.get("values") if isinstance(spec, dict) else spec
    return [str(v) for v in (vals or [])]


def main() -> int:
    parent = mutant = axis = slug = kind = ""
    for a in sys.argv[1:]:
        for k in ("parent", "mutant", "axis", "slug", "kind"):
            if a.startswith(f"--{k}="):
                v = a.split("=", 1)[1]
                if k == "parent": parent = v
                elif k == "mutant": mutant = v
                elif k == "axis": axis = v
                elif k == "slug": slug = v
                else: kind = v
    if not (parent and mutant and axis):
        print(__doc__); return 2

    ent = load_entries()
    for t in (parent, mutant):
        if t not in ent:
            print(f"{t}: not in any registry file"); return 2

    pv, mv = axis_values(ent[parent], axis), axis_values(ent[mutant], axis)
    shared = [v for v in pv if v in mv]
    print(f"parent {parent}.{axis}: {pv}")
    print(f"mutant {mutant}.{axis}: {mv}")
    print(f"shared values: {shared}")
    if not shared:
        print("\nNo shared value. A mutation is one changed gene against a common background;\n"
              "with no rung in common there is no paired comparison and this is a synthesis,\n"
              "not a mutation. Score it with score_wave.py instead.")
        return 1
    added, lost = [v for v in mv if v not in pv], [v for v in pv if v not in mv]
    if added: print(f"gained rungs : {added}")
    if lost:  print(f"lost rungs   : {lost}")

    pf, mf = frames_for(parent, slug), frames_for(mutant, slug)
    if not pf or not mf:
        print(f"\nno frames found (parent {len(pf)}, mutant {len(mf)}) — sweep both first")
        return 1

    def pick(frames, val):
        want = f"{axis}-{val}"
        hits = [k for k in frames if any(x == want for x in k)]
        return frames[sorted(hits, key=len)[0]] if hits else None

    # ---- drift: the same rung, two artifacts -----------------------------
    print(f"\nDRIFT — the same rung rendered by parent and mutant (paired, so the rig cancels)")
    print(f"  {'value':<18}{'mean|dL|':>10}{'moved%':>9}")
    drift = {}
    for v in shared:
        a, b = pick(pf, v), pick(mf, v)
        if not (a and b):
            print(f"  {v:<18}{'— not rendered in both':>19}"); continue
        m, mv2 = luma_delta(a, b)
        drift[v] = dict(mean=round(m, 3), moved=round(mv2, 2))
        print(f"  {v:<18}{m:>10.3f}{mv2:>9.2f}")

    # ---- spread: does each artifact's own axis vary? ----------------------
    def spread(frames, vals, who):
        pts = [(v, pick(frames, v)) for v in vals]
        pts = [(v, p) for v, p in pts if p]
        rows = []
        for i in range(len(pts)):
            for j in range(i + 1, len(pts)):
                m, _ = luma_delta(pts[i][1], pts[j][1])
                rows.append((m, pts[i][0], pts[j][0]))
        if not rows:
            return None
        rows.sort()
        print(f"  {who:<10}{len(rows):>3} pairs   min {rows[0][0]:.3f} ({rows[0][1]}/{rows[0][2]})"
              f"   max {rows[-1][0]:.3f}   mean {sum(r[0] for r in rows)/len(rows):.3f}")
        return dict(n=len(rows), min=round(rows[0][0], 3), max=round(rows[-1][0], 3),
                    mean=round(sum(r[0] for r in rows) / len(rows), 3),
                    closest=[rows[0][1], rows[0][2]])

    print(f"\nSPREAD — how much each artifact's own `{axis}` varies")
    sp = spread(pf, pv, "parent"), spread(mf, mv, "mutant")

    verdict = ""
    if sp[0] and sp[1]:
        pm, mm = sp[0]["mean"], sp[1]["mean"]
        ratio = (mm / pm) if pm else float("inf")
        print(f"\n  mutant/parent spread ratio: {ratio:.3f}")
        if kind == "knockout":
            # A knockout SUCCEEDS by flattening. That is the one case in this whole programme
            # where a small number is the wanted result rather than a suspect one — and it is
            # only readable because the parent is measured in the same breath.
            verdict = ("KNOCKED OUT — the axis stops varying without the gene"
                       if ratio < 0.15 else
                       "PARTIAL — the axis still varies with the gene disabled" if ratio < 0.6 else
                       "NOT KNOCKED OUT — disabling the gene changed nothing about the axis")
        else:
            verdict = ("mutation SUPPRESSED the axis" if ratio < 0.6 else
                       "mutation AMPLIFIED the axis" if ratio > 1.6 else
                       "axis carries at comparable strength in both")
        print(f"  {verdict}")

    out = dict(parent=parent, mutant=mutant, axis=axis, kind=kind or "unspecified",
               shared=shared, gained=added, lost=lost, drift=drift,
               parent_spread=sp[0], mutant_spread=sp[1], verdict=verdict)
    dest = REPO / "doc" / "reports" / f"mutation_{parent}__{mutant}.json"
    dest.write_text(json.dumps(out, indent=1), encoding="utf-8")
    print(f"\n-> {dest.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
