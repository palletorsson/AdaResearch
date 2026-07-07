#!/usr/bin/env python3
"""
sieve_proposals.py — parse sieve passes into structured proposal records.

Reads `doc/sieve_passes/*.md`, finds "Reorder candidates" tables, and emits
one JSON record per proposed structural move. Records persist under
`data/sieve_proposals/{pass_id}_proposals.json` so the encyclopedia's
/sieve-proposals page can render them as actionable chips.

Idempotent: re-running updates `pending` rows but leaves rows with
status `applied`, `deferred`, or `rejected` unchanged.

Usage:
    python tools/sieve_proposals.py                 # parse all passes
    python tools/sieve_proposals.py --pass <id>     # parse one pass
    python tools/sieve_proposals.py --list          # list parsed proposals
    python tools/sieve_proposals.py --json          # emit all to stdout (for piping)

Background: doc/proposals/2026-05-13_chip-and-pause.md
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Optional

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

REPO_ROOT = Path(__file__).resolve().parent.parent
PASSES_DIR = REPO_ROOT / "doc" / "sieve_passes"
PROPOSALS_DIR = REPO_ROOT / "data" / "sieve_proposals"

# Section headers that introduce a reorder table. We scan permissively because
# the sieves vary in section numbering ("## 7. Reorder candidates", "### 6a. ..."
# etc.) — the constant is the header text.
REORDER_HEADER_RE = re.compile(r"^#{1,4}\s*[\d\.a-zA-Z]*\s*Reorder candidates\b", re.MULTILINE)

# Markdown table row, splitting on unescaped pipes. Light-weight — we don't
# handle escaped pipes because the sieves don't use them.
ROW_SPLIT_RE = re.compile(r"\s*\|\s*")


@dataclass
class Proposal:
    pass_id: str
    move_id: str           # short stable id within the pass
    change: str            # what changes (e.g., "cellularautomata")
    from_state: str        # "order 9, phase E_entropy"
    to_state: str          # "order 9, phase lambda_edge"
    impact: str            # impact note, may be empty
    rationale_excerpt: str # nearby context from the sieve doc
    status: str = "pending"   # pending | applied | deferred | rejected
    applied_at: Optional[str] = None
    applied_by: Optional[str] = None
    pre_existing: bool = False  # for backfill of moves already applied tonight
    notes: str = ""


def parse_table_rows(lines: list[str], start_idx: int) -> tuple[list[list[str]], int]:
    """Parse a markdown table starting at start_idx. Return (rows, next_idx).
    rows includes header but not the separator row.
    """
    rows: list[list[str]] = []
    i = start_idx
    seen_separator = False
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            if rows:  # blank line after table content means we're done
                break
            i += 1
            continue
        if not line.startswith("|"):
            break
        # Strip leading/trailing pipes, split on |
        inner = line.strip("|")
        cells = [c.strip() for c in ROW_SPLIT_RE.split(inner)]
        # Separator row like |---|---|
        if all(re.match(r"^:?-+:?$", c) for c in cells if c):
            seen_separator = True
            i += 1
            continue
        rows.append(cells)
        i += 1
    return rows, i


def slug(text: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9._-]+", "-", text).strip("-").lower()
    return s or "move"


def strip_bold(text: str) -> str:
    # Markdown **bold** → plain
    return re.sub(r"\*\*(.+?)\*\*", r"\1", text)


def extract_rationale_around(content: str, table_start_char: int, window: int = 600) -> str:
    """Pull ~window chars around the table position to provide rationale context."""
    lo = max(0, table_start_char - window)
    hi = min(len(content), table_start_char + window)
    snippet = content[lo:hi]
    # Compress whitespace
    snippet = re.sub(r"\n{2,}", "\n\n", snippet)
    return snippet.strip()


def parse_pass_file(path: Path) -> list[Proposal]:
    """Return a list of Proposal records for one sieve pass markdown file."""
    pass_id = path.stem  # filename without .md
    content = path.read_text(encoding="utf-8")
    lines = content.splitlines()
    proposals: list[Proposal] = []

    # Find every "Reorder candidates" header
    header_positions: list[tuple[int, int]] = []
    for m in REORDER_HEADER_RE.finditer(content):
        # Convert char offset to line index
        char_offset = m.start()
        line_idx = content[:char_offset].count("\n")
        header_positions.append((line_idx, char_offset))

    for header_line_idx, char_offset in header_positions:
        # Scan forward for the first table after the header
        i = header_line_idx + 1
        while i < len(lines):
            line = lines[i].strip()
            if line.startswith("|"):
                rows, _ = parse_table_rows(lines, i)
                if not rows:
                    break
                header = [c.lower() for c in rows[0]]
                data_rows = rows[1:]
                # Required columns: change, from, to (impact optional)
                if not ("change" in header and "from" in header and "to" in header):
                    break
                idx_change = header.index("change")
                idx_from = header.index("from")
                idx_to = header.index("to")
                idx_impact = header.index("impact") if "impact" in header else -1
                rationale = extract_rationale_around(content, char_offset)
                for row_idx, cells in enumerate(data_rows):
                    if len(cells) <= max(idx_change, idx_from, idx_to):
                        continue
                    change = strip_bold(cells[idx_change])
                    from_state = strip_bold(cells[idx_from])
                    to_state = strip_bold(cells[idx_to])
                    impact = strip_bold(cells[idx_impact]) if idx_impact >= 0 and idx_impact < len(cells) else ""
                    if not change or not from_state or not to_state:
                        continue
                    move_id = f"{slug(change)}-{row_idx}"
                    proposals.append(Proposal(
                        pass_id=pass_id,
                        move_id=move_id,
                        change=change,
                        from_state=from_state,
                        to_state=to_state,
                        impact=impact,
                        rationale_excerpt=rationale,
                    ))
                break
            i += 1

    return proposals


def load_existing(pass_id: str) -> list[dict]:
    path = PROPOSALS_DIR / f"{pass_id}_proposals.json"
    if not path.exists():
        return []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return data.get("proposals", [])
    except Exception:
        return []


def merge_with_existing(new: list[Proposal], existing: list[dict]) -> list[dict]:
    """Preserve status/applied_at/applied_by/notes from existing records for
    rows with matching (pass_id, move_id). New rows enter as pending."""
    by_key = {(r.get("pass_id"), r.get("move_id")): r for r in existing}
    out: list[dict] = []
    for p in new:
        key = (p.pass_id, p.move_id)
        if key in by_key:
            ex = by_key[key]
            if ex.get("status") in ("applied", "deferred", "rejected"):
                # Keep the historical state, but refresh fields that may have changed.
                merged = dict(ex)
                merged.update({
                    "change": p.change,
                    "from_state": p.from_state,
                    "to_state": p.to_state,
                    "impact": p.impact,
                    "rationale_excerpt": p.rationale_excerpt,
                })
                out.append(merged)
                continue
        out.append(asdict(p))
    return out


def write_pass_proposals(pass_id: str, proposals: list[dict]) -> Path:
    PROPOSALS_DIR.mkdir(parents=True, exist_ok=True)
    path = PROPOSALS_DIR / f"{pass_id}_proposals.json"
    payload = {
        "pass_id": pass_id,
        "proposals": proposals,
    }
    path.write_text(json.dumps(payload, indent="\t", ensure_ascii=False) + "\n", encoding="utf-8")
    return path


def parse_all(only_pass: Optional[str] = None) -> dict[str, int]:
    """Walk all sieve passes, parse, and persist. Returns a count summary."""
    counts: dict[str, int] = {}
    if not PASSES_DIR.exists():
        return counts
    for md in sorted(PASSES_DIR.glob("*.md")):
        pass_id = md.stem
        if only_pass and only_pass not in pass_id:
            continue
        new_proposals = parse_pass_file(md)
        if not new_proposals:
            continue
        existing = load_existing(pass_id)
        merged = merge_with_existing(new_proposals, existing)
        write_pass_proposals(pass_id, merged)
        counts[pass_id] = len(merged)
    return counts


def list_all() -> None:
    if not PROPOSALS_DIR.exists():
        print("No proposal records yet. Run parser first.")
        return
    total = 0
    by_status = {"pending": 0, "applied": 0, "deferred": 0, "rejected": 0}
    for jf in sorted(PROPOSALS_DIR.glob("*_proposals.json")):
        try:
            data = json.loads(jf.read_text(encoding="utf-8"))
        except Exception:
            continue
        props = data.get("proposals", [])
        for p in props:
            by_status[p.get("status", "pending")] = by_status.get(p.get("status", "pending"), 0) + 1
            total += 1
        print(f"{jf.stem}: {len(props)} proposals")
    print(f"\nTotal: {total}  (pending={by_status['pending']} applied={by_status['applied']} deferred={by_status['deferred']} rejected={by_status['rejected']})")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--pass", dest="only_pass", help="Parse only passes whose id contains this substring.")
    parser.add_argument("--list", action="store_true", help="List existing proposal records.")
    parser.add_argument("--json", action="store_true", help="Emit all proposals as JSON to stdout.")
    args = parser.parse_args()

    if args.list:
        list_all()
        return 0

    counts = parse_all(args.only_pass)
    if args.json:
        all_proposals: list[dict] = []
        for jf in sorted(PROPOSALS_DIR.glob("*_proposals.json")):
            try:
                data = json.loads(jf.read_text(encoding="utf-8"))
                all_proposals.extend(data.get("proposals", []))
            except Exception:
                continue
        print(json.dumps(all_proposals, indent=2, ensure_ascii=False))
    else:
        for k, v in counts.items():
            print(f"  {k}: {v} proposals")
        print(f"\nWrote {sum(counts.values())} proposals across {len(counts)} passes.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
