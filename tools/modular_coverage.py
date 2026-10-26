#!/usr/bin/env python3
"""Does the grammar cover the spine's PRINCIPLES, not only its heroes?

Palle, 23 Oct 2026: "this does not cover all the elements in the spine. How can we cover all?
Not only the heroes are relevant, I mean all principles. Are they covered?"

The principles are what the sequence files STATE: every `learning_objectives` line, every
`content` line (one per map: "Map: Title — the principle"), and the sequence `truth`. This
tool reads all of them for the 25 spine sequences (≈ 425 statements) and asks, for each one,
whether the grammar has words for it — the 51 saved terms, the plan's 44 proposed families
(name, expression, axis values) and the five kernel pieces with their edges. The match is
LEXICAL: a statement is `covered` when a term or family names it, `kernel` when only a kernel
piece's words reach it (the machinery exists, no lesson stands on it yet), `uncovered` when
nothing in the grammar speaks of it. A hypothesis, coarse by design — its value is the
uncovered list, which is the next families to author, sequence by sequence.

    python tools/modular_coverage.py          # writes doc/book/course/MODULAR_COVERAGE.md
                                              #   + coverage into commons/data/modular_spine_plan.json
    python tools/modular_coverage.py --print
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import modular_spine_plan as plan  # noqa: E402  (the proposals, the kernel, the edges)

SEQ_DIR = ROOT / "commons/maps/sequences"
OUT = ROOT / "doc/book/course/MODULAR_COVERAGE.md"

STOP = set("""a an the and or of to in on for with by from as is are be at it its this that these those into
onto than then when where which who what how why not no one two three one's their there here each every all
any some more most less least into over under between through across along without within before after
first second third next last same other another such can could may might will would should must do does
did done make makes made use uses used using see sees show shows seen observe observed relate relates
compare compares distinguish distinguishes predict identify locate describe explain name names stage stages
particular familiar own very just only also both either neither still yet already again
you your we our us they them give gives take takes read reads""".split())   # 26 Oct: "take you", "gives", "reads" matched as content


def words(text: str) -> set[str]:
    return {w for w in re.findall(r"[a-z][a-z_]{2,}", text.lower().replace("-", "_")) if w not in STOP}


def stem(w: str) -> str:
    for suf in ("ings", "ing", "ies", "ers", "er", "es", "s", "ed", "al", "ly"):
        if w.endswith(suf) and len(w) - len(suf) >= 4:
            return w[: -len(suf)]
    return w


# The spine's words for the grammar's primitives: a statement that says "position" is
# talking about the point, "boundary" about the collider. Mapped onto the grammar's stems.
SYNONYMS = {
    "position": "point", "location": "point", "coordinate": "point", "vertex": "point", "dot": "point",
    "surface": "mesh", "appearance": "mesh", "visible": "mesh", "skin": "mesh", "face": "mesh",
    "boundary": "collider", "collision": "collider", "solid": "collider", "wall": "collider",
    "illumination": "light", "lamp": "light", "shadow": "light",
    "edge": "line", "segment": "line", "stroke": "line", "distance": "line", "length": "line",
    "repeat": "replicate", "repetition": "replicate", "copy": "replicate", "row": "array", "lattice": "grid",
    "stochastic": "random", "chance": "random", "dice": "random", "seed": "random",
    "iterate": "step", "iteration": "step", "tick": "step", "neighbour": "step", "neighbor": "step", "rule": "step",
    "oscillat": "sine", "wave": "sine", "period": "sine", "frequency": "sine", "phase": "sine",
    "gravity": "physics", "mass": "physics", "collide": "physics", "fall": "physics", "weight": "physics",
    "spring": "connect", "tension": "connect", "link": "connect", "relation": "connect", "edge_of": "connect",
    "material": "surface", "texture": "surface", "colour": "color", "paint": "color", "hue": "color",
    "threshold": "deadband", "resolution": "quantiser", "clamp": "shelf", "limit": "ceiling",
}


def stems(text: str) -> set[str]:
    out = set()
    for w in words(text):
        s = stem(w)
        out.add(s)
        for key, val in SYNONYMS.items():
            if w.startswith(key) or s.startswith(key):
                out.add(val)
        for part in w.split("_"):
            if len(part) >= 4 and part not in STOP:
                out.add(stem(part))
    return out


def vocabulary() -> tuple[dict[str, set[str]], dict[str, set[str]], dict[str, set[str]]]:
    """terms (saved), families (proposed), kernel (pieces + edges) → name → stems"""
    terms_doc = json.loads(plan.TERMS.read_text(encoding="utf-8"))
    terms = {}
    for tid, t in terms_doc["terms"].items():
        terms[tid] = stems(f"{tid} {t.get('label', '')} {t.get('expr', '')} {t.get('chapter', '')}")
    fams = {}
    for seq, p in plan.PROPOSALS.items():
        for name, expr, axis in p["families"]:
            fams[f"{seq}:{name}"] = stems(f"{name} {expr} {axis.replace('|', ' ').replace(':', ' ')} {p['room']}")
    kernel = {}
    for key, text in plan.KERNEL.items():
        rows = plan.EDGES.get(key, [])
        kernel[key] = stems(f"{key} {text} " + " ".join(" ".join(r) for r in rows))
    return terms, fams, kernel


def principles(seq_name: str) -> list[dict]:
    f = SEQ_DIR / f"{seq_name}.json"
    if not f.exists():
        return []
    d = json.loads(f.read_text(encoding="utf-8"))
    sq = d["sequences"].get(seq_name) or next(iter(d["sequences"].values()))
    out = []
    if sq.get("truth"):
        out.append(dict(kind="truth", text=str(sq["truth"]), map=""))
    for lo in sq.get("learning_objectives", []) or []:
        out.append(dict(kind="objective", text=str(lo), map=""))
    for c in sq.get("content", []) or []:
        c = str(c)
        m = re.match(r"\s*([A-Za-z0-9_]+)\s*:\s*(.*)", c)
        out.append(dict(kind="content", text=m.group(2) if m else c, map=m.group(1) if m else ""))
    return out


def best(st: set[str], vocab: dict[str, set[str]], need: int) -> tuple[str, int]:
    hit, score = "", 0
    for name, v in vocab.items():
        n = len(st & v)
        if n > score:
            hit, score = name, n
    return (hit, score) if score >= need else ("", 0)


def coverage() -> list[dict]:
    terms, fams, kernel = vocabulary()
    spine, _, _, _ = plan.load()
    out = []
    for s in spine:
        name = s["name"]
        own_terms = {k: v for k, v in terms.items()} if True else {}
        own_fams = {k: v for k, v in fams.items() if k.startswith(name + ":")}
        rows = []
        for pr in principles(name):
            st = stems(pr["text"])
            # two shared stems — or all of them, when the principle has fewer: a one-word title ("Metaballs",
            # "Caves") can share at most one, and at two it could never count, whatever the grammar held
            # (26 Oct: the field terms metaballs, gyroid, cave_chamber were reported "uncovered" this way)
            need = min(2, len(st)) or 2
            f_hit, f_n = best(st, own_fams, need)
            t_hit, t_n = best(st, {**own_terms, **fams}, need)
            k_hit, k_n = best(st, kernel, need)
            if f_hit or t_hit:
                status, by = "covered", (f_hit if f_n >= t_n else t_hit)
            elif k_hit:
                status, by = "kernel", k_hit
            else:
                status, by = "uncovered", ""
            rows.append(dict(**pr, status=status, by=by.split(":")[-1]))
        c = {k: sum(1 for r in rows if r["status"] == k) for k in ("covered", "kernel", "uncovered")}
        out.append(dict(order=s["order"], name=name, principles=rows, counts=c, total=len(rows)))
    return out


def render(cov: list[dict]) -> str:
    tot = {k: sum(c["counts"][k] for c in cov) for k in ("covered", "kernel", "uncovered")}
    _t, _f, _k = vocabulary()
    n_terms, n_fams = len(_t), len(_f)
    n = sum(c["total"] for c in cov)
    L = ["# Does the grammar cover the spine's principles?\n",
         "*Generated by `tools/modular_coverage.py` from the 25 spine sequence files (`truth`, `learning_objectives`, "
         f"`content`), the {n_terms} saved terms, the plan's {n_fams} proposed families and the five kernel pieces. The match is "
         "lexical and coarse: `covered` means a term or family names the principle, `kernel` means only a kernel "
         "piece's words reach it (the machinery exists, no lesson stands on it), `uncovered` means nothing in the "
         "grammar speaks of it. Palle, 23 Oct 2026: \"not only the heroes are relevant, I mean all principles. Are "
         "they covered?\"*\n",
         f"**{n} principles** stated by the spine: **{tot['covered']} covered, {tot['kernel']} reached only by the "
         f"kernel, {tot['uncovered']} uncovered.** The uncovered list, sequence by sequence, is the next families to "
         "author — and it is where the plan's hero-twins were not enough.\n",
         "| # | sequence | principles | covered | kernel only | uncovered |", "|---|---|---|---|---|---|"]
    for c in cov:
        L.append(f"| {c['order']} | {c['name']} | {c['total']} | {c['counts']['covered']} | {c['counts']['kernel']} | "
                 f"**{c['counts']['uncovered']}** |")
    L.append("")
    # what the uncovered principles are ABOUT: not things, but what is done with things
    classes = {
        "compare — two things under one rule": r"compar|distinguish|differ|versus|same|equal|contrast|relate",
        "measure — a value read off a thing": r"measur|entropy|count|magnitude|length|dimension|quantity|ratio|rate|threshold|resolution|share|projection|readout|estimate",
        "procedure — sample, select, filter, order": r"sampl|select|filter|draw|order|sequence|procedure|eligib|clip|rebin|assign|choose|choice",
        "retain — state kept across steps": r"retain|record|history|memory|stored|state|trail|accumulat|persist|remember",
        "body — reach, gait, hand, passage": r"body|visitor|hand|gait|walk|passage|reach|traverse|support|contract",
        "frame — origin, display, representation": r"frame|origin|display|diagram|representation|claim|interpret|notation|formula",
    }
    unc = [r for c in cov for r in c["principles"] if r["status"] != "covered"]
    hits = {k: sum(1 for r in unc if re.search(rx, r["text"].lower())) for k, rx in classes.items()}
    L.append("## What the uncovered principles are about\n")
    L.append(f"Read as a whole, the {len(unc)} principles the grammar does not cover are not missing THINGS. They are "
             "what is done with things — the spine's principles are verbs, and the grammar so far has only nouns. "
             "Counted by the words they use (a statement can fall in more than one class):\n")
    L.append("| class | principles |")
    L.append("|---|---|")
    for k, v in sorted(hits.items(), key=lambda kv: -kv[1]):
        L.append(f"| {k} | {v} |")
    L.append("")
    L.append("**So the way to cover all of them is not more families; it is a sixth kernel piece — `measure`, added to the "
             "plan on Palle's word (23 Oct: \"add measure as the sixth piece\").** A value read off a thing (a length, a "
             "count, an entropy, a projection), `retain`ed across steps (a record, a trail, a history — the sibling of "
             "`trace_data`, which already carries what a visitor meant) and `compare`d with another under a stated rule. "
             "It is the instrument half of the grammar: every hall that says *compare*, *distinguish*, *measure* or "
             "*retain* stands on it. It has edges like the rest — the measure's resolution (quantiser), what the record "
             "forgets (window), what the comparison equates (coupling) — and its leaks go to the same bus. Eight families "
             "stand on it so far (length, velocity_readout, entropy_meter, spectrum_reading, field_probe, loss_meter, "
             "dial_reading, rule_census); the uncovered list below is where the next ones go. The body class (reach, "
             "gait, passage) is the visitor's own contract and belongs to the walk model, not the grammar; the frame "
             "class is the lesson every measure carries about its own origin.\n")
    L.append("## The uncovered principles — what the grammar has no words for yet\n")
    for c in cov:
        unc = [r for r in c["principles"] if r["status"] != "covered"]
        if not unc:
            continue
        L.append(f"### {c['order']}. {c['name']} — {c['counts']['uncovered']} uncovered, {c['counts']['kernel']} kernel only\n")
        for r in unc:
            tag = f" *(kernel: {r['by']})*" if r["status"] == "kernel" else ""
            where = f" `{r['map']}`" if r["map"] else ""
            L.append(f"- [{r['kind']}]{where} {r['text']}{tag}")
        L.append("")
    L.append("## The covered principles — and what covers them\n")
    for c in cov:
        cov_rows = [r for r in c["principles"] if r["status"] == "covered"]
        if not cov_rows:
            continue
        L.append(f"### {c['order']}. {c['name']}\n")
        for r in cov_rows:
            where = f" `{r['map']}`" if r["map"] else ""
            L.append(f"- [{r['kind']}]{where} {r['text']} → `{r['by']}`")
        L.append("")
    return "\n".join(L)


def main() -> int:
    cov = coverage()
    text = render(cov)
    if "--print" in sys.argv:
        print(text)
        return 0
    OUT.write_text(text, encoding="utf-8")
    # the numbers ride along in the plan's JSON so /modular-plan can draw them
    if plan.JSON_OUT.exists():
        doc = json.loads(plan.JSON_OUT.read_text(encoding="utf-8"))
        by = {c["name"]: dict(c["counts"], total=c["total"]) for c in cov}
        for s in doc["sequences"]:
            s["coverage"] = by.get(s["name"])
        doc["coverage"] = {c["name"]: [dict(kind=r["kind"], map=r["map"], text=r["text"], status=r["status"], by=r["by"]) for r in c["principles"]] for c in cov}
        plan.JSON_OUT.write_text(json.dumps(doc, indent=1), encoding="utf-8")
    tot = {k: sum(c["counts"][k] for c in cov) for k in ("covered", "kernel", "uncovered")}
    print(f"wrote {OUT.relative_to(ROOT)} — {sum(c['total'] for c in cov)} principles: {tot}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
