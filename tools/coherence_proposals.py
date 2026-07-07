#!/usr/bin/env python3
"""
coherence_proposals.py — bridge text-map coherence findings into proposal chips.

Manual-invocation only (v1): runs the existing text-map coherence pipeline
across a named sequence's maps and emits one proposal record per finding
that's actionable.

Findings the existing pipeline produces, surfaced as chips:
  - placedButUnmentioned: artifact placed in the map but never in any .md  → text drift
  - mentionedButUnplaced: artifact mentioned in a .md but never placed     → map drift
  - missingFromMap (vs intent): intent.md names artifacts not on the grid  → intent gap
  - intent missing entirely                                                → write intent
  - stub texts (low word count)                                            → write summary
  - low overall score                                                      → general audit

Each chip has kind="coherence" and a deep_links dict. The chip UI's `apply`
button for coherence chips opens the deep link in a new tab rather than
running an apply script — the apply IS the editor jump.

Usage:
    python tools/coherence_proposals.py --sequence primitives
    python tools/coherence_proposals.py --sequence forces --threshold 80
    python tools/coherence_proposals.py --list
    python tools/coherence_proposals.py --base-url http://localhost:3003

Background:
    doc/proposals/2026-05-13_book-coherence-bridge.md
    /blog/2026-03-10-text-map-coherence
    /blog/2026-05-13-the-hold-collapsed
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
import urllib.parse
import urllib.request
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Optional

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

REPO_ROOT = Path(__file__).resolve().parent.parent
PROPOSALS_DIR = REPO_ROOT / "data" / "sieve_proposals"
SEQUENCES_DIR = REPO_ROOT / "commons" / "maps" / "sequences"

DEFAULT_BASE_URL = "http://localhost:3003"
ADA_WRITER_BASE = "http://localhost:3002"  # ada_writer_pro live port
DEFAULT_THRESHOLD = 80

# Structural rules (Palle, 2026-05-13):
#   - sequences should fit in ≤10 maps
#   - most maps should be concept-explaining (intro/foundation/exploration);
#     explorative comes later in the sequence (integration/synthesis)
MAX_MAPS_PER_SEQUENCE = 10
CONCEPT_POSITIONS = {"intro", "foundation", "exploration"}
MIN_CONCEPT_RATIO = 0.6


# ---------- HTTP helpers (no deps) -----------------------------------------

def http_get_json(url: str, timeout: float = 15.0) -> Any:
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


# ---------- Finding extraction --------------------------------------------

@dataclass
class CoherenceFinding:
    """One actionable finding for a single map."""
    pass_id: str                  # coherence-<sequence>-<date>
    move_id: str                  # short id within the pass
    change: str                   # e.g., "Point_One · text drift"
    from_state: str               # the problem stated concretely
    to_state: str                 # what resolution looks like
    impact: str                   # severity label
    rationale_excerpt: str        # short context from the coherence report
    kind: str = "coherence"
    severity: str = "medium"      # low | medium | high
    deep_links: dict[str, str] = field(default_factory=dict)
    status: str = "pending"
    applied_at: Optional[str] = None
    applied_by: Optional[str] = None
    pre_existing: bool = False
    notes: str = ""


def deep_links_for(map_name: str, base_url: str) -> dict[str, str]:
    return {
        "map_builder": f"{base_url}/map-builder?name={urllib.parse.quote(map_name)}",
        "text_map_coherence": f"{base_url}/text-map-coherence?map={urllib.parse.quote(map_name)}",
        "ada_writer": f"{ADA_WRITER_BASE}/editor?map={urllib.parse.quote(map_name)}",
    }


def severity_from_score(score: int, threshold: int) -> str:
    if score < threshold - 20:
        return "high"
    if score < threshold - 5:
        return "medium"
    return "low"


def extract_findings(
    report: dict[str, Any],
    map_name: str,
    pass_id: str,
    threshold: int,
    base_url: str,
) -> list[CoherenceFinding]:
    findings: list[CoherenceFinding] = []
    deep = deep_links_for(map_name, base_url)
    overall = report.get("overallScore", 100)
    sev_overall = severity_from_score(overall, threshold)

    dims = report.get("dimensions", {}) or {}
    am = dims.get("artifactMention") or {}
    ia = dims.get("intentAlignment") or {}
    comp = dims.get("completeness") or {}

    # Finding 1: placed but unmentioned in text
    pbu = am.get("placedButUnmentioned") or []
    if pbu:
        findings.append(CoherenceFinding(
            pass_id=pass_id,
            move_id=f"{map_name}-text-drift",
            change=f"{map_name} · text drift",
            from_state=f"{len(pbu)} artifact(s) placed but unmentioned in any .md: {', '.join(pbu[:5])}{'...' if len(pbu) > 5 else ''}",
            to_state="mention each in summary.md or technical.md, or remove from grid if no longer pedagogically central",
            impact=f"{sev_overall}",
            rationale_excerpt=f"Map score: {overall}. The map is doing more than its text reports. Either the text needs to catch up, or the placed artifacts are supporting cast rather than leads.",
            severity=sev_overall,
            deep_links=deep,
        ))

    # Finding 2: mentioned but unplaced
    mbu = am.get("mentionedButUnplaced") or []
    if mbu:
        findings.append(CoherenceFinding(
            pass_id=pass_id,
            move_id=f"{map_name}-map-drift",
            change=f"{map_name} · map drift",
            from_state=f"{len(mbu)} artifact(s) mentioned in .md but never placed: {', '.join(mbu[:5])}{'...' if len(mbu) > 5 else ''}",
            to_state="place each on the grid, or remove the mention if the design changed",
            impact=f"{sev_overall}",
            rationale_excerpt=f"Map score: {overall}. The text is doing more than the map reports. The text knows about artifacts the player will never see.",
            severity=sev_overall,
            deep_links=deep,
        ))

    # Finding 3: intent key artifacts missing from map
    intent_missing = ia.get("missingFromMap") or []
    has_intent = ia.get("hasIntent", False)
    if has_intent and intent_missing:
        findings.append(CoherenceFinding(
            pass_id=pass_id,
            move_id=f"{map_name}-intent-gap",
            change=f"{map_name} · intent gap",
            from_state=f"intent.md names {len(intent_missing)} key artifact(s) not placed: {', '.join(intent_missing[:5])}",
            to_state="place the named artifacts, or revise intent.md to match what's actually placed",
            impact=f"{sev_overall}",
            rationale_excerpt="intent.md is the five-line pedagogical contract; its key artifacts must be present in the map for the contract to hold.",
            severity=sev_overall,
            deep_links=deep,
        ))

    # Finding 4: no intent.md at all
    if not has_intent:
        findings.append(CoherenceFinding(
            pass_id=pass_id,
            move_id=f"{map_name}-intent-missing",
            change=f"{map_name} · intent missing",
            from_state="intent.md does not exist",
            to_state="write the five-line pedagogical contract (concept, sequence role, technical angle, critical angle, key artifacts)",
            impact="medium",
            rationale_excerpt="Without intent.md, the map has no explicit pedagogical claim. Intent alignment scoring is excluded; coherence becomes uncheckable.",
            severity="medium",
            deep_links=deep,
        ))

    # Finding 5: stub texts
    tr = comp.get("textReadiness") or {}
    stubs = tr.get("stubDetected") or []
    if stubs:
        files = [s for s in stubs if isinstance(s, str)]
        if files:
            findings.append(CoherenceFinding(
                pass_id=pass_id,
                move_id=f"{map_name}-stubs",
                change=f"{map_name} · stub text",
                from_state=f"stub-flagged file(s): {', '.join(files)}",
                to_state="expand each stub to a real first draft (or remove if not yet warranted)",
                impact="low",
                rationale_excerpt="Stub detection flags files below file-type word-count thresholds. A 30-word summary is not a real summary; it's a placeholder.",
                severity="low",
                deep_links=deep,
            ))

    # Finding 6: low overall score (catch-all if no specific finding above triggered)
    if overall < threshold and not findings:
        findings.append(CoherenceFinding(
            pass_id=pass_id,
            move_id=f"{map_name}-overall",
            change=f"{map_name} · low coherence",
            from_state=f"overall score {overall} below threshold {threshold}",
            to_state="audit the map in /text-map-coherence and resolve the specific axis flagging",
            impact=sev_overall,
            rationale_excerpt=f"Grade {report.get('overallGrade', '?')}. No single axis flags individually but the weighted score is below threshold.",
            severity=sev_overall,
            deep_links=deep,
        ))

    return findings


# ---------- Sequence runner -----------------------------------------------

def fetch_sequence_maps(sequence_id: str, base_url: str) -> list[str]:
    """Return ordered list of map names for the sequence."""
    data = http_get_json(f"{base_url}/api/sequences", timeout=20.0)
    seqs = data if isinstance(data, list) else data.get("sequences", data)
    if isinstance(seqs, dict):
        seqs = list(seqs.values())
    for s in seqs:
        if not isinstance(s, dict):
            continue
        sid = s.get("id") or s.get("name")
        if sid == sequence_id:
            return list(s.get("maps", []))
    raise ValueError(f"sequence {sequence_id!r} not found")


def load_sequence_data(sequence_id: str) -> Optional[dict]:
    """Read the sequence file from disk for fields the API doesn't expose
    (artifact_groups[].position, etc.)."""
    path = SEQUENCES_DIR / f"{sequence_id}.json"
    if not path.exists():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return data.get("sequences", {}).get(sequence_id)
    except Exception:
        return None


def emit_length_finding(sequence_id: str, n_maps: int, pass_id: str, base_url: str) -> Optional[CoherenceFinding]:
    """Sequence has too many maps. The ≤10 rule."""
    if n_maps <= MAX_MAPS_PER_SEQUENCE:
        return None
    excess = n_maps - MAX_MAPS_PER_SEQUENCE
    return CoherenceFinding(
        pass_id=pass_id,
        move_id=f"{sequence_id}-length",
        change=f"sequence '{sequence_id}' length",
        from_state=f"{n_maps} maps",
        to_state=f"≤{MAX_MAPS_PER_SEQUENCE} maps (drop or consolidate {excess})",
        impact="high",
        rationale_excerpt=(
            f"Sequence '{sequence_id}' has {n_maps} maps. The structural rule "
            f"caps sequences at {MAX_MAPS_PER_SEQUENCE}: most maps explain "
            "concepts, fewer go explorative later. Above the cap the chapter "
            "loses rhythm and the reader loses the thread. Apply path: open "
            "the sequence in the editor; mark concept-essential vs foldable."
        ),
        kind="coherence",
        severity="high",
        deep_links={
            "encyclopedia": f"{base_url}/sequence/{sequence_id}",
            "sequence_file": f"commons/maps/sequences/{sequence_id}.json",
        },
    )


def emit_balance_finding(sequence_id: str, seq_data: dict, pass_id: str, base_url: str) -> Optional[CoherenceFinding]:
    """Most maps should be concept-explaining. Flag if <60% are."""
    groups = seq_data.get("artifact_groups", []) or []
    positioned = [g for g in groups if g.get("position")]
    if not positioned:
        return None
    concept_count = sum(1 for g in positioned if g.get("position") in CONCEPT_POSITIONS)
    ratio = concept_count / len(positioned)
    if ratio >= MIN_CONCEPT_RATIO:
        return None
    return CoherenceFinding(
        pass_id=pass_id,
        move_id=f"{sequence_id}-balance",
        change=f"sequence '{sequence_id}' arc balance",
        from_state=f"{concept_count}/{len(positioned)} positioned maps are concept-explaining ({ratio:.0%})",
        to_state=f"≥{int(MIN_CONCEPT_RATIO*100)}% concept-explaining; explorative later",
        impact="medium",
        rationale_excerpt=(
            "Rule: most maps explain concepts (intro/foundation/exploration); "
            "explorative maps (integration/synthesis) come later. Currently "
            f"only {ratio:.0%} of positioned maps are concept-explaining. "
            "Re-position maps in the sequence file, or trim/merge."
        ),
        kind="coherence",
        severity="medium",
        deep_links={
            "encyclopedia": f"{base_url}/sequence/{sequence_id}",
            "sequence_file": f"commons/maps/sequences/{sequence_id}.json",
        },
    )


def run_for_sequence(sequence_id: str, base_url: str, threshold: int) -> dict:
    pass_id = f"coherence-{sequence_id}-{dt.datetime.now().strftime('%Y%m%dT%H%M%S')}"
    map_names = fetch_sequence_maps(sequence_id, base_url)
    print(f"  sequence {sequence_id!r}: {len(map_names)} maps")
    all_findings: list[CoherenceFinding] = []
    skipped: list[str] = []
    failed: list[tuple[str, str]] = []

    # Sequence-level structural findings (run before per-map iteration).
    length_finding = emit_length_finding(sequence_id, len(map_names), pass_id, base_url)
    if length_finding:
        all_findings.append(length_finding)
        print(f"  ! length: {len(map_names)} > {MAX_MAPS_PER_SEQUENCE} maps")
    seq_data = load_sequence_data(sequence_id)
    if seq_data:
        balance_finding = emit_balance_finding(sequence_id, seq_data, pass_id, base_url)
        if balance_finding:
            all_findings.append(balance_finding)
            print(f"  ! balance: under {int(MIN_CONCEPT_RATIO*100)}% concept-explaining")

    for i, m in enumerate(map_names, 1):
        url = f"{base_url}/api/game/coherence?name={urllib.parse.quote(m)}&sequence={urllib.parse.quote(sequence_id)}"
        try:
            report = http_get_json(url, timeout=20.0)
        except Exception as e:
            failed.append((m, str(e)[:80]))
            print(f"    {i:3d}/{len(map_names)} {m}: FAIL {str(e)[:60]}")
            continue
        if "error" in report:
            skipped.append(m)
            continue
        overall = report.get("overallScore", 100)
        findings = extract_findings(report, m, pass_id, threshold, base_url)
        if findings:
            print(f"    {i:3d}/{len(map_names)} {m}: score={overall} → {len(findings)} chip(s)")
        else:
            print(f"    {i:3d}/{len(map_names)} {m}: score={overall} OK")
        all_findings.extend(findings)

    PROPOSALS_DIR.mkdir(parents=True, exist_ok=True)
    out_path = PROPOSALS_DIR / f"{pass_id}_proposals.json"
    payload = {
        "pass_id": pass_id,
        "kind": "coherence",
        "sequence_id": sequence_id,
        "threshold": threshold,
        "ran_at": dt.datetime.now().isoformat(timespec="seconds"),
        "stats": {
            "maps_analysed": len(map_names),
            "chips_emitted": len(all_findings),
            "maps_skipped": len(skipped),
            "maps_failed": len(failed),
        },
        "proposals": [asdict(f) for f in all_findings],
    }
    out_path.write_text(json.dumps(payload, indent="\t", ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"\nwrote {len(all_findings)} chips to {out_path.relative_to(REPO_ROOT)}")
    return payload


def list_runs() -> None:
    if not PROPOSALS_DIR.exists():
        print("no proposal records yet")
        return
    files = sorted(PROPOSALS_DIR.glob("coherence-*_proposals.json"))
    if not files:
        print("no coherence runs recorded")
        return
    for f in files:
        try:
            data = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        stats = data.get("stats", {})
        print(f"  {f.stem}: {stats.get('chips_emitted', 0)} chips ({stats.get('maps_analysed', 0)} maps)")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--sequence", help="Sequence id to analyse (e.g. primitives, forces).")
    parser.add_argument("--threshold", type=int, default=DEFAULT_THRESHOLD, help="Score threshold below which findings emit (default 80).")
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL, help="Encyclopedia base URL (default http://localhost:3003).")
    parser.add_argument("--list", action="store_true", help="List existing coherence runs.")
    args = parser.parse_args()

    if args.list:
        list_runs()
        return 0
    if not args.sequence:
        parser.print_help()
        return 1
    try:
        run_for_sequence(args.sequence, args.base_url, args.threshold)
    except Exception as e:
        print(f"error: {e}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
