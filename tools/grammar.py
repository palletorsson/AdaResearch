#!/usr/bin/env python3
"""The grammar of the spine, checked against the tower (Palle, 2026-11-09: "make a grammar that can work throughout
the whole spine"). The grammar is commons/modular/grammar.json: ONE vocabulary of operations (each with a kind - Palle:
"extension is body, association is name" - and aliases for the words the term expressions and builds already use),
the axes they raise, and a ROOT card per spine sequence. The cards live on terms (commons/modular/terms.json `card`:
formula, motive, op, with, axes, said) and fall in the artifact timeline where tools/artifact_timeline.py place_cards
puts them - the same function, so the page, the timeline and this check agree.

What is checked (exit code = the number of violations):
  vocabulary  every card names an operation of the grammar; every `with` and axis is one the grammar declares
  earned      a main work may use an operation only after the card that introduces it (Palle, 2026-11-08: each floor
              only what it has earned). A work's operations are read from its form's term: the card op, the
              expression's words through the aliases, and the same for every term it is made `from`.
  axes        an axis level n stands only after level n-1 of the same axis
  spine       each spine sequence's root card exists, is placed, and stands on that sequence's own floors
Reported, not counted: expression words the grammar does not read yet, and cards whose operation the term's own
expression does not use (the card and the expression disagree - one of them should change).

    python tools/grammar.py check [--markdown] [--json]
    python tools/grammar.py spine                  # the spine table: sequence, floors, root card, where it stands
    python tools/grammar.py ops                    # each operation, where it is introduced, how many works use it
"""
from __future__ import annotations

import glob
import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import artifact_timeline as at  # noqa: E402

GRAMMAR = ROOT / "commons/modular/grammar.json"
TERMS = ROOT / "commons/modular/terms.json"
ROOMS = ROOT / "commons/void/rooms.json"
SPINE = ROOT / "commons/maps/curriculum_spine.json"
SEQUENCES = ROOT / "commons/maps/sequences"
WORD = re.compile(r"([A-Za-z_]+)\(")   # call syntax only: "oil drum (..." is prose
BODY_PART = re.compile(r"association\(\s*[^)]*(collider|mesh|skin)", re.I)


def read(p: Path):
    return json.loads(p.read_text(encoding="utf-8"))


def load() -> dict:
    g = read(GRAMMAR)
    terms = read(TERMS)
    return {"grammar": g, "terms": terms["terms"], "track": terms.get("track", []), "doc": read(at.AUTHORED),
            "rooms": read(ROOMS)["floors"]}


def alias_map(g: dict) -> dict:
    """plain alias word -> set of operations (a word may mean two: noise = a field of samples)"""
    out = defaultdict(set)
    for op, o in g["operations"].items():
        out[op].add(op)
        for a in o.get("aliases", []):
            if re.fullmatch(r"[A-Za-z_]+|[×*∪∩]", a):
                out[a].add(op)
    return out


def expr_ops(term: str, t: dict, g: dict, amap: dict, unknown: dict | None = None) -> set:
    """the operations one term's own expression and build name (not its parts')"""
    e = t.get("expr", "") or ""
    ops: set = set()
    rel = t.get("chapter") in set(g.get("relation_chapters", []))
    for w in WORD.findall(e):
        if w == "association" and BODY_PART.search(e):
            ops.add("extension")   # Palle: extension is body - a skin or a collider given to a form is a body
            if re.search(r"association\(\s*(?![^)]*(collider|mesh|skin))", e):
                ops.add("association")
            continue
        if w == "connect":
            ops.add("connect" if rel else "tie")
            continue
        if w in amap:
            ops |= amap[w]
        elif unknown is not None:
            unknown[w].append(term)
    for sym in ("×", "∪", "∩"):
        if sym in e:
            ops |= amap.get(sym, set())
    if re.search(r"\w\s\*\s|\)\s*\*\s|\*\s*\d", e):
        ops |= amap.get("*", set())
    b = t.get("build") if isinstance(t.get("build"), dict) else {}
    bop = b.get("op")
    if bop == "associate":
        ops.add("association")
    elif bop == "connect":
        ops.add("connect" if rel else "tie")
    elif bop in g["operations"]:
        ops.add(bop)
    if "grabbable" in (t.get("from") or []):
        ops.add("hand")
    return ops


def term_ops(g: dict, terms: dict) -> tuple:
    """term -> every operation it uses, its own and its parts' (recursively, through `from`); unknown words"""
    amap = alias_map(g)
    unknown: dict = defaultdict(list)
    own = {}
    for k, t in terms.items():
        o = expr_ops(k, t, g, amap, unknown)
        c = t.get("card") if isinstance(t.get("card"), dict) else None
        if c:
            o |= {c.get("op")} | set(c.get("with") or [])
        own[k] = o - {None, ""}
    memo: dict = {}

    def deep(k: str, seen: frozenset) -> set:
        if k in memo:
            return memo[k]
        out = set(own.get(k, set()))
        for f in (terms.get(k) or {}).get("from") or []:
            if f in terms and f not in seen and f != k:
                out |= deep(f, seen | {k})
        memo[k] = out
        return out
    return {k: deep(k, frozenset()) for k in terms}, own, {w: ts for w, ts in unknown.items() if w not in terms}


