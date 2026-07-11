#!/usr/bin/env python3
"""order_grammar.py — THE ORDER IS WRITTEN, NOT PLANNED.

Palle: "the writing can produce the order of the artifacts... introducing one
concept at a time, building and criting... the order in the text is natural
because it has good rules, discovered, and iterated. Then we have an order we
can lean on."

Five mechanical rules make 'natural order' checkable (the em-square move,
applied to prose sequence):
  R1 ONE-AT-A-TIME    each section introduces at most one new concept
  R2 WALK-DEBUT       first mention happens in a walk section, never a turn
  R3 BUILD            the new arrives through the old (intro section mentions
                      an earlier concept)
  R4 CRITIQUE-FOLLOWS every concept meets a turn section within K sections
  R5 EARN-THE-NEXT    the previous concept is used again before the next debuts

Per-sequence lexicon: doc/book/order_pilot/<seq>_lexicon.json
  {"baseline_order": [concept ids in beat order],
   "concepts": {id: {"cast": artifact, "aliases": [words]}},
   "aside": [artifacts the concepts do NOT cover — the honest leftover]}

Commands (seq derived from the draft filename <seq>_draft.md):
  python tools/order_grammar.py check  doc/book/order_pilot/<seq>_draft.md
  python tools/order_grammar.py report doc/book/order_pilot/<seq>_draft.md
      -> doc/reports/order_pilot_<seq>.json
      -> ../ada_encyclopedia/public/order-pilot/<seq>.json (+ index.json)
"""
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENC = ROOT.parent / "ada_encyclopedia"
PILOT = ROOT / "doc" / "book" / "order_pilot"
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

K_CRITIQUE = 4          # R4 window (sections)


def load_lexicon(seq: str):
    p = PILOT / f"{seq}_lexicon.json"
    d = json.loads(p.read_text(encoding="utf-8"))
    return d["concepts"], d["baseline_order"], d.get("aside", [])


def parse_sections(text: str):
    out = []
    # split only on real section heads (## <n>. ...) so a quoted GDScript
    # doc-comment line (## Foo) inside a code section never splits.
    blocks = re.split(r"^## +(?=\d)", text, flags=re.M)[1:]
    for b in blocks:
        lines = b.strip().splitlines()
        head = lines[0].strip()
        m = re.match(r"(\d+)\.\s*(.*)", head)
        n = int(m.group(1)) if m else len(out) + 1
        title = m.group(2) if m else head
        register = "walk"
        body_lines = []
        for ln in lines[1:]:
            r = re.match(r"\*register:\s*(walk|turn|code)\*", ln.strip(), re.I)
            if r:
                register = r.group(1).lower()
                continue
            body_lines.append(ln)
        body = "\n".join(body_lines).split("<!-- order-declaration")[0].strip()
        out.append({"n": n, "title": title, "register": register, "body": body})
    return out


def mentions(body: str, concepts: dict) -> set:
    low = " " + re.sub(r"[^a-z0-9\- ]", " ", body.lower()) + " "
    hit = set()
    for cid, spec in concepts.items():
        for a in spec["aliases"]:
            if re.search(r"(?<![a-z0-9])" + re.escape(a.lower()) + r"(?![a-z0-9])", low):
                hit.add(cid)
                break
    return hit


_SRC_CACHE = {}


def find_source(cast: str):
    """repo-relative path of <cast>.gd (under algorithms/ or commons/), or None
    — so R6 can confirm a code section quotes a REAL file, not pseudocode."""
    if cast in _SRC_CACHE:
        return _SRC_CACHE[cast]
    hit = None
    for base in ("algorithms", "commons"):
        d = ROOT / base
        if not d.exists():
            continue
        for p in d.rglob(cast + ".gd"):
            if ".claude" in p.parts:
                continue
            hit = str(p.relative_to(ROOT)).replace("\\", "/")
            break
        if hit:
            break
    _SRC_CACHE[cast] = hit
    return hit


def code_casts(body: str, concepts: dict) -> set:
    """concepts whose cast-artifact token appears in a code body (code sections
    are tied to a concept by the source they quote, NOT by alias-scan — a
    variable name like _heads_count must not count as the concept 'uniform')."""
    low = body.lower()
    return {cid for cid, spec in concepts.items()
            if str(spec.get("cast", "")).lower()
            and str(spec["cast"]).lower() in low}


