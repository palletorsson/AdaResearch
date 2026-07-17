"""text_to_target.py — edge-12: the text compiles into the desire target.

The full L-017/P-6 loop: a map's tutorial.md (and walked.md's turn) become
its desire curves. Segments are read off the text — prose and fenced code
alternate; a prose block that opens an invitation (try/change/tweak/
experiment) is a TRY segment and contracts a hand spike right after it.
Loads are computed (prose 220 wpm, code 80 wpm). Emphasis comes from the
script's hero (the axis climax) and walked.md's turn (noted beside it).

  python tools/text_to_target.py --scripts doc/book/look_scripts/primitives.json

Targets land in doc/book/look_scripts/desire_targets/<Map>.json — the same
files /desire-timeline edits and script_compose chases (FIT). The seeded
shadows of the composed maps are REPLACED by text-derived curves: from here
on the writing times and shapes the room.
"""
import argparse
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPS_DIR = os.path.join(ROOT, "commons", "maps")
TARGETS_DIR = os.path.join(ROOT, "doc", "book", "look_scripts", "desire_targets")

PROSE_WPM, CODE_WPM = 220.0, 80.0
N = 16
TRY_RE = re.compile(r"\b(try|experiment|exercise|change the|tweak|adjust|now you)\b", re.I)


def segments_of(map_name):
    p = os.path.join(MAPS_DIR, map_name, "tutorial.md")
    if not os.path.isfile(p):
        return []
    text = open(p, encoding="utf-8", errors="replace").read()
    parts = re.split(r"```[^\n]*\n?", text)
    segs = []
    for i, seg in enumerate(parts):
        words = len(seg.split())
        if words < 8:
            continue
        if i % 2 == 1:
            segs.append({"kind": "code", "seconds": round(words / CODE_WPM * 60)})
        else:
            kind = "try" if TRY_RE.search(seg[:300]) else "idea"
            segs.append({"kind": kind, "seconds": round(words / PROSE_WPM * 60)})
    return segs


def turn_of(map_name):
    p = os.path.join(MAPS_DIR, map_name, "walked.md")
    if not os.path.isfile(p):
        return None
    text = open(p, encoding="utf-8", errors="replace").read()
    m = re.search(r"## The turn.*?\n+(.+?)(?:\n\n|\Z)", text, re.S)
    if not m:
        return None
    return " ".join(m.group(1).split())[:200]


def compile_target(register, segs, hero_is_instrument):
    hero_idx = {"arrival": 9, "close": 14}.get(register, 11)
    visual = [28.0] * N
    hand = [0.0] * N
    if register == "arrival":
        for i in range(4):
            visual[i] = 8 + 2 * i  # the void: awe needs a vacuum
    # reading segments occupy the pre-hero region in text order,
    # bump proportional to their load (a board fills the view when read)
    region = [i for i in range(2, hero_idx - 3)] or [2]
    total = sum(s["seconds"] for s in segs) or 1
    cursor = 0.0
    for s in segs:
        frac = s["seconds"] / total
        idx = region[min(len(region) - 1, int(cursor * len(region)))]
        cursor += frac
        if s["kind"] in ("idea", "code"):
            visual[idx] = max(visual[idx], 38 if s["kind"] == "idea" else 45)
        elif s["kind"] == "try":
            hand[min(N - 1, idx + 1)] = 35.0  # the contract: an instrument in reach
    # the dolly-in: monotone ramp to one climax at the hero
    ramp = range(max(0, hero_idx - 4), hero_idx + 1)
    for k, i in enumerate(ramp):
        visual[i] = max(visual[i], 30 + (72 - 30) * k / max(1, len(ramp) - 1))
    if hero_is_instrument:
        hand[hero_idx] = 32.0
    for i in range(hero_idx + 1, N):
        visual[i] = 24.0  # release after the climax
    visual[N - 1] = 18.0  # the exit sightline, modest
    return {"visual": [round(v, 1) for v in visual], "hand": [round(h, 1) for h in hand]}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--scripts", default="doc/book/look_scripts/primitives.json")
    args = ap.parse_args()
    scripts = json.load(open(os.path.join(ROOT, args.scripts), encoding="utf-8"))
    os.makedirs(TARGETS_DIR, exist_ok=True)
    from script_compose import read_cast, pick, base_of  # noqa: E402
    import desire_timeline as dt  # noqa: E402
    for map_name, script in scripts["maps"].items():
        segs = segments_of(map_name)
        turn = turn_of(map_name)
        _, cast, _ = read_cast(map_name)
        for pin in script.get("pins", []):
            if not any(base_of(t) == base_of(pin) for t in cast):
                cast.append(pin)
        hero_i = pick(cast, script["hero"])
        hero_b = base_of(cast[hero_i]) if hero_i is not None else ""
        hero_kind = dt.kind_of(hero_b)
        target = compile_target(script["register"], segs, hero_kind == "instrument")
        read_s = sum(s["seconds"] for s in segs if s["kind"] in ("idea", "code"))
        out = {
            "map": map_name,
            "saved": "2026-07-14",
            "source": "text compiler (edge-12): tutorial.md segments + walked.md turn + script hero",
            "segments": segs,
            "reading_load_s": read_s,
            "turn": turn,
            "hero": hero_b,
            "target": target,
        }
        json.dump(out, open(os.path.join(TARGETS_DIR, f"{map_name}.json"), "w",
                            encoding="utf-8"), indent=1)
        tries = sum(1 for s in segs if s["kind"] == "try")
        print(f"{map_name:28} segs={len(segs):2} (try {tries}) read={read_s:3}s "
              f"hero={hero_b[:24]} [{hero_kind}] turn={'yes' if turn else 'no'}")


if __name__ == "__main__":
    import sys
    sys.path.insert(0, os.path.join(ROOT, "tools"))
    main()
