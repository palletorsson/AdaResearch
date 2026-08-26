#!/usr/bin/env python3
"""DOES THE HALL SHOW WHAT THE MAP DECLARES? (2026-08-26)

Palle: "we should try to keep the artifact content the same."

A hall's artifacts can be decided four ways, and only one of them is the map:

    transplant  the map's own bodies, positioned by the museum
    stamp       the bench's necklace overrules the map and CHOOSES THE CAST
    grid        a real GridSystem builds the map, full complement
    template    the map is never opened; the museum deals the room

This does not forbid a hall from differing - a bench cut is a curation and
Palle made those on purpose. It makes the difference VISIBLE, so a cast that
shrinks is a decision rather than a drift. That is the same shape as
check_map_tokens.py: state the fact, let the ruling be a ruling.

    python tools/em_content_parity.py              # every hall, worst first
    python tools/em_content_parity.py --lane=stamp # one lane
    python tools/em_content_parity.py --strict     # exit 1 if a stamped hall lost ground
"""
import collections, json, os, sys

PLAN = "ada_run/em_plan.json"
HAND = "ada_run/necklace_hand.json"
AUTH = "commons/data/map_authored.json"


def _load(p, default):
    try:
        with open(p, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return default


def map_tokens(m):
    f = "commons/maps/%s/map_data.json" % m
    if not os.path.exists(f):
        return None
    d = _load(f, {})
    c = collections.Counter()
    for row in (d.get("layers", {}) or {}).get("interactables", []) or []:
        for x in row:
            t = str(x).strip()
            if t and not t.startswith("#"):
                c[t.split("#")[0].split(":")[0]] += 1
    return c


def main(argv):
    only = ""
    strict = False
    for a in argv:
        if a.startswith("--lane="):
            only = a[7:]
        elif a == "--strict":
            strict = True
    plan = _load(PLAN, {}).get("plans", [])
    hand = _load(HAND, {}).get("halls", {})
    lic = {k for k in _load(AUTH, {}) if not k.startswith("_")}
    stamped = {k for k, v in hand.items() if v.get("stamp")}
    rows, tally = [], collections.Counter()
    for r in plan:
        ch = r.get("sequence") or ""
        key = "%s|%s" % (ch, r.get("pearl") or "")
        m = r.get("map") or ""
        sim = r.get("simulation")
        if ch not in lic:
            lane = "template"
        elif isinstance(sim, dict) and sim.get("grid"):
            lane = "grid"
        elif key in stamped:
            lane = "stamp"
        elif r.get("authored") == "map":
            lane = "transplant"
        else:
            lane = "template"
        tally[lane] += 1
        if only and lane != only:
            continue
        want = map_tokens(m)
        if want is None:
            continue
        declared = sum(want.values())
        if lane == "stamp":
            beads = collections.Counter(str(b.get("token", "")) for b in hand[key].get("beads", []))
            kept = sum(min(beads.get(t, 0), want[t]) for t in want)
            lost = sorted(t for t in want if beads.get(t, 0) < want[t])
        elif lane == "template":
            kept, lost = 0, sorted(want)
        else:
            kept, lost = declared, []
        rows.append((declared - kept, m, lane, declared, kept, lost))

    rows.sort(key=lambda r: (-r[0], r[1]))
    print("%-30s %-11s %6s %6s %6s  %s" % ("map", "lane", "decl", "shown", "%", "not shown"))
    for gap, m, lane, decl, kept, lost in rows:
        pct = 100.0 * kept / decl if decl else 100.0
        print("%-30s %-11s %6d %6d %5.0f%%  %s" % (m[:30], lane, decl, kept, pct,
              ", ".join(lost[:3]) + (" +%d" % (len(lost) - 3) if len(lost) > 3 else "")))
    print()
    for lane, n in tally.most_common():
        print("  %-11s %3d hall(s)" % (lane, n))
    short = [r for r in rows if r[2] == "stamp" and r[0] > 0]
    print("\n  %d stamped hall(s) show fewer artifacts than their map declares" % len(short))
    if strict and short:
        print("  --strict: the bench has cut a cast. Rule on it, or widen the necklace.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
