#!/usr/bin/env python3
"""
negotiate_band.py — the common edge between an artifact and the room it stands in.

THE BAND. Three months of DNA promotion built a negotiation surface: 924 declared
axes across 679 artifacts, each value carrying a written argument for what it
MEANS (housing = how a capability is kept until it is yours; cage says specimen,
plinth says conferred, open says nobody thought to fence it). That surface now
sits under 71% of every placement in the spine — 986 of 1394 — and the
curriculum takes the default 97% of the time, silently. 34 placements choose a
value; 4 have prose that names the choice. The band is 986 wide and 4 deep.

The promotion work's own thesis was that an artifact is a FAMILY and the default
is merely the branch that got walked. Nothing has walked another branch.

WHAT THIS TOOL DOES, AND WHAT IT REFUSES TO DO. It does not rank 986 rows. Most
of them deserve their default: an exhibit_furniture in a corridor is furniture,
and a default is a perfectly good answer. The band worth opening is the one where
the artifact's axis and the room's argument are ABOUT THE SAME THING — where the
thing the artifact can argue and the thing the room exists to say rhyme. That is
a much smaller set, and each member of it is a single rulable line, not a report.

The rhyme test: content words shared between (axis name + its value names + the
registry's dna.note, which is where the argument lives) and (the room's own
intent/critical/blurb prose + its sequence's truth statement). The artifact's own
token is excluded — a room naming its own cast is not agreement about meaning.

Output is rulings, one per line, worst-defaulted first. Nothing is written to the
corpus: a ruling is Palle's to make.

  python tools/negotiate_band.py
  python tools/negotiate_band.py --seq=randomness --min=3
"""
from __future__ import annotations
import argparse
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

STOP = set("""the a an and or of to in on at is are was were be been being it its this that these those
with for from by as not no non one two three all any each every some such then than there here what which
who whom whose how why when where while into onto over under out up down off about after before between
you your yours we our ours they them their he she his her i me my mine do does did done can could will
would shall should may might must have has had having if but so because both few more most other same
very just also only own too s t don now map room artifact artifacts thing things make makes made made
use uses used using way ways get gets got new old first last next big small""".split())


## Word-boundary match. Written with an explicit constant because two attempts
## to patch this file through a shell heredoc turned the regex  into a literal
## BACKSPACE byte (0x08), and the resulting pattern matched nothing — reporting
## ZERO rhymes twice while a cross-check said 862 of 1262 axis values are spoken
## somewhere in the corpus. A measurement that contradicts its own cross-check is
## a broken instrument, not a finding.
_B = chr(92) + "b"


def RE_WORD(v: str):
    return re.compile(_B + re.escape(v) + _B)


def words(text: str) -> set[str]:
    return {w for w in re.findall(r"[a-z][a-z_]{3,}", text.lower()) if w not in STOP}


def load_axes() -> dict:
    out = {}
    for f in glob.glob(os.path.join(ROOT, "commons", "artifacts", "registry", "*.json")):
        try:
            arts = json.load(open(f, encoding="utf-8")).get("artifacts", {})
        except (json.JSONDecodeError, OSError):
            continue
        for tok, e in arts.items():
            dna = e.get("dna") if isinstance(e, dict) else None
            if isinstance(dna, dict) and dna.get("axes"):
                out[tok] = {"axes": dna["axes"], "note": str(dna.get("note", "")),
                            "default": str(dna.get("default", "")),
                            "desc": str(e.get("description", ""))}
    return out


