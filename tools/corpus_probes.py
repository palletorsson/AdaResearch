#!/usr/bin/env python3
"""
corpus_probes.py — every hard-won case from a session, re-asked of the whole corpus.

THE METHOD THIS EXISTS TO MAKE CHEAP. A fault gets found by looking at one artifact, usually
expensively: cctv's dead axis took a render and a byte-comparison, the substrate gap took a
survey, info_board's tiling trap took arithmetic on a scene file. The finding is then worth
far more as a QUESTION asked of all 2,671 entries than as one fix, because the answer is
either "this was unique" or "there are sixteen more" — and both are results.

Run after any session that discovers something. A probe whose count RISES is a regression;
a probe that stays at its baseline is a class that is no longer coming back.

WHAT EACH PROBE COST TO LEARN, and what it returned when first asked corpus-wide:

  hidden_family        The corpus's most common structural shape, found BY HAND seven times
                       (curation_station's booleans, four grab spheres, the pickup cubes,
                       the synth racks, the translation cubes, looms, mills). Then found
                       mechanically at a scale nobody had seen: all 104 substrates are six
                       scenes under 104 names. A scene with many registry names is a family
                       whether or not anyone declared it; the names ARE the axis values.

  unreadable_values    Why those 104 were never declared. The value list lives in a TYPED
                       GODOT ENUM, and code_values() reads @export_enum(strings), const
                       dispatch tables and match blocks — not `enum Foo {A, B}`. An entire
                       category was invisible to the DNA system for one unread syntax.

  root_scale_trap      info_board's .tscn bakes a 0.2 root scale, and PbrKit's triplanar is
                       LOCAL, so every tiling number lands 5x too fine and a texture feature
                       falls on 0.7 pixels. That is the dome static, which cost eleven
                       renders and six wrong hypotheses. Asked corpus-wide: ONE artifact.
                       A genuine one-off, and worth knowing it is one.

  axis_barely_read     TrigWalkingPath declared `provision` and had a PROVISIONS allow-list,
                       and nothing anywhere read either — declared, gated green, INERT in the
                       render. Asked corpus-wide: one, and that one is numeric where it is
                       expected.

A PROBE IS NOT A GATE. These report; check_dna_declarations.py is what fails a build. The
split is deliberate: a probe's job is to find out whether a thing is a pattern, and a
question that fails the build the first time it is asked can never be asked honestly.

Usage:
  python tools/corpus_probes.py                # run all, compare against baselines
  python tools/corpus_probes.py --probe=hidden_family --verbose
  python tools/corpus_probes.py --record       # write current counts as the new baseline
"""
from __future__ import annotations
import collections
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))
from check_dna_declarations import (  # noqa: E402
    registry, source_for, sources_for, code_values)

BASELINE = REPO / "doc" / "reports" / "corpus_probes_baseline.json"


def _axes(entry: dict) -> dict:
    return ((entry.get("dna") or {}).get("axes") or {})


def _scene_text(entry: dict):
    sp = str(entry.get("scene", "") or "").replace("res://", "")
    if not sp.endswith(".tscn"):
        return None, None
    p = REPO / sp
    if not p.exists():
        return sp, None
    try:
        return sp, p.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return sp, None


def probe_token_collision(reg: dict) -> list:
    """One registry NAME pointing at two or more DIFFERENT scenes.

    Found by using the tooling rather than by reading it. Declaring living_paper wrote a
    perfectly valid block that no reader could see: the token is in living_paper.json AND
    primitives.json, both naming a scene, and those are two genuinely different artifacts
    that happen to share a name. Sorted-order last-write-wins resolves the bare token to the
    primitives one, so the 33-name substrate family is shadowed by a same-named primitive.

    This is worse than an ordinary duplicate. A map placing the token gets whichever entry
    wins the sort; the other artifact is unreachable by that name and nothing says so.
    """
    import collections as _c
    scenes = _c.defaultdict(set)
    for tok, (e, _f) in reg.items():
        pass                                    # reg is already deduplicated; read files
    import json as _j
    REGDIR = REPO / "commons" / "artifacts" / "registry"
    files = _c.defaultdict(set)
    for f in sorted(REGDIR.glob("*.json")):
        try:
            d = _j.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        arts = d.get("artifacts", d)
        if not isinstance(arts, dict):
            continue
        for tok, e in arts.items():
            if not isinstance(e, dict):
                continue
            sp = str(e.get("scene") or e.get("scene_path") or "").strip()
            if sp:
                scenes[tok].add(sp)
                files[tok].add(f.name)
    return sorted((tok, sorted(s), sorted(files[tok]))
                  for tok, s in scenes.items() if len(s) > 1)


def probe_hidden_family(reg: dict) -> list:
    """Scenes worn by 3+ registry names where most of the family is undeclared.

    The names are already the axis: living_paper_mandelbrot and living_paper_life are one
    scene choosing a cartridge from get_meta("artifact_lookup_name"). A family like this is
    a promotion that is already implemented and simply never written down.
    """
    byscene = collections.defaultdict(list)
    for tok, (e, _f) in reg.items():
        sp = str(e.get("scene", "") or "").strip()
        if sp:
            byscene[sp].append(tok)
    hits = []
    for sp, toks in byscene.items():
        if len(toks) < 3:
            continue
        dec = sum(1 for t in toks if _axes(reg[t][0]))
        if dec * 2 >= len(toks):          # already mostly declared: not a finding
            continue
        hits.append((len(toks), dec, sp.split("/")[-1], sorted(toks)))
    return sorted(hits, reverse=True)


