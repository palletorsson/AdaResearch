"""tools/spine_gaps.py — find concepts claimed by the curriculum but not delivered.

For each spine sequence, read its description + learning_objectives + truth + name
from `commons/maps/sequences/<seq>.json`. Extract concept keywords (noun-ish
tokens, stopword-filtered, lemma-light). For each keyword, count how many of the
sequence's artifacts have that keyword in their text (description + tags + identity).

Output:
  per-sequence keyword coverage: keyword → (n_artifacts_covering, coverage_pct)
  per-sequence "claimed but uncovered": keywords with 0 or 1 hits across many artifacts
  global summary: which sequences have the most gaps

The heuristic is intentionally naive — keyword overlap, no embeddings, no semantic
expansion. False positives happen (e.g., "shape" is too generic to be useful as a gap
signal). The point isn't precision; it's surfacing WHERE TO LOOK. A claim like
"learning_objectives: bay rhythm" that matches zero artifacts is a real gap signal.

Run:
  python tools/spine_gaps.py
  python tools/spine_gaps.py --sequence=randomness     # one sequence's full picture
"""
from __future__ import annotations

import argparse
import json
import math
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
SPINE_PATH = ROOT / "commons" / "maps" / "curriculum_spine.json"
SEQ_DIR = ROOT / "commons" / "maps" / "sequences"
REGISTRY_DIR = ROOT / "commons" / "artifacts" / "registry"
MAPS_DIR = ROOT / "commons" / "maps"
OUT_DIR = ROOT / "doc" / "placement_research"

# Reuse coherence's text helpers
sys.path.insert(0, str(ROOT / "tools"))
from spine_coherence import (
    tokenize, STOPWORDS, walk_for_artifacts, load_artifacts,
    build_artifact_to_sequences, load_spine_sequences, artifact_doc,
)


# Additional stopwords for curriculum text — words that are TOO generic to be
# useful gap signals (they appear everywhere)
META_STOPS = set("""
sequence map artifact algorithm system maps artifacts player walk walked walking
demonstrate demonstrates demonstration show shows shown showing example examples
visualization visualize visualized vis simple basic test tests testing teaching
learning learn learns playing lesson lessons concept concepts shape shapes form
forms element elements approach approaches generation generate generated thing
things kind kinds way ways place places placed playing point points line lines
exercise exercises chapter walk walks walking moving move moves work works
working teach teaches teaches arc phase progress
""".split())


def keywords_from_text(text: str) -> set[str]:
    """Extract concept keywords (tokens, filtered)."""
    toks = tokenize(text)
    return {t for t in toks if t not in META_STOPS and len(t) > 3}


def load_sequence_text(spine_seq_name: str) -> dict:
    """Find this sequence's text block in sequence files. Returns {description,
    learning_objectives, truth, qfep_term, qfep_connection}.

    BUG FIX 2026-05-15: collect ALL matches across sequence files and pick the
    entry with the richest content. Previously the function returned the first
    match alphabetically, which gave us empty stubs from `sequence_index.json`
    even when the same sequence had a populated entry in `<seqname>.json`.
    """
    candidates: list[dict] = []
    for sf in SEQ_DIR.glob("*.json"):
        try:
            with open(sf, "r", encoding="utf-8") as f:
                data = json.load(f)
        except (json.JSONDecodeError, OSError):
            continue
        seqs_raw = data.get("sequences") or {}
        iterable = seqs_raw.items() if isinstance(seqs_raw, dict) else (
            ((s.get("id") or s.get("name") or sf.stem, s)
             for s in seqs_raw if isinstance(s, dict))
        )
        for sid, seq in iterable:
            if sid != spine_seq_name: continue
            if not isinstance(seq, dict): continue
            entry = {
                "description": seq.get("description") or seq.get("desc") or "",
                "learning_objectives": seq.get("learning_objectives") or [],
                "truth": seq.get("truth") or "",
                "qfep_term": seq.get("qfep_term") or "",
                "qfep_connection": seq.get("qfep_connection") or "",
                "name": seq.get("name") or sid,
                "_source_file": sf.name,
            }
            candidates.append(entry)
    if not candidates:
        return {}
    # Pick the candidate with the longest combined text payload
    def richness(e: dict) -> int:
        return (
            len(e.get("description", ""))
            + len(e.get("truth", ""))
            + len(e.get("qfep_connection", ""))
            + sum(len(str(o)) for o in (e.get("learning_objectives") or []))
        )
    candidates.sort(key=richness, reverse=True)
    return candidates[0]


def claim_keywords(seq_text: dict) -> set[str]:
    """Extract claimed concept keywords from the sequence's own text."""
    pool = []
    pool.append(seq_text.get("description", ""))
    pool.append(seq_text.get("truth", ""))
    pool.append(seq_text.get("qfep_connection", ""))
    pool.append(seq_text.get("name", ""))
    obj = seq_text.get("learning_objectives") or []
    if isinstance(obj, list):
        pool.extend(str(o) for o in obj)
    text = " ".join(pool)
    return keywords_from_text(text)


