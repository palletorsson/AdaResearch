#!/usr/bin/env python3
"""dig_report.py — the deep dig: roles, counters, and blanks for a chapter (R-008).

Replaces withholding with finding. For a sequence, this evaluates EVERY pearl —
walked and at depth — and proposes:

  roles      load-bearing / counter / side / ornament / prop for the walked ring
  promotions depth artifacts the chapter probably needs (with reasons)
  counters   opposed pairs (kin by concept, opposed by operation) — the λ tension
  burials    what stays at depth, WITH REASONS (not a count)
  blanks     declared gaps that couple the book and the game (open slot = empty plinth)

All scores are transparent heuristics with reason strings; the report PROPOSES,
the rulings decide (trench protocol). Signals used: sequence truth/formula overlap,
@identity theory-claim strength (qfep_signal), ladder concept anchoring, capture
presence, measured scale, and operation-polarity axes mined from the artifacts'
own texts.

Usage:  python tools/dig_report.py randomness fractals
Output: doc/book/dig_reports/<seq>.md
"""
from __future__ import annotations

import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.environ.get("ADA_ENCYCLOPEDIA_PATH", "C:/Users/palle/Documents/GitHub/ada_encyclopedia")
sys.path.insert(0, os.path.join(REPO, "tools"))
from qfep_signal import build_critical_index  # noqa: E402

TUTORIAL_DIR = os.path.join(ENC, "public", "tutorial")
THREE_ORDERS = os.path.join(ENC, "public", "three-orders.json")
CAPTURES = os.path.join(ENC, "public", "artifact-gallery", "captures")
SEQ_DIR = os.path.join(REPO, "commons", "maps", "sequences")
REG_DIR = os.path.join(REPO, "commons", "artifacts", "registry")
SIZES = os.path.join(REPO, "commons", "data", "artifact_sizes.json")
DOC = os.path.join(REPO, "doc")
OUT_DIR = os.path.join(REPO, "doc", "book", "dig_reports")

CONCEPT_MAP_ALIASES = {"fractals": "fractal", "cellularautomata": "ca", "lsystems": "lsystem",
                       "softbodies": "softbody", "proceduralgeneration": "procgen",
                       "foundationscrisis": "foundations", "qfeplaboratory": "qfep",
                       "postfoundationscrisis": "postcrisis"}

# operation-polarity axes: (name, side A keywords, side B keywords)
AXES = [
    ("build/remove", ("add", "grow", "build", "accumulat", "stack", "copies", "spawn", "branch"),
     ("remove", "subtract", "delete", "erase", "take away", "taking away", "carve", "cut", "deplet")),
    ("determinism/chance", ("determinist", "fixed rule", "exact", "seed", "same every", "predictab"),
     ("random", "stochastic", "chance", "unpredictab", "probabil")),
    ("order/entropy", ("order", "regular", "uniform", "structure", "f_order", "stable"),
     ("entropy", "disorder", "chaos", "e_entropy", "mixing", "decay")),
    ("continuous/discrete", ("continuous", "smooth", "analog", "infinite detail"),
     ("discrete", "threshold", "bits", "grid", "voxel", "sample")),
]

STOP = set("the a an of and or to in on for with is are be as by from at it its this that not "
           "artifact vr demo scene example".split())


def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def tokens(s: str) -> set[str]:
    return {w for w in re.findall(r"[a-z]{3,}", (s or "").lower()) if w not in STOP}


def load_registry() -> dict:
    out = {}
    for f in sorted(os.listdir(REG_DIR)):
        if not f.endswith(".json"):
            continue
        d = load_json(os.path.join(REG_DIR, f))
        if not isinstance(d, dict):
            continue
        arts = d.get("artifacts") if isinstance(d.get("artifacts"), dict) else d
        for k, v in arts.items():
            if isinstance(v, dict) and k not in out:
                out[k] = v
    return out


def seq_def(seq_id: str) -> dict:
    d = load_json(os.path.join(SEQ_DIR, f"{seq_id}.json")) or {}
    s = d.get("sequences")
    if isinstance(s, list) and s:
        return s[0]
    if isinstance(s, dict) and s:
        return next(iter(s.values()))
    return d


