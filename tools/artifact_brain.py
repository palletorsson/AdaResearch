"""tools/artifact_brain.py — index every @identity block in the codebase.

The artifact brain is a read-only layer over content that already exists. It
does not generate improvements; it indexes the 8-field @identity blocks (and
the chamber proposals that have already shipped) so that one artifact's
identity can inform the next.

Three indices it builds:

  1. identities    — full @identity content per .gd file
  2. relationships — the directed graph extracted from the relationships:
                     field across all identities
  3. proposals     — chamber proposal titles + their classification
                     (add_identity / refactor / behavioral / aesthetic)

Output: doc/placement_research/artifact_brain.json

Run:
  python tools/artifact_brain.py
"""
from __future__ import annotations

import json
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
OUT = ROOT / "doc" / "placement_research" / "artifact_brain.json"
CHAMBER_ROOT = ROOT / ".." / "ada_encyclopedia" / "public" / "chamber-runs"

IDENTITY_FIELDS = [
    "essence", "desire", "critical_parameter", "triggers",
    "emerges", "needs", "relationships", "truth",
]

# Stopwords for keyword extraction
STOPWORDS = {
    "the", "a", "an", "of", "to", "in", "and", "or", "is", "are", "be", "by",
    "for", "on", "at", "as", "with", "from", "that", "this", "it", "its",
    "into", "but", "not", "no", "yes", "if", "when", "where", "while", "what",
    "which", "who", "whose", "how", "than", "then", "also", "just", "only",
    "very", "more", "less", "all", "any", "some", "each", "every", "you",
    "your", "they", "them", "their", "we", "our", "us", "i", "me", "my",
    "can", "will", "would", "should", "could", "may", "might", "must", "do",
    "does", "did", "done", "have", "has", "had", "having", "been", "being",
    "was", "were", "am", "so", "still", "again", "still",
}


# ── parse @identity from a .gd file ──────────────────────────────────────

IDENTITY_HEADER = re.compile(r"^#\s*@identity\s*$", re.MULTILINE)
FIELD_LINE = re.compile(r"^#\s*([a-z_]+)\s*:\s*(.+?)\s*$")


def parse_identity_block(text: str) -> dict | None:
    """Return dict of {field: value} or None if no @identity block."""
    m = IDENTITY_HEADER.search(text)
    if not m:
        return None
    # Read subsequent lines starting AFTER the header newline.
    # m.end() may land on a newline char — split into lines and skip the
    # first empty one if present.
    tail = text[m.end():]
    lines = tail.splitlines()
    # Skip leading blank/whitespace-only lines (the newline immediately after
    # the header produces an empty string at index 0).
    i = 0
    while i < len(lines) and not lines[i].strip():
        i += 1
    fields: dict[str, str] = {}
    for line in lines[i:]:
        line = line.rstrip("\r")
        if not line.startswith("#"):
            break
        fm = FIELD_LINE.match(line)
        if not fm:
            # comment line that doesn't look like "# field: value" — stop
            # (catches end of block / next-section header)
            stripped = line.strip("# ").strip()
            if not stripped:
                break
            # Non-field-like comment line — also break
            break
        field, value = fm.group(1), fm.group(2).strip()
        if field in IDENTITY_FIELDS:
            fields[field] = value
    return fields if fields else None


# ── relationships extraction ─────────────────────────────────────────────

# Heuristic: the relationships field mentions other artifact lookup_names
# Examples: "companion to vectorline (geometric length) and to the science_screen family"
# We extract snake_case identifiers.
LOOKUP_RE = re.compile(r"\b[a-z][a-z0-9_]{3,}\b")
KNOWN_NON_LOOKUPS = {
    "and", "the", "with", "to", "from", "for", "via", "this", "that",
    "their", "into", "system", "family", "depends", "companion", "pairs",
    "alongside", "always", "placed", "after", "before", "doubles", "hazard",
    "in_world", "out_world", "ready", "process", "ready_with",
}


