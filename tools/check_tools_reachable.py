"""Every tool on this disk is in the repository -- an ABSOLUTE census, not a walk.

WHY THIS EXISTS
---------------
The exists-vs-git class has three surfaces. Gate L asks git about the prose a
room declares. Gate M asks git about the files an artifact reaches. Gate H asks
git about tools -- but it asks by WALKING: it collects what a gate runner
invokes and what a gate tool names as a remedy, and checks those. That works for
a tool with callers and fails for a tool without them.

A REACHABILITY WALK CANNOT SEE AN ORPHAN (measured 2026-09-07, confirmed
2026-09-08). tools/pull_vr_feedback.py was written on 09-07, tested on a real
Quest, recorded as LANDED, and left untracked. Gate H read 53 tools referenced,
0 unreachable from a clone, every day it sat there. Widening the walk would not
have found it either: the only two files that name it are its own uncommitted
hunks, so HEAD greps 0 for the name. When a tool and its callers land or fail to
land as one commit, the naming set is empty exactly when the tool is absent.

The population a tools gate should ask about is therefore the DIRECTORY. On
2026-09-08 that was 671 .py on disk and 11 of them untracked, the oldest twelve
days -- while gate H printed OK. This gate is that census.

    tools/em_cartridge.py  tools/activation_ladder.py  tools/compose_docs.py
    tools/dream_bodies_promote.py  tools/test_place_artifacts_room.py  ...

WHAT IT CONVICTS, AND WHAT IT ONLY COUNTS
-----------------------------------------
Several sessions edit this repo at once, and a file written ten minutes ago is
somebody's open buffer, not a stranded orphan. Convicting those would make this
gate red every day forever, and this project has already recorded what happens
then: a metric with junk in it stops being read (gate M's own first run
convicted 143 vendored addon files). Gate M's answer was to COUNT the
out-of-scope population and convict none of it, and that is the rule here too.

  convicted  untracked, not ignored, and untouched for >= HOLD_HOURS (24)
  counted    untracked but written within HOLD_HOURS -- live work, someone's
             hands are on it. Reported as `live_uncommitted` so the number is
             visible and the next run can tell whether it aged into a fault.
  counted    ignored on purpose (.gitignore). A clone does not get these by
             project decision, which is gate M's vendored case.

The 24-hour hold is the discriminator the 09-07 evening breath used by hand
("the oldest twelve days"), made explicit. It is a clock, and a clock in a gate
is a compromise: a file can be stranded for a week and touched today, and this
gate will call it live. That is the dark spot, and it is why `live_uncommitted`
is always printed rather than silently subtracted -- the full census is on every
line of output, and only the verdict is scoped.

    python tools/check_tools_reachable.py            # human
    python tools/check_tools_reachable.py --json     # machine-readable
    python tools/check_tools_reachable.py --selftest # the gate still bites

Exit code is the number of stranded tools, so it gates.
"""

import json
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# The directory this gate is a census of, and what counts as code in it. A
# .json beside a tool is data and its absence is a different fault; .py and .gd
# are the two things a clone must have to RUN what this directory offers.
SCOPE = "tools"
CODE_SUFFIXES = (".py", ".gd")

# How long a file may sit untracked before it stops being somebody's open
# buffer and becomes a stranded orphan.
HOLD_HOURS = 24.0


def git(args):
    out = subprocess.run(["git"] + args, cwd=ROOT, capture_output=True, text=True)
    return {line.strip().replace("\\", "/") for line in out.stdout.splitlines()
            if line.strip()}


def in_scope(rel):
    return rel.startswith(SCOPE + "/") and rel.endswith(CODE_SUFFIXES)


def census(disk, tracked, ignored, mtimes, now, hold_hours=HOLD_HOURS):
    """-> (stranded, live, ignored_in_scope) each a sorted list of dicts.

    Pure so the selftest can fixture a tree that does not exist. `disk` is every
    in-scope path present, `tracked` and `ignored` come from git, `mtimes` maps
    path -> epoch seconds.
    """
    stranded, live, skipped = [], [], []
    hold = hold_hours * 3600.0
    for rel in sorted(disk):
        if rel in tracked:
            continue
        age = now - mtimes.get(rel, now)
        row = {"path": rel, "age_hours": round(age / 3600.0, 1)}
        if rel in ignored:
            skipped.append(row)
        elif age >= hold:
            stranded.append(row)
        else:
            live.append(row)
    return stranded, live, skipped


def scan():
    disk = {
        p.relative_to(ROOT).as_posix()
        for p in (ROOT / SCOPE).rglob("*")
        if p.is_file() and p.suffix in CODE_SUFFIXES
    }
    tracked = {r for r in git(["ls-files"]) if in_scope(r)}
    ignored = {r for r in git(["ls-files", "--others", "--ignored",
                               "--exclude-standard"]) if in_scope(r)}
    mtimes = {rel: (ROOT / rel).stat().st_mtime for rel in disk}
    return disk, tracked, ignored, mtimes


