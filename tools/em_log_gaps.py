#!/usr/bin/env python3
"""THE SILENCES IN A DEVICE LOG (2026-08-26).

The largest term in the museum's Quest boot is a stretch with no log lines at
all - 13795 ms in ada_run/quest_boot_trap.log - and it was found by reading
timestamps by hand. What brackets a silence is usually the whole diagnosis:
that one ends with the hand rig speaking again, which no summary mentioned.

    python tools/em_log_gaps.py ada_run/quest_boot_1204.log [--min=1.5]
"""
import re, sys

TS = re.compile(r"^(\d\d)-(\d\d)\s+(\d\d):(\d\d):(\d\d)\.(\d\d\d)")


def secs(m):
    return (int(m.group(3)) * 3600 + int(m.group(4)) * 60
            + int(m.group(5)) + int(m.group(6)) / 1000.0)


def main(path, min_gap=1.5):
    lines = open(path, encoding="utf-8", errors="replace").read().split("\n")
    stamped = [(secs(m), i, l) for i, l in enumerate(lines) if (m := TS.match(l))]
    if not stamped:
        print("no timestamped lines in %s" % path)
        return 1
    print("%s  %d timestamped line(s), %.1f s span" % (
        path, len(stamped), stamped[-1][0] - stamped[0][0]))
    gaps = []
    for (t0, i0, l0), (t1, i1, l1) in zip(stamped, stamped[1:]):
        if t1 - t0 >= min_gap:
            gaps.append((t1 - t0, l0, l1))
    gaps.sort(key=lambda g: -g[0])
    if not gaps:
        print("  no silence longer than %.1f s" % min_gap)
        return 0
    print("  %d silence(s) over %.1f s, longest first:\n" % (len(gaps), min_gap))
    for d, before, after in gaps[:8]:
        print("  %6.2f s of silence" % d)
        print("    last  %s" % before.strip()[:150])
        print("    next  %s" % after.strip()[:150])
        print()
    return 0


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    mg = [a for a in sys.argv[1:] if a.startswith("--min=")]
    sys.exit(main(args[0] if args else "ada_run/quest_boot_trap.log",
                  float(mg[0][6:]) if mg else 1.5))