def extract_relationships(rel_text: str, known_lookups: set[str]) -> list[str]:
    """Pull artifact lookup_names out of free-text relationships field."""
    candidates = LOOKUP_RE.findall(rel_text.lower())
    return sorted(set(c for c in candidates
                      if c in known_lookups and c not in KNOWN_NON_LOOKUPS))


# ── keyword extraction (for clustering) ──────────────────────────────────

WORD_RE = re.compile(r"[a-z][a-z\-]+")

def keywords_of(text: str) -> list[str]:
    return [w for w in WORD_RE.findall(text.lower())
            if w not in STOPWORDS and len(w) >= 3]


# ── chamber proposals ─────────────────────────────────────────────────────

TITLE_RE = re.compile(r"^#\s*Improvement:\s*(\S+)\s*[—\-]\s*(.+)$", re.MULTILINE)


def classify_proposal_title(title_tail: str) -> str:
    """Classify the kind of work a chamber proposal represents."""
    low = title_tail.lower()
    if "@identity" in low or "identity block" in low:
        return "add_identity"
    if "refactor" in low or "use canonical" in low or "use existing" in low:
        return "refactor_to_canonical"
    if "via map flag" in low or "opt-in" in low or "map-flag" in low:
        return "behavioral_opt_in"
    if "fix" in low or "bug" in low:
        return "fix"
    if "polish" in low or "visual" in low or "aesthetic" in low:
        return "aesthetic"
    if "ruler" in low or "readout" in low or "label" in low or "tick" in low:
        return "legibility"
    return "other"


def read_chamber_runs() -> list[dict]:
    runs: list[dict] = []
    for bucket in ["approved", "rejected", "draft"]:
        bd = CHAMBER_ROOT / bucket
        if not bd.exists():
            continue
        for art_dir in bd.iterdir():
            if not art_dir.is_dir():
                continue
            for run_dir in art_dir.iterdir():
                if not run_dir.is_dir():
                    continue
                prop = run_dir / "proposal.md"
                if not prop.exists():
                    continue
                try:
                    text = prop.read_text(encoding="utf-8")
                except (UnicodeDecodeError, OSError):
                    continue
                m = TITLE_RE.search(text)
                title_tail = m.group(2) if m else ""
                meta_path = run_dir / "meta.json"
                meta = {}
                if meta_path.exists():
                    try:
                        meta = json.loads(meta_path.read_text(encoding="utf-8"))
                    except (json.JSONDecodeError, OSError):
                        meta = {}
                runs.append({
                    "artifact": art_dir.name,
                    "bucket": bucket,
                    "timestamp": run_dir.name,
                    "title_tail": title_tail,
                    "classification": classify_proposal_title(title_tail),
                    "rating": meta.get("rating"),
                    "reason": meta.get("reason"),
                })
    return runs


# ── main scan ────────────────────────────────────────────────────────────

