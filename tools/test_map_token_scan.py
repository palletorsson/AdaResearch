"""Negative test for check_map_tokens.scan_map -- synthetic maps, no corpus.

WHY THIS EXISTS
---------------
check_map_tokens.py was written on 2026-08-23 because a rounded percentage
is a verdict whose sensitivity is set by its denominator: one dead token in
primitives (1 of 144) dropped that sequence three pipeline stages, and the
identical fault in forces (1 of 319) rounded to 100% and read OK for 68 days.

The gate then repeated the shape at its own granularity. `scan_map` returned
(0, [], 0) for a map with no map_data.json, and `main` counted that map in
its "N maps" headline -- so a map that vanished under a sequence would have
printed exactly like a map that was read and found clean. The whole-corpus
guard does not help: it only fires when EVERY map is empty, and both faults
this gate was built from were single instances.

Measured on 2026-08-24: 0 of the spine's 268 named maps are missing their
map_data.json, so the hazard was latent, not live. That is the right moment
to close it, and it is why the headline numbers must not move (the sweep
before and after this change both read 268 maps / 1517 placements / 0
unresolved). Half of these cases therefore assert that the instrument stays
QUIET -- a recorder that fires on the healthy corpus is the same failure as
one that never fires, one register up.

    python tools/test_map_token_scan.py

Prints MAP TOKEN SCAN: PASS|FAIL and exits non-zero on failure, so it gates.
"""

import json
import shutil
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import check_map_tokens as C  # noqa: E402

REG = {
    "live_artifact": "res://commons/artifacts/live/live.tscn",
    "ghost_artifact": "res://commons/artifacts/gone/nope.tscn",
}

failures = []


def check(label, got, want):
    if got != want:
        failures.append("%s: got %r, want %r" % (label, got, want))
    return got == want


def write_map(root, name, interactables=None, raw=None):
    d = root / name
    d.mkdir(parents=True, exist_ok=True)
    if raw is not None:
        (d / "map_data.json").write_text(raw, encoding="utf-8")
        return
    if interactables is None:
        return  # a named map with a directory but no map_data.json
    (d / "map_data.json").write_text(
        json.dumps({"layers": {"interactables": interactables}}),
        encoding="utf-8",
    )


def main():
    tmp = Path(tempfile.mkdtemp(prefix="mts_"))
    real_maps, real_root = C.MAPS_DIR, C.ROOT
    try:
        C.MAPS_DIR = tmp
        # scan_map resolves registry scenes against ROOT; point it at a tree
        # where live.tscn exists and nope.tscn does not.
        C.ROOT = tmp
        (tmp / "commons" / "artifacts" / "live").mkdir(parents=True)
        (tmp / "commons" / "artifacts" / "live" / "live.tscn").write_text("", "utf-8")

        write_map(tmp, "Clean", [[" ", "live_artifact"], [" ", " "]])
        write_map(tmp, "Dead", [["ghost_artifact", " "]])
        write_map(tmp, "NoRegistry", [["never_registered:90", " "]])
        write_map(tmp, "EmptyLayer", [[" ", " "], [" ", " "]])
        write_map(tmp, "Absent")  # directory, no map_data.json
        write_map(tmp, "Unparseable", raw="{not json")
        write_map(tmp, "Dialects", [[", ", "0"], ["live_artifact", " "]])

        def scan(name):
            return C.scan_map(name, REG)

        # --- THE INSTRUMENT MUST BITE ---------------------------------
        p, bad, mal, scanned = scan("Dead")
        check("Dead scanned", scanned, True)
        check("Dead placements", p, 1)
        check("Dead unresolved", len(bad), 1)
        check("Dead reason", bad[0]["reason"].startswith(
            "registry scene missing on disk"), True)

        p, bad, mal, scanned = scan("NoRegistry")
        check("NoRegistry unresolved", len(bad), 1)
        check("NoRegistry reason", bad[0]["reason"], "no registry entry")
        check("NoRegistry token strips rotation", bad[0]["token"],
              "never_registered")

        p, bad, mal, scanned = scan("Unparseable")
        check("Unparseable is scanned", scanned, True)
        check("Unparseable is a finding", len(bad), 1)
        check("Unparseable token", bad[0]["token"], "<unparseable>")

        # THE FAULT THIS TEST WAS WRITTEN FOR: a named map with no data is
        # not a scanned map. Before the fix these four assertions and the
        # Clean case were byte-identical in every printed form.
        p, bad, mal, scanned = scan("Absent")
        check("Absent NOT scanned", scanned, False)
        check("Absent placements", p, 0)
        check("Absent raises no finding", len(bad), 0)

        # --- THE INSTRUMENT MUST STAY QUIET ---------------------------
        p, bad, mal, scanned = scan("Clean")
        check("Clean scanned", scanned, True)
        check("Clean placements", p, 1)
        check("Clean silent", len(bad), 0)

        p, bad, mal, scanned = scan("EmptyLayer")
        check("EmptyLayer IS scanned", scanned, True)  # read, and found empty
        check("EmptyLayer placements", p, 0)
        check("EmptyLayer silent", len(bad), 0)

        # The three empty-cell dialects stay a hygiene count, not 2587
        # dead artifacts burying the two real ones.
        p, bad, mal, scanned = scan("Dialects")
        check("Dialects placements", p, 1)
        check("Dialects malformed", mal, 2)
        check("Dialects silent", len(bad), 0)

        # A prefix form is a second addressing scheme, not a lookup name.
        write_map(tmp, "Prefixed", [["mc:anything", "gridagent:x"]])
        p, bad, mal, scanned = scan("Prefixed")
        check("Prefix forms counted as placements", p, 2)
        check("Prefix forms silent", len(bad), 0)

        # cluster: is the one prefix that names a file, so it is the one
        # that can be wrong.
        write_map(tmp, "Cluster", [["cluster:nk_missing:0"]])
        C.CLUSTERS_DIR = tmp / "clusters"
        C.CLUSTERS_DIR.mkdir()
        p, bad, mal, scanned = scan("Cluster")
        check("Missing cluster is a finding", len(bad), 1)
        (C.CLUSTERS_DIR / "nk_missing.json").write_text("{}", "utf-8")
        p, bad, mal, scanned = scan("Cluster")
        check("Present cluster is silent", len(bad), 0)
    finally:
        C.MAPS_DIR, C.ROOT = real_maps, real_root
        shutil.rmtree(tmp, ignore_errors=True)

    total = 17
    if failures:
        print("MAP TOKEN SCAN: FAIL %d of %d" % (len(failures), total))
        for f in failures:
            print("  " + f)
        return 1
    print("MAP TOKEN SCAN: PASS %d of %d - a named map with no map_data.json "
          "is counted as unread, not folded into the clean count; dead "
          "tokens, missing scenes, unparseable maps and missing clusters "
          "still bite; empty layers, empty-cell dialects and prefix forms "
          "stay silent" % (total, total))
    return 0


if __name__ == "__main__":
    sys.exit(main())
