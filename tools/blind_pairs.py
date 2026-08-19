# -*- coding: utf-8 -*-
"""blind_pairs.py — the first number about this project we did not author.

Every score the composer has been judged by, we wrote. The rounds optimised
against a rubric in our own canon; grammar_fit induces rules in the canon's own
vocabulary, so a map composed from those operations is trivially more
describable by them. That gap may be real or tautological and no amount of
re-running it will say which.

This puts the CORPUS on the other side of the comparison. For each of N authored
maps it composes a machine map from the same cast, renders one eye shot of each
by the SAME RULE, and shuffles them into unlabelled pairs. The judge answers two
questions per pair, and they are kept apart on purpose because they are not the
same claim:

    which of these is machine-made?      -> discrimination (50% = indistinguishable)
    which would you rather walk?         -> preference

Passing as human and being better are different results. A harness that reports
one number cannot tell you which one it found.

    python tools/blind_pairs.py build --pairs 10
    <render: one godot run per map, the tool prints the commands>
    python tools/blind_pairs.py assemble

Stages are separate because the render is the slow part and must be serialised —
two Godot instances race on the user:// lock and the second dies silently.
"""
import json, math, random, argparse, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAPS = ROOT / "commons/maps"
WORK = ROOT / "commons/data/blind_pairs"
PRE = ("cluster:", "mc:", "gridagent:", "criticalinfo:")
COMPOSED_PREFIX = ("Thread_Gate", "Trial_", "Track_", "Wizard_", "Probe_", "Dwell_", "BP_")

sys.path.insert(0, str(ROOT / "tools"))
import walk_polish as wp                      # noqa: E402  (route + grids)
import wizard_compose as wc                   # noqa: E402  (the composer under test)


def cells(md):
    S = (md.get("layers") or md).get("structure") or []
    return len(S) * max((len(r) for r in S), default=0)


def cast_of(md):
    """The artifacts an authored map actually stands on its floor."""
    I = (md.get("layers") or md).get("interactables") or []
    seen = []
    for row in I:
        for c in row:
            t = str(c).strip().split(":")[0]
            if t and not str(c).strip().startswith(PRE) and not t.startswith("hangar_"):
                if t not in seen:
                    seen.append(t)
    return seen


# PROVENANCE, and the surprise that made it necessary. The first build drew ten
# "authored" maps and four of them were machine output from OLDER generators —
# germinate, wave-function-collapse, the random-room families. At the scale
# where this comparison is interesting (700-1600 cells) the corpus is mostly
# already simulated: of 37 candidates only about a dozen look hand-made. So the
# question "can we beat the maps we have" is largely "can this composer beat the
# project's earlier generators", and a harness that called all of them AUTHORED
# would have reported a machine-vs-machine draw as indistinguishability.
#
# Provenance is inferred from naming families, because nothing stamps it: no map
# outside the wizard carries a design block. Inference is not proof, and the key
# records the class so a wrong call can be found later rather than believed.
LEGACY_MARKERS = (
    "Auto_", "Germ_", "GermAxis_", "Mission_", "MissionWFC_", "MissionDerive_",
    "Room_Random", "Room_Randomness", "Dollhouse_Random", "Archetype_", "MapSim_",
    "TemplateMap_", "Structure_Examples", "Script_",
)


def provenance(name):
    if name.startswith(COMPOSED_PREFIX):
        return "composed"
    if name.endswith("_composed") or name.startswith(LEGACY_MARKERS):
        return "legacy"                    # machine-made, by an older generator
    return "hand"                          # presumed hand-authored; not provable


def select_authored(n, lo=700, hi=1600, min_cast=5, seed=46, want="hand"):
    """Maps in the band where the comparison is fair.

    The composer's gates run about 1100 cells; the corpus median is 195. A pair
    at different scales measures scale, not authorship — and the interesting
    claim is precisely about SIZE, since authored maps drift out of the alive
    band as they grow. So the other side is drawn from the same band.
    """
    out = []
    for d in sorted(MAPS.iterdir()):
        if not (d / "map_data.json").exists():
            continue
        if provenance(d.name) != want:
            continue
        try:
            md = json.loads((d / "map_data.json").read_text(encoding="utf-8"))
        except Exception:
            continue
        if not (lo <= cells(md) <= hi):
            continue
        cast = cast_of(md)
        if len(cast) < min_cast:
            continue
        out.append((d.name, cast))
    random.Random(seed).shuffle(out)
    return out[:n]


def compose_match(cast):
    """The composer's best, from the same cast. Everything the pipeline does
    today, op 10 included — the question is what we SHIP, not what we could."""
    spec = dict(wc.DEFAULT_SPEC)
    spec["cast"] = cast[:7]
    spec["hero"] = cast[0]
    spec["anti"] = cast[-1] if len(cast) > 7 else ""
    spec["dwell"] = {"enabled": True, "budget": 12}
    spec["_recipe_keys"] = sorted(spec.keys())     # everything here is explicit
    data, stages = wc.compose(spec)
    return data, stages


