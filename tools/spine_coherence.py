"""tools/spine_coherence.py — measure how tightly each sequence's artifacts cluster.

For each sequence, compute:
  - intra_similarity: mean pairwise cosine similarity of artifacts' text representations
  - centroid_distance: how far each artifact is from the sequence's centre
  - dispersion: how spread the artifacts are in concept-space

Each artifact's "document" = description + tags + @identity + lookup_name (lowercased,
tokenized, stopword-filtered). TF-IDF weighting across the project corpus.

Heuristic, not perfect: TF-IDF + cosine is a 1980s technique. We accept that the
absolute numbers are approximate; what matters is RANKING (which sequence is most
coherent / least coherent) and OUTLIERS (artifacts that don't fit their sequence).

Run:
  python tools/spine_coherence.py
  python tools/spine_coherence.py --sequence=primitives    # detail for one sequence
"""
from __future__ import annotations

import argparse
import json
import math
import random
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


# Stopwords for the heuristic
STOPWORDS = set("""
a an the of in on at to from for with by as is are was were be been being
this that these those it its their there here we you they i me my our
or and not but if so do does did have has had can could would should
will shall may might must one two three some any all every each
about into out up down over under above below between through during
also just only same other new old big small first last next previous
type using used uses use shows show demonstrate demonstrating
""".split())

TOKEN_RE = re.compile(r"[a-zA-Z][a-zA-Z0-9_-]+")


def tokenize(text: str) -> list[str]:
    """Lowercase, split, filter stopwords + very short tokens."""
    if not text: return []
    toks = TOKEN_RE.findall(text.lower())
    return [t for t in toks if len(t) > 2 and t not in STOPWORDS]


# ─────────────────────────────────────────────────────────────────────
# Data loading
# ─────────────────────────────────────────────────────────────────────

def walk_for_artifacts(node, out: list[dict]) -> None:
    if isinstance(node, dict):
        if "lookup_name" in node and isinstance(node["lookup_name"], str):
            out.append(node)
        for v in node.values():
            walk_for_artifacts(v, out)
    elif isinstance(node, list):
        for v in node:
            walk_for_artifacts(v, out)


def load_artifacts() -> list[dict]:
    out: list[dict] = []
    for f in REGISTRY_DIR.glob("*.json"):
        try:
            with open(f, "r", encoding="utf-8") as fp:
                walk_for_artifacts(json.load(fp), out)
        except (json.JSONDecodeError, OSError):
            continue
    return out


def build_artifact_to_sequences() -> dict[str, list[str]]:
    """Map artifact → sequences via the maps' interactables (ground truth)."""
    # Build map → sequences first
    map_to_seq: dict[str, list[str]] = defaultdict(list)
    for sf in SEQ_DIR.glob("*.json"):
        try:
            with open(sf, "r", encoding="utf-8") as f:
                data = json.load(f)
        except (json.JSONDecodeError, OSError):
            continue
        seqs_raw = data.get("sequences") or {}
        iterable = seqs_raw.items() if isinstance(seqs_raw, dict) else (
            ((s.get("id") or s.get("name") or sf.stem, s) for s in seqs_raw if isinstance(s, dict))
        )
        for sid, seq in iterable:
            if not isinstance(seq, dict): continue
            for m in (seq.get("maps") or []):
                mname = m if isinstance(m, str) else (
                    m.get("name") or m.get("map") or m.get("id") if isinstance(m, dict) else None
                )
                if mname:
                    map_to_seq[mname].append(sid)

    # Now walk maps' interactables, extract artifact names
    out: dict[str, set[str]] = defaultdict(set)
    for sub in MAPS_DIR.iterdir():
        if not sub.is_dir(): continue
        md = sub / "map_data.json"
        if not md.exists(): continue
        try:
            with open(md, "r", encoding="utf-8") as f:
                m = json.load(f)
        except (json.JSONDecodeError, OSError):
            continue
        inter = (m.get("layers") or {}).get("interactables") or []
        seqs = map_to_seq.get(sub.name, [])
        if not seqs: continue
        for row in inter:
            for tok in row:
                if not isinstance(tok, str) or not tok.strip(): continue
                # First identifier in the token
                base_match = re.match(r"^([a-zA-Z_][a-zA-Z0-9_]*)", tok.strip())
                if base_match:
                    out[base_match.group(1)].update(seqs)
    return {k: sorted(v) for k, v in out.items()}


