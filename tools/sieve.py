#!/usr/bin/env python3
"""
sieve.py — the three-question cognitive-water sieve.

Apply to any design decision, artifact, sequence, substrate, or commit.

The sieve is the operational form of the Self-Q recursion on QFEP.
It is qualitative. It is a thinking ritual, not an evaluator. The tool's
job is to surface the questions with the target in frame, and (optionally)
record the answers as durable notes under doc/sieve_passes/.

Three questions:

  1. Does this thicken the cognitive water?
       relational handles, ways of moving through, things made thinkable

  2. What is foreclosed?
       thinking made harder, habits suppressed, grammar installed at cost

  3. What lives in the dark spot?
       what the encoding hides — generative habitat or sterilising seal?

Usage:
    python tools/sieve.py <target>                # print framed questions
    python tools/sieve.py <target> --record       # record a pass (interactive)
    python tools/sieve.py --list                  # list recorded passes
    python tools/sieve.py --show <query>          # print a recorded pass

Background:
    doc/ENTRY.md                                  § The Self-Q
    /blog/2026-05-11-cognitive-water              the frame
    /blog/2026-05-11-self-colonial-recognition    the generalised pattern
"""

from __future__ import annotations

import argparse
import datetime as dt
import re
import sys
from pathlib import Path
from typing import List

# Make UTF-8 the print encoding even on Windows cp1252 consoles so the
# framed questions render with em-dashes intact. Silently falls back on
# older Pythons.
try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except (AttributeError, Exception):
    pass

REPO_ROOT = Path(__file__).resolve().parent.parent
PASSES_DIR = REPO_ROOT / "doc" / "sieve_passes"

QUESTIONS = [
    {
        "n": 1,
        "short": "Does this thicken the cognitive water?",
        "prompts": [
            "What relational handles does it add?",
            "What ways of moving through become possible?",
            "What new things does it make thinkable?",
        ],
    },
    {
        "n": 2,
        "short": "What is foreclosed?",
        "prompts": [
            "What thinking becomes harder under this structure?",
            "What habit does it suppress?",
            "What cognitive grammar does it install — and at what cost?",
        ],
    },
    {
        "n": 3,
        "short": "What lives in the dark spot?",
        "prompts": [
            "What does this encoding hide?",
            "Is the hiding generative (room for experience to exceed) or sterilising (sealed)?",
            "Is the surrounding encoding rigorous enough that the dark spot is habitat, not mystification?",
        ],
    },
]


def slug(text: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9._-]+", "-", text).strip("-").lower()
    return s or "target"


def print_framed(target: str) -> None:
    print(f"# Sieve pass — {target}")
    print()
    for q in QUESTIONS:
        print(f"## {q['n']}. {q['short']}")
        for p in q["prompts"]:
            print(f"   - {p}")
        print()
    print("---")
    print()
    print(f"To record interactively: python tools/sieve.py {target!r} --record")
    print("Background: doc/ENTRY.md § The Self-Q  ·  /blog/2026-05-11-cognitive-water")


def _read_block(prompt: str) -> str:
    """Read one or more lines from stdin until two consecutive blanks."""
    print(prompt, end="", flush=True)
    lines: List[str] = []
    while True:
        try:
            line = input()
        except EOFError:
            break
        if line == "" and lines and lines[-1] == "":
            break
        lines.append(line)
    while lines and lines[-1] == "":
        lines.pop()
    return "\n".join(lines)


def record_pass(target: str) -> Path:
    PASSES_DIR.mkdir(parents=True, exist_ok=True)
    print(f"Recording sieve pass for: {target}")
    print("(Each answer: type freely; press Enter on a blank line twice to finish. Ctrl-C to abort.)")
    print()
    answers: List[str] = []
    for q in QUESTIONS:
        print(f"  {q['n']}. {q['short']}")
        for p in q["prompts"]:
            print(f"     - {p}")
        answer = _read_block("     > ")
        answers.append(answer)
        print()

    now = dt.datetime.now()
    stamp = now.strftime("%Y-%m-%dT%H-%M-%S")
    path = PASSES_DIR / f"{stamp}_{slug(target)}.md"
    lines: List[str] = []
    lines.append(f"# Sieve pass — {target}")
    lines.append("")
    lines.append(f"_Recorded {now.isoformat(timespec='seconds')}_")
    lines.append("")
    for q, a in zip(QUESTIONS, answers):
        lines.append(f"## {q['n']}. {q['short']}")
        lines.append("")
        for p in q["prompts"]:
            lines.append(f"> {p}")
        lines.append("")
        lines.append(a.strip() if a.strip() else "_(no answer)_")
        lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Recorded: {path.relative_to(REPO_ROOT)}")
    return path


def list_passes() -> None:
    if not PASSES_DIR.exists():
        print("No sieve passes recorded yet.")
        print(f"  (Will be saved under {PASSES_DIR.relative_to(REPO_ROOT)} on first --record.)")
        return
    paths = sorted(PASSES_DIR.glob("*.md"), reverse=True)
    if not paths:
        print("No sieve passes recorded yet.")
        return
    print(f"{len(paths)} sieve passes (newest first):")
    for p in paths:
        print(f"  {p.name}")


def show_pass(query: str) -> int:
    if not PASSES_DIR.exists():
        print("No sieve passes recorded yet.", file=sys.stderr)
        return 1
    matches = sorted(
        [p for p in PASSES_DIR.glob("*.md") if query in p.name],
        reverse=True,
    )
    if not matches:
        print(f"No sieve pass matching {query!r}.", file=sys.stderr)
        return 1
    print(matches[0].read_text(encoding="utf-8"))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="The three-question cognitive-water sieve. See doc/ENTRY.md § The Self-Q.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  python tools/sieve.py orb-gesture-detector\n"
            "  python tools/sieve.py 'capacity_ladder rename' --record\n"
            "  python tools/sieve.py --list\n"
            "  python tools/sieve.py --show orb\n"
        ),
    )
    parser.add_argument("target", nargs="?", help="What to apply the sieve to (free-form name).")
    parser.add_argument("--record", action="store_true", help="Record a pass interactively.")
    parser.add_argument("--list", action="store_true", help="List recorded passes.")
    parser.add_argument("--show", metavar="QUERY", help="Print a recorded pass whose filename contains QUERY (newest match).")
    args = parser.parse_args()

    if args.list:
        list_passes()
        return 0
    if args.show:
        return show_pass(args.show)
    if not args.target:
        parser.print_help()
        return 1
    if args.record:
        record_pass(args.target)
    else:
        print_framed(args.target)
    return 0


if __name__ == "__main__":
    sys.exit(main())