def floor_sequences(rooms: list, spine: list) -> dict:
    """spine sequence -> the tower floors whose map belongs to it (first sequence file that lists the map)"""
    m2s = {}
    for f in sorted(glob.glob(str(SEQUENCES / "*.json"))):
        try:
            d = json.loads(Path(f).read_text(encoding="utf-8"))
        except (OSError, ValueError):
            continue
        seqs = d.get("sequences")
        if isinstance(seqs, dict):
            items = seqs.items()
        elif isinstance(seqs, list):
            items = [(x.get("id") or x.get("sequence_id") or x.get("name"), x) for x in seqs if isinstance(x, dict)]
        else:
            items = [(d.get("id") or os.path.basename(f)[:-5], d)]
        for sid, sd in items:
            if sid not in spine or not isinstance(sd, dict):
                continue
            for m in sd.get("maps") or []:
                n = m if isinstance(m, str) else (m.get("map") or m.get("name") or m.get("id") or m.get("map_name"))
                if n:
                    m2s.setdefault(n, sid)
    out = defaultdict(list)
    for i, f in enumerate(rooms):
        if m2s.get(f.get("map")):
            out[m2s[f["map"]]].append(i)
    return out


def axes_of(card: dict) -> list:
    a = card.get("axes") or ([card["axis"]] if card.get("axis") else [])
    out = []
    for x in a:
        name, _, lvl = str(x).partition(":")
        out.append((name, int(lvl) if lvl.isdigit() else 1))
    return out


def check(data: dict | None = None) -> dict:
    d = data or load()
    g, terms, doc = d["grammar"], d["terms"], d["doc"]
    ops = g["operations"]
    main = doc.get("main", [])
    pos = {r["key"]: i for i, r in enumerate(main)}
    floor_of = {r["key"]: r.get("floor") for r in main}
    carded, cards_before, _ = at.place_cards(doc, terms)
    # reading order of every placed card: (position of its work, its place among the cards on that work)
    order = {t: (pos[k], cards_before[k].index(t)) for t, k in carded.items() if k in pos}
    cards = {t: v["card"] for t, v in terms.items() if isinstance(v.get("card"), dict)}
    violations, notes = [], []

    # VOCABULARY
    for t, c in cards.items():
        if c.get("op") not in ops:
            violations.append(("vocabulary", f"card {t}: op {c.get('op')!r} is not an operation of the grammar"))
        for w in c.get("with") or []:
            if w not in ops:
                violations.append(("vocabulary", f"card {t}: with {w!r} is not an operation of the grammar"))
        for name, lvl in axes_of(c):
            levels = g["axes"].get(name)
            if levels is None or not 1 <= lvl <= len(levels):
                violations.append(("vocabulary", f"card {t}: axis {name}:{lvl} is not declared in grammar.json"))
        if not axes_of(c):
            violations.append(("vocabulary", f"card {t}: no axis - which axis does this step raise?"))

    # WHERE EACH OPERATION IS INTRODUCED: the first placed card that names it (op or with)
    intro = {}
    for t in sorted(order, key=order.get):
        c = cards[t]
        for o in [c.get("op")] + list(c.get("with") or []):
            if o and o not in intro:
                intro[o] = (t, order[t])

    # EARNED: every formed main work uses only introduced operations
    deep, own, unknown = term_ops(g, terms)
    uses = defaultdict(list)
    for r in main:
        f = r.get("form") or {}
        names = [f.get("term")] + ([f.get("of_form")] if f.get("kind") == "child" else [])
        used = set()
        for n in names:
            if n in terms:
                used |= deep[n]
        if f.get("kind") == "collection" and f.get("op") in ops:
            used.add(f["op"])
        here = (pos[r["key"]], 10 ** 6)   # the work stands after every card placed before it
        for o in sorted(used):
            uses[o].append(r["key"])
            if o not in intro:
                violations.append(("earned", f"#{pos[r['key']] + 1} {r['key']} (floor {r.get('floor')}) uses {o}, and no placed card introduces {o}"))
            elif intro[o][1] > here:
                it, (ip, _) = intro[o]
                violations.append(("earned", f"#{pos[r['key']] + 1} {r['key']} (floor {r.get('floor')}) uses {o} before its card "
                                             f"({it}, before #{ip + 1} {main[ip]['key']} on floor {floor_of[main[ip]['key']]})"))

    # AXES: level n after level n-1
    first_at = {}
    for t in sorted(order, key=order.get):
        for name, lvl in axes_of(cards[t]):
            first_at.setdefault((name, lvl), (t, order[t]))
    for (name, lvl), (t, o) in sorted(first_at.items()):
        if lvl > 1:
            below = first_at.get((name, lvl - 1))
            if below is None:
                violations.append(("axes", f"{t} raises {name} to {lvl}, and no placed card raises it to {lvl - 1}"))
            elif below[1] > o:
                violations.append(("axes", f"{t} raises {name} to {lvl} (#{o[0] + 1} {main[o[0]]['key']}, floor {floor_of[main[o[0]]['key']]}) "
                                           f"before {below[0]} raises it to {lvl - 1} (#{below[1][0] + 1} {main[below[1][0]]['key']}, "
                                           f"floor {floor_of[main[below[1][0]]['key']]})"))

    # SPINE: one root per sequence, on its own floors
    spine_names = [s["name"] for s in read(SPINE)["spine"]["sequences"]]
    floors = floor_sequences(d["rooms"], spine_names)
    rows = []
    declared = {s["sequence"]: s for s in g.get("spine", [])}
    for name in spine_names:
        s = declared.get(name)
        fl = floors.get(name, [])
        row = {"sequence": name, "floors": [fl[0], fl[-1]] if fl else [], "root": (s or {}).get("root")}
        if s is None:
            violations.append(("spine", f"{name}: the grammar names no root for this spine sequence"))
        elif s.get("root") is None:
            notes.append(f"{name}: no root card - {s.get('note', 'no reason given')}")
            if fl:
                violations.append(("spine", f"{name} has floors {fl[0]}-{fl[-1]} but no root card"))
        else:
            r = s["root"]
            row["at"] = carded.get(r)
            row["floor"] = floor_of.get(carded.get(r))
            row["formula"] = (cards.get(r) or {}).get("formula")
            if r not in cards:
                violations.append(("spine", f"{name}: root {r} carries no card"))
            elif r not in carded:
                violations.append(("spine", f"{name}: root card {r} is not placed in the timeline"))
            elif fl and floor_of.get(carded[r]) not in fl:
                violations.append(("spine", f"{name}: root card {r} stands on floor {floor_of.get(carded[r])}, "
                                           f"not on the sequence's floors {fl[0]}-{fl[-1]}"))
        rows.append(row)

    # REPORTED: a card whose op its term's own expression does not use
    disagree = []
    for t, c in cards.items():
        o = own.get(t, set()) - {c.get("op")} - set(c.get("with") or [])
        expr_says = expr_ops(t, terms[t], g, alias_map(g))
        if expr_says and c.get("op") not in expr_says:
            disagree.append(f"{t}: the card says {c.get('op')}, its expression says {', '.join(sorted(expr_says))}")
    return {"violations": violations, "notes": notes, "spine": rows,
            "intro": {o: {"card": t, "at": main[p[0]]["key"], "n": p[0] + 1, "floor": floor_of[main[p[0]]["key"]]}
                      for o, (t, p) in intro.items()},
            "uses": {o: len(v) for o, v in uses.items()}, "unknown": {w: ts for w, ts in sorted(unknown.items())},
            "disagree": disagree, "cards": len(cards), "placed": len(carded)}