def load_spine_sequences() -> dict[str, dict]:
    with open(SPINE_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
    return {entry["name"]: entry for entry in data["spine"]["sequences"]}


# ─────────────────────────────────────────────────────────────────────
# Artifact text document
# ─────────────────────────────────────────────────────────────────────

def artifact_doc(artifact: dict) -> list[str]:
    """Build the bag of tokens for an artifact."""
    parts: list[str] = []
    parts.extend(tokenize(artifact.get("lookup_name", "")))
    parts.extend(tokenize(artifact.get("description", "")))
    parts.extend(tokenize(artifact.get("name", "")))
    for tag in artifact.get("tags") or []:
        if isinstance(tag, str):
            parts.extend(tokenize(tag))
    # @identity field if present
    identity = artifact.get("@identity") or artifact.get("identity")
    if isinstance(identity, str):
        parts.extend(tokenize(identity))
    elif isinstance(identity, dict):
        parts.extend(tokenize(json.dumps(identity)))
    for t in artifact.get("dev_themes") or []:
        if isinstance(t, str):
            parts.extend(tokenize(t))
    return parts


# ─────────────────────────────────────────────────────────────────────
# TF-IDF + cosine similarity
# ─────────────────────────────────────────────────────────────────────

def compute_tfidf(docs: dict[str, list[str]]) -> dict[str, dict[str, float]]:
    """Compute TF-IDF vector per document. Returns {doc_id: {term: weight}}."""
    n_docs = len(docs)
    # IDF
    df: Counter[str] = Counter()
    for tokens in docs.values():
        for t in set(tokens):
            df[t] += 1
    idf: dict[str, float] = {
        t: math.log(n_docs / max(1, df_t)) + 1.0 for t, df_t in df.items()
    }
    # TF-IDF
    out: dict[str, dict[str, float]] = {}
    for did, tokens in docs.items():
        tf: Counter[str] = Counter(tokens)
        total = sum(tf.values())
        if total == 0:
            out[did] = {}
            continue
        out[did] = {t: (count / total) * idf.get(t, 0.0) for t, count in tf.items()}
    return out


def cosine(a: dict[str, float], b: dict[str, float]) -> float:
    if not a or not b: return 0.0
    common = set(a) & set(b)
    if not common: return 0.0
    dot = sum(a[t] * b[t] for t in common)
    na = math.sqrt(sum(v * v for v in a.values()))
    nb = math.sqrt(sum(v * v for v in b.values()))
    if na == 0 or nb == 0: return 0.0
    return dot / (na * nb)


# ─────────────────────────────────────────────────────────────────────
# Fix 1 — Null-distribution calibration
# Returns expected mean pairwise similarity for a random sample of N
# artifacts drawn from the full corpus. Used to compute Z-like scores
# so a sequence's coherence is compared against what you'd get by
# chance at its size.
# ─────────────────────────────────────────────────────────────────────

def null_similarity_at_size(tfidf: dict[str, dict[str, float]],
                              n: int, n_samples: int = 24,
                              seed: int = 42) -> tuple[float, float]:
    """Mean + std of pairwise similarity in random samples of size n."""
    if n < 2 or len(tfidf) < 2:
        return 0.0, 0.0
    rng = random.Random(seed + n)
    names = list(tfidf.keys())
    sample_means = []
    for _ in range(n_samples):
        sample_names = rng.sample(names, min(n, len(names)))
        sims = []
        for i in range(len(sample_names)):
            for j in range(i + 1, len(sample_names)):
                sims.append(cosine(tfidf[sample_names[i]], tfidf[sample_names[j]]))
        if sims:
            sample_means.append(sum(sims) / len(sims))
    if not sample_means:
        return 0.0, 0.0
    mu = sum(sample_means) / len(sample_means)
    var = sum((m - mu) ** 2 for m in sample_means) / max(1, len(sample_means))
    return mu, math.sqrt(var)


# ─────────────────────────────────────────────────────────────────────
# Fix 2 — Infrastructure detection
# Artifacts appearing in MANY sequences are scaffolding (science_screen,
# dark_sphere, catalyst_target, etc). They dilute every sequence's
# coherence equally. Exclude them from intra-sequence similarity calc.
# ─────────────────────────────────────────────────────────────────────

# Hard-coded list (extends the cross-sequence heuristic)
SCAFFOLDING_NAMES = {
    "dark_sphere", "science_screen", "catalyst_target", "configurable_portal",
    "library_rack", "health_display", "spawn_point", "teleporter",
    "catalyst_foe", "catalyst_vent", "wedge_skill_pickup",
    "configurable_doorway", "catalyst_sustain_demo",
}

INFRASTRUCTURE_THRESHOLD = 5   # appears in >= this many sequences → infrastructure


def detect_infrastructure(art_to_seqs: dict[str, list[str]]) -> set[str]:
    """Return the set of artifact names that are infrastructure (appear in
    many sequences). Union with the explicit SCAFFOLDING_NAMES list."""
    cross_seq = {
        name for name, seqs in art_to_seqs.items()
        if len(set(seqs)) >= INFRASTRUCTURE_THRESHOLD
    }
    return cross_seq | SCAFFOLDING_NAMES


# ─────────────────────────────────────────────────────────────────────
# Main analysis
# ─────────────────────────────────────────────────────────────────────

def analyze(detail_sequence: str | None = None) -> dict:
    print("loading artifacts...")
    artifacts = load_artifacts()
    by_name = {a["lookup_name"]: a for a in artifacts}
    print(f"  {len(artifacts)} artifacts")

    print("building artifact → sequence map from real map placements...")
    art_to_seqs = build_artifact_to_sequences()
    print(f"  {len(art_to_seqs)} artifacts found in maps")

    spine_seqs = load_spine_sequences()
    print(f"  {len(spine_seqs)} spine sequences")

    # Detect infrastructure artifacts (Fix 2)
    infrastructure = detect_infrastructure(art_to_seqs)
    print(f"  {len(infrastructure)} infrastructure artifacts detected (will be excluded from coherence)")

    # For each spine sequence, list its artifacts
    seq_to_arts: dict[str, list[dict]] = {sid: [] for sid in spine_seqs}
    for a in artifacts:
        name = a["lookup_name"]
        seqs = art_to_seqs.get(name) or a.get("map_sequences") or []
        if isinstance(seqs, str): seqs = [seqs]
        for s in seqs:
            if s in seq_to_arts:
                seq_to_arts[s].append(a)
                break   # only count for one sequence (primary)

    # Build docs for each artifact (used in TF-IDF)
    print("building TF-IDF...")
    docs: dict[str, list[str]] = {}
    for sid, arts in seq_to_arts.items():
        for a in arts:
            docs[a["lookup_name"]] = artifact_doc(a)
    # Drop empty-doc artifacts
    docs = {k: v for k, v in docs.items() if v}
    print(f"  {len(docs)} artifacts with extractable text")

    tfidf = compute_tfidf(docs)

    # Pre-compute null distribution for each common N (Fix 1)
    # Build a corpus excluding infrastructure for fair sampling
    non_infra_tfidf = {k: v for k, v in tfidf.items() if k not in infrastructure}
    print(f"  computing null distribution from {len(non_infra_tfidf)} non-infra artifacts...")
    null_cache: dict[int, tuple[float, float]] = {}

    # Per sequence: intra-similarity + per-artifact centroid distance
    results: dict[str, dict] = {}
    for sid, arts in seq_to_arts.items():
        # Members WITH text, EXCLUDING infrastructure for the coherence calc
        all_names = [a["lookup_name"] for a in arts if a["lookup_name"] in tfidf]
        core_names = [n for n in all_names if n not in infrastructure]
        infra_in_seq = [n for n in all_names if n in infrastructure]

        if len(core_names) < 2:
            results[sid] = {
                "n_artifacts":            len(arts),
                "n_with_text":            len(all_names),
                "n_core":                 len(core_names),
                "n_infrastructure":       len(infra_in_seq),
                "intra_similarity":       None,
                "calibrated_coherence":   None,
                "outliers":               [],
                "members":                core_names,
                "infrastructure_members": infra_in_seq[:8],
            }
            continue

        # Pairwise mean similarity on core members
        sims = []
        for i in range(len(core_names)):
            for j in range(i + 1, len(core_names)):
                sims.append(cosine(tfidf[core_names[i]], tfidf[core_names[j]]))
        mean_sim = sum(sims) / len(sims) if sims else 0.0

        # Null distribution at this size
        size = len(core_names)
        if size not in null_cache:
            null_cache[size] = null_similarity_at_size(non_infra_tfidf, size)
        null_mu, null_sd = null_cache[size]
        # Calibrated coherence: how many "null std deviations" above expectation
        # If null_sd is tiny, fall back to ratio
        if null_sd > 0.001:
            calibrated = (mean_sim - null_mu) / null_sd
        elif null_mu > 0:
            calibrated = (mean_sim / null_mu) - 1.0
        else:
            calibrated = 0.0

        # Centroid (excluding infrastructure)
        centroid: dict[str, float] = defaultdict(float)
        for nm in core_names:
            for t, w in tfidf[nm].items():
                centroid[t] += w
        for t in centroid:
            centroid[t] /= len(core_names)

        # Outliers within core members
        dists = {nm: cosine(tfidf[nm], dict(centroid)) for nm in core_names}
        mean_d = sum(dists.values()) / len(dists)
        std_d = math.sqrt(sum((d - mean_d) ** 2 for d in dists.values()) / len(dists))
        outliers = [
            (nm, round(d, 3))
            for nm, d in sorted(dists.items(), key=lambda kv: kv[1])
            if d < mean_d - std_d * 0.7
        ][:5]

        results[sid] = {
            "n_artifacts":            len(arts),
            "n_with_text":            len(all_names),
            "n_core":                 len(core_names),
            "n_infrastructure":       len(infra_in_seq),
            "intra_similarity":       round(mean_sim, 4),
            "null_mean":              round(null_mu, 4),
            "null_std":               round(null_sd, 4),
            "calibrated_coherence":   round(calibrated, 3),
            "mean_centroid_distance": round(mean_d, 4),
            "centroid_top_terms":     sorted(centroid.items(), key=lambda kv: -kv[1])[:8],
            "outliers":               outliers,
            "members":                core_names[:30],
            "infrastructure_members": infra_in_seq[:8],
        }

    return results


def render_table(results: dict, write_svg_path: Path | None = None) -> None:
    # Order by CALIBRATED coherence (size-fair ranking)
    ordered = sorted(
        results.items(),
        key=lambda kv: -(kv[1].get("calibrated_coherence") if kv[1].get("calibrated_coherence") is not None else -99),
    )
    print()
    print(f"{'sequence':28} {'core/all':>9} {'infra':>6} {'sim':>6} {'null':>6} {'CALIB':>7}  outliers (in core only)")
    print("-" * 110)
    for sid, r in ordered:
        sim = r.get("intra_similarity")
        cal = r.get("calibrated_coherence")
        null_mu = r.get("null_mean")
        sim_s = f"{sim:.3f}" if sim is not None else "  --"
        null_s = f"{null_mu:.3f}" if null_mu is not None else "  --"
        cal_s = f"{cal:+.2f}σ" if cal is not None else "   --"
        n_core = r.get("n_core", 0)
        n_text = r.get("n_with_text", 0)
        n_infra = r.get("n_infrastructure", 0)
        core_s = f"{n_core}/{n_text}"
        ol = r.get("outliers") or []
        ol_s = ", ".join(f"{n[0][:16]}({n[1]:.2f})" for n in ol[:3])
        print(f"{sid:28} {core_s:>9} {n_infra:>6} {sim_s:>6} {null_s:>6} {cal_s:>7}  {ol_s}")
    print()
    # Legend
    print("  CALIB > 0σ  = tighter than chance for this size (genuinely coherent)")
    print("  CALIB ~ 0σ  = roughly chance (descriptive)")
    print("  CALIB < 0σ  = LOOSER than chance (suspicious — fragmented?)")
    print()

    if write_svg_path is None:
        return
    # SVG: bar chart of CALIBRATED coherence with raw similarity as a thin overlay
    W = 1280
    row_h = 32
    H = 110 + len(ordered) * row_h + 60
    parts = [f'<rect width="{W}" height="{H}" fill="#0A0A0E"/>']
    parts.append(f'<text x="20" y="36" font-family="ui-monospace" font-size="20" '
                 f'font-weight="700" fill="#FFFFFF">Spine coherence — size-calibrated</text>')
    parts.append(f'<text x="20" y="58" font-family="ui-monospace" font-size="11" fill="#9090A0">'
                 f'bars = sigma above/below chance for this size · GREEN positive (genuinely coherent) · '
                 f'RED negative (looser than chance — suspicious). Infrastructure artifacts excluded.</text>')

    label_w = 260
    centre_x = 30 + label_w + 200
    bar_max = 260  # half-width each side

    for i, (sid, r) in enumerate(ordered):
        y = 90 + i * row_h
        cal = r.get("calibrated_coherence")
        n_core = r.get("n_core", 0)
        n_infra = r.get("n_infrastructure", 0)
        sim = r.get("intra_similarity")
        null_mu = r.get("null_mean")

        # Label
        infra_s = f" (+{n_infra} infra)" if n_infra > 0 else ""
        parts.append(f'<text x="{20 + label_w}" y="{y + 18}" font-family="ui-monospace" '
                     f'font-size="11" fill="#E8E8EE" text-anchor="end">{sid} ({n_core}{infra_s})</text>')

        # Centre tick (chance line)
        parts.append(f'<line x1="{centre_x}" y1="{y + 4}" x2="{centre_x}" y2="{y + row_h - 4}" '
                     f'stroke="#3A3A45" stroke-width="1"/>')

        # Calibrated bar (signed, sigma units, clip ±5σ)
        if cal is not None:
            clipped = max(-5.0, min(5.0, cal))
            w = abs(clipped) / 5.0 * bar_max
            col = "#7DFFA8" if clipped > 0.3 else "#F4A261" if abs(clipped) <= 0.3 else "#E63946"
            x0 = centre_x if clipped > 0 else centre_x - w
            parts.append(f'<rect x="{x0}" y="{y + 8}" width="{w}" height="{row_h - 16}" '
                         f'fill="{col}" fill-opacity="0.85"/>')
            # Number
            tx = centre_x + bar_max + 12 if clipped >= 0 else centre_x - bar_max - 12
            anchor = "start" if clipped >= 0 else "end"
            parts.append(f'<text x="{tx}" y="{y + 18}" font-family="ui-monospace" '
                         f'font-size="11" fill="#E8E8EE" text-anchor="{anchor}">{cal:+.2f}σ</text>')

        # Raw similarity as small grey hint
        if sim is not None:
            parts.append(f'<text x="{centre_x + bar_max + 80}" y="{y + 18}" '
                         f'font-family="ui-monospace" font-size="9" fill="#7070A0">'
                         f'sim {sim:.3f} · null {null_mu:.3f}</text>')

    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
           f'viewBox="0 0 {W} {H}">{"".join(parts)}</svg>')
    write_svg_path.write_text(svg, encoding="utf-8")
    print(f"wrote {write_svg_path}")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--sequence", type=str, help="show details for one sequence")
    args = p.parse_args()

    results = analyze(args.sequence)

    if args.sequence:
        r = results.get(args.sequence)
        if not r:
            print(f"no such sequence: {args.sequence}")
            return
        print()
        print(f"=== {args.sequence} ===")
        print(f"  artifacts: {r['n_artifacts']}, with extractable text: {r['n_with_text']}")
        if r.get("intra_similarity") is not None:
            print(f"  intra-similarity: {r['intra_similarity']:.4f}")
            print(f"  centroid top terms: {', '.join(t[0] for t in r['centroid_top_terms'])}")
            print(f"  most outlying:")
            for nm, d in r.get("outliers", []):
                print(f"    {nm:35} centroid_sim={d:.3f}")
            print(f"  members ({len(r.get('members', []))}): {', '.join(r.get('members', [])[:10])}")
        return

    render_table(results, OUT_DIR / "spine_coherence.svg")

    # Save JSON
    json_path = OUT_DIR / "spine_coherence.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, default=lambda o: list(o) if isinstance(o, set) else str(o))
    print(f"wrote {json_path}")


if __name__ == "__main__":
    main()
