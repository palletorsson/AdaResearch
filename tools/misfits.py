#!/usr/bin/env python3
"""THE MISFIT LEDGER, read and re-measured (commons/modular/misfits.json; Palle, 2026-11-11: "can we build a category
or assemblage theory that is not restrictive?" ... "yes, pilot the misfit ledger on the randomness floors").

The grammar (commons/modular/grammar.json) stays strict; the ledger is what happens to whatever the strict readings
turn away: it is filed with the reading that found it, how we know, and what would have to change for it to fit. A
PROPOSAL is a change several entries ask for, and it carries a test: the floors re-read with the change applied IN
MEMORY - what it removes, what it creates. Nothing here writes the grammar, the terms or the timeline.

    python tools/misfits.py                 the ledger: open, kept and closed entries, then the proposals
    python tools/misfits.py --test          re-measure every proposal's test; exit 1 if a recorded number has drifted
    python tools/misfits.py --reading=body  only one reading's entries

Readings re-measured here: `timeline` (tools/grammar.py check: what it removes and creates), `words` (terms whose
formula uses a call word the grammar cannot read) and `vocabulary` (the change itself is well-formed: creates nothing).
`body`, `eye`, `parts` and `arrival` numbers are measured in the game or counted from a report and are only printed.
The forms a pilot reads with (ledger `pilot.forms`, a thread on /artifact-timeline) are applied in memory to rows that
have no confirmed form; a confirmed form always wins.
"""
from __future__ import annotations

import copy
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
LEDGER = ROOT / "commons/modular/misfits.json"
ENTRY_KEYS = ("id", "reading", "status", "state", "floors", "lands_in", "works", "misfit", "would_change")
STATES = ("open", "kept", "closed")


def shape(doc: dict) -> list:
    """what is wrong with the file itself"""
    bad = []
    ids = [e.get("id") for e in doc.get("entries", [])]
    props = {p.get("id") for p in doc.get("proposals", [])}
    for e in doc.get("entries", []):
        for k in ENTRY_KEYS:
            if k not in e:
                bad.append(f"{e.get('id')}: no {k}")
        if e.get("reading") not in doc["readings"]:
            bad.append(f"{e.get('id')}: reading {e.get('reading')!r} is not declared")
        if e.get("status") not in doc["status"]:
            bad.append(f"{e.get('id')}: status {e.get('status')!r} is not imagined, built or observed")
        if e.get("lands_in") not in doc["lands_in"]:
            bad.append(f"{e.get('id')}: lands_in {e.get('lands_in')!r} is not declared")
        if e.get("state") not in STATES:
            bad.append(f"{e.get('id')}: state {e.get('state')!r} is not open, kept or closed")
        if e.get("proposal") and e["proposal"] not in props:
            bad.append(f"{e.get('id')}: proposal {e['proposal']} does not exist")
        if e.get("state") == "closed" and not e.get("closed_by"):
            bad.append(f"{e.get('id')}: closed without closed_by")
        if (e.get("second") or {}).get("reading") not in (None, *doc["readings"]):
            bad.append(f"{e.get('id')}: second reading is not declared")
    if len(ids) != len(set(ids)):
        bad.append("an entry id is used twice")
    for p in doc.get("proposals", []):
        for a in p.get("asked_by", []):
            if a not in ids:
                bad.append(f"{p.get('id')}: asked_by {a} does not exist")
        if not p.get("asked_by"):
            bad.append(f"{p.get('id')}: a proposal nobody asked for")
        if not p.get("forecloses"):
            bad.append(f"{p.get('id')}: no `forecloses` - what does accepting it make harder?")
    return bad


def world(thread_id: str | None) -> tuple:
    """the grammar, the terms with the waiting drafts, and the timeline with the pilot's proposed forms applied"""
    import artifact_timeline as at
    import grammar as gr
    tm, dr = at.terms(), at.drafts()
    terms = {**{k: {x: y for x, y in v.items() if x not in ("drafted_by", "drafted_for", "used_by")} for k, v in dr.items()}, **tm}
    doc = copy.deepcopy(at.read(at.AUTHORED))
    entry = next((e for e in at.read_threads()["entries"] if e["id"] == thread_id), None) if thread_id else None
    forms = {o["key"]: o["form"] for o in ((entry or {}).get("answer") or {}).get("operations", []) if o.get("valid") and o.get("op") == "form"}
    for r in doc["main"]:
        if r["key"] in forms and not r.get("form"):
            r["form"] = dict(forms[r["key"]])
    data = gr.load()
    return gr, data, terms, doc


def apply(delta: list, g: dict, terms: dict, doc: dict) -> None:
    """one proposal's change, in memory. `timeline` operations are left to the page that owns them."""
    for d in delta:
        if "card" in d:
            terms[d["card"]["term"]] = {**terms[d["card"]["term"]], "card": dict(d["card"]["card"])}
        elif "term_expr" in d:
            terms[d["term_expr"]["term"]] = {**terms[d["term_expr"]["term"]], "expr": d["term_expr"]["expr"]}
        elif "alias_add" in d:
            g["operations"][d["alias_add"]["op"]]["aliases"].append(d["alias_add"]["word"])
        elif "alias_remove" in d:
            g["operations"][d["alias_remove"]["op"]]["aliases"].remove(d["alias_remove"]["word"])
        elif "unhand_card" in d:
            for r in doc["main"]:
                if r.get("cards"):
                    r["cards"] = [c for c in r["cards"] if c != d["unhand_card"]]
        elif "operation" in d:
            o = d["operation"]
            g["operations"][o["name"]] = {k: o[k] for k in ("kind", "sig", "adds", "aliases")}
        elif "axis_level" in d:
            g["axes"][d["axis_level"]["axis"]].append(d["axis_level"]["level"])


