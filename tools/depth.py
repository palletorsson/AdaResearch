#!/usr/bin/env python3
"""THE DEPENDENCY GRADIENT — what should become visible, here, now.

    python tools/depth.py --map=Point_One      # one room's gradient
    python tools/depth.py                       # the corpus: ruled vs unruled
    python tools/depth.py --apply               # write commons/data/depth.json
    python tools/depth.py --propose=Point_Lines # what a room MIGHT raise (never binds)

2026-09-01, Palle, ruling. This file exists because the version before it was
wrong in a way worth recording, since the wrong version is the obvious one.

THE VERSION BEFORE THIS (tools/code_debt.py) measured every language construct a
room's tutorial used and printed it as a debt: "stands on functions, .new(),
add_child — not taught here." It was accurate and it was a DEPENDENCY WALL.
Follow that logic and you get: before Vector3, floats; before floats, binary;
before binary, electricity; before electricity, electromagnetism; and the learner
has learned nothing about points. The opposite failure is equally bad — "here is
Vector3(1, 0.5, 0), don't worry about the rest" — and leaves them surrounded by
unexplained magic.

    "Explain a dependency when ignorance of it prevents the learner from forming
     the intended mental model. Don't explain it merely because it exists."

So a thing is not present-or-absent. It has a STATUS on a ladder, and the ladder's
bottom rungs SHOW NOTHING:

    background   in the building, never on the path (the basement)
    used         the learner acts through it and need not know it exists  <- DEFAULT
    named        one line, beside the thing, no theory
    glimpsed     the line, plus a descent they may decline
    understood   the room's subject; this is what it teaches
    mastered     carried across rooms — not a property of any one room

THE DEFAULT IS 'used', WHICH MEANS THE DEFAULT IS SILENCE. That single choice is
the whole difference between this tool and the last one. A child meets sentences
containing words they do not know; we do not treat every unknown word as a
prerequisite before the sentence can mean anything. `func place_point(position:
Vector3) -> MeshInstance3D:` may stand in a room whose narration says only "this
is the instruction that makes a point appear". The code is allowed to be more
sophisticated than the learner's current vocabulary.

MEASURED vs RULED — the split this tool refuses to blur:
  MEASURED (findings, cheap, fallible): which constructs a room's code contains.
      That is what code_debt.py did well, and it is kept below, because knowing
      what is IN the room is still the input to judging it.
  RULED (claims, authored, binding): what status each thing has in that room.
      Lives in commons/data/depth_rulings.json, edited by hand. Explanatory
      relevance is a judgment about a learner, and a measurement that guessed at
      it would be a wall wearing a gradient's clothes.

--propose crosses that line ON PURPOSE and says so: it prints what a room might
want to raise, marked `proposed`, and writes nothing. Heuristics propose; only a
person binds.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MAPS = REPO / "commons" / "maps"
RULINGS = REPO / "commons" / "data" / "depth_rulings.json"
OUT = REPO / "commons" / "data" / "depth.json"

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

GD = "https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/"

# WHAT IS IN THE ROOM — a finding, not a verdict. Every doc target here was
# FETCHED before it was written down: '#static-typing' does not exist on
# gdscript_basics.html (inference lives on static_typing.html), and a dead link
# is worst for exactly the reader who cannot tell a broken anchor from their own
# mistake.
CONSTRUCTS = [
    ("function", "functions", r"^\s*func\s", GD + "gdscript_basics.html#functions"),
    ("variable", "variables", r"^\s*var\s", GD + "gdscript_basics.html#variables"),
    ("constant", "constants", r"^\s*const\s", GD + "gdscript_basics.html#constants"),
    ("inference", "type inference (:=)", r":=",
     GD + "static_typing.html#static-typing-in-gdscript"),
    ("typed", "typed values (: Type, -> Type)",
     r"->\s*\w+|\b\w+\s*:\s*(?:float|int|String|bool|Vector[23]|Node3D|Array|Dictionary)\b",
     GD + "static_typing.html#static-typing-in-gdscript"),
    ("new", "making an object (.new())", r"\.new\(\)",
     "https://docs.godotengine.org/en/stable/classes/class_object.html"),
    ("scenetree", "the scene tree (add_child)", r"\badd_child\(",
     "https://docs.godotengine.org/en/stable/classes/class_node.html"),
    ("preload", "preload()", r"\bpreload\(", GD + "gdscript_basics.html#annotations"),
    ("builtin", "built-in maths (round, floor…)", r"\b(?:round|floor|ceil|abs|clamp|lerp)\(",
     "https://docs.godotengine.org/en/stable/classes/class_%40globalscope.html"),
    ("format", "string formatting (%)", r'"%[\d.]*[sfd]|%\s*\[', GD + "gdscript_format_string.html"),
    ("loop", "loops (for, while)", r"^\s*(?:for|while)\s", GD + "gdscript_basics.html#if-else-elif"),
    ("branch", "branching (if, else)", r"^\s*(?:if|elif|else)\b", GD + "gdscript_basics.html#if-else-elif"),
]

## Rungs, low to high. Index is the only ordering; nothing else may assume it.
LADDER = ["background", "used", "named", "glimpsed", "understood", "mastered"]

## AT OR ABOVE THIS RUNG, A THING IS SAID SOMEWHERE. Below it, silence. This
## constant is the tool's whole editorial position and it is one line long, which
## is the point: the argument lives in the ruling file, not in the code.
SPEAKS_AT = LADDER.index("named")


def blocks(md: str) -> str:
    return "\n".join(re.findall(r"```gdscript\n(.*?)^```", md, re.S | re.M))


def present_in(code: str) -> list[dict]:
    """MEASURED: which constructs this room's own code contains."""
    out = []
    for key, human, pat, url in CONSTRUCTS:
        n = len(re.findall(pat, code, re.M))
        if n:
            out.append({"key": key, "name": human, "uses": n, "url": url})
    return out