def main(argv: list) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    cmd = argv[1] if len(argv) > 1 and not argv[1].startswith("--") else "check"
    if cmd == "assembly":   # Assembly Theory's index of the grammar: tools/grammar_assembly.py (2026-11-09)
        import grammar_assembly
        return grammar_assembly.main(argv)
    r = check()
    if "--json" in argv:
        print(json.dumps(r, ensure_ascii=False, indent=1))
        return len(r["violations"])
    if cmd == "spine":
        for s in r["spine"]:
            fl = "-".join(map(str, s["floors"])) or "no floor"
            print(f"{s['sequence']:22} {fl:8} {str(s.get('root')):18} floor {str(s.get('floor')):4} {s.get('formula') or ''}")
        return 0
    if cmd == "ops":
        g = read(GRAMMAR)
        for o, v in g["operations"].items():
            i = r["intro"].get(o)
            where = f"#{i['n']} {i['at']} floor {i['floor']} ({i['card']})" if i else "not introduced"
            print(f"{o:12} {v['kind']:9} used by {r['uses'].get(o, 0):3} formed works   introduced {where}")
        return 0
    md = "--markdown" in argv
    print(("## " if md else "") + f"Grammar of the spine: {r['cards']} cards, {r['placed']} placed, {len(r['violations'])} violations")
    by = defaultdict(list)
    for kind, text in r["violations"]:
        by[kind].append(text)
    for kind in ("vocabulary", "earned", "axes", "spine"):
        print(("\n### " if md else "\n") + f"{kind}: {len(by[kind])}")
        for text in by[kind]:
            print(("- " if md else "  ") + text)
    for n in r["notes"]:
        print(("- note: " if md else "  note: ") + n)
    print(("\n### " if md else "\n") + f"cards that disagree with their term's expression: {len(r['disagree'])}")
    for text in r["disagree"]:
        print(("- " if md else "  ") + text)
    print(("\n### " if md else "\n") + f"expression words the grammar does not read: {len(r['unknown'])}")
    print(("" if md else "  ") + ", ".join(f"{w} ({len(ts)})" for w, ts in r["unknown"].items()))
    return len(r["violations"])


if __name__ == "__main__":
    sys.exit(main(sys.argv))
