#!/usr/bin/env python3
"""
Extract @identity blocks from artifact .gd files.
Generates a registry of what each artifact wants, needs, and emerges.

Usage:
    python tools/extract_identities.py              # all artifacts with @identity
    python tools/extract_identities.py --json       # output as JSON
    python tools/extract_identities.py --missing    # find artifacts WITHOUT @identity
"""

import sys
import re
import json
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SEARCH_DIRS = [
    REPO / "algorithms",
    REPO / "commons" / "artifacts",
]

IDENTITY_FIELDS = [
    "essence", "desire", "critical_parameter", "triggers",
    "emerges", "needs", "relationships", "truth"
]


def extract_identity(gd_path):
    """Extract @identity block from a .gd file."""
    text = gd_path.read_text(encoding="utf-8", errors="replace")

    if "@identity" not in text:
        return None

    identity = {"file": str(gd_path.relative_to(REPO))}

    for field in IDENTITY_FIELDS:
        pattern = rf"#\s*{field}:\s*(.+)"
        match = re.search(pattern, text)
        if match:
            identity[field] = match.group(1).strip()

    return identity


def find_all_gd_files():
    """Find all .gd files in artifact directories."""
    files = []
    for search_dir in SEARCH_DIRS:
        if search_dir.exists():
            files.extend(search_dir.rglob("*.gd"))
    return sorted(files)


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "--list"
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    all_files = find_all_gd_files()
    identities = []
    missing = []

    for gd_file in all_files:
        identity = extract_identity(gd_file)
        if identity:
            identities.append(identity)
        else:
            missing.append(str(gd_file.relative_to(REPO)))

    if mode == "--json":
        print(json.dumps(identities, indent=2, ensure_ascii=False))

    elif mode == "--missing":
        print(f"Artifacts WITHOUT @identity: {len(missing)} of {len(all_files)}")
        print()
        for f in missing[:50]:
            print(f"  {f}")
        if len(missing) > 50:
            print(f"  ... and {len(missing) - 50} more")

    else:
        print(f"Artifacts WITH @identity: {len(identities)}")
        print()
        for ident in identities:
            name = Path(ident["file"]).stem
            essence = ident.get("essence", "(no essence)")
            desire = ident.get("desire", "(no desire)")
            needs = ident.get("needs", "(no needs)")
            truth = ident.get("truth", "(no truth)")
            print(f"  {name}")
            print(f"    essence: {essence}")
            print(f"    desire:  {desire}")
            print(f"    needs:   {needs}")
            print(f"    truth:   {truth}")
            print()


if __name__ == "__main__":
    main()