def selftest():
    """A gate reads zero on a good day, which is indistinguishable from one that
    stopped checking. Each fixture trips one rule deliberately, and three of them
    are cases this class has already produced in the tree.
    """
    now = 1_000_000.0
    hour = 3600.0
    disk = {
        "tools/tracked.py",      # in the repo
        "tools/old_orphan.py",   # untracked, twelve days -- the fault
        "tools/fresh.py",        # untracked, ten minutes -- someone's buffer
        "tools/ignored.py",      # untracked on purpose
        "tools/probes/deep.gd",  # nested, and a .gd
        "tools/edge.py",         # untracked, exactly at the hold
    }
    tracked = {"tools/tracked.py"}
    ignored = {"tools/ignored.py"}
    mtimes = {
        "tools/tracked.py": now - 99 * hour,
        "tools/old_orphan.py": now - 12 * 24 * hour,
        "tools/fresh.py": now - 0.16 * hour,
        "tools/ignored.py": now - 99 * hour,
        "tools/probes/deep.gd": now - 99 * hour,
        "tools/edge.py": now - HOLD_HOURS * hour,
    }
    st, live, skip = census(disk, tracked, ignored, mtimes, now)
    names = lambda rows: sorted(r["path"] for r in rows)
    cases = []

    # 1. The fault this gate exists for: an orphan no runner names. Gate H's
    #    walk reads 0 unreachable over exactly this file.
    cases.append(("catches an orphan nothing references",
                  "tools/old_orphan.py" in names(st)))

    # 2. A tracked file is never a finding, however old.
    cases.append(("never convicts a tracked tool",
                  "tools/tracked.py" not in names(st) + names(live) + names(skip)))

    # 3. Live work is COUNTED, not convicted -- gate M's vendored rule. On
    #    2026-09-08 a concurrent session wrote 105 files during one reading.
    cases.append(("counts a file written minutes ago without convicting it",
                  names(live) == ["tools/fresh.py"]))

    # 4. Ignored on purpose is counted, not convicted. Gate M's first run
    #    convicted 143 addon files this way.
    cases.append(("counts an ignored file without convicting it",
                  names(skip) == ["tools/ignored.py"]))

    # 5. The census is of the DIRECTORY, so it must descend. tools/probes/
    #    held three untracked .gd on the day this was written.
    cases.append(("descends into subdirectories and reads .gd",
                  "tools/probes/deep.gd" in names(st)))

    # 6. The boundary is inclusive: at exactly the hold, it is stranded. A
    #    threshold nobody pinned drifts by one file per run.
    cases.append(("convicts at exactly the hold, not one second later",
                  "tools/edge.py" in names(st)))

    # 7. An empty scan must not read green -- the guard gate G needed after its
    #    own first run printed a clean bill over an empty denominator.
    st2, live2, skip2 = census(set(), set(), set(), {}, now)
    cases.append(("has an empty-population guard (see main)",
                  st2 == [] and live2 == [] and skip2 == []))

    bad = [name for name, ok in cases if not ok]
    for name, ok in cases:
        print("  %-52s %s" % (name, "ok" if ok else "FAIL"))
    print("selftest: %d/%d" % (len(cases) - len(bad), len(cases)))
    return 1 if bad else 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    as_json = "--json" in sys.argv

    disk, tracked, ignored, mtimes = scan()
    stranded, live, skipped = census(disk, tracked, ignored, mtimes, time.time())

    if as_json:
        print(json.dumps({
            "scope": SCOPE,
            "hold_hours": HOLD_HOURS,
            "tools_on_disk": len(disk),
            "tools_tracked": len(tracked),
            "live_uncommitted": len(live),
            "ignored_on_purpose": len(skipped),
            "unreachable_from_a_clone": len(stranded),
            "stranded": stranded,
            "live": live,
        }, indent=2))
        return len(stranded)

    print("=== TOOLS REACHABLE FROM A CLONE ===")
    if not disk:
        # An empty census prints identically to a clean one in every summary
        # form. Refuse the verdict rather than certify nothing.
        print("BROKEN: no %s/*%s found -- refusing a verdict on an empty scan."
              % (SCOPE, "/*".join(CODE_SUFFIXES)))
        return 250
    print("%d files under %s/, %d in the repository, %d stranded, "
          "%d live (< %gh), %d ignored on purpose"
          % (len(disk), SCOPE, len(tracked), len(stranded), len(live),
             HOLD_HOURS, len(skipped)))
    if not stranded:
        print("\nOK: every tool untouched for %gh is in the repository."
              % HOLD_HOURS)
        return 0
    print()
    for row in sorted(stranded, key=lambda r: -r["age_hours"]):
        print("  %-52s NOT IN THE REPOSITORY, %.0fh old"
              % (row["path"], row["age_hours"]))
    print("\nFAIL: %d tool(s) a clone of HEAD would not have. A reachability "
          "walk cannot see these -- nothing in HEAD names them, which is "
          "exactly what makes them orphans." % len(stranded))
    return len(stranded)


if __name__ == "__main__":
    sys.exit(min(main(), 250))