def check(sections, concepts):
    intro = {}
    per = []
    violations = []
    for i, s in enumerate(sections):
        reg = s["register"]
        if reg == "code":
            cc = code_casts(s["body"], concepts)
            per.append({"n": s["n"], "register": reg, "title": s["title"],
                        "mentions": sorted(cc), "introduces": []})
            continue
        ment = mentions(s["body"] + " " + s["title"], concepts)
        new = sorted(m for m in ment if m not in intro)
        per.append({"n": s["n"], "register": reg, "title": s["title"],
                    "mentions": sorted(ment), "introduces": new})
        if len(new) > 1:
            violations.append({"rule": "R1", "section": s["n"],
                               "detail": f"introduces {len(new)} concepts: {', '.join(new)}"})
        for c in new:
            if reg == "turn":
                violations.append({"rule": "R2", "section": s["n"],
                                   "detail": f"'{c}' debuts in a turn section"})
            if intro and not (ment & set(intro)):
                violations.append({"rule": "R3", "section": s["n"],
                                   "detail": f"'{c}' arrives without any earlier concept"})
            intro[c] = i
    for c, i in intro.items():
        window = sections[i + 1: i + 1 + K_CRITIQUE]
        hit = any(s["register"] == "turn" and c in mentions(s["body"] + " " + s["title"], concepts)
                  for s in window)
        if not hit:
            violations.append({"rule": "R4", "section": sections[i]["n"],
                               "detail": f"'{c}' never meets a turn within {K_CRITIQUE} sections"})
    order = sorted(intro, key=lambda c: intro[c])
    for a, b in zip(order, order[1:]):
        ia, ib = intro[a], intro[b]
        used = any(a in p["mentions"] for p in per[ia + 1: ib + 1])
        if not used:
            violations.append({"rule": "R5", "section": sections[ib]["n"],
                               "detail": f"'{b}' debuts before '{a}' was ever used again"})
    # R6 CODE REGISTER (opt-in — the walk->code->turn hinge). If the chapter
    # shows source at all, it must show it right: >= 3 code sections, each
    # quoting a concept's REAL .gd, each placed after that concept's walk and
    # at/before its critiquing turn.
    code_secs = [(i, s) for i, s in enumerate(sections) if s["register"] == "code"]
    if code_secs:
        crit_turn = {}
        for c, di in intro.items():
            for j in range(di + 1, len(sections)):
                if sections[j]["register"] == "turn" and c in mentions(
                        sections[j]["body"] + " " + sections[j]["title"], concepts):
                    crit_turn[c] = j
                    break
        valid = 0
        for j, s in code_secs:
            for c in code_casts(s["body"], concepts):
                di = intro.get(c)
                if di is None or not find_source(concepts[c]["cast"]):
                    continue
                if di < j <= crit_turn.get(c, len(sections)):
                    valid += 1
                    break
        if valid < 3:
            violations.append({"rule": "R6", "section": 0,
                               "detail": f"{valid} valid code section(s); need >=3 "
                                         f"(each quotes a real .gd, placed walk->code->turn)"})
    return order, per, violations


def kendall(a: list, b: list) -> float:
    common = [x for x in a if x in b]
    if len(common) < 2:
        return 0.0
    pos_b = {c: b.index(c) for c in common}
    conc = disc = 0
    for i in range(len(common)):
        for j in range(i + 1, len(common)):
            d = pos_b[common[i]] - pos_b[common[j]]
            if d < 0:
                conc += 1
            elif d > 0:
                disc += 1
    n = conc + disc
    return round((conc - disc) / n, 3) if n else 0.0


