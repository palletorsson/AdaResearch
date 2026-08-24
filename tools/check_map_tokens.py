"""Resolve every interactable token in every map against the artifact registry.

WHY THIS EXISTS
---------------
A map can name an artifact that resolves to no scene, and until this tool
nothing in the project said so BY NAME.

  * `sequence_pipeline_scorer.py` sees it, but only as a rounded percentage
    whose sensitivity depends on the size of the thing it is judging.
    `floor_anchor` is 1 of primitives' 144 placements -> 99.306% -> prints
    "99%" -> drops the sequence's HEAD from stage 6 to stage 3.
    `calder_mobile_primaries` is 1 of forces' 319 -> 99.687% -> prints
    "100%" -> read OK for 68 days. Same fault, opposite verdicts, and the
    discriminator is the denominator.

  * `map_pathfinder.py` -- the one instrument a map author actually runs
    before committing -- validates reachability and geometry and never
    resolves a token against the registry at all. It reported Point_Lines
    as OK with `floor_anchor` among the "31 artifacts" it counted.

  * The two concurrency instruments (prop-006 scans commits, prop-012 scans
    git status) both ask what CHANGED. Nothing was asking what is TRUE.
    A token either resolves or it does not.

ONE TRUTH, NOT TWO
------------------
The definition of "resolves" is imported from the scorer, not reimplemented.
A second implementation would be a second truth, which is the fault class
this repository keeps paying for. If the scorer's delegate_to handling
changes, this gate changes with it, for free.

USAGE
-----
    python tools/check_map_tokens.py             # spine sequences only
    python tools/check_map_tokens.py --all       # every map on disk
    python tools/check_map_tokens.py --json      # machine-readable
    python tools/check_map_tokens.py --scenes    # also check embedded scene_path

Exit code is the number of unresolved PLACEMENTS, so it gates.
"""

import json
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from sequence_pipeline_scorer import (  # noqa: E402
    MAPS_DIR,
    ROOT,
    load_all_registry_scenes,
    load_sequence_maps,
    load_spine,
)

# The scorer treats these as resolved without consulting the registry
# (dark_sphere / ds is the void-marker utility, not an artifact).
# Kept in sync with sequence_pipeline_scorer.py:165.
ALWAYS_OK = {"dark_sphere", "ds"}

# GridInteractablesComponent.gd dispatches these prefixes BEFORE it ever
# consults the registry (:561-612 -- "Check for special prefixes BEFORE
# parsing"). They are a second addressing form, not artifact lookup names,
# so demanding a registry entry for them would be inventing a second truth
# about what a map cell may say. `cluster:` is the one that can still be
# checked, because ClusterResolver names its source directory.
PREFIX_FORMS = ("mc:", "gridagent:", "criticalinfo:", "cluster:")
CLUSTERS_DIR = ROOT / "commons" / "data" / "curated_walls" / "clusters"


def is_empty_cell(raw):
    """True for a cell that means 'nothing here'.

    The corpus carries three empty-cell conventions, not one: "" / " "
    (the documented form), ", " (every MindMap_* map, 1988 cells) and "0"
    (the Particles_* and Grid_Subset_* maps, 599 cells). The scorer's own
    test -- `if c and c != " "` -- passes the last two through, so they
    are counted as placements and then fail to resolve. Reporting 2587
    punctuation marks as dead artifacts would bury the two real ones, so
    they are separated here and counted as a data-hygiene finding instead.
    """
    return raw == "" or not any(ch.isalpha() for ch in raw)


def map_dirs_for_spine():
    """Map name -> list of spine sequences that declare it."""
    owners = defaultdict(list)
    for entry in load_spine():
        # curriculum_spine.json keys its sequences on `name`. Reading the
        # wrong key here does not raise -- it yields an empty scan, and an
        # empty denominator prints as "0 unresolved / OK". That is the
        # fault class this gate exists to catch, so it must not be the
        # gate's own failure mode; see the guard in main().
        seq_id = entry.get("name") if isinstance(entry, dict) else entry
        if not isinstance(seq_id, str):
            continue
        for m in load_sequence_maps(seq_id):
            owners[m].append(seq_id)
    return owners