def main():
    print("scanning .gd files for @identity blocks...")
    identities: dict[str, dict] = {}
    for root_dir in ("commons", "algorithms"):
        root_path = ROOT / root_dir
        if not root_path.exists():
            continue
        for gd in root_path.rglob("*.gd"):
            try:
                text = gd.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                continue
            block = parse_identity_block(text)
            if not block:
                continue
            rel = gd.relative_to(ROOT).as_posix()
            # Try to derive lookup_name from filename stem
            lookup_name = gd.stem
            identities[rel] = {
                "path":        rel,
                "lookup_name": lookup_name,
                **block,
            }
    print(f"  {len(identities)} @identity blocks parsed")

    # Build set of known lookup_names for relationship resolution
    known_lookups = {ent["lookup_name"] for ent in identities.values()}

    # Resolve relationships into edges
    print("resolving relationships graph...")
    edges: list[dict] = []
    incoming_count: Counter = Counter()
    outgoing_count: Counter = Counter()
    for path, ent in identities.items():
        rel_text = ent.get("relationships", "")
        if not rel_text:
            continue
        targets = extract_relationships(rel_text, known_lookups)
        src = ent["lookup_name"]
        for t in targets:
            if t == src:
                continue
            edges.append({"from": src, "to": t})
            outgoing_count[src] += 1
            incoming_count[t] += 1
    print(f"  {len(edges)} relationship edges")

    # Truth-keyword clusters
    print("computing truth-keyword clusters...")
    keyword_to_artifacts: dict[str, list[str]] = defaultdict(list)
    for ent in identities.values():
        for kw in keywords_of(ent.get("truth", "")):
            keyword_to_artifacts[kw].append(ent["lookup_name"])
    # Keep only keywords shared by 3+ artifacts
    clusters = {
        k: sorted(set(v))
        for k, v in keyword_to_artifacts.items()
        if len(set(v)) >= 3
    }
    # Top by cluster size
    top_clusters = sorted(clusters.items(), key=lambda kv: -len(kv[1]))[:20]
    print(f"  {len(clusters)} keyword clusters (3+ artifacts), top sizes: {[len(v) for _, v in top_clusters[:5]]}")

    # Chamber proposals
    print("reading chamber proposals...")
    runs = read_chamber_runs()
    class_counts = Counter(r["classification"] for r in runs)
    bucket_counts = Counter(r["bucket"] for r in runs)
    print(f"  {len(runs)} chamber runs · classifications: {dict(class_counts)} · buckets: {dict(bucket_counts)}")

    # Per-field statistics (which fields are best authored)
    field_filled = {f: sum(1 for e in identities.values() if e.get(f)) for f in IDENTITY_FIELDS}
    field_avg_len = {f: int(sum(len(e.get(f, "")) for e in identities.values()) / max(1, len(identities))) for f in IDENTITY_FIELDS}

    # Total .gd count for coverage stat
    total_gd = sum(
        1 for d in ("commons", "algorithms")
        for _ in (ROOT / d).rglob("*.gd") if (ROOT / d).exists()
    )

    output = {
        "_meta": {
            "tool": "tools/artifact_brain.py",
            "generated_for": "doc/placement_research/artifact_brain.json",
        },
        "coverage": {
            "total_gd_files": total_gd,
            "with_identity":  len(identities),
            "percent":        round(100 * len(identities) / max(1, total_gd), 1),
        },
        "field_filled": field_filled,
        "field_avg_len": field_avg_len,
        "identities": list(identities.values()),
        "relationships": {
            "edges": edges,
            "n_edges": len(edges),
            "top_incoming": [{"lookup": k, "n": n} for k, n in incoming_count.most_common(15)],
            "top_outgoing": [{"lookup": k, "n": n} for k, n in outgoing_count.most_common(15)],
        },
        "truth_clusters": [
            {"keyword": k, "n": len(v), "artifacts": v}
            for k, v in top_clusters
        ],
        "chamber_runs": runs,
        "chamber_stats": {
            "total":            len(runs),
            "by_bucket":        dict(bucket_counts),
            "by_classification": dict(class_counts),
        },
    }

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(output, indent=2, ensure_ascii=False), encoding="utf-8")
    print()
    print(f"wrote {OUT.relative_to(ROOT)}")
    print()
    print("SUMMARY:")
    print(f"  coverage:        {len(identities)}/{total_gd} ({100 * len(identities) / total_gd:.1f}%)")
    print(f"  relationships:   {len(edges)} edges")
    print(f"  truth clusters:  {len(clusters)} (≥3 artifacts each)")
    print(f"  chamber runs:    {len(runs)}")
    print()
    print("TOP TRUTH CLUSTERS (shared themes across artifacts):")
    for kw, arts in top_clusters[:8]:
        print(f"  '{kw:18s}'  {len(arts):3d} artifacts  ({', '.join(arts[:5])}{'...' if len(arts) > 5 else ''})")
    print()
    print("TOP INCOMING IN RELATIONSHIPS GRAPH (most-referenced artifacts):")
    for r in [{"lookup": k, "n": n} for k, n in incoming_count.most_common(8)]:
        print(f"  {r['lookup']:30s} <- {r['n']:3d} references")
    print()
    print("CHAMBER CLASSIFICATIONS:")
    for cls, n in class_counts.most_common():
        print(f"  {cls:25s} {n:3d}")


if __name__ == "__main__":
    main()
