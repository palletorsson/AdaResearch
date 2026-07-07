"""tools/draft_beats.py — scaffold a beats.json for a sequence from its data.

Reads commons/maps/sequences/<seq>.json (the sequence definition) and produces
a starter commons/maps/sequences/<seq>.beats.json with:

  - 1 GATEWAY (no map, low intensity, structural register)
  - One beat per map (role inferred from name patterns)
  - 1 CHAMBER at end (if no map already serves that role)
  - All beats marked stage="draft" so they're visibly unfinished
  - Bleed scaffolds where the description mentions another sequence

Run:
  python tools/draft_beats.py foundationscrisis
  python tools/draft_beats.py --all-priority   # 7 priority sequences

Will NOT overwrite an existing beats.json unless --force is passed.

The output is a scaffold, not a finished design. Open /beats in the encyclopedia
to refine each beat via the editor.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
SEQ_DIR = ROOT / "commons" / "maps" / "sequences"
SPINE_PATH = ROOT / "commons" / "maps" / "curriculum_spine.json"

# Priority order — sequences that close the most bleed asymmetries first
PRIORITY = [
    "foundationscrisis",
    "softbodies",
    "noise",
    "boolean_surfaces",
    "isosurfaces",
    "color",
    "postfoundationscrisis",
]

# Sequence id → single-letter beat-id prefix (matches existing convention)
DEFAULT_PREFIX = {
    "primitives":            "P",
    "transformation":        "T",
    "wavefunctions":         "W",
    "randomness":            "R",
    "foundationscrisis":     "F",
    "softbodies":            "S",
    "noise":                 "N",
    "boolean_surfaces":      "B",
    "isosurfaces":           "I",
    "color":                 "C",
    "postfoundationscrisis": "Z",
    "array_tutorial":        "A",
    "change":                "Ch",
    "forces":                "Fo",
    "cellularautomata":      "CA",
    "fractals":              "Fr",
    "lsystems":              "L",
    "proceduralgeneration":  "PG",
    "swarmintelligence":     "SI",
    "machinelearning":       "ML",
    "graphtheory":           "G",
    "qfeplaboratory":        "Q",
}


# ── role inference from map name ──────────────────────────────────────────

def infer_role(map_name: str, is_first: bool = False, is_last: bool = False) -> str:
    n = map_name.lower()
    if is_first:
        # First map after the gateway often introduces
        return "INTRODUCE"
    if is_last:
        # Last map in the list is usually the chamber
        if "chamber" in n:
            return "CHAMBER"
        return "SYNTHESIZE"
    if "chamber" in n:
        return "CHAMBER"
    if "catalyst" in n:
        return "CATALYST_GAIN"
    if any(k in n for k in ("intro", "introduction", "definition", "_one")):
        return "INTRODUCE"
    if any(k in n for k in ("walk", "path", "trace", "space", "wander")):
        return "PRACTICE"
    if any(k in n for k in ("workbench", "lab", "synthesis")):
        return "SYNTHESIZE"
    if any(k in n for k in ("ignorance", "limit", "paradox")):
        return "LIMIT"
    if any(k in n for k in ("refuse", "melencolia", "anti", "crisis")):
        return "REFUSE"
    if any(k in n for k in ("examples", "gallery", "showcase")):
        return "VARIATE"
    # Numeric suffix → likely a variation
    if re.search(r"_\d+$", map_name):
        return "VARIATE"
    return "DEMONSTRATE"


REGISTER_DEFAULT = {
    "INTRODUCE":     "teaching",
    "DEMONSTRATE":   "teaching",
    "PRACTICE":      "exploring",
    "VARIATE":       "teaching",
    "LIMIT":         "reflecting",
    "SYNTHESIZE":    "synthesizing",
    "WANDER":        "exploring",
    "PAUSE":         "resting",
    "BLEED":         "exploring",
    "ANTI":          "refusing",
    "REFUSE":        "refusing",
    "GATEWAY":       "structural",
    "CHAMBER":       "synthesizing",
    "CRISIS":        "refusing",
    "REFLECT":       "reflecting",
    "CATALYST_GAIN": "catalyst",
    "META":          "structural",
}

INTENSITY_DEFAULT = {
    "INTRODUCE":     "high",
    "DEMONSTRATE":   "high",
    "PRACTICE":      "medium",
    "VARIATE":       "medium",
    "LIMIT":         "high",
    "SYNTHESIZE":    "high",
    "WANDER":        "low",
    "PAUSE":         "low",
    "BLEED":         "medium",
    "ANTI":          "high",
    "REFUSE":        "high",
    "GATEWAY":       "low",
    "CHAMBER":       "high",
    "CRISIS":        "high",
    "REFLECT":       "medium",
    "CATALYST_GAIN": "high",
    "META":          "low",
}


# ── helpers ───────────────────────────────────────────────────────────────

def load_sequence(seq_id: str) -> tuple[dict, list[str], str] | None:
    """Return (inner_dict, maps, description) for the sequence."""
    p = SEQ_DIR / f"{seq_id}.json"
    if not p.exists():
        return None
    try:
        d = json.loads(p.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as e:
        print(f"  WARN: failed to parse {p.name}: {e}")
        return None
    seqs = d.get("sequences", d)
    if not isinstance(seqs, dict):
        return None
    inner = seqs.get(seq_id, {})
    maps = list(inner.get("maps") or [])
    desc = inner.get("description", "") or ""
    return inner, maps, desc


def load_spine_phase(seq_id: str) -> str:
    """Return the phase tag for a sequence from the spine, or empty string."""
    if not SPINE_PATH.exists():
        return ""
    try:
        d = json.loads(SPINE_PATH.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return ""
    spine_seqs = d.get("spine", {}).get("sequences", [])
    for s in spine_seqs:
        if isinstance(s, dict) and s.get("name") == seq_id:
            return s.get("phase", "") or ""
    return ""


def detect_bleed_mentions(desc: str, all_seq_ids: set[str], own_seq: str) -> list[str]:
    """Find other sequence ids referenced in the description text."""
    found = []
    low = desc.lower()
    for other in all_seq_ids:
        if other == own_seq:
            continue
        # Whole-word-ish match
        if re.search(r"\b" + re.escape(other.lower().replace("_", " ")) + r"\b", low) \
           or re.search(r"\b" + re.escape(other.lower()) + r"\b", low):
            found.append(other)
    return found


def collect_reciprocations(own_seq: str) -> tuple[set[str], set[str]]:
    """Scan all existing beats files for references to own_seq.

    Returns (needs_bleed_to, needs_bleed_from):
    - needs_bleed_to: other sequences that have `bleed_from own_seq` somewhere —
      we should bleed_to them to close the symmetry.
    - needs_bleed_from: other sequences that have `bleed_to own_seq` somewhere —
      we should bleed_from them.
    """
    needs_to: set[str] = set()
    needs_from: set[str] = set()
    for bf in SEQ_DIR.glob("*.beats.json"):
        try:
            d = json.loads(bf.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            continue
        other_seq = d.get("_meta", {}).get("sequence") or bf.stem.replace(".beats", "")
        if other_seq == own_seq:
            continue
        for b in d.get("beats", []):
            if own_seq in (b.get("bleed_from") or []):
                needs_to.add(other_seq)
            if own_seq in (b.get("bleed_to") or []):
                needs_from.add(other_seq)
    return needs_to, needs_from


def shorten_concept(map_name: str) -> str:
    """Turn a map name into a placeholder concept phrase."""
    # Strip common prefixes
    stripped = re.sub(r"^[A-Z][a-z]+_+", "", map_name)
    # Split underscores/CamelCase into words
    pieces = re.split(r"[_\s]+", stripped)
    pieces = [w for w in pieces if w]
    if not pieces:
        return map_name
    return " ".join(p.lower() for p in pieces) + " — to be authored"


def derive_concept_from_content(map_name: str) -> tuple[str, str] | None:
    """Try to pull a real concept from the map's authored content.
    Returns (concept_text, origin) or None.
    """
    md = ROOT / "commons" / "maps" / map_name
    if not md.exists():
        return None
    for fname, origin in (("blurb.md", "blurb"), ("intent.md", "intent"), ("technical.md", "technical")):
        p = md / fname
        if not p.exists() or p.stat().st_size < 20:
            continue
        try:
            raw = p.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        # First non-empty paragraph
        paras = [pp.strip() for pp in re.split(r"\n\s*\n", raw) if pp.strip()]
        first = ""
        for pp in paras:
            cleaned = re.sub(r"^#+\s+", "", pp).strip()
            if cleaned and len(cleaned) > 10:
                first = cleaned
                break
        if not first:
            continue
        # Light markdown strip
        first = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", first)
        first = re.sub(r"`([^`]+)`", r"\1", first)
        first = re.sub(r"\*\*([^*]+)\*\*", r"\1", first)
        # Truncate at sentence boundary near 220 chars
        if len(first) > 220:
            sentences = re.split(r"(?<=[.!?])\s+", first)
            out = sentences[0]
            for s in sentences[1:]:
                if len(out + " " + s) > 220:
                    break
                out = out + " " + s
            first = out
        if first and len(first) > 15:
            return first, origin
    return None


# ── draft generator ──────────────────────────────────────────────────────

def draft_beats(seq_id: str, force: bool = False) -> str:
    """Generate <seq>.beats.json. Returns a status string."""
    target = SEQ_DIR / f"{seq_id}.beats.json"
    if target.exists() and not force:
        return f"  SKIP {seq_id}: beats file exists (use --force to overwrite)"

    sd = load_sequence(seq_id)
    if not sd:
        return f"  SKIP {seq_id}: no sequence file or unreadable"
    inner, maps, desc = sd

    # All known sequence ids (for bleed mention detection)
    all_seq_ids = {p.stem for p in SEQ_DIR.glob("*.json") if not p.stem.endswith(".beats")}
    bleed_mentions = detect_bleed_mentions(desc, all_seq_ids, seq_id)

    prefix = DEFAULT_PREFIX.get(seq_id, seq_id[:2].upper())
    phase = load_spine_phase(seq_id) or "(phase?)"

    beats = []
    n = 0

    # 1. GATEWAY
    beats.append({
        "id":        f"{prefix}{n}",
        "role":      "GATEWAY",
        "concept":   f"entering {seq_id} — the substrate shifts",
        "register":  "structural",
        "intensity": "low",
        "maps":      [],
        "stage":     "draft",
        "next":      f"{prefix}{n + 1}",
    })
    n += 1

    # 2. One beat per map
    n_maps = len(maps)
    for i, m in enumerate(maps):
        is_first = i == 0
        is_last = i == n_maps - 1
        role = infer_role(m, is_first=is_first, is_last=is_last)
        # Try to derive a real concept from the map's authored content; fall back to placeholder
        derived = derive_concept_from_content(m)
        concept_text = derived[0] if derived else shorten_concept(m)
        beat = {
            "id":        f"{prefix}{n}",
            "role":      role,
            "concept":   concept_text,
            "register":  REGISTER_DEFAULT.get(role, "teaching"),
            "intensity": INTENSITY_DEFAULT.get(role, "medium"),
            "maps":      [m],
            "stage":     "draft",
        }
        if derived:
            beat["_concept_origin"] = derived[1]
        # Suggest scaffold bleeds on the first non-gateway beat
        if is_first and bleed_mentions:
            beat["bleed_from"] = bleed_mentions[:3]
            beat["note"] = ("auto-detected from description; refine via editor")
        beat["next"] = f"{prefix}{n + 1}" if not is_last else None
        beats.append(beat)
        n += 1

    # 3. CHAMBER (if the last map's beat isn't already a chamber)
    if beats[-1]["role"] != "CHAMBER":
        # Replace the trailing None next of the last map-beat
        beats[-1]["next"] = f"{prefix}{n}"
        beats.append({
            "id":        f"{prefix}{n}",
            "role":      "CHAMBER",
            "concept":   f"the {seq_id} principle held — carried forward",
            "register":  "synthesizing",
            "intensity": "high",
            "maps":      [],
            "stage":     "draft",
            "note":      "no map yet — assign a Chamber_<seq> map or absorb into the last map-beat",
            "next":      None,
        })

    # 4. Auto-reciprocation: close the bleed graph from this sequence's side.
    #    Convention: chamber carries the outflow; gateway absorbs the inflow.
    needs_to, needs_from = collect_reciprocations(seq_id)
    chamber = next((b for b in beats if b["role"] == "CHAMBER"), None)
    gateway = next((b for b in beats if b["role"] == "GATEWAY"), None)
    first_non_gw = next((b for b in beats if b["role"] != "GATEWAY"), None)

    if chamber and needs_to:
        existing = set(chamber.get("bleed_to") or [])
        new = sorted(existing | needs_to)
        chamber["bleed_to"] = new
        chamber["note"] = (chamber.get("note", "") + (
            " · auto-reciprocates inbound bleed_from references"
            if new != list(existing) else ""
        )).strip(" ·")

    # Inflows: any other sequence that bleed_to's us → we should bleed_from them.
    # Put on gateway preferentially (the inflow point); fall back to first beat.
    inflow_target = gateway or first_non_gw
    if inflow_target and needs_from:
        existing = set(inflow_target.get("bleed_from") or [])
        # Don't duplicate the description-mention bleeds already added
        new = sorted(existing | needs_from)
        if new != sorted(existing):
            inflow_target["bleed_from"] = new
            inflow_target["note"] = (inflow_target.get("note", "") +
                " · auto-reciprocates outbound bleed_to references").strip(" ·")

    # Build the document
    out = {
        "_meta": {
            "schema_version": "beats/0.1",
            "schema_doc":     "doc/beats/schema.md",
            "sequence":       seq_id,
            "phase":          phase,
            "description":    desc[:200] + ("…" if len(desc) > 200 else ""),
            "_draft":         True,
            "_draft_origin":  "tools/draft_beats.py — refine via /beats editor",
        },
        "beats": beats,
    }

    target.write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n",
                       encoding="utf-8")
    return (f"  OK   {seq_id}: {len(beats)} beats "
            f"({len(maps)} maps + GATEWAY/CHAMBER), phase={phase}")


# ── main ─────────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser()
    p.add_argument("sequence", nargs="?", help="sequence id to draft")
    p.add_argument("--all-priority", action="store_true",
                   help=f"draft the {len(PRIORITY)} priority sequences (those that close bleed asymmetries)")
    p.add_argument("--force", action="store_true",
                   help="overwrite existing beats file(s)")
    args = p.parse_args()

    if args.all_priority:
        print(f"drafting {len(PRIORITY)} priority sequences:")
        for seq in PRIORITY:
            print(draft_beats(seq, force=args.force))
    elif args.sequence:
        print(draft_beats(args.sequence, force=args.force))
    else:
        p.print_help()
        return

    print()
    print("next: open http://localhost:3003/beats to refine each draft via the editor")


if __name__ == "__main__":
    main()
