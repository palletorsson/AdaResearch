#!/usr/bin/env python
"""
sync_artifact_descriptions.py — pull artifact descriptions from .gd @identity
blocks into the registry JSONs.

Problem this solves
-------------------
Each artifact's .gd has an @identity block that reads like this::

    # @identity
    # essence: (0, 0, 0) — the reference from which all coordinates are measured
    # desire: learner viscerally locates themselves relative to the world's fixed anchor
    # critical_parameter: ...
    # emerges: ...
    # truth: ...

That's the authored description. But the registry JSONs
(``commons/artifacts/registry/*.json``) frequently have stubs like
``"description": "origin"`` or ``"description": "draw_dot."`` — never synced
from the real source. APIs, the web UI, and the evals-based stub/signature
audit all read the JSON. So artifacts look unfinished when actually their
documentation is just in the wrong place.

This tool walks every .gd file that defines an artifact, parses its @identity
block, and updates the matching registry entry. Stub descriptions get
replaced by the ``essence`` line; non-stub descriptions are left alone unless
``--force`` is passed.

Use modes::

    python tools/sync_artifact_descriptions.py                    # dry-run
    python tools/sync_artifact_descriptions.py --apply            # write
    python tools/sync_artifact_descriptions.py --token origin     # one artifact
    python tools/sync_artifact_descriptions.py --force --apply    # replace all,
                                                                  # even non-stubs

The script is idempotent and preserves tab indentation. It does NOT touch
fields other than ``description``. Everything else (tags, spatial_needs,
category, complexity, etc.) is out of scope — that's the larger
registry-as-build-artifact move.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

# Windows consoles default to cp1252; our @identity strings often contain
# Unicode math (⊗, ∈, ⇒, —) — force UTF-8 on stdout or the prints crash.
try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

REPO = Path(__file__).resolve().parent.parent
REGISTRY_DIR = REPO / "commons" / "artifacts" / "registry"
GD_ROOTS = [REPO / "commons", REPO / "algorithms"]

# ─── .gd @identity parser ────────────────────────────────────────────────

# Matches one @identity block: a "# @identity" header followed by any number
# of "# key: value" comment lines, stopping at the first non-comment line.
_IDENTITY_BLOCK_RE = re.compile(
    r"#\s*@identity\s*\n((?:#[^\n]*\n?)+)",
    re.MULTILINE,
)

# Matches "# essence: ..." (one-line key:value). Stops at end of line.
_IDENTITY_FIELD_RE = re.compile(r"^\s*#\s*([A-Za-z_][A-Za-z0-9_]*):\s*(.+?)\s*$")


def parse_identity(source: str) -> dict[str, str] | None:
    """Return the first @identity block's fields as a {key: value} dict,
    or None if no block is present."""
    m = _IDENTITY_BLOCK_RE.search(source)
    if not m:
        return None
    block = m.group(1)
    out: dict[str, str] = {}
    for line in block.splitlines():
        fm = _IDENTITY_FIELD_RE.match(line)
        if fm:
            key, val = fm.group(1).lower(), fm.group(2).strip()
            out[key] = val
    return out or None


def collect_identities() -> dict[str, dict[str, str]]:
    """Walk every .gd file under the configured roots and index by
    filename-stem (= artifact token). Skips android/ subtrees."""
    out: dict[str, dict[str, str]] = {}
    for root in GD_ROOTS:
        if not root.exists():
            continue
        for p in root.rglob("*.gd"):
            if "android" in p.parts:
                continue
            try:
                txt = p.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                continue
            ident = parse_identity(txt)
            if ident is not None:
                token = p.stem
                # First-write wins — warn on duplicates, but keep the first
                if token not in out:
                    out[token] = ident
    return out


# ─── registry helpers ────────────────────────────────────────────────────

def is_stub_description(token: str, desc: str | None) -> bool:
    """A description is a 'stub' if it's missing, empty, equal to the token,
    equal to the token with a trailing period, or shorter than token + 4."""
    if not desc:
        return True
    s = desc.strip()
    if not s:
        return True
    if s == token or s == token + ".":
        return True
    # Single-token placeholders — e.g. "grid_lines.", "draw_dot.", "origin"
    if len(s) <= len(token) + 2:
        return True
    return False


def load_registry(path: Path) -> tuple[dict, str]:
    """Load a registry JSON and remember its newline style."""
    raw = path.read_text(encoding="utf-8")
    # Tolerate trailing commas (some registries have them after hand edits)
    cleaned = re.sub(r",\s*([\]}])", r"\1", raw)
    data = json.loads(cleaned)
    # Detect indent style: tabs vs spaces. All our registries use tabs.
    return data, "\t"


def save_registry(path: Path, data: dict, indent_char: str) -> None:
    """Serialize with tab indentation to match the existing files."""
    out = json.dumps(data, indent=1, ensure_ascii=False)
    # json.dumps indent=N uses spaces; swap for our char
    out = out.replace(" " * 1, indent_char) if indent_char != " " else out
    # The above swap is naive for "indent=1"; do it per-line properly:
    if indent_char == "\t":
        lines = []
        for line in json.dumps(data, indent="\t", ensure_ascii=False).splitlines():
            lines.append(line)
        out = "\n".join(lines) + "\n"
    path.write_text(out, encoding="utf-8")


# ─── main sync ───────────────────────────────────────────────────────────

def sync(
    force: bool,
    apply: bool,
    only_token: str | None,
) -> int:
    identities = collect_identities()
    print(f"Parsed @identity from {len(identities)} .gd file(s).")
    print()

    changes: list[tuple[Path, str, str, str, str]] = []
    # Each change: (registry_path, token, field, before, after)

    for reg_path in sorted(REGISTRY_DIR.glob("*.json")):
        if reg_path.name.endswith(".deprecated"):
            continue
        try:
            data, indent_char = load_registry(reg_path)
        except Exception as e:
            print(f"  [SKIP] {reg_path.name}: {e}")
            continue

        arts = data.get("artifacts") or {}
        if not isinstance(arts, dict):
            continue

        for token, entry in arts.items():
            if only_token and token != only_token:
                continue
            ident = identities.get(token)
            if not ident or "essence" not in ident:
                continue
            current = entry.get("description") if isinstance(entry, dict) else None
            if not force and not is_stub_description(token, current):
                continue
            new_desc = ident["essence"]
            # Don't claim a "change" if the new value is identical to existing
            if (current or "").strip() == new_desc.strip():
                continue
            changes.append((reg_path, token, "description", current or "", new_desc))
            if apply:
                entry["description"] = new_desc

        if apply and any(c[0] == reg_path for c in changes):
            save_registry(reg_path, data, indent_char)

    # Report
    if not changes:
        print("Nothing to update.")
        return 0

    width = max(len(c[1]) for c in changes)
    for reg_path, token, _field, before, after in changes:
        print(f"  {reg_path.name:<32s} {token:<{width}s}")
        print(f"    - {before[:110]!r}")
        print(f"    + {after[:110]!r}")

    print()
    print(f"{len(changes)} update(s).")
    if apply:
        print("Applied.")
    else:
        print("Dry-run. Pass --apply to write.")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="write changes (default: dry-run)")
    ap.add_argument("--force", action="store_true", help="replace even non-stub descriptions")
    ap.add_argument("--token", help="only this artifact token")
    args = ap.parse_args()
    return sync(force=args.force, apply=args.apply, only_token=args.token)


if __name__ == "__main__":
    sys.exit(main())
