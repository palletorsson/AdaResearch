#!/usr/bin/env python3
"""Drop write-only fields from ada_run/em_plan.json.

2026-08-28, Palle: "remove the 43% that has no reader."

THE 43% WAS WRONG, and this tool exists partly to say so with a number. That
figure came from six adversarial audits agreeing, and it did not survive one
`grep -rl` across commons/**/*.gd, tools/*.py and the encyclopedia's src/:

    pending_synthesis    1,448 rows, 127 halls, 247,464 B  3.50%   no reader
    dna_spatial_demand      84 rows,  59 halls,  29,005 B  0.41%   no reader
    ------------------------------------------------------------
    genuinely dead                              276,469 B  3.91%

    museums (top level)     17 entries,        375,638 B  5.31%   READ - it is
        the v1 first-wins fallback, consulted at endless_museum.gd:4034 and
        :7563 when the chapter-keyed lookup misses, and :10101 tests it for
        emptiness. Removing it changes behaviour for any hall that falls
        through, silently.
    wall_runs unhoused   2,343 rows,           910,997 B 12.89%   READ - the
        runtime counts them into planned_refused (endless_museum.gd:9705), and
        their 298 `why` strings are the record of what the negotiator declined.
        A candidate, but a decision about the refusal record, not dead weight.
    relational_kind                                              READ by the
        encyclopedia: /api/museum-plan-view serves it and the page shows it on
        hover.
    slot / fill / dark_sphere                                    ALIVE: 12, 11
        and 27 GDScript files respectively.

So: 3.91% removed here, not 43%. The counts of both dropped arrays stay in each
row's `relational` block, so the demand is still reported and putting the rows
back is a one-line revert in tools/export_museum_plan.py rather than archaeology.

    python tools/plan_prune.py            # report only
    python tools/plan_prune.py --apply    # write, after a .bak
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAN = os.path.join(ROOT, "ada_run", "em_plan.json")

#: Write-only per-row arrays. Anything added here must first come back empty from
#: a repo-wide grep for its name in .gd, .py, .ts and .tsx — the producer itself
#: excepted. The plan is READ BY THE ENGINE; a wrong entry here is a silent
#: behaviour change, not a tidy-up.
DEAD = ("pending_synthesis", "dna_spatial_demand")


def measure(doc: dict) -> list[tuple[str, int, int, int]]:
    out = []
    for key in DEAD:
        rows = halls = size = 0
        for row in doc.get("plans", []):
            v = row.get(key)
            if v:
                halls += 1
                rows += len(v) if isinstance(v, list) else 1
                size += len(json.dumps(v, separators=(",", ":")).encode("utf-8"))
        out.append((key, rows, halls, size))
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description="drop write-only fields from em_plan.json")
    ap.add_argument("--apply", action="store_true", help="write the pruned plan (a .bak is kept)")
    a = ap.parse_args()

    with open(PLAN, encoding="utf-8") as fh:
        raw = fh.read()
    doc = json.loads(raw)
    total = len(raw.encode("utf-8"))

    rows = measure(doc)
    print("em_plan.json  %d bytes  %d halls" % (total, len(doc.get("plans", []))))
    dead_bytes = 0
    for key, n, halls, size in rows:
        dead_bytes += size
        print("  %-20s %5d rows in %3d halls  %8d B  %5.2f%%"
              % (key, n, halls, size, 100.0 * size / total))
    print("  %-20s %31s %8d B  %5.2f%%" % ("TOTAL", "", dead_bytes, 100.0 * dead_bytes / total))

    if not a.apply:
        print("\n(report only — pass --apply to write)")
        return 0
    if dead_bytes == 0:
        print("\nnothing to prune")
        return 0

    kept_counts = 0
    for row in doc.get("plans", []):
        for key in DEAD:
            if key in row:
                # the COUNT survives in `relational`, which the producer already
                # writes — checked here rather than assumed, because "the summary
                # is still there" is exactly the sort of claim that quietly stops
                # being true.
                rel = row.get("relational") or {}
                if key == "pending_synthesis":
                    kept_counts += 1 if "measured_synthesis_pending" in rel else 0
                else:
                    kept_counts += 1 if "dna_spatial_demand" in rel else 0
                del row[key]

    out = json.dumps(doc, indent=2) + "\n"     # the dialect export_museum_plan.py writes
    json.loads(out)
    shutil.copyfile(PLAN, PLAN + ".bak")
    tmp = PLAN + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="") as fh:
        fh.write(out)
    os.replace(tmp, PLAN)
    after = len(out.encode("utf-8"))
    print("\nwrote %s" % os.path.relpath(PLAN, ROOT))
    print("  %d -> %d bytes (-%d, -%.2f%%)" % (total, after, total - after,
                                               100.0 * (total - after) / total))
    print("  %d rows still report their count in `relational`" % kept_counts)
    print("  backup: %s" % os.path.relpath(PLAN + ".bak", ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
