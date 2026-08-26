#!/usr/bin/env python3
"""THE BOOT CLOCK, READ AS A TIMELINE (2026-08-26).

Every field of em_boot_last.json is milliseconds since the museum's _ready,
except engine_to_ready which is process uptime — so the file has never been
readable as a sequence without doing the arithmetic by hand, and no tool in
this repo read it at all. Two agents in a row optimised the wrong number.

    python tools/em_boot_read.py ada_run/quest_em_boot_last.json
"""
import json, sys

ORDER = [
    ("engine_pak",        "engine + pak mount"),
    ("autoloads",         "the autoload parade"),
    ("staging_load",      "vr_staging stands up"),
    ("staging_to_museum", "staging -> museum (menu dwell, or the 5 s autolaunch wait)"),
    ("scene_chain",       "autoload end -> museum ready (only when staging did not run)"),
    ("modules_loaded",    "the museum's modules"),
    ("museum_data",       "museum data"),
    ("plan_parsed",       "em_plan.json parsed"),
    ("bake_parsed",       "em_bake.json parsed"),
    ("pool_done",         "the artifact pool"),
    ("guests_loaded",     "guests resolved"),
    ("world_ready",       "world ready"),
    ("segment0_built",    "the first hall built"),
    ("boot_tail",         "the museum's last line"),
    ("content_ready",     "the stamp queue emptied"),
    ("first_physics",     "first physics step"),
    ("first_frame",       "first frame"),
]


def main(path: str) -> int:
    doc = json.load(open(path, encoding="utf-8"))
    b = doc.get("boot_ms", doc)
    entry = b.get("entry")
    mods = b.get("modules_loaded", -1)
    print("%s  vr=%s tier=%s at=%s" % (path, doc.get("vr"), doc.get("tier"), doc.get("at")))
    if entry is not None and int(entry) > 1:
        print("  !! entry %s - this is a RELOAD, not a boot. Its numbers are process uptime." % entry)
    elif entry is None and 0 <= mods <= 20:
        print("  !! modules_loaded=%d — the re-entry signature. Treat as a reload, not a boot." % mods)
    print()
    prev = 0
    for key, what in ORDER:
        if key not in b:
            continue
        v = int(b[key])
        if key in ("engine_pak", "autoloads", "staging_load", "staging_to_museum", "scene_chain"):
            print("  %-18s %7d ms   %s" % (key, v, what))
            continue
        step = v - prev
        bar = "#" * min(60, max(0, step // 100))
        print("  %-18s %7d ms  (+%6d)  %-52s %s" % (key, v, step, what, bar))
        prev = v
    # THE SILENT WINDOW: the museum's last line to the first frame, which
    # contains no museum code at all and is the largest term on the Quest
    tail = b.get("boot_tail")
    ff = b.get("first_frame")
    if tail is not None and ff is not None:
        gap = int(ff) - int(tail)
        phys = b.get("first_physics")
        print()
        print("  THE SILENT WINDOW  %d ms  (boot_tail -> first_frame)" % gap)
        if phys is not None:
            print("    engine flush + physics : %6d ms  (boot_tail -> first_physics)" % (int(phys) - int(tail)))
            print("    deferred + render sync : %6d ms  (first_physics -> first_frame)" % (int(ff) - int(phys)))
        else:
            print("    (no first_physics stamp — this build predates the split)")
        total = int(b.get("engine_to_ready", 0)) + int(ff)
        if total:
            print("    that is %.0f%% of a %d ms boot" % (100.0 * gap / total, total))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "ada_run/em_boot_last.json"))
