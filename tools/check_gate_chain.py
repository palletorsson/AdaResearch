"""Every tool the gate runners invoke is present on disk AND in the repository.

WHY THIS EXISTS
---------------
On 2026-08-24 the breath log recorded the EIGHTH occurrence of the same
fault, and the first time anyone looked at its shape rather than its
instance: `tools/check_map_tokens.py` had been printing gate G PASS in
every release-gate run for a day while being untracked, and its 48-line
registration in run_release_gates.py was uncommitted. `run_em_gates.py`
named `res://commons/testing/test_em_seal_clamp.gd` as gate seal_clamp,
and that file was in no commit either.

The failure mode is silent in the only direction that matters. Locally the
gate runs and prints a row; a clone of HEAD simply has fewer gates, no row
missing, nothing to notice. The verdict table that certifies the museum was
partly produced by code the repository did not contain. Six separate breaths
found instances of this by hand, one at a time, which is the signature of a
class nothing is watching.

So: parse both runners for the tools they name, and require each to exist
and to be tracked. It is the cheapest possible check and it would have
caught the eighth occurrence on the day it started.

WHAT THIS DOES NOT CHECK
------------------------
Whether a tracked file is COMMITTED in its current state. A tool can be
tracked and dirty, which is normal mid-session and not a fault -- the fault
is a runner reaching code the repository has never seen. Nor does it follow
imports: check_map_tokens.py imports sequence_pipeline_scorer, and a
gate-chain check that recursed would have to decide how deep the chain runs.
One level, named explicitly by a runner, is the level at which the eight
occurrences happened.

    python tools/check_gate_chain.py            # human
    python tools/check_gate_chain.py --json     # machine-readable

Exit code is the number of unreachable tools, so it gates.
"""

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

RUNNERS = [
    "tools/run_release_gates.py",
    "tools/run_em_gates.py",
]

# A runner names its tools two ways: as a repo-relative python path in an
# argv list, and as a res:// path handed to Godot.
PY_REF = re.compile(r"(?:tools|scripts)/[A-Za-z0-9_]+\.py")
GD_REF = re.compile(r"res://(commons/[A-Za-z0-9_/]+\.gd)")


def tracked_files():
    out = subprocess.run(
        ["git", "ls-files"], cwd=ROOT, capture_output=True, text=True
    )
    return {line.strip().replace("\\", "/") for line in out.stdout.splitlines()
            if line.strip()}


def referenced():
    """runner path -> sorted list of tool paths it names."""
    found = {}
    for runner in RUNNERS:
        src = ROOT / runner
        if not src.exists():
            found[runner] = None  # the runner itself is gone
            continue
        text = src.read_text(encoding="utf-8", errors="replace")
        refs = set(PY_REF.findall(text)) | set(GD_REF.findall(text))
        refs.discard(runner)  # a runner naming itself is not a dependency
        found[runner] = sorted(refs)
    return found


def main():
    as_json = "--json" in sys.argv
    tracked = tracked_files()
    refs = referenced()

    missing_runners = [r for r, v in refs.items() if v is None]
    all_refs = sorted({t for v in refs.values() if v for t in v})

    absent, untracked = [], []
    for rel in all_refs:
        if not (ROOT / rel).exists():
            absent.append(rel)
        elif rel not in tracked:
            untracked.append(rel)

    # A check that resolved nothing must not report OK -- the same guard
    # gate G needed after its own first run printed a clean bill over an
    # empty denominator.
    if not all_refs or missing_runners:
        print("BROKEN: %d runner(s) unreadable, %d tools referenced -- "
              "refusing a verdict on an empty scan.%s"
              % (len(missing_runners), len(all_refs),
                 (" missing: " + ", ".join(missing_runners))
                 if missing_runners else ""))
        return 250

    bad = len(absent) + len(untracked)
    if as_json:
        print(json.dumps({
            "runners": list(RUNNERS),
            "tools_referenced": len(all_refs),
            "absent_on_disk": absent,
            "present_but_untracked": untracked,
            "unreachable_from_a_clone": bad,
        }, indent=2))
        return bad

    print("=== GATE CHAIN INTEGRITY ===")
    print("%d tools named by %d gate runner(s), %d unreachable from a clone"
          % (len(all_refs), len(RUNNERS), bad))
    if not bad:
        print("\nOK: every tool the gate runners invoke is on disk and in "
              "the repository.")
        return 0
    print()
    for rel in absent:
        print("  %-52s referenced, NOT ON DISK" % rel)
    for rel in untracked:
        print("  %-52s on disk, NOT IN THE REPOSITORY" % rel)
    print("\nFAIL: %d tool(s) a clone of HEAD would not have. The gate that "
          "names them would silently not run." % bad)
    return bad


if __name__ == "__main__":
    sys.exit(min(main(), 250))
