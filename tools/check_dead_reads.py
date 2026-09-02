#!/usr/bin/env python3
"""A READ WHOSE VALUE IS THROWN AWAY — the typo that hides until a key is missing.

    python tools/check_dead_reads.py          # exit code = findings, so it gates

2026-09-01. Found because the museum threw, in VR, at hall one of a chapter:

    Invalid access to property or key 'transformation|trans introduction'
    on a base object of type 'Dictionary'.
    endless_museum.gd:395 @ _load_showing_cards()

The line was:

    if not _cards_seen.has(k):
        _cards_seen[k]              # the `= []` had been lost
    (_cards_seen[k] as Array).append(c)

A bare subscript as a whole statement. GDScript compiles it — it is a legal
expression — and it does nothing except throw when the key is absent, which is
the only case the branch exists to handle. So the key was never created, every
one of the 4,879 cards in em_showing_cards.json threw twice, and _cards_seen
stayed EMPTY: the seen-filter never loaded from disk at all and every hall the
museum had already shown read as unshown. _save_showing_cards, twelve lines
below, had always written `fresh[k] = []` correctly.

WHY A SCANNER AND NOT JUST A FIX. This is invisible three ways at once: it
compiles, it is one token from correct, and it is silent on any key that happens
to exist already. The runtime error names a missing KEY, which reads like a data
problem — the file is fine; the loader is not.

TWO THINGS THIS GOT WRONG BEFORE IT GOT THEM RIGHT, both worth keeping:

  * TRAILING COMMENTS. The first pass called
    `target_points[i % target_points.size()]` a finding. Its previous line is
    `Vector3.ZERO,  # Always start from center` — a comma, then a comment. Strip
    comments before asking whether the previous line continues an expression, or
    every multi-line array literal with a note in it looks like a bug.

  * `:` IS NOT A CONTINUATION. Treating it as one made the scanner miss the ONE
    real finding in the corpus, because the line above it is `if not
    _cards_seen.has(k):`. A colon ends a block header, and the line after a block
    header is exactly the statement position this is looking for. A filter tuned
    until it is quiet is a filter that has been tuned into uselessness.

Measured over commons/, algorithms/ and tools/: 26 lines match the shape, 25 are
continuation lines inside multi-line expressions, 1 was the bug.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
ROOTS = ("commons", "algorithms", "tools", "addons")

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

## An indented line that is nothing but `name[...]`.
SHAPE = re.compile(r"^\s+([_a-zA-Z][_a-zA-Z0-9]*)\[[^\]]+\]\s*$")

## …where `name` is a variable, not a keyword. `return["a string"]` is a return
## with an array literal and matched the shape exactly; reported as a finding it
## sent the reader to a line of godot-xr-tools that was never wrong. A scanner
## whose first output is a false positive gets muted, and then it is worth less
## than nothing — it is a gate everybody has learned to ignore.
KEYWORDS = {"return", "await", "yield", "assert", "print", "breakpoint",
            "pass", "break", "continue", "elif", "if", "else", "while", "for",
            "in", "and", "or", "not", "var", "const", "match", "when", "emit"}

## If the previous line ends with one of these, our line is the middle of an
## expression, not a statement. NOTE the absence of ":" — see the docstring.
CONTINUES = (",", "(", "[", "+", "-", "*", "/", "=", "\\", "&", "|",
             "and", "or", "not", "if", "else")


def _strip_comment(s: str) -> str:
    """Good enough for this shape: these lines carry no '#' inside a string."""
    return (s.split("#")[0] if "#" in s else s).rstrip()


def scan() -> list[tuple[str, int, str, str]]:
    out = []
    for root in ROOTS:
        base = REPO / root
        if not base.exists():
            continue
        for f in sorted(base.rglob("*.gd")):
            try:
                src = f.read_text(encoding="utf-8", errors="replace").split("\n")
            except Exception:
                continue
            for i, line in enumerate(src):
                m = SHAPE.match(line)
                if not m or m.group(1) in KEYWORDS:
                    continue
                prev = ""
                for j in range(i - 1, -1, -1):
                    if src[j].strip():
                        prev = _strip_comment(src[j])
                        break
                if prev.endswith(CONTINUES):
                    continue
                out.append((f.relative_to(REPO).as_posix(), i + 1,
                            prev.strip(), line.strip()))
    return out


def main() -> int:
    found = scan()
    print("DEAD READS — a subscript evaluated as a whole statement")
    print()
    if not found:
        print("  none. (A read that is thrown away does nothing except throw")
        print("   when the key is missing, which is usually the case the branch")
        print("   was written to handle.)")
        return 0
    for path, n, prev, cur in found:
        print("  %s:%d" % (path, n))
        print("      after: %s" % prev)
        print("      this : %s" % cur)
        print("      -> did you mean `%s = ...`?" % cur)
        print()
    print("  %d finding(s)." % len(found))
    return len(found)


if __name__ == "__main__":
    raise SystemExit(main())