def probe_unreadable_values(reg: dict) -> list:
    """Artifacts whose axis-shaped export exists but whose values the deriver cannot read.

    A typed `enum` is the form this corpus's whole substrate category uses, and it is the one
    form code_values() has no branch for. These are declarable the moment it does.
    """
    hits = []
    seen_src = set()
    for tok, (e, _f) in sorted(reg.items()):
        pairs = sources_for(e)
        src = "".join(t for _p, t in pairs if isinstance(t, str))
        key = "|".join(str(_p) for _p, _t in pairs)
        if not src or key in seen_src:
            continue
        seen_src.add(key)
        m = re.search(r"^\s*enum\s+(\w+)\s*\{([^}]*)\}", src, re.M | re.S)
        if not m:
            continue
        members = [x.strip().split("=")[0].strip() for x in m.group(2).split(",") if x.strip()]
        exp = re.search(r"@export var (\w+)\s*:\s*" + re.escape(m.group(1)), src)
        if not exp:
            continue
        vals, _how = code_values(src, exp.group(1))
        if vals:
            continue                       # readable: nothing to report
        hits.append((len(members), tok, exp.group(1), m.group(1), bool(_axes(e))))
    return sorted(hits, reverse=True)


def probe_root_scale_trap(reg: dict) -> list:
    """Root transform scale != 1 on a scene whose script uses LOCAL triplanar tiling."""
    hits = []
    for tok, (e, _f) in sorted(reg.items()):
        sp, raw = _scene_text(e)
        if not raw:
            continue
        nodes = raw.split("[node ")
        if len(nodes) < 2:
            continue
        m = re.search(r"transform = Transform3D\(([-\d.e, ]+)\)", nodes[1])
        if not m:
            continue
        v = [float(x) for x in m.group(1).split(",") if x.strip()]
        if len(v) < 9:
            continue
        s = (v[0] ** 2 + v[1] ** 2 + v[2] ** 2) ** 0.5
        if abs(s - 1.0) <= 0.02:
            continue
        _gd, src = source_for(e)
        if not src or not re.search(r"(PbrKit|PBR)\.|triplanar", src):
            continue
        hits.append((round(s, 3), tok, sp))
    return sorted(hits)


def probe_axis_barely_read(reg: dict) -> list:
    """A declared axis mentioned <=2 times in its OWN SCRIPTS: declared, never consumed.

    EVERY script the scene runs, plus what they inherit from — not just the one the name
    resolves to. The first run of this probe used the singular resolver and reported five
    axes with ZERO mentions, all five false: draw_dot_time_domain.retention reads 0 in its
    own file and 10 across the two scripts it actually runs; tessellation_lattice_demo.cell
    reads 0 and 23. The axes were fine; the probe was looking in one of two places. That is
    the same fault the gate documents at sources_for, arriving here because this probe
    reached for the convenient function instead of the correct one.
    """
    hits = []
    for tok, (e, _f) in sorted(reg.items()):
        ax = _axes(e)
        if not ax:
            continue
        src = "".join(t for _p, t in sources_for(e) if isinstance(t, str))
        if not src:
            continue
        for a in ax:
            n = len(re.findall(r"\b" + re.escape(a) + r"\b", src))
            if n <= 2:
                hits.append((n, tok, a))
    return sorted(hits)


PROBES = {
    "token_collision": (probe_token_collision,
                        "one registry NAME pointing at two different scenes"),
    "hidden_family": (probe_hidden_family,
                      "one scene worn by 3+ registry names, mostly undeclared"),
    "unreadable_values": (probe_unreadable_values,
                          "axis values in a typed enum the deriver cannot read"),
    "root_scale_trap": (probe_root_scale_trap,
                        "root scale != 1 with local triplanar: tiling off by that factor"),
    "axis_barely_read": (probe_axis_barely_read,
                         "declared axis its own source barely mentions"),
}


def main() -> int:
    only, verbose, record = "", "--verbose" in sys.argv, "--record" in sys.argv
    for a in sys.argv[1:]:
        if a.startswith("--probe="):
            only = a.split("=", 1)[1]
    reg = registry()
    base = {}
    if BASELINE.exists():
        try:
            base = json.loads(BASELINE.read_text(encoding="utf-8")).get("counts", {})
        except Exception:
            base = {}
    counts, drift = {}, 0
    for name, (fn, blurb) in PROBES.items():
        if only and name != only:
            continue
        hits = fn(reg)
        counts[name] = len(hits)
        was = base.get(name)
        mark = ""
        if was is not None and len(hits) != was:
            mark = f"   <-- was {was}"
            drift += 1
        print(f"\n=== {name}  ({len(hits)}){mark}")
        print(f"    {blurb}")
        show = hits if verbose else hits[:6]
        for h in show:
            print(f"      {h}")
        if len(hits) > len(show):
            print(f"      ... {len(hits)-len(show)} more (--verbose)")
    if record:
        BASELINE.write_text(json.dumps({
            "_note": "Counts at the time of recording. A probe that RISES is a regression; "
                     "one that holds is a class that stopped coming back. Re-record only "
                     "when the change is understood and intended.",
            "counts": counts}, indent=1), encoding="utf-8")
        print(f"\nbaseline written -> {BASELINE.relative_to(REPO)}")
    elif base:
        print(f"\n{drift} probe(s) moved from baseline")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
