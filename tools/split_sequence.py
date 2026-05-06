#!/usr/bin/env python
"""
split_sequence.py — write an edited bundle back to individual map files.

Pairs with bundle_sequence.py. Parses the bundle's front matter, finds
each <<<MAP: NAME>>> boundary, extracts the content for that map, and
writes it back to commons/maps/NAME/{file_role}. Originals are backed
up to .before_bundle next to each target.

Safety checks before any write:
- Bundle front matter must parse (sequence + file)
- Every map section must have non-empty content (strips comment-only sections)
- --dry-run flag shows what would be written without touching disk
- If any check fails, no files are modified (atomic across the whole split)

Usage::

    python tools/split_sequence.py --bundle doc/_bundles/primitives_technical.md
    python tools/split_sequence.py --bundle doc/_bundles/primitives_technical.md --dry-run
    python tools/split_sequence.py --bundle doc/_bundles/primitives_technical.md --no-backup
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Any

REPO = Path(__file__).resolve().parent.parent
MAPS = REPO / "commons" / "maps"

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass


MARKER_START = "<<<ADA_BUNDLE>>>"
MARKER_END = "<<</ADA_BUNDLE>>>"
MAP_MARKER_RE = re.compile(r"^<<<MAP:\s+([A-Za-z0-9_]+)\s*>>>\s*$", re.MULTILINE)


def parse_front_matter(bundle: str) -> dict[str, str]:
    """Extract key: value pairs from the ADA_BUNDLE front matter block."""
    start = bundle.find(MARKER_START)
    end = bundle.find(MARKER_END, start + 1)
    if start == -1 or end == -1:
        raise SystemExit("Bundle missing <<<ADA_BUNDLE>>> / <<</ADA_BUNDLE>>> front matter")
    block = bundle[start + len(MARKER_START):end].strip()
    fm: dict[str, str] = {}
    for line in block.splitlines():
        line = line.strip()
        if not line or ":" not in line:
            continue
        k, _, v = line.partition(":")
        fm[k.strip()] = v.strip()
    return fm


def extract_sections(bundle: str) -> list[tuple[str, str]]:
    """Return [(map_name, content), ...] preserving document order."""
    # Find all map markers; content runs from the marker line to the next marker
    matches = list(MAP_MARKER_RE.finditer(bundle))
    if not matches:
        return []
    sections: list[tuple[str, str]] = []
    for i, m in enumerate(matches):
        name = m.group(1)
        content_start = m.end()
        content_end = matches[i + 1].start() if i + 1 < len(matches) else len(bundle)
        raw = bundle[content_start:content_end]
        # Strip the line containing the marker itself (we're past m.end() so we're on
        # the next char; move past the trailing newline of the marker line)
        raw = raw.lstrip("\n")
        sections.append((name, raw.rstrip() + "\n"))
    return sections


def strip_leading_comments(content: str) -> str:
    """Remove leading # comment lines (FAILURE/INTENT/BLURB annotations) and
    leading blank lines from a section body."""
    lines = content.splitlines()
    i = 0
    while i < len(lines):
        s = lines[i].strip()
        # Strip comment annotations we injected as editor hints
        if s.startswith("# FAILURE:") or s.startswith("# STATUS:") \
                or s.startswith("# INTENT:") or s.startswith("# BLURB:"):
            i += 1
            continue
        if not s:
            i += 1
            continue
        break
    return "\n".join(lines[i:]).rstrip() + "\n"


def is_placeholder(content: str) -> bool:
    """Detect the placeholder strings we emit for missing/empty maps."""
    stripped = content.strip().lower()
    return stripped in (
        "[empty — file does not yet exist]",
        "[empty — to generate]",
        "[empty - file does not yet exist]",
        "[empty - to generate]",
        "",
    )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--bundle", required=True, help="Path to bundle file to split")
    ap.add_argument("--dry-run", action="store_true",
                    help="Report what would be written; do not touch disk")
    ap.add_argument("--no-backup", action="store_true",
                    help="Do not write .before_bundle backup (disables rollback)")
    ap.add_argument("--allow-empty", action="store_true",
                    help="Allow writing placeholder/empty sections (normally skipped)")
    args = ap.parse_args()

    bundle_path = Path(args.bundle)
    if not bundle_path.is_absolute():
        bundle_path = (REPO / bundle_path).resolve()
    if not bundle_path.exists():
        raise SystemExit(f"Bundle not found: {bundle_path}")

    text = bundle_path.read_text(encoding="utf-8", errors="replace")

    fm = parse_front_matter(text)
    sequence = fm.get("sequence", "")
    file_role = fm.get("file", "")
    if not sequence or not file_role:
        raise SystemExit("Front matter missing 'sequence' or 'file' field")

    sections_raw = extract_sections(text)
    if not sections_raw:
        raise SystemExit("No <<<MAP: NAME>>> sections found in bundle")

    # Clean each section, filter empties unless --allow-empty
    planned: list[tuple[str, str, Path]] = []  # (name, content, target_path)
    skipped_empty: list[str] = []
    missing_dirs: list[str] = []

    for name, raw in sections_raw:
        cleaned = strip_leading_comments(raw)
        if is_placeholder(cleaned) and not args.allow_empty:
            skipped_empty.append(name)
            continue
        target = MAPS / name / file_role
        if not target.parent.exists():
            missing_dirs.append(name)
            continue
        planned.append((name, cleaned, target))

    print(f"Split plan: {sequence} / {file_role}")
    print(f"  sections in bundle:   {len(sections_raw)}")
    print(f"  will write:           {len(planned)}")
    if skipped_empty:
        print(f"  skipped (empty):      {len(skipped_empty)}"
              f" ({', '.join(skipped_empty[:5])}"
              f"{'...' if len(skipped_empty) > 5 else ''})")
    if missing_dirs:
        print(f"  skipped (no map dir): {len(missing_dirs)}"
              f" ({', '.join(missing_dirs)})")
        if not args.dry_run:
            print("  ABORT: some map directories missing; use --dry-run to inspect")
            return 2

    if args.dry_run:
        for name, content, target in planned:
            short = content.splitlines()[0] if content else "<empty>"
            rel = target.relative_to(REPO) if REPO in target.parents else target
            print(f"  [dry] {rel}  ({len(content):,} chars)  first: {short[:60]!r}")
        return 0

    wrote = 0
    for name, content, target in planned:
        if not args.no_backup and target.exists():
            backup = target.with_suffix(target.suffix + ".before_bundle")
            backup.write_bytes(target.read_bytes())
        target.write_text(content, encoding="utf-8")
        wrote += 1

    print(f"Wrote {wrote} files"
          f"{'' if args.no_backup else ' (originals backed up to *.before_bundle)'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
