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

Commands:
  python tools/order_grammar.py check doc/book/order_pilot/randomness_draft.md
  python tools/order_grammar.py report doc/book/order_pilot/randomness_draft.md
      -> doc/reports/order_pilot_randomness.json
      -> ../ada_encyclopedia/public/order-pilot.json  (the /order-pilot page)
"""
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENC = ROOT.parent / "ada_encyclopedia"
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

K_CRITIQUE = 4          # R4 window (sections)

# the concept lexicon: id -> (cast artifact, alias regexes)
CONCEPTS = {
    "uniform":    ("coin_toss", ["coin", "flip", "heads", "tails", "fifty-fifty", "uniform"]),
    "walk":       ("random_walk_leash", ["walk", "step", "wander", "drunkard"]),
    "distribution": ("distribution_comparator", ["distribution", "histogram", "shape of chance", "comparator", "cluster"]),
    "gaussian":   ("galton_board", ["gaussian", "bell", "normal", "galton", "peg", "pile"]),
    "entropy":    ("shannon_entropy_meter", ["entropy", "disorder", "surprise", "bits", "shannon"]),
    "seed":       ("seed_replay_demo", ["seed", "replay", "same sequence", "deterministic chance"]),
    "prng":       ("prng_crank_machine", ["pseudo", "prng", "crank", "generator", "formula chance"]),
    "trng":       ("hardware_entropy_decay", ["true random", "trng", "hardware", "decay", "physical noise"]),
    "paint":      ("pollock_painting_in_3d", ["pollock", "paint", "drip", "splatter", "gesture"]),
    "montecarlo": ("monte_carlo_dartboard", ["monte carlo", "dartboard", "dart", "estimate", "pi by throwing"]),
    "book1955":   ("random_number_book_page_1955", ["1955", "rand book", "printed table", "page of digits"]),
}

BASELINE_ORDER = ["uniform", "walk", "distribution", "gaussian", "entropy",
                  "seed", "prng", "paint", "montecarlo"]   # beat order (trng/book are voltage)


def parse_sections(text: str):
    """[{n, title, register, body}] from the pilot format."""
    out = []
    blocks = re.split(r"^## +", text, flags=re.M)[1:]
    for b in blocks:
        lines = b.strip().splitlines()
        head = lines[0].strip()
        m = re.match(r"(\d+)\.\s*(.*)", head)
        n = int(m.group(1)) if m else len(out) + 1
        title = m.group(2) if m else head
        register = "walk"
        body_lines = []
        for ln in lines[1:]:
            r = re.match(r"\*register:\s*(walk|turn)\*", ln.strip(), re.I)
            if r:
                register = r.group(1).lower()
                continue
            body_lines.append(ln)
        body = "\n".join(body_lines).split("<!-- order-declaration")[0].strip()
        out.append({"n": n, "title": title, "register": register, "body": body})
    return out


def mentions(body: str) -> set:
    low = " " + re.sub(r"[^a-z0-9\- ]", " ", body.lower()) + " "
    hit = set()
    for cid, (_, aliases) in CONCEPTS.items():
        for a in aliases:
            if re.search(r"(?<![a-z0-9])" + re.escape(a) + r"(?![a-z0-9])", low):
                hit.add(cid)
                break
    return hit


def check(sections):
    """returns (intro_order, per-section mentions, violations[])"""
    intro = {}
    per = []
    violations = []
    for i, s in enumerate(sections):
        ment = mentions(s["body"] + " " + s["title"])
        new = sorted(m for m in ment if m not in intro)
        per.append({"n": s["n"], "register": s["register"], "title": s["title"],
                    "mentions": sorted(ment), "introduces": new})
        if len(new) > 1:
            violations.append({"rule": "R1", "section": s["n"],
                               "detail": f"introduces {len(new)} concepts: {', '.join(new)}"})
        for c in new:
            if s["register"] == "turn":
                violations.append({"rule": "R2", "section": s["n"],
                                   "detail": f"'{c}' debuts in a turn section"})
            if intro and not (ment & set(intro)):
                violations.append({"rule": "R3", "section": s["n"],
                                   "detail": f"'{c}' arrives without any earlier concept"})
            intro[c] = i
    # R4: a turn within K sections after intro
    for c, i in intro.items():
        window = sections[i + 1: i + 1 + K_CRITIQUE]
        hit = any(s["register"] == "turn" and c in mentions(s["body"] + " " + s["title"])
                  for s in window)
        # the intro section itself being a turn is impossible (R2); same-section ok if turn follows
        if not hit:
            violations.append({"rule": "R4", "section": sections[i]["n"],
                               "detail": f"'{c}' never meets a turn within {K_CRITIQUE} sections"})
    # R5: used again before the next debut
    order = sorted(intro, key=lambda c: intro[c])
    for a, b in zip(order, order[1:]):
        ia, ib = intro[a], intro[b]
        used = any(a in p["mentions"] for p in per[ia + 1: ib + 1])
        if not used:
            violations.append({"rule": "R5", "section": sections[ib]["n"],
                               "detail": f"'{b}' debuts before '{a}' was ever used again"})
    return order, per, violations


def kendall(a: list, b: list) -> float:
    """kendall tau over the concepts present in both."""
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


def three_orders_ranks():
    """cast-artifact -> {ped, onto, crit} class ranks from three_orders.py."""
    try:
        r = subprocess.run([sys.executable, "tools/three_orders.py", "randomness"],
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
    text = path.read_text(encoding="utf-8")
    sections = parse_sections(text)
    order, per, violations = check(sections)
    print(f"sections: {len(sections)}  concepts introduced: {len(order)}/{len(CONCEPTS)}")
    print("written order:", " -> ".join(order))
    if violations:
        print(f"VIOLATIONS ({len(violations)}):")
        for v in violations:
            print(f"  [{v['rule']}] section {v['section']}: {v['detail']}")
    else:
        print("GRAMMAR CLEAN — all five rules hold")
    if sys.argv[1] == "check":
        return 0 if not violations else 2

    # report: diff against baseline + three orders, emit page data
    decl = ""
    m = re.search(r"<!-- order-declaration(.*?)-->", text, re.S)
    if m:
        decl = m.group(1).strip()
    t3 = three_orders_ranks()
    rows = []
    for c in order:
        cast = CONCEPTS[c][0]
        r3 = t3.get(cast, {})
        rows.append({"concept": c, "cast": cast,
                     "written": order.index(c),
                     "baseline": BASELINE_ORDER.index(c) if c in BASELINE_ORDER else None,
                     "ped": r3.get("ped"), "onto": r3.get("onto"), "crit": r3.get("crit")})
    tau_baseline = kendall(order, BASELINE_ORDER)

    def class_order(key):
        have = [r for r in rows if r[key] is not None]
        return [r["concept"] for r in sorted(have, key=lambda r: (r[key], order.index(r["concept"])))]
    taus = {"baseline": tau_baseline,
            "pedagogy": kendall(order, class_order("ped")),
            "ontology": kendall(order, class_order("onto")),
            "criticality": kendall(order, class_order("crit"))}
    report = {"sequence": "randomness",
              "written_order": order, "baseline_order": BASELINE_ORDER,
              "agreement_kendall": taus, "rows": rows,
              "sections": per,
              "text_sections": sections,
              "violations": violations,
              "declaration": decl,
              "grammar": {"R1": "one concept per section", "R2": "debut in walk, never turn",
                          "R3": "the new arrives through the old",
                          "R4": f"a turn within {K_CRITIQUE} sections",
                          "R5": "used again before the next debut"}}
    out1 = ROOT / "doc" / "reports" / "order_pilot_randomness.json"
    out1.write_text(json.dumps(report, indent=1), encoding="utf-8", newline="\n")
    out2 = ENC / "public" / "order-pilot.json"
    out2.write_text(json.dumps(report, indent=1), encoding="utf-8", newline="\n")
    print(f"agreement (kendall tau): baseline {taus['baseline']}  ped {taus['pedagogy']}  "
          f"onto {taus['ontology']}  crit {taus['criticality']}")
    print(f"-> {out1}")
    print(f"-> {out2}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
