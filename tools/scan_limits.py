"""scan_limits.py — what limits does the corpus actually encode?

2026-08-27, Palle: "research other limits, and all limits in the project and elsewhere
that makes up the edge and its negotiations of the queer."

WHY THIS IS A TOOL AND NOT A PARAGRAPH. doc/THE_LIMITS.md quotes numbers - 2,155 clamp
sites, 98.1% of them silent, 45.4% of scripts carrying a budget parameter. A number
written into a document is a fact about the tree on the day it was written, and this
corpus grows by dozens of artifacts a week. So the document cites this script, and the
script re-derives the numbers on demand. If a claim in THE_LIMITS.md disagrees with this
output, THIS is right and the document is stale.

THE HEADLINE IS THE SILENCE. A clamp() is the most common way an artifact here meets a
boundary, and clamp() by construction says nothing when it fires: the value is moved and
the caller is told exactly what it would have been told had nothing happened. The
--clamps report counts how many call sites have ANY report near them (print, warning,
signal, a variable admitting it clamped). It came back 1.9%. That is Ahmed's wall - what
you come up against, invisible to everyone who does not - occurring two thousand times
in a codebase where nobody decided it should.

  python tools/scan_limits.py              families, counts, % of corpus
  python tools/scan_limits.py --clamps     the silence measurement alone
  python tools/scan_limits.py --json       machine-readable, for a gate or a page
  python tools/scan_limits.py --path=commons/grid   scan somewhere else
"""
from __future__ import annotations
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_PATH = os.path.join("commons", "artifacts")

# Deliberately narrow patterns. A family that matches everything measures nothing, and
# the point of these rows is that the differences between them mean something.
FAMILIES = [
    ("clamp()", r"\bclamp[fi]?\s*\("),
    ("tick / discrete time", r"\b(physics_ticks_per_second|fixed_fps|max_fps|_physics_process|delta)\b"),
    ("budget: segments/resolution/samples", r"\b(radial_segments|rings|resolution|subdivisions?|subdiv|grid_size|sample\w*|steps|precision)\b"),
    ("seed (chance authored)", r"\b(seed|rng\.seed|set_seed)\b"),
    ("cull / visibility refusal", r"\b(cull_mode|CULL_|visible\s*=\s*false|layers\s*=\s*0|frustum|occlu)"),
    ("far plane / draw distance", r"\b(far\b|draw_distance|visibility_range|lod_bias|far_plane)"),
    ("max_* variable or export", r"\b(var|@export[^\n]*var)\s+max_\w+"),
    ("hard cap (MAX_ const)", r"\bconst\s+[A-Z_]*MAX[A-Z_]*\s*(:|=)"),
    ("threshold / iso level", r"\b(threshold|iso_level|isolevel|cutoff|surface_level)\b"),
    ("epsilon / is_zero_approx", r"\b(EPSILON|epsilon|is_zero_approx|is_equal_approx)\b"),
    ("recursion depth cap", r"\b(max_depth|depth_limit|MAX_DEPTH|max_iterations|MAX_ITER\w*|max_generations)\b"),
    ("timeout / time budget", r"\b(timeout|time_budget|max_time|deadline|watchdog)\b"),
]

RX_CLAMP = re.compile(r"\bclamp[fi]?\s*\(")
# a clamp "reports" if anything within two lines could reach a human or another system
RX_TELL = re.compile(r"(print|push_warning|push_error|emit_signal|_report|clamped|was_clamped|_notice)")


def gd_files(base: str):
    for dirpath, dirnames, filenames in os.walk(base):
        dirnames[:] = [d for d in dirnames if d not in (".git", "__pycache__", ".godot")]
        for fn in filenames:
            if fn.endswith(".gd"):
                yield os.path.join(dirpath, fn)


def scan(base: str) -> dict:
    compiled = [(label, re.compile(rx)) for label, rx in FAMILIES]
    hits = {label: 0 for label, _ in FAMILIES}
    files = {label: 0 for label, _ in FAMILIES}
    nfiles = 0
    clamp_total = 0
    clamp_telling = 0

    for path in gd_files(base):
        try:
            src = open(path, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        nfiles += 1
        for label, rx in compiled:
            n = len(rx.findall(src))
            if n:
                hits[label] += n
                files[label] += 1
        if "clamp" in src:
            lines = src.splitlines()
            for i, line in enumerate(lines):
                if not RX_CLAMP.search(line):
                    continue
                clamp_total += 1
                if RX_TELL.search("\n".join(lines[max(0, i - 2):i + 3])):
                    clamp_telling += 1

    return {
        "path": base,
        "files_scanned": nfiles,
        "families": [
            {"family": label, "hits": hits[label], "files": files[label],
             "pct_files": round(100.0 * files[label] / max(nfiles, 1), 1)}
            for label, _ in FAMILIES
        ],
        "clamps": {
            "call_sites": clamp_total,
            "reporting": clamp_telling,
            "silent": clamp_total - clamp_telling,
            "pct_silent": round(100.0 * (clamp_total - clamp_telling) / max(clamp_total, 1), 1),
        },
    }


def main() -> int:
    flags = {a.split("=", 1)[0]: (a.split("=", 1)[1] if "=" in a else True)
             for a in sys.argv[1:] if a.startswith("--")}
    base = os.path.join(ROOT, str(flags.get("--path", DEFAULT_PATH)))
    if not os.path.isdir(base):
        print("no such path:", base)
        return 2

    out = scan(base)

    if flags.get("--json"):
        print(json.dumps(out, indent=2))
        return 0

    c = out["clamps"]
    if flags.get("--clamps"):
        print("clamp() call sites          : %d" % c["call_sites"])
        print("...with any nearby report   : %d  (%.1f%%)" % (
            c["reporting"], 100.0 - c["pct_silent"]))
        print("...silent                   : %d  (%.1f%%)" % (c["silent"], c["pct_silent"]))
        return 0

    print("scanned %d .gd files under %s\n" % (
        out["files_scanned"], os.path.relpath(base, ROOT).replace("\\", "/")))
    print("%-38s %8s %8s  %s" % ("limit family", "hits", "files", "% of corpus"))
    print("-" * 74)
    for row in out["families"]:
        print("%-38s %8d %8d  %5.1f%%" % (
            row["family"], row["hits"], row["files"], row["pct_files"]))
    print()
    print("THE SILENCE: %d of %d clamp() sites report nothing (%.1f%%)." % (
        c["silent"], c["call_sites"], c["pct_silent"]))
    print("A clamp that reports is a limit you can argue with. There are %d of those." % c["reporting"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