def measure(reading: str, test: dict, delta: list, base: tuple) -> dict | None:
    gr, data, terms0, doc0 = base
    g0 = data["grammar"]
    g, terms, doc = copy.deepcopy(g0), copy.deepcopy(terms0), copy.deepcopy(doc0)

    def faults(gg, tt, dd):
        return [t for _, t in gr.check({**data, "grammar": gg, "terms": tt, "doc": dd})["violations"]]
    if reading in ("timeline", "vocabulary"):
        before = faults(g0, terms0, doc0)
        apply(delta, g, terms, doc)
        after = faults(g, terms, doc)
        out = {"before": len(before), "after": len(after), "removes": len([x for x in before if x not in after]),
               "creates": len([x for x in after if x not in before])}
        return {"creates": out["creates"]} if reading == "vocabulary" else out
    if reading == "words":
        word = test["word"]
        before = len(gr.term_ops(g0, terms0)[2].get(word, []))
        apply(delta, g, terms, doc)
        after = len(gr.term_ops(g, terms)[2].get(word, []))
        out = {"before": before, "after": after, "removes": before - after, "creates": 0}
        out["creates"] = len([x for x in faults(g, terms, doc) if x not in faults(g0, terms0, doc0)])
        return out
    return None      # measured in the game or counted from a report


def run_tests(doc: dict) -> int:
    base = world((doc.get("pilot") or {}).get("forms"))
    drift = 0
    for p in doc["proposals"]:
        for label, delta, test in [(p["title"], p["delta"], p["test"])] + [("  instead: " + t["what"], t["delta"], t["test"]) for t in p.get("tested_instead", [])]:
            got = measure(test["reading"], test, delta, base)
            if got is None:
                print(f"{p['id']} {label}: {test['reading']} - recorded, not re-measured here")
                continue
            want = {k: test[k] for k in got if k in test}
            ok = all(got[k] == v for k, v in want.items())
            drift += 0 if ok else 1
            print(f"{p['id']} {label}: {test['reading']} " + ", ".join(f"{k} {v}" for k, v in got.items()) + ("" if ok else f"   DRIFT - the ledger says {want}"))
    print("\n" + ("every recorded test still measures the same" if not drift else f"{drift} test(s) have drifted: re-read the entries they answer"))
    return 1 if drift else 0


def main(argv: list) -> int:
    if hasattr(sys.stdout, "reconfigure"):      # a Windows console is cp1252 and the entries quote formulas
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    doc = json.loads(LEDGER.read_text(encoding="utf-8"))
    bad = shape(doc)
    for b in bad:
        print("SHAPE:", b)
    if "--test" in argv:
        return 1 if bad else run_tests(doc)
    only = next((a.split("=", 1)[1] for a in argv if a.startswith("--reading=")), None)
    entries = [e for e in doc["entries"] if not only or e["reading"] == only]
    for state in STATES:
        rows = [e for e in entries if e["state"] == state]
        if not rows:
            continue
        print(f"\n{state.upper()} ({len(rows)})")
        for e in rows:
            fl = e["floors"]
            where = f"floor {fl[0]}" if len(fl) == 1 else f"floors {fl[0]}-{fl[-1]}"
            print(f"  {e['id']} {e['reading']:8s} {e['status']:8s} {where:13s} needed by {e.get('needed_by', len(e['works'])):>2}"
                  + (f"  -> {e['proposal']}" if e.get("proposal") else "") + (f"  ({e['closed_by']})" if e.get("closed_by") else ""))
            print(f"      {e['misfit']}")
            print(f"      would change ({e['lands_in']}): {e['would_change']}")
            if e.get("second"):
                print(f"      the {e['second']['reading']} reading: {e['second']['says']}")
    if not only:
        print(f"\nPROPOSALS ({len(doc['proposals'])}) - waiting for Palle")
        for p in doc["proposals"]:
            t = p["test"]
            nums = ", ".join(f"{k} {t[k]}" for k in ("before", "after", "removes", "creates") if k in t)
            print(f"  {p['id']} {p['title']} - asked by {', '.join(p['asked_by'])}; {p['needed_by']}")
            print(f"      {p['in_words']}")
            print(f"      test ({t['reading']}): {nums}" + (f" - {t['note']}" if t.get("note") else ""))
            print(f"      forecloses: {p['forecloses']}")
    c = {s: sum(1 for e in doc["entries"] if e["state"] == s) for s in STATES}
    print(f"\n{len(doc['entries'])} entries: {c['open']} open, {c['kept']} kept, {c['closed']} closed; {len(doc['proposals'])} proposals; "
          f"floors {doc['pilot']['floors'][0]}-{doc['pilot']['floors'][1]}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
