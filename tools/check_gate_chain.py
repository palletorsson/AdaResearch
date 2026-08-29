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

THE REMEDY POSITION (added 2026-08-29)
-------------------------------------
On 2026-08-28 the fault reproduced one position outside this gate's reach,
and the gate stayed green through it. `referenced()` collected only what a
runner INVOKES. But `check_map_tokens.py` NAMES `tools/normalize_map_fillers.py`
twice -- once in a comment and once in its own failure output -- as the
remedy an operator should run when gate G fails. That file was 11,742 bytes
old and had never been `git add`ed. So a clone of HEAD could fail gate G and
be told to run a file it does not have: the gate chain broken by this gate's
own definition, in the one position it was not looking.

So there are now two levels, reported separately because they fail
differently. Level 1 is INVOKED -- a runner shells out to it, and its absence
makes a gate silently not run. Level 2 is NAMED -- a gate tool prints it as a
remedy, and its absence makes a failing gate's advice unfollowable. Both are
held to the same bar: on disk, and in the repository.

Level 2 cannot tell a remedy string from a comment -- this very docstring puts
check_gate_chain.py among normalize_map_fillers.py's namers. That is left
imprecise on purpose. The bar a level-2 hit must clear is only 'exists and is
tracked', which any legitimately mentioned tool clears; the only thing a loose
regex can over-report is a tool that a gate mentions and the repository does
not have, which is the finding either way.

WHAT THIS DOES NOT CHECK
------------------------
Whether a tracked file is COMMITTED in its current state. A tool can be
tracked and dirty, which is normal mid-session and not a fault -- the fault
is a runner reaching code the repository has never seen. That rule is good
for an hour and poor for a week: on 2026-08-29 four gate tools had been
tracked-and-dirty for one to three days, hardened in one working tree only,
while this gate printed 0 unreachable. It is still not checked here, because
a dirty tool IS in the repository and a clone gets a working older version of
it; the ledger is the right place for that, and the 2026-08-29 breath moved
it there. Nor does this follow imports: check_map_tokens.py imports
sequence_pipeline_scorer, and a gate-chain check that recursed would have to
decide how deep the chain runs. Invoked-by-a-runner and named-by-a-gate-tool
are the two levels at which every recorded occurrence happened.

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


def named_by(invoked):
    """tool path -> sorted list of the gate tools that NAME it.

    A gate tool names a python tool it does not invoke when it prints a
    remedy: 'run tools/normalize_map_fillers.py --apply'. Only paths that
    are not already invoked by a runner are returned -- the two levels are
    disjoint so nothing is counted twice.
    """
    found = {}
    for rel in invoked:
        src = ROOT / rel  # a .gd gate names a python tool the same way
        if not src.exists():
            continue
        text = src.read_text(encoding="utf-8", errors="replace")
        for ref in set(PY_REF.findall(text)):
            if ref == rel or ref in invoked or ref in RUNNERS:
                continue
            found.setdefault(ref, []).append(rel)
    return {k: sorted(v) for k, v in sorted(found.items())}


def classify(rels, tracked):
    """-> (absent on disk, present but untracked)"""
    absent, untracked = [], []
    for rel in rels:
        if not (ROOT / rel).exists():
            absent.append(rel)
        elif rel not in tracked:
            untracked.append(rel)
    return absent, untracked


def main():
    as_json = "--json" in sys.argv
    tracked = tracked_files()
    refs = referenced()

    missing_runners = [r for r, v in refs.items() if v is None]
    all_refs = sorted({t for v in refs.values() if v for t in v})

    absent, untracked = classify(all_refs, tracked)

    named = named_by(all_refs)
    named_absent, named_untracked = classify(sorted(named), tracked)

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

    bad_invoked = len(absent) + len(untracked)
    bad_named = len(named_absent) + len(named_untracked)
    bad = bad_invoked + bad_named

    if as_json:
        # tools_referenced and unreachable_from_a_clone keep their meaning
        # for run_release_gates.py: the first is the invoked count it has
        # always read, the second is now the total across both levels.
        print(json.dumps({
            "runners": list(RUNNERS),
            "tools_referenced": len(all_refs),
            "absent_on_disk": absent,
            "present_but_untracked": untracked,
            "tools_named_as_remedies": len(named),
            "named_absent_on_disk": named_absent,
            "named_present_but_untracked": named_untracked,
            "named_by": {k: v for k, v in named.items()
                         if k in named_absent or k in named_untracked},
            "unreachable_from_a_clone": bad,
        }, indent=2))
        return bad

    print("=== GATE CHAIN INTEGRITY ===")
    print("%d tools invoked by %d gate runner(s), %d further named as "
          "remedies, %d unreachable from a clone"
          % (len(all_refs), len(RUNNERS), len(named), bad))
    if not bad:
        print("\nOK: every tool the gate runners invoke, and every tool the "
              "gates name as a remedy, is on disk and in the repository.")
        return 0
    print()
    for rel in absent:
        print("  %-52s invoked, NOT ON DISK" % rel)
    for rel in untracked:
        print("  %-52s invoked, NOT IN THE REPOSITORY" % rel)
    for rel in named_absent:
        print("  %-52s remedy, NOT ON DISK        (named by %s)"
              % (rel, ", ".join(named[rel])))
    for rel in named_untracked:
        print("  %-52s remedy, NOT IN THE REPOSITORY (named by %s)"
              % (rel, ", ".join(named[rel])))
    print("\nFAIL: %d tool(s) a clone of HEAD would not have -- %d that a "
          "gate invokes (it would silently not run) and %d that a gate names "
          "as the remedy for its own failure (the advice would be "
          "unfollowable)." % (bad, bad_invoked, bad_named))
    return bad


if __name__ == "__main__":
    sys.exit(min(main(), 250))