# ─────────────────────────────────────────────────────────────────────
# Main analysis
# ─────────────────────────────────────────────────────────────────────

def analyze() -> dict:
    print("loading artifacts...")
    artifacts = load_artifacts()
    print(f"  {len(artifacts)} artifacts")

    print("building artifact → sequence map...")
    art_to_seqs = build_artifact_to_sequences()

    spine_seqs = load_spine_sequences()
    print(f"  {len(spine_seqs)} spine sequences")

    # Group artifacts per sequence
    seq_to_arts: dict[str, list[dict]] = {sid: [] for sid in spine_seqs}
    for a in artifacts:
        name = a["lookup_name"]
        seqs = art_to_seqs.get(name) or a.get("map_sequences") or []
        if isinstance(seqs, str): seqs = [seqs]
        for s in seqs:
            if s in seq_to_arts:
                seq_to_arts[s].append(a)
                break

    results: dict[str, dict] = {}
    for sid in spine_seqs:
        seq_text = load_sequence_text(sid)
        claims = claim_keywords(seq_text)
        arts = seq_to_arts[sid]
        if not claims:
            results[sid] = {
                "n_artifacts":    len(arts),
                "n_claims":       0,
                "claims":         [],
                "coverage":       {},
                "uncovered":      [],
                "well_covered":   [],
            }
            continue
        # For each claim keyword, count artifacts in the sequence whose doc contains it
        coverage: dict[str, int] = {}
        artifact_keywords: dict[str, set[str]] = {
            a["lookup_name"]: set(artifact_doc(a)) for a in arts
        }
        for kw in claims:
            n = sum(1 for kws in artifact_keywords.values() if kw in kws)
            coverage[kw] = n
        # Uncovered = claim keywords with 0 hits
        uncovered = sorted([k for k, n in coverage.items() if n == 0])
        # Thin coverage = 1 hit
        thin = sorted([k for k, n in coverage.items() if n == 1])
        # Well-covered = >= 3 hits
        well = sorted([(k, n) for k, n in coverage.items() if n >= 3], key=lambda x: -x[1])

        coverage_pct = round(100 * (1 - len(uncovered) / max(1, len(claims))), 1)
        # claim_richness: how much text the curriculum wrote about this sequence
        claim_richness = len(claims)
        results[sid] = {
            "n_artifacts":      len(arts),
            "n_claims":         len(claims),
            "claim_richness":   claim_richness,   # alias for clarity
            "n_uncovered":      len(uncovered),
            "n_thin":           len(thin),
            "n_well":           len(well),
            "coverage_pct":     coverage_pct,
            "coverage_rate":    round(coverage_pct / 100, 3),  # alias for clarity (0..1)
            "classification":   None,   # filled below
            "claims":           sorted(claims),
            "coverage":         coverage,
            "uncovered":        uncovered,
            "thin":             thin,
            "well_covered":     well[:10],
            "claim_sources": {
                "description":          seq_text.get("description", "")[:200],
                "truth":                seq_text.get("truth", "")[:200],
                "qfep_connection":      seq_text.get("qfep_connection", "")[:200],
                "learning_objectives":  seq_text.get("learning_objectives", []),
            },
        }
    # Classify
    for sid, r in results.items():
        r["classification"] = classify_gap(r.get("n_claims", 0), r.get("coverage_pct", 0))
    return results


def classify_gap(n_claims: int, coverage_pct: float) -> str:
    """Two-axis classification:
       LOW_CLAIMS = sequence description is too thin to make claims (under-described)
       BUILT      = many claims, well-covered
       GAP        = many claims, poorly covered (real curriculum gap)
       OK         = few claims, well-covered (minimal but matched)
    """
    if n_claims < 8:
        return "LOW_CLAIMS" if coverage_pct < 50 else "OK"
    return "BUILT" if coverage_pct >= 50 else "GAP"