def ladder_concepts(seq: str) -> dict[str, str]:
    stem = CONCEPT_MAP_ALIASES.get(seq, seq)
    cm = load_json(os.path.join(DOC, f"{stem}_concept_map.json"))
    out: dict[str, str] = {}
    if not isinstance(cm, dict):
        return out
    for concept, meta in (cm.get("concept_meta") or {}).items():
        for names in (meta.get("tiers") or {}).values():
            for n in names or []:
                out.setdefault(n, concept)
    return out


def polarity(text: str) -> dict[str, int]:
    t = (text or "").lower()
    out = {}
    for name, a, b in AXES:
        va = any(k in t for k in a)
        vb = any(k in t for k in b)
        if va and not vb:
            out[name] = 1
        elif vb and not va:
            out[name] = -1
    return out


def main() -> int:
    targets = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not targets:
        print("usage: dig_report.py <seq> [<seq> ...]")
        return 1
    registry = load_registry()
    crit = build_critical_index()
    sizes = (load_json(SIZES) or {}).get("sizes") or {}
    to = load_json(THREE_ORDERS) or {}
    orders = {s["seq"]: s for s in to.get("sequences", [])}
    os.makedirs(OUT_DIR, exist_ok=True)

    for seq in targets:
        t = load_json(os.path.join(TUTORIAL_DIR, f"{seq}.json"))
        entry = orders.get(seq)
        if not t or not entry:
            print(f"!! missing tutorial or pearls for {seq}")
            continue
        sd = seq_def(seq)
        seq_text = " ".join(str(sd.get(k, "")) for k in ("truth", "formula", "description",
                                                         "qfep_connection", "qfep_term"))
        seq_tok = tokens(seq_text)
        concepts = ladder_concepts(seq)

        walked = []
        for p in t.get("pages", []):
            if p["kind"] == "primitive" and isinstance(p.get("artifact"), dict):
                walked.append(p["artifact"]["name"])
            elif p["kind"] == "walk":
                walked += [a["name"] for a in p.get("artifacts") or []]
        pearls = list(dict.fromkeys(entry["pearls"]))
        depth = [p for p in pearls if p not in walked]

        def record(name: str) -> dict:
            reg = registry.get(name, {})
            c = crit.get(name, {})
            text = " ".join([str(reg.get("description", "")), str(reg.get("qfep_connection", "")),
                             c.get("crit_text") or ""])
            tok = tokens(text) | tokens(name.replace("_", " "))
            overlap = len(tok & seq_tok)
            claim = len(c.get("crit_text") or "")
            cap = os.path.exists(os.path.join(CAPTURES, name, "front.png"))
            sz = sizes.get(name) or {}
            base = sz.get("base_m") if isinstance(sz, dict) else None
            lb = min(3, overlap // 3) + (2 if claim > 120 else 1 if claim > 40 else 0) \
                + (1 if name in concepts else 0)
            reasons = []
            if overlap >= 3:
                reasons.append(f"echoes the sequence truth ({overlap} shared terms)")
            if claim > 120:
                reasons.append("strong @identity theory-claim")
            elif claim == 0:
                reasons.append("mute (no @identity)")
            if not cap:
                reasons.append("no capture — invisible to the book")
            return {"name": name, "lb": lb, "reasons": reasons, "claim": claim, "cap": cap,
                    "concept": concepts.get(name), "pol": polarity(text), "tok": tok,
                    "base": base, "role_hint": (c.get("role") or "content")}

        W = [record(n) for n in walked]
        D = [record(n) for n in depth]

        # roles for the walked ring
        Ws = sorted(W, key=lambda r: -r["lb"])
        load_bearing = [r["name"] for r in Ws[:2] if r["lb"] >= 4] or [Ws[0]["name"]]
        for r in W:
            if r["name"] in load_bearing:
                r["role"] = "load-bearing"
            elif r["role_hint"] == "ambient":
                r["role"] = "ornament"
            elif r["claim"] == 0 and r["lb"] <= 1:
                r["role"] = "ornament?"
            else:
                r["role"] = "side"

        # counters: kin (shared concept or >=4 shared tokens) + opposed on >=1 axis
        def opposed(a, b):
            axes = [ax for ax in a["pol"] if ax in b["pol"] and a["pol"][ax] * b["pol"][ax] < 0]
            kin = (a["concept"] and a["concept"] == b["concept"]) or len(a["tok"] & b["tok"]) >= 4
            return axes if (axes and kin) else None

        counters = []
        pool = W + [d for d in D if d["lb"] >= 3]
        for i, a in enumerate(pool):
            for b in pool[i + 1:]:
                axes = opposed(a, b)
                if axes:
                    counters.append((a["name"], b["name"], axes,
                                     "walked×walked" if a in W and b in W else "needs promotion"))
        for a_, b_, _, kind in counters:
            for r in W:
                if r["name"] in (a_, b_) and r["role"] == "side":
                    r["role"] = "counter"

        # verdicts for depth
        promote, blanks_rel, bury = [], [], []
        walked_concepts = {r["concept"] for r in W if r["concept"]}
        counter_names = {n for c in counters for n in c[:2]}
        for d in sorted(D, key=lambda r: -r["lb"]):
            if d["lb"] >= 5 or (d["name"] in counter_names):
                promote.append(d)
            elif d["lb"] >= 3 and d["concept"] not in walked_concepts:
                blanks_rel.append(d)
            else:
                why = ("same concept as a walked artifact" if d["concept"] in walked_concepts
                       else "weak signal")
                if not d["cap"]:
                    why += "; no capture"
                if d["claim"] == 0:
                    why += "; mute"
                bury.append((d["name"], why))

        # blanks: load-bearing without any counter pairing
        blanks = []
        for lb_name in load_bearing:
            if not any(lb_name in c[:2] for c in counters):
                blanks.append(f"counter to **{lb_name}** — unoccupied (no kin-but-opposed artifact found)")

        L = [f"# Dig report — {t.get('name', seq)}", "",
             f"> {sd.get('truth', '')}", "",
             f"Walked {len(W)} · at depth {len(D)} · load-bearing proposal: **{', '.join(load_bearing)}**", "",
             "## The walked ring — proposed roles",
             "| artifact | role | LB score | why |", "|---|---|---|---|"]
        for r in W:
            L.append(f"| {r['name']} | **{r['role']}** | {r['lb']} | {'; '.join(r['reasons']) or '—'} |")
        L += ["", "## Counter-pairs proposed (kin + opposed operation)"]
        if counters:
            for a_, b_, axes, kind in counters:
                L.append(f"- **{a_} ⟷ {b_}** — opposed on {', '.join(axes)} ({kind})")
        else:
            L.append("- none found — see blanks")
        L += ["", "## Promotions proposed (from depth)"]
        for d in promote[:6]:
            L.append(f"- **{d['name']}** (LB {d['lb']}) — {'; '.join(d['reasons']) or 'counter-pair member'}")
        if not promote:
            L.append("- none")
        L += ["", "## Blank-relevant (concepts the walk doesn't cover)"]
        for d in blanks_rel[:6]:
            L.append(f"- {d['name']} — concept: {d['concept'] or '—'}; {'; '.join(d['reasons']) or ''}")
        if not blanks_rel:
            L.append("- none")
        L += ["", "## Blanks declared"]
        for b_ in blanks:
            L.append(f"- {b_}")
        if not blanks:
            L.append("- none — every load-bearing artifact has a counter candidate")
        L += ["", f"## Buried with reasons ({len(bury)})"]
        for n, why in bury:
            L.append(f"- {n} — {why}")
        L.append("")
        path = os.path.join(OUT_DIR, f"{seq}.md")
        with open(path, "w", encoding="utf-8") as f:
            f.write("\n".join(L))
        print(f"— {seq}: LB={load_bearing} · {len(counters)} counter-pairs · "
              f"{len(promote)} promotions · {len(blanks)} blanks -> {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
