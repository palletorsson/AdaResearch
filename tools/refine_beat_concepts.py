"""tools/refine_beat_concepts.py — pull real concept text from existing content.

For every beat across all beats files:

  - If the concept text is a drafter placeholder (ends "— to be authored",
    or matches the shorten_concept pattern), AND
  - The beat has exactly one map (single referent), AND
  - That map has blurb.md / intent.md / technical.md authored content

Then derive a one-sentence concept from the authored text (priority:
blurb > intent > technical), preserving the curriculum's existing voice.

The beat also gets `_concept_origin: blurb|intent|technical` so the editor
can later distinguish derived vs. authored concepts.

This is mechanical refinement — it pulls existing content into a new index.
Authorial work (cross-sequence weave, bleeds, voice) stays manual.

Run:
  python tools/refine_beat_concepts.py                 # dry-run
  python tools/refine_beat_concepts.py --apply         # write changes
  python tools/refine_beat_concepts.py --seq=primitives --apply  # one sequence
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
MAPS_DIR = ROOT / "commons" / "maps"


# ── concept extraction ───────────────────────────────────────────────────

def first_paragraph(text: str) -> str:
    """First non-empty paragraph, with leading markdown headings stripped."""
    if not text:
        return ""
    # Split on blank lines
    paras = [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]
    for p in paras:
        # Strip leading markdown heading
        cleaned = re.sub(r"^#+\s+", "", p).strip()
        # Skip empty or just-heading paragraphs
        if cleaned and len(cleaned) > 10:
            return cleaned
    return ""


def truncate_at_sentence(text: str, max_len: int = 220) -> str:
    """Truncate at a sentence boundary near max_len characters."""
    text = text.strip()
    if len(text) <= max_len:
        return text
    # Split sentences
    parts = re.split(r"(?<=[.!?])\s+", text)
    out = parts[0]
    for p in parts[1:]:
        candidate = out + " " + p
        if len(candidate) > max_len:
            break
        out = candidate
    # If even the first sentence is too long, hard truncate at word boundary
    if len(out) > max_len:
        out = out[:max_len].rsplit(" ", 1)[0] + "…"
    return out


def strip_markdown(text: str) -> str:
    """Light markdown removal — links, emphasis, inline code."""
    # [text](link) → text
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    # **bold** / __bold__ → bold
    text = re.sub(r"\*\*([^*]+)\*\*", r"\1", text)
    text = re.sub(r"__([^_]+)__", r"\1", text)
    # *italic* / _italic_ → italic (careful not to strip mid-word _)
    text = re.sub(r"(?<!\w)\*([^*]+)\*(?!\w)", r"\1", text)
    text = re.sub(r"(?<!\w)_([^_]+)_(?!\w)", r"\1", text)
    # `code` → code
    text = re.sub(r"`([^`]+)`", r"\1", text)
    return text


def derive_concept(map_name: str) -> tuple[str, str] | None:
    """Return (concept_text, origin) or None if nothing usable."""
    md = MAPS_DIR / map_name
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
        para = first_paragraph(raw)
        if not para:
            continue
        cleaned = strip_markdown(para)
        concept = truncate_at_sentence(cleaned, max_len=220)
        if concept and len(concept) > 15:
            return concept, origin
    return None


# ── placeholder detection ────────────────────────────────────────────────

PLACEHOLDER_PATTERNS = [
    r"^.*— to be authored\s*$",
    r"^entering .+ — the substrate shifts$",
    r"^the .+ principle held — carried forward$",
]

def is_placeholder(concept: str) -> bool:
    if not concept:
        return True
    for pat in PLACEHOLDER_PATTERNS:
        if re.match(pat, concept.strip(), re.IGNORECASE):
            return True
    return False


# ── refinement ───────────────────────────────────────────────────────────

def refine_beats_file(path: Path, apply: bool) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    beats = data.get("beats", [])
    changes = []
    for b in beats:
        bid = b.get("id", "?")
        concept = b.get("concept", "")
        maps = b.get("maps") or []
        if not is_placeholder(concept):
            continue
        # Only refine beats with a single canonical map; multi-map beats need editorial choice
        if len(maps) != 1:
            continue
        derived = derive_concept(maps[0])
        if not derived:
            continue
        new_concept, origin = derived
        changes.append({
            "beat": bid,
            "map": maps[0],
            "from": concept[:80],
            "to": new_concept[:120],
            "origin": origin,
        })
        if apply:
            b["concept"] = new_concept
            b["_concept_origin"] = origin
    if apply and changes:
        path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return {
        "sequence": path.stem.replace(".beats", ""),
        "changes":  changes,
        "n_beats":  len(beats),
    }


# ── main ─────────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--seq", type=str, help="single sequence to refine")
    p.add_argument("--apply", action="store_true", help="write changes (default = dry-run)")
    args = p.parse_args()

    target_files = []
    if args.seq:
        f = SEQ_DIR / f"{args.seq}.beats.json"
        if f.exists():
            target_files.append(f)
    else:
        target_files = sorted(SEQ_DIR.glob("*.beats.json"))

    if not target_files:
        print("no beats files found")
        return

    total_changes = 0
    print(f"{'WROTE' if args.apply else 'DRY-RUN'} concept refinement:\n")
    for f in target_files:
        report = refine_beats_file(f, apply=args.apply)
        n = len(report["changes"])
        total_changes += n
        if n == 0:
            print(f"  {report['sequence']:<25} 0 changes ({report['n_beats']} beats)")
            continue
        origins = {}
        for c in report["changes"]:
            origins[c["origin"]] = origins.get(c["origin"], 0) + 1
        ori_summary = ", ".join(f"{k}×{v}" for k, v in origins.items())
        print(f"  {report['sequence']:<25} {n:2d} concept(s) derived  ({ori_summary})")
        for c in report["changes"][:3]:
            print(f"    [{c['beat']}] {c['map']}")
            print(f"      → {c['to'][:110]}")
        if n > 3:
            print(f"    ... +{n - 3} more")
        print()

    print(f"TOTAL: {total_changes} concept(s) refined across {len(target_files)} sequence(s)")
    if not args.apply:
        print("run with --apply to write changes")


if __name__ == "__main__":
    main()