def render_table(results: dict, write_svg_path: Path | None = None) -> None:
    # Order by (classification severity, coverage_pct ascending)
    cls_order = {"GAP": 0, "LOW_CLAIMS": 1, "OK": 2, "BUILT": 3}
    ordered = sorted(
        results.items(),
        key=lambda kv: (
            cls_order.get(classify_gap(kv[1].get("n_claims", 0), kv[1].get("coverage_pct", 100)), 9),
            kv[1].get("coverage_pct", 100),
        ),
    )
    print()
    print(f"{'sequence':28} {'arts':>5} {'claims':>7} {'coverd':>7} {'class':>11}  uncovered (sample)")
    print("-" * 110)
    for sid, r in ordered:
        u = r.get("uncovered", [])
        u_s = ", ".join(u[:4])
        cls = classify_gap(r.get("n_claims", 0), r.get("coverage_pct", 0))
        print(f"{sid:28} {r['n_artifacts']:>5} {r['n_claims']:>7} "
              f"{r.get('coverage_pct', 0):>6.1f}% {cls:>11}  {u_s}")
    print()
    print("  GAP        = many claims, low coverage → curriculum claims things it hasn't built")
    print("  LOW_CLAIMS = sequence description is too thin to make claims (no judgment possible)")
    print("  OK         = few claims, mostly covered")
    print("  BUILT      = many claims, well-covered (good)")
    print()

    if write_svg_path is None: return
    # SVG: two-axis scatter plot — claim_richness × coverage_rate
    # Quadrants: top-right = BUILT, top-left = LOW_CLAIMS (sparse),
    # bottom-right = GAP (claims many, covers few), bottom-left = OK (small + matched)
    W = 1200
    H = 720
    margin_l = 100; margin_r = 320; margin_t = 80; margin_b = 90
    plot_w = W - margin_l - margin_r
    plot_h = H - margin_t - margin_b

    parts = [f'<rect width="{W}" height="{H}" fill="#0A0A0E"/>']
    parts.append(f'<text x="20" y="36" font-family="ui-monospace" font-size="20" '
                 f'font-weight="700" fill="#FFFFFF">Spine gaps — two-axis</text>')
    parts.append(f'<text x="20" y="58" font-family="ui-monospace" font-size="11" fill="#9090A0">'
                 f'X = claim richness (more keywords claimed → curriculum has more to say). '
                 f'Y = coverage rate. Quadrants: top-right BUILT, bottom-right GAP.</text>')

    max_claims = max((r.get("n_claims", 0) for r in results.values()), default=10)
    # Axes
    parts.append(f'<line x1="{margin_l}" y1="{margin_t + plot_h}" '
                 f'x2="{margin_l + plot_w}" y2="{margin_t + plot_h}" stroke="#3A3A45"/>')
    parts.append(f'<line x1="{margin_l}" y1="{margin_t}" '
                 f'x2="{margin_l}" y2="{margin_t + plot_h}" stroke="#3A3A45"/>')

    # Quadrant divider lines (50% claims, 50% coverage)
    mid_x = margin_l + plot_w * 0.5
    mid_y = margin_t + plot_h * 0.5
    parts.append(f'<line x1="{mid_x}" y1="{margin_t}" x2="{mid_x}" y2="{margin_t + plot_h}" '
                 f'stroke="#3A3A45" stroke-dasharray="3,3"/>')
    parts.append(f'<line x1="{margin_l}" y1="{mid_y}" x2="{margin_l + plot_w}" y2="{mid_y}" '
                 f'stroke="#3A3A45" stroke-dasharray="3,3"/>')

    # Quadrant labels
    parts.append(f'<text x="{margin_l + 8}" y="{margin_t + 18}" font-family="ui-monospace" '
                 f'font-size="11" fill="#FBE38A" fill-opacity="0.6">LOW_CLAIMS (covered)</text>')
    parts.append(f'<text x="{mid_x + 8}" y="{margin_t + 18}" font-family="ui-monospace" '
                 f'font-size="11" fill="#7DFFA8" fill-opacity="0.6">BUILT</text>')
    parts.append(f'<text x="{margin_l + 8}" y="{margin_t + plot_h - 8}" font-family="ui-monospace" '
                 f'font-size="11" fill="#F4A261" fill-opacity="0.6">OK (small)</text>')
    parts.append(f'<text x="{mid_x + 8}" y="{margin_t + plot_h - 8}" font-family="ui-monospace" '
                 f'font-size="11" fill="#E63946" fill-opacity="0.6">GAP (real curriculum gap)</text>')

    # Axis ticks
    parts.append(f'<text x="{margin_l}" y="{margin_t + plot_h + 18}" font-family="ui-monospace" '
                 f'font-size="10" fill="#9090A0" text-anchor="middle">0</text>')
    parts.append(f'<text x="{margin_l + plot_w}" y="{margin_t + plot_h + 18}" font-family="ui-monospace" '
                 f'font-size="10" fill="#9090A0" text-anchor="middle">{max_claims}</text>')
    parts.append(f'<text x="{margin_l + plot_w / 2}" y="{margin_t + plot_h + 38}" '
                 f'font-family="ui-monospace" font-size="11" fill="#9090A0" text-anchor="middle">'
                 f'claim richness (n keywords)</text>')
    parts.append(f'<text x="{margin_l - 8}" y="{margin_t + plot_h}" font-family="ui-monospace" '
                 f'font-size="10" fill="#9090A0" text-anchor="end">0%</text>')
    parts.append(f'<text x="{margin_l - 8}" y="{margin_t + 8}" font-family="ui-monospace" '
                 f'font-size="10" fill="#9090A0" text-anchor="end">100%</text>')
    parts.append(f'<text x="40" y="{margin_t + plot_h / 2}" font-family="ui-monospace" '
                 f'font-size="11" fill="#9090A0" text-anchor="middle" '
                 f'transform="rotate(-90,40,{margin_t + plot_h / 2})">coverage rate</text>')

    cls_color = {
        "GAP":        "#E63946",
        "LOW_CLAIMS": "#FBE38A",
        "OK":         "#F4A261",
        "BUILT":      "#7DFFA8",
    }

    # Dots
    for sid, r in results.items():
        nc = r.get("n_claims", 0)
        cp = r.get("coverage_pct", 0)
        cls = r.get("classification", "OK")
        x = margin_l + (nc / max(1, max_claims)) * plot_w
        y = margin_t + plot_h - (cp / 100) * plot_h
        col = cls_color.get(cls, "#888")
        radius = 5 + min(r.get("n_artifacts", 0), 80) / 8
        parts.append(f'<circle cx="{x}" cy="{y}" r="{radius}" fill="{col}" '
                     f'fill-opacity="0.6" stroke="{col}" stroke-width="1.5"/>')
        # Label — offset slightly so they don't all collide
        offset_x = 8 if x < W * 0.7 else -8
        anchor = "start" if x < W * 0.7 else "end"
        parts.append(f'<text x="{x + offset_x}" y="{y + 4}" font-family="ui-monospace" '
                     f'font-size="9" fill="#E8E8EE" text-anchor="{anchor}">{sid} ({r.get("n_artifacts", 0)})</text>')

    # Legend table on right
    leg_x = margin_l + plot_w + 30
    parts.append(f'<text x="{leg_x}" y="{margin_t + 8}" font-family="ui-monospace" '
                 f'font-size="12" font-weight="700" fill="#E8E8EE">classification</text>')
    classes = [
        ("BUILT",      "rich claims, well-covered"),
        ("GAP",        "rich claims, poorly covered"),
        ("LOW_CLAIMS", "thin claims, covered"),
        ("OK",         "thin claims, also poorly covered"),
    ]
    for i, (cls, desc) in enumerate(classes):
        ly = margin_t + 28 + i * 22
        parts.append(f'<rect x="{leg_x}" y="{ly}" width="14" height="14" '
                     f'fill="{cls_color[cls]}" fill-opacity="0.7"/>')
        parts.append(f'<text x="{leg_x + 20}" y="{ly + 11}" font-family="ui-monospace" '
                     f'font-size="11" fill="#E8E8EE">{cls}</text>')
        parts.append(f'<text x="{leg_x + 20}" y="{ly + 23}" font-family="ui-monospace" '
                     f'font-size="9" fill="#9090A0">{desc}</text>')

    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
           f'viewBox="0 0 {W} {H}">{"".join(parts)}</svg>')
    write_svg_path.write_text(svg, encoding="utf-8")
    print(f"wrote {write_svg_path}")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--sequence", type=str, help="show details for one sequence")
    args = p.parse_args()

    results = analyze()

    if args.sequence:
        r = results.get(args.sequence)
        if not r:
            print(f"no such sequence: {args.sequence}")
            return
        print()
        print(f"=== {args.sequence} ===")
        print(f"  artifacts:  {r['n_artifacts']}")
        print(f"  claims:     {r['n_claims']} keywords")
        print(f"  coverage:   {r.get('coverage_pct', 0):.1f}%")
        print()
        sources = r.get("claim_sources", {})
        if sources.get("description"):
            print(f"  description: {sources['description']}")
        if sources.get("truth"):
            print(f"  truth: {sources['truth']}")
        if sources.get("qfep_connection"):
            print(f"  qfep_connection: {sources['qfep_connection']}")
        obj = sources.get("learning_objectives") or []
        if obj:
            print(f"  learning_objectives:")
            for o in obj[:6]:
                print(f"    - {o}")
        print()
        if r.get("uncovered"):
            print(f"  UNCOVERED ({len(r['uncovered'])}):  {', '.join(r['uncovered'][:30])}")
        if r.get("thin"):
            print(f"  THIN ({len(r['thin'])}):  {', '.join(r['thin'][:30])}")
        if r.get("well_covered"):
            print(f"  WELL ({len(r['well_covered'])}):")
            for kw, n in r["well_covered"][:10]:
                print(f"    {kw} (×{n})")
        return

    render_table(results, OUT_DIR / "spine_gaps.svg")

    json_path = OUT_DIR / "spine_gaps.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)
    print(f"wrote {json_path}")


if __name__ == "__main__":
    main()