def rulings() -> dict:
    try:
        return json.loads(RULINGS.read_text(encoding="utf-8"))
    except Exception as e:
        print("cannot read %s: %s" % (RULINGS.name, e), file=sys.stderr)
        return {}


def survey(only: str = "") -> list[dict]:
    rows = []
    for p in sorted(MAPS.glob("*/tutorial.md")):
        mp = p.parent.name
        if only and mp != only:
            continue
        code = blocks(p.read_text(encoding="utf-8", errors="replace"))
        rows.append({"map": mp, "lines": len(code.strip().split("\n")) if code.strip() else 0,
                     "present": present_in(code)})
    return rows


def spoken(room: dict) -> list[dict]:
    """RULED: the things this room actually says, in ladder order, high first.

    A room with no ruling returns EMPTY — not a default list. That is the
    behaviour the whole design rests on, and probe_depth.gd holds it in place."""
    out = [t for t in room.get("things", [])
           if LADDER.index(t.get("status", "used")) >= SPEAKS_AT]
    out.sort(key=lambda t: -LADDER.index(t.get("status", "used")))
    return out


def basement(room: dict) -> list[dict]:
    return [t for t in room.get("things", []) if t.get("status") == "background"]


def apply() -> dict:
    r = rulings()
    rooms_ruled = r.get("rooms", {})
    doc = {
        "_producer": "tools/depth.py --apply",
        "_what": "the dependency gradient: what each room says, and at which rung",
        "_note": "DERIVED from commons/data/depth_rulings.json (authored). Do not edit.",
        "_rule": r.get("_rule", ""),
        "_thrownness": r.get("_thrownness", ""),
        "ladder": r.get("ladder", []),
        "speaks_at": LADDER[SPEAKS_AT],
        "rooms": {},
    }
    for mp, room in rooms_ruled.items():
        says = spoken(room)
        if not says and not basement(room):
            continue
        doc["rooms"][mp] = {
            "says": says,
            "basement": basement(room),
            "silent": [t.get("thing") for t in room.get("things", [])
                       if t.get("status", "used") == "used"],
        }
    OUT.write_text(json.dumps(doc, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    return doc


def propose(mp: str) -> None:
    """Cross the line on purpose, and label it. Writes nothing."""
    rows = survey(mp)
    if not rows:
        print("no such room: %s" % mp, file=sys.stderr)
        return
    r = rulings()
    ruled = r.get("rooms", {}).get(mp, {})
    named = {str(t.get("thing", "")).lower() for t in ruled.get("things", [])}
    print("PROPOSED for %s — nothing here binds anything." % mp)
    print("  A person decides which of these the room should raise, and to what")
    print("  rung. The tool can see what is PRESENT; it cannot see what a learner")
    print("  needs in order to act.")
    print()
    if not ruled:
        print("  (this room has NO ruling yet — everything below defaults to 'used',")
        print("   which means the room currently says nothing, which may be right)")
        print()
    for c in rows[0]["present"]:
        mark = "ruled" if c["name"].lower() in named or c["key"] in named else "proposed"
        print("  %-9s %-32s x%-3d %s" % (mark, c["name"], c["uses"], c["url"]))


def main() -> int:
    ap = argparse.ArgumentParser(description="the dependency gradient")
    ap.add_argument("--map", default="")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--propose", default="")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()

    if a.propose:
        propose(a.propose)
        return 0

    r = rulings()
    if not r:
        return 2
    rooms_ruled = r.get("rooms", {})

    if a.apply:
        doc = apply()
        n_say = sum(len(v["says"]) for v in doc["rooms"].values())
        print("DEPTH — %s" % OUT.relative_to(REPO).as_posix())
        print("  %d room(s) ruled, %d thing(s) said, %d in the basement."
              % (len(doc["rooms"]), n_say,
                 sum(len(v["basement"]) for v in doc["rooms"].values())))
        print("  Everything else is 'used': the learner acts through it and the")
        print("  museum says nothing. That silence is the ruling, not an omission.")
        return 0

    if a.json:
        print(json.dumps(apply(), ensure_ascii=False, indent=1))
        return 0

    if a.map:
        room = rooms_ruled.get(a.map)
        if not room:
            print("%s has no ruling — it says nothing, and that is a legal answer." % a.map)
            print("  python tools/depth.py --propose=%s  to see what is in it." % a.map)
            return 0
        print("THE GRADIENT — %s" % a.map)
        print()
        by = {}
        for t in room.get("things", []):
            by.setdefault(t.get("status", "used"), []).append(t)
        for rung in reversed(LADDER):
            if rung not in by:
                continue
            shows = "shown" if LADDER.index(rung) >= SPEAKS_AT else "SILENT"
            print("  %-11s (%s)" % (rung, shows))
            for t in by[rung]:
                print("      %s" % t["thing"])
                if t.get("say"):
                    print("          “%s”" % t["say"])
                if t.get("descend"):
                    print("          ↳ %s" % t["descend"])
        print()
        print("  %d said, %d silent." % (len(spoken(room)),
                                         len(room.get("things", [])) - len(spoken(room))))
        return 0

    rows = survey()
    with_code = [r_ for r_ in rows if r_["present"]]
    print("THE DEPENDENCY GRADIENT")
    print()
    print("  %d room(s), %d with code of their own." % (len(rows), len(with_code)))
    print("  %d ruled by hand. %d unruled — which means they say NOTHING, and for"
          % (len(rooms_ruled), len(rows) - len(rooms_ruled)))
    print("  most of them that is the right answer, not a backlog.")
    print()
    for mp, room in rooms_ruled.items():
        says = spoken(room)
        print("  %-24s %d said, %d silent, %d in the basement"
              % (mp, len(says), len(room.get("things", [])) - len(says), len(basement(room))))
    print()
    print("  %s" % r.get("_rule", ""))
    print()
    print("  --map=<Name> for one room's ladder · --propose=<Name> for what is in it")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
