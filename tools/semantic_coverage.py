#!/usr/bin/env python
"""
semantic_coverage.py — keyword-overlap check between map texts and
placed artifacts' documentation.

For each spine map:
  1. Build a keyword set from blurb.md (lowercased content words,
     stopwords removed, short tokens removed).
  2. Build a per-artifact keyword set from the artifact's
     @identity (essence + truth), registry description, and any
     prose header text.
  3. Aggregate all load-bearing artifacts' keyword sets.
  4. Compute: what fraction of the blurb's distinctive keywords
     appear in the aggregated artifact vocabulary.

Output flags maps where the blurb makes claims whose vocabulary has
no echo in any placed artifact's declared behaviour. These are the
candidates for either (a) rewriting the text, (b) placing an
additional artifact that enacts the claim, or (c) improving the
artifact docs to reflect what they actually do.

This is a heuristic, not a proof. Low overlap is a signal to review,
not automatic condemnation — the blurb may enact claims through
map structure (architecture) rather than artifacts.

Run:
    python tools/semantic_coverage.py
    python tools/semantic_coverage.py --map Point_One --verbose
    python tools/semantic_coverage.py --threshold 0.4 --format summary
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
MAPS = REPO / "commons" / "maps"
REPORTS = REPO / "doc" / "reports"
COVERAGE_JSON = REPORTS / "MAP_COVERAGE.json"
INDEX_JSON = REPORTS / "ARTIFACT_DOC_INDEX.json"

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass


STOPWORDS = {
    # english stopwords (trimmed to what's relevant in blurb-prose)
    "a", "an", "the", "this", "that", "these", "those", "is", "are", "was", "were",
    "be", "been", "being", "am", "do", "does", "did", "have", "has", "had", "having",
    "i", "me", "my", "mine", "we", "us", "our", "ours", "you", "your", "yours",
    "he", "him", "his", "she", "her", "hers", "it", "its", "they", "them", "their",
    "in", "on", "at", "by", "for", "with", "about", "against", "between", "into",
    "through", "during", "before", "after", "above", "below", "from", "up", "down",
    "out", "off", "over", "under", "again", "further", "then", "once", "here",
    "there", "when", "where", "why", "how", "all", "any", "both", "each", "few",
    "more", "most", "other", "some", "such", "no", "nor", "not", "only", "own",
    "same", "so", "than", "too", "very", "can", "will", "just", "should", "now",
    "and", "but", "or", "if", "because", "as", "until", "while", "of", "to",
    "what", "which", "who", "whom", "whose",
    # trivial connective / filler
    "also", "still", "even", "yet", "one", "two", "three", "four", "five",
    "thing", "things", "way", "ways", "like", "make", "makes", "made",
    "use", "used", "using", "let", "lets", "see", "sees", "saw", "seen",
    "look", "looks", "looked", "looking", "become", "becomes", "became",
    "becoming", "get", "gets", "got", "getting", "go", "goes", "went", "gone",
    "going", "come", "comes", "came", "coming", "put", "puts", "putting",
    "take", "takes", "took", "taken", "taking",
    # meta artifacts
    "map", "maps", "artifact", "artifacts", "sequence", "sequences",
    "scene", "scenes", "learner", "learners", "player", "players",
    "feature", "features",
}

TOKEN_RE = re.compile(r"[a-zA-Z][a-zA-Z_0-9]{2,}")
FENCE_RE = re.compile(r"```.*?```", re.DOTALL)
BACKTICK_RE = re.compile(r"`[^`]+`")


def tokenize(text: str) -> set[str]:
    """Lowercase content words, minus stopwords, minus short tokens."""
    # Strip code fences and backticked spans (we measure prose vocabulary)
    t = FENCE_RE.sub(" ", text)
    t = BACKTICK_RE.sub(" ", t)
    toks = TOKEN_RE.findall(t.lower())
    return {tok for tok in toks if tok not in STOPWORDS and len(tok) >= 4}


def read_text_file(path: Path) -> str:
    if not path.exists():
        return ""
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return ""


def artifact_vocabulary(entry: dict) -> set[str]:
    """Build a keyword set from an artifact's declared behaviour."""
    bits: list[str] = []
    ifields = entry.get("identity_fields") or {}
    for key in ("essence", "truth", "desire", "emerges"):
        v = ifields.get(key)
        if v:
            bits.append(v)
    desc = entry.get("registry_description") or ""
    if desc:
        bits.append(desc)
    header = entry.get("header_text") or ""
    if header:
        bits.append(header)
    return tokenize(" ".join(bits))


@dataclass
class SemanticCoverage:
    sequence: str
    map: str
    blurb_keywords: list[str] = field(default_factory=list)
    matched_keywords: list[str] = field(default_factory=list)
    unmatched_keywords: list[str] = field(default_factory=list)
    load_bearing_count: int = 0
    coverage: float = 1.0