def scan_map(map_name, registry_scenes, check_scenes=False):
    """Return (placements, unresolved, malformed, scanned) for one map.

    unresolved is a list of dicts: token, row, col, cell, reason.

    `scanned` is False when the map named by a sequence has no map_data.json
    to read. That map contributes nothing to any count, so without the flag
    it is indistinguishable in the headline from a map that was read and
    found clean -- the gate's own fault class, one granularity down. The
    whole-corpus guard in main() only fires when EVERY map is empty, and
    both faults this gate was built from were single instances hidden by an
    insensitive summary. A missing map is NOT reported as an unresolved
    placement: whether a sequence may name a map that is not built yet is
    stage 1's question, not this gate's. It is counted and named.
    """
    map_file = MAPS_DIR / map_name / "map_data.json"
    if not map_file.exists():
        return 0, [], 0, False
    try:
        with open(map_file, encoding="utf-8") as fh:
            mdata = json.load(fh)
    except Exception as exc:
        return 0, [{"token": "<unparseable>", "row": -1, "col": -1,
                    "cell": str(exc)[:120],
                    "reason": "map_data.json will not parse"}], 0, True

    placements = 0
    malformed = 0
    bad = []
    rows = mdata.get("layers", {}).get("interactables", []) or []
    for r, row in enumerate(rows):
        if not isinstance(row, list):
            continue
        for c, cell in enumerate(row):
            raw = (cell or "").strip() if isinstance(cell, str) else ""
            if not raw or raw == " " or raw.startswith("#"):
                continue
            if is_empty_cell(raw):
                malformed += 1
                continue
            placements += 1
            token = raw.split(":")[0].split("#")[0]
            if token in ALWAYS_OK:
                continue

            if raw.startswith(PREFIX_FORMS):
                # Only cluster: names a source this tool can open.
                if raw.startswith("cluster:"):
                    cname = raw.split(":")[1].split("#")[0].strip()
                    if cname and not (CLUSTERS_DIR / (cname + ".json")).exists():
                        bad.append({"token": "cluster:" + cname, "row": r, "col": c,
                                    "cell": raw,
                                    "reason": "cluster JSON missing: %s.json" % cname})
                continue

            scene_path = registry_scenes.get(token, "")
            if not scene_path:
                bad.append({"token": token, "row": r, "col": c, "cell": raw,
                            "reason": "no registry entry"})
                continue
            if not (ROOT / scene_path.replace("res://", "")).exists():
                bad.append({"token": token, "row": r, "col": c, "cell": raw,
                            "reason": "registry scene missing on disk: " + scene_path})
                continue

            # Second class, opt-in: a resolved loader token carrying an
            # embedded scene_path that itself does not exist on disk.
            if check_scenes and "scene_path:" in raw:
                embedded = raw.split("scene_path:", 1)[1].split("#")[0].strip()
                if embedded.startswith("res://") and not (
                    ROOT / embedded.replace("res://", "")
                ).exists():
                    bad.append({"token": token, "row": r, "col": c, "cell": raw,
                                "reason": "embedded scene_path missing: " + embedded})
    return placements, bad, malformed, True


def main():
    as_json = "--json" in sys.argv
    scan_all = "--all" in sys.argv
    check_scenes = "--scenes" in sys.argv

    registry_scenes = load_all_registry_scenes()
    owners = map_dirs_for_spine()

    if scan_all:
        names = sorted(p.name for p in MAPS_DIR.iterdir()
                       if p.is_dir() and (p / "map_data.json").exists())
    else:
        names = sorted(owners.keys())

    total_placements = 0
    total_malformed = 0
    malformed_maps = {}
    findings = {}
    unscanned = []
    for name in names:
        placements, bad, malformed, scanned = scan_map(
            name, registry_scenes, check_scenes)
        if not scanned:
            unscanned.append(name)
        total_placements += placements
        total_malformed += malformed
        if malformed:
            malformed_maps[name] = malformed
        if bad:
            findings[name] = bad

    # A gate that scanned nothing must not report OK. An empty denominator
    # is indistinguishable from a clean corpus in every printed form, and
    # this gate's first run did exactly that (wrong spine key -> 0 maps ->
    # "OK: every interactable token resolves").
    scanned_count = len(names) - len(unscanned)
    if not scanned_count or not total_placements:
        print("BROKEN: named %d maps, read %d of them, %d placements -- "
              "refusing to report a verdict on an empty scan."
              % (len(names), scanned_count, total_placements))
        return 250

    unresolved = sum(len(v) for v in findings.values())
    by_token = defaultdict(list)
    for name, bad in findings.items():
        for b in bad:
            by_token[b["token"]].append(name)

    if as_json:
        print(json.dumps({
            "scope": "all" if scan_all else "spine",
            # maps_scanned counts maps that were READ. A map named by a
            # sequence with no map_data.json is not a scanned map, and
            # folding it into this number is how a denominator lies.
            "maps_scanned": scanned_count,
            "maps_named": len(names),
            "maps_without_data": unscanned,
            "placements": total_placements,
            "unresolved_placements": unresolved,
            "unresolved_tokens": {t: sorted(set(m)) for t, m in by_token.items()},
            "malformed_empty_cells": total_malformed,
            "malformed_empty_cell_maps": malformed_maps,
            "findings": findings,
        }, indent=2))
        return unresolved

    scope = "ALL MAPS" if scan_all else "SPINE"
    print("=== MAP TOKEN RESOLUTION (%s) ===" % scope)
    print("%d maps read, %d placements, %d unresolved (%d distinct tokens)"
          % (scanned_count, total_placements, unresolved, len(by_token)))
    if unscanned:
        print("note: %d of %d maps named by a spine sequence have no "
              "map_data.json and were NOT read -- they contribute no "
              "placements and cannot be found clean (%s)"
              % (len(unscanned), len(names), ", ".join(sorted(unscanned)[:6])
                 + (", ..." if len(unscanned) > 6 else "")))
    if total_malformed:
        print("note: %d non-standard empty cells in %d map(s) -- not counted as "
              "placements here, but the pipeline scorer DOES count them "
              "(top: %s)"
              % (total_malformed, len(malformed_maps),
                 ", ".join("%s x%d" % (m, n) for m, n in
                           sorted(malformed_maps.items(),
                                  key=lambda kv: -kv[1])[:3])))
    if not unresolved:
        print("\nOK: every interactable token resolves to a scene on disk.")
        return 0

    print()
    for token in sorted(by_token, key=lambda t: (-len(by_token[t]), t)):
        maps = sorted(set(by_token[token]))
        seqs = sorted({s for m in maps for s in owners.get(m, [])})
        print("  %-34s %d placement(s) in %s%s"
              % (token, len(by_token[token]), ", ".join(maps),
                 ("   [spine: " + ", ".join(seqs) + "]") if seqs else ""))
        reasons = sorted({b["reason"] for m in maps for b in findings[m]
                          if b["token"] == token})
        for reason in reasons:
            print("      %s" % reason)
    print("\nFAIL: %d unresolved placement(s)." % unresolved)
    return unresolved


if __name__ == "__main__":
    sys.exit(min(main(), 250))