def station_for(md):
    """ONE RULE for both sides: stand a third of the way along the walk, facing
    the way the walk goes. Choosing each viewpoint by hand would make the
    harness the thing being judged."""
    S, U, I, WL = wp.grids(md)
    order, floor, dist, route = wp.walk(md)
    if len(route) < 4:
        route = order[:max(4, len(order) // 3)]
    i = max(1, len(route) // 3)
    c = route[min(i, len(route) - 2)]
    nxt = route[min(i + 1, len(route) - 1)]
    facing = (nxt[0] - c[0], nxt[1] - c[1])
    if facing not in wp.DIRS:
        facing = (0, 1)
    return {"cell": [c[0], c[1]], "facing": [facing[0], facing[1]],
            "y": max(0, wp.h_at(S, *c)), "pitch": -3.0, "tag": "v"}


def build(n, seed):
    WORK.mkdir(parents=True, exist_ok=True)
    # Two opponents, reported apart. Beating the project's older generators and
    # beating a hand-made map are different claims and a single average hides
    # which one happened.
    hand = select_authored(n, seed=seed, want="hand")
    legacy = select_authored(max(0, n - len(hand)) or n // 3, seed=seed, want="legacy")
    picks = [(nm, c, "hand") for nm, c in hand] + [(nm, c, "legacy") for nm, c in legacy]
    picks = picks[:n]
    print("opponents: %d hand-authored, %d legacy-generated"
          % (sum(1 for p in picks if p[2] == "hand"),
             sum(1 for p in picks if p[2] == "legacy")))
    rng = random.Random(seed)
    key, shots = [], []
    for idx, (name, cast, klass) in enumerate(picks, 1):
        authored = json.loads((MAPS / name / "map_data.json").read_text(encoding="utf-8"))
        try:
            composed, _ = compose_match(cast)
        except Exception as exc:
            print("  pair %02d SKIPPED (%s did not compose: %s)" % (idx, name, exc))
            continue
        sides = [(klass, authored, name), ("composed", composed, "composer")]
        rng.shuffle(sides)                       # A/B decided by coin, not by order
        rec = {"pair": idx, "opponent_map": name, "opponent_class": klass,
               "cast": len(cast)}
        for letter, (kind, md, origin) in zip("AB", sides):
            slug = "BP_%02d%s" % (idx, letter)
            d = MAPS / slug
            d.mkdir(exist_ok=True)
            for k in ("name", "lookup_name", "title"):
                md.setdefault("map_info", {})[k] = slug
            (d / "map_data.json").write_text(json.dumps(md), encoding="utf-8")
            st = station_for(md)
            (WORK / ("%s.stations.json" % slug)).write_text(
                json.dumps({"map": slug, "stations": [st]}), encoding="utf-8")
            rec[letter] = {"kind": kind, "origin": origin, "cells": cells(md),
                           "station": st["cell"], "facing": st["facing"]}
            shots.append(slug)
        key.append(rec)
        # NOT printed: which letter is which. The first run of this tool put
        # "A=composed B=hand" on the terminal for every pair, which disqualifies
        # whoever read it from judging. A blind harness that narrates its own key
        # is not blind.
        print("  pair %02d  %-30s %-6s cast %2d   built"
              % (idx, name, klass, len(cast)))
    (WORK / "key.json").write_text(json.dumps({"seed": seed, "pairs": key}, indent=1),
                                   encoding="utf-8")
    lines = ["# render these, one at a time (two Godot instances race the user:// lock)", ""]
    for slug in shots:
        lines.append(
            'python tools/godot_watchdog.py --expect="%%APPDATA%%/Godot/app_userdata/'
            'Ada Research Zero One/blind/%s_v.png" -- '
            '"C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . --xr-mode off '
            '--no-window --script res://commons/testing/capture_eye_stations.gd -- '
            '--map=%s --stations=commons/data/blind_pairs/%s.stations.json '
            '--outdir=user://blind' % (slug, slug, slug))
    (WORK / "render.txt").write_text("\n".join(lines), encoding="utf-8")
    print("\n%d pairs, %d maps to render -> commons/data/blind_pairs/render.txt" %
          (len(key), len(shots)))
    print("KEY IS HIDDEN IN key.json — do not read it before judging.")


def assemble(shots_dir):
    """Collect the renders into a sheet the judge can answer without seeing which
    is which. The key stays in a separate file nobody opens until the answers
    are written down."""
    src = pathlib.Path(shots_dir)
    key = json.loads((WORK / "key.json").read_text(encoding="utf-8"))
    rows, missing = [], 0
    for rec in key["pairs"]:
        i = rec["pair"]
        pa, pb = src / ("BP_%02dA_v.png" % i), src / ("BP_%02dB_v.png" % i)
        if not (pa.exists() and pb.exists()):
            missing += 1
            continue
        rows.append((i, pa, pb))
    sheet = ["# Blind pairs — answer before opening key.json", "",
             "Two questions per pair. They are different questions; answer both.", "",
             "| pair | which is machine-made? (A/B) | which would you rather walk? (A/B) | note |",
             "|---|---|---|---|"]
    for i, _, _ in rows:
        sheet.append("| %02d |  |  |  |" % i)
    sheet += ["", "Scoring: discrimination = share of pairs where the machine was "
              "correctly named. 50%% means indistinguishable, and note that 20%% is a "
              "result too — it means the machine map reads as the more human one.",
              "Preference is scored separately and means nothing about discrimination."]
    (WORK / "sheet.md").write_text("\n".join(sheet), encoding="utf-8")
    print("%d pairs ready, %d missing renders -> commons/data/blind_pairs/sheet.md" %
          (len(rows), missing))
    return rows


def _wilson(k, n, z=1.96):
    """Wilson interval — an honest error bar on a small sample. Ten pairs cannot
    prove indistinguishability; they can only fail to find a difference, and the
    width of this interval is the difference between those two sentences."""
    if not n:
        return 0.0, 1.0
    p = k / float(n)
    d = 1 + z * z / n
    c = p + z * z / (2 * n)
    s = z * ((p * (1 - p) / n + z * z / (4 * n * n)) ** 0.5)
    return max(0.0, (c - s) / d), min(1.0, (c + s) / d)


def score():
    """Read the filled sheet against the key. Kept in the tool so the arithmetic
    is not done by the person who wants a particular answer."""
    key = {r["pair"]: r for r in json.loads((WORK / "key.json").read_text(encoding="utf-8"))["pairs"]}
    text = (WORK / "sheet.md").read_text(encoding="utf-8")
    named = pref = answered = pref_answered = 0
    by_class = {}
    for line in text.splitlines():
        if not line.startswith("| ") or "which" in line or line.startswith("|---"):
            continue
        cols = [c.strip() for c in line.strip("|").split("|")]
        if len(cols) < 3 or not cols[0].isdigit():
            continue
        p = int(cols[0])
        if p not in key or not cols[1]:
            continue
        answered += 1
        klass = key[p].get("opponent_class", "hand")
        by_class.setdefault(klass, [0, 0, 0, 0])
        by_class[klass][0] += 1
        if key[p].get(cols[1].upper(), {}).get("kind") == "composed":
            named += 1; by_class[klass][1] += 1
        if cols[2]:
            by_class[klass][3] += 1
            pref_answered += 1
            if key[p].get(cols[2].upper(), {}).get("kind") == "composed":
                pref += 1; by_class[klass][2] += 1
    if not answered:
        print("no answers in sheet.md yet")
        return
    print("answered %d pairs" % answered)
    print("  discrimination : %d/%d = %.0f%% named the machine correctly (50%% = indistinguishable)"
          % (named, answered, 100.0 * named / answered))
    # An unanswered question is not a vote against. The first run of this
    # reported "0% preferred the machine" when the preference column was simply
    # blank — a missing measurement dressed as a finding, which is the exact
    # failure this harness exists to prevent.
    if pref_answered:
        print("  preference     : %d/%d = %.0f%% preferred the machine's map"
              % (pref, pref_answered, 100.0 * pref / pref_answered))
    else:
        print("  preference     : NOT ANSWERED (0 of %d) — no result, not a zero" % answered)
    for k, (tot, nm, pf, pa) in sorted(by_class.items()):
        print("  vs %-6s      : n=%d  named %.0f%%  preference %s"
              % (k, tot, 100.0 * nm / tot,
                 ("%.0f%% (n=%d)" % (100.0 * pf / pa, pa)) if pa else "not answered"))
    # how surprised should we be? exact two-sided binomial against a coin
    from math import comb
    k_ = min(named, answered - named)
    tail = sum(comb(answered, i) for i in range(0, k_ + 1)) / float(2 ** answered)
    lo, hi = _wilson(named, answered)
    print("  against chance : two-sided p = %.2f   95%% CI [%.0f%%, %.0f%%]"
          % (min(1.0, 2 * tail), 100 * lo, 100 * hi))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("stage", choices=["build", "assemble", "score", "clean"])
    ap.add_argument("--pairs", type=int, default=10)
    ap.add_argument("--seed", type=int, default=46)
    ap.add_argument("--shots", default=str(pathlib.Path.home() /
                    "AppData/Roaming/Godot/app_userdata/Ada Research Zero One/blind"))
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")
    if a.stage == "build":
        build(a.pairs, a.seed)
    elif a.stage == "assemble":
        assemble(a.shots)
    elif a.stage == "score":
        score()
    else:
        for d in MAPS.glob("BP_*"):
            for f in d.iterdir():
                f.unlink()
            d.rmdir()
        print("removed the BP_ scratch maps (key, sheet and renders kept)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