def build_coverage(
    coverage_map: dict,
    artifact_index: dict[str, dict],
) -> SemanticCoverage:
    s = SemanticCoverage(
        sequence=coverage_map["sequence"],
        map=coverage_map["map"],
        load_bearing_count=len(coverage_map.get("load_bearing", [])),
    )
    blurb = read_text_file(MAPS / coverage_map["map"] / "blurb.md")
    summary = read_text_file(MAPS / coverage_map["map"] / "summary.md")
    text_vocab = tokenize(blurb + "\n" + summary)

    # Aggregate artifact vocabulary across load-bearing placements
    agg: set[str] = set()
    for token in coverage_map.get("load_bearing", []):
        entry = artifact_index.get(token)
        if not entry:
            continue
        agg |= artifact_vocabulary(entry)

    matched = sorted(text_vocab & agg)
    unmatched = sorted(text_vocab - agg)
    s.blurb_keywords = sorted(text_vocab)
    s.matched_keywords = matched
    s.unmatched_keywords = unmatched
    if text_vocab:
        s.coverage = round(len(matched) / len(text_vocab), 3)
    else:
        s.coverage = 1.0
    return s


def summarize(rows: list[SemanticCoverage]) -> dict[str, Any]:
    total = len(rows)
    with_text = [r for r in rows if r.blurb_keywords]
    avg = sum(r.coverage for r in with_text) / max(len(with_text), 1)
    buckets = {"ge90": 0, "70_90": 0, "50_70": 0, "lt50": 0}
    for r in with_text:
        c = r.coverage
        if c >= 0.9: buckets["ge90"] += 1
        elif c >= 0.7: buckets["70_90"] += 1
        elif c >= 0.5: buckets["50_70"] += 1
        else: buckets["lt50"] += 1
    return {
        "maps": total,
        "maps_with_text": len(with_text),
        "avg_semantic_coverage": round(avg, 3),
        "buckets": buckets,
    }


def print_markdown(rows: list[SemanticCoverage], summary: dict[str, Any], threshold: float) -> None:
    print("# Semantic Coverage (keyword overlap)\n")
    print("For each spine map: what fraction of the blurb's distinctive")
    print("vocabulary appears in at least one placed artifact's declared")
    print("behaviour (essence / truth / registry description / prose header).\n")
    print(f"- Maps scanned: **{summary['maps']}**")
    print(f"- Maps with blurb/summary text: **{summary['maps_with_text']}**")
    print(f"- Average semantic coverage: **{summary['avg_semantic_coverage'] * 100:.1f}%**\n")
    b = summary["buckets"]
    print("## Distribution\n")
    print(f"- ≥ 90%: **{b['ge90']}**")
    print(f"- 70–90%: **{b['70_90']}**")
    print(f"- 50–70%: **{b['50_70']}**")
    print(f"- < 50%: **{b['lt50']}**\n")
    below = [r for r in rows if r.coverage < threshold and r.blurb_keywords]
    below.sort(key=lambda r: r.coverage)
    if below:
        print(f"## Maps below {threshold * 100:.0f}% threshold — review candidates\n")
        print("| Map | Sequence | Coverage | Blurb keywords | Top unmatched |")
        print("|---|---|---:|---:|---|")
        for r in below[:40]:
            top_un = ", ".join(r.unmatched_keywords[:8])
            print(
                f"| {r.map} | {r.sequence} | {r.coverage * 100:.0f}% "
                f"| {len(r.blurb_keywords)} | {top_un} |"
            )


def print_detail(r: SemanticCoverage) -> None:
    print(f"\n# {r.map} ({r.sequence})")
    print(f"  semantic coverage: {r.coverage * 100:.0f}%")
    print(f"  blurb+summary keywords: {len(r.blurb_keywords)}")
    print(f"  matched: {len(r.matched_keywords)}")
    print(f"  unmatched: {len(r.unmatched_keywords)}")
    print()
    print(f"  matched: {r.matched_keywords[:40]}")
    print()
    print(f"  unmatched: {r.unmatched_keywords[:40]}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--map", help="Inspect one map")
    ap.add_argument("--threshold", type=float, default=0.5, help="Cutoff for the review list (default 0.5)")
    ap.add_argument("--format", choices=["markdown", "json", "summary"], default="markdown")
    ap.add_argument("--out-dir", default=str(REPORTS))
    args = ap.parse_args()

    if not COVERAGE_JSON.exists() or not INDEX_JSON.exists():
        print(
            "ERROR: required reports missing. Run:\n"
            "  python tools/artifact_doc_index.py\n"
            "  python tools/map_coverage.py",
            file=sys.stderr,
        )
        return 2

    coverage = json.loads(COVERAGE_JSON.read_text(encoding="utf-8"))
    index_raw = json.loads(INDEX_JSON.read_text(encoding="utf-8"))
    artifact_index = {e["token"]: e for e in index_raw.get("entries", []) if e.get("token")}

    if args.map:
        m = next((m for m in coverage["maps"] if m["map"] == args.map), None)
        if not m:
            print(f"no map named {args.map!r}", file=sys.stderr)
            return 1
        row = build_coverage(m, artifact_index)
        if args.format == "json":
            print(json.dumps(asdict(row), indent=2))
        else:
            print_detail(row)
        return 0

    rows = [build_coverage(m, artifact_index) for m in coverage["maps"]]
    summary = summarize(rows)

    if args.format == "summary":
        print(json.dumps(summary, indent=2))
        return 0

    if args.format == "json":
        print(json.dumps({"summary": summary, "maps": [asdict(r) for r in rows]}, indent=2))
        return 0

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "SEMANTIC_COVERAGE.json").write_text(
        json.dumps({"summary": summary, "maps": [asdict(r) for r in rows]}, indent=2),
        encoding="utf-8",
    )
    print_markdown(rows, summary, args.threshold)
    print(f"\n_JSON sidecar: {(out_dir / 'SEMANTIC_COVERAGE.json').relative_to(REPO)}_", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