def three_orders_ranks(seq: str):
    try:
        r = subprocess.run([sys.executable, "tools/three_orders.py", seq],
                           capture_output=True, text=True, cwd=ROOT, timeout=120)
        txt = r.stdout
    except Exception:
        return {}
    ranks = {}
    for line in txt.splitlines():
        m = re.match(r"\s*\*?\s*([A-Za-z0-9_]+)\s+ped:(\w+)\s+onto:(\w+)\s+crit:(\w+)", line)
        if m:
            cls = {"early": 0, "mid": 1, "late": 2}
            ranks[m.group(1)] = {"ped": cls.get(m.group(2), 1),
                                 "onto": cls.get(m.group(3), 1),
                                 "crit": cls.get(m.group(4), 1)}
    return ranks


def main():
    if len(sys.argv) < 3 or sys.argv[1] not in ("check", "report"):
        print(__doc__)
        return 1
    path = ROOT / sys.argv[2]
    seq = path.stem.replace("_draft", "")
    concepts, baseline_order, aside = load_lexicon(seq)
    text = path.read_text(encoding="utf-8")
    sections = parse_sections(text)
    order, per, violations = check(sections, concepts)
    print(f"[{seq}] sections: {len(sections)}  concepts introduced: {len(order)}/{len(concepts)}")
    print("written order:", " -> ".join(order))
    missing = [c for c in concepts if c not in order]
    if missing:
        violations.append({"rule": "R0", "section": 0,
                           "detail": f"never introduced: {', '.join(missing)}"})
    if violations:
        print(f"VIOLATIONS ({len(violations)}):")
        for v in violations:
            print(f"  [{v['rule']}] section {v['section']}: {v['detail']}")
    else:
        print("GRAMMAR CLEAN — all five rules hold")
    if sys.argv[1] == "check":
        return 0 if not violations else 2

    decl = ""
    m = re.search(r"<!-- order-declaration(.*?)-->", text, re.S)
    if m:
        decl = m.group(1).strip()
    t3 = three_orders_ranks(seq)
    rows = []
    for c in order:
        cast = concepts[c]["cast"]
        r3 = t3.get(cast, {})
        rows.append({"concept": c, "cast": cast,
                     "written": order.index(c),
                     "baseline": baseline_order.index(c) if c in baseline_order else None,
                     "ped": r3.get("ped"), "onto": r3.get("onto"), "crit": r3.get("crit")})

    def class_order(key):
        have = [r for r in rows if r[key] is not None]
        return [r["concept"] for r in sorted(have, key=lambda r: (r[key], order.index(r["concept"])))]
    taus = {"baseline": kendall(order, baseline_order),
            "pedagogy": kendall(order, class_order("ped")),
            "ontology": kendall(order, class_order("onto")),
            "criticality": kendall(order, class_order("crit"))}
    report = {"sequence": seq,
              "written_order": order, "baseline_order": baseline_order,
              "agreement_kendall": taus, "rows": rows,
              "sections": per,
              "text_sections": sections,
              "violations": violations,
              "declaration": decl,
              "aside": aside,
              "grammar": {"R1": "one concept per section", "R2": "debut in walk, never turn",
                          "R3": "the new arrives through the old",
                          "R4": f"a turn within {K_CRITIQUE} sections",
                          "R5": "used again before the next debut"}}
    out1 = ROOT / "doc" / "reports" / f"order_pilot_{seq}.json"
    out1.write_text(json.dumps(report, indent=1), encoding="utf-8", newline="\n")
    outdir = ENC / "public" / "order-pilot"
    outdir.mkdir(parents=True, exist_ok=True)
    (outdir / f"{seq}.json").write_text(json.dumps(report, indent=1),
                                        encoding="utf-8", newline="\n")
    idx_p = outdir / "index.json"
    idx = {"sequences": []}
    if idx_p.exists():
        idx = json.loads(idx_p.read_text(encoding="utf-8"))
    entry = {"seq": seq, "concepts": len(order), "clean": not violations,
             "tau_baseline": taus["baseline"]}
    idx["sequences"] = [e for e in idx["sequences"] if e["seq"] != seq] + [entry]
    idx_p.write_text(json.dumps(idx, indent=1), encoding="utf-8", newline="\n")
    print(f"agreement (kendall tau): baseline {taus['baseline']}  ped {taus['pedagogy']}  "
          f"onto {taus['ontology']}  crit {taus['criticality']}")
    print(f"-> {out1}")
    print(f"-> {outdir / (seq + '.json')}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