def room_text(m: str) -> str:
    t = []
    for doc in ("intent.md", "critical.md", "blurb.md", "walked.md"):
        p = os.path.join(ROOT, "commons", "maps", m, doc)
        if os.path.exists(p):
            t.append(open(p, encoding="utf-8", errors="replace").read())
    return "\n".join(t)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--seq", default="")
    ap.add_argument("--min", type=int, default=1, help="minimum value-names the prose must say")
    ap.add_argument("--limit", type=int, default=40)
    a = ap.parse_args()

    axes = load_axes()
    spine = json.load(open(os.path.join(ROOT, "commons", "maps", "curriculum_spine.json"),
                           encoding="utf-8"))["spine"]["sequences"]
    rows = []
    for s in [x["name"] for x in sorted(spine, key=lambda r: r.get("order", 999))]:
        if a.seq and s != a.seq:
            continue
        sf = os.path.join(ROOT, "commons", "maps", "sequences", f"{s}.json")
        if not os.path.exists(sf):
            continue
        sd = json.load(open(sf, encoding="utf-8"))["sequences"][s]
        truth = " ".join(str(sd.get(k, "")) for k in ("description", "qfep_connection", "qfep_term"))
        for m in sd.get("maps", []):
            if not os.path.exists(os.path.join(ROOT, "commons", "maps", m, "map_data.json")):
                continue
            rtext = room_text(m)
            rtext_lc = rtext.lower()
            if not rtext.strip():
                continue
            rwords = words(rtext + " " + truth)
            d = json.load(open(os.path.join(ROOT, "commons", "maps", m, "map_data.json"),
                               encoding="utf-8"))
            for row in d.get("layers", {}).get("interactables", []):
                for cell in row:
                    cell = str(cell).strip()
                    if not cell:
                        continue
                    tok = cell.split("#")[0].split(":")[0]
                    if tok not in axes:
                        continue
                    set_keys = {kv.partition(":")[0] for kv in cell.split("#")[1:]}
                    info = axes[tok]
                    for ax, vals in info["axes"].items():
                        if ax in set_keys:
                            continue                      # already negotiated
                        # THE ONLY RHYME THAT MEANS ANYTHING. The first version of
                        # this test compared the axis's whole note against the room's
                        # whole prose and returned 742 hits on words like "back",
                        # "body" and "different" — it was measuring English, not
                        # agreement, which is this project's oldest disease: an
                        # instrument reporting a fact about itself as a fact about
                        # its subject. The tight test is the one that is actionable:
                        # does the room's prose already SAY one of the axis's value
                        # names, while the map stands at the default? Then the room
                        # has already made the argument and the placement has not
                        # heard it.
                        named = []
                        for v in vals:
                            vs = str(v).strip().lower()
                            if len(vs) < 4 or vs in STOP:
                                continue
                            if RE_WORD(vs).search(rtext_lc):
                                named.append(vs)
                        rhyme = named
                        if len(rhyme) >= 1:
                            rows.append({"seq": s, "map": m, "artifact": tok, "axis": ax,
                                         "values": [str(v) for v in vals], "rhyme": rhyme,
                                         "n": len(rhyme), "note": info["note"][:300],
                                         "default": info["default"][:160]})
    rows.sort(key=lambda r: -r["n"])
    seen = set()
    shown = 0
    print(f"THE BAND — {len(rows)} placements where the artifact's axis and the room's argument rhyme\n")
    for r in rows:
        key = (r["map"], r["artifact"], r["axis"])
        if key in seen:
            continue
        seen.add(key)
        shown += 1
        if shown > a.limit:
            break
        print(f"{r['map']} · {r['artifact']}#{r['axis']}  [{r['seq']}]")
        print(f"   can argue : {' | '.join(r['values'])}")
        print(f"   rhymes on : {', '.join(r['rhyme'][:10])}")
        if r["default"]:
            print(f"   default   : {r['default']}")
        print()
    out = os.path.join(ROOT, "doc", "reports", "band_rulings.json")
    json.dump({"_readme": "Placements where the artifact's declared axis and the room's own "
                          "argument rhyme. Each row is a rulable line: choose a value or keep "
                          "the default deliberately. PROPOSES; nothing is written to the corpus.",
               "band_total": len(rows), "rows": rows},
              open(out, "w", encoding="utf-8"), indent=1)
    print(f"{len(rows)} rulings -> doc/reports/band_rulings.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
