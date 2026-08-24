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
import re
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


# ── THE ROOT-TYPE CHECK (2026-08-24) ─────────────────────────────────────────
# A token can resolve to a scene that EXISTS and still be unplaceable: the
# museum needs a Node3D, and a scene whose root is Node / Node2D / Control
# fails at instantiate — silently, in the middle of a hall build. Found when
# `gridcolorizer` (a MUTATOR that colours an existing MultiMesh, root type
# Node) was moved into a room and the bake refused it 117 times, once per
# ring-search cell. The file-exists gate is blind to this whole class, so it
# reports it beside the resolution verdict rather than pretending it is fine.
SPATIAL_ROOTS = re.compile(
    r"^(Node3D|Spatial|StaticBody3D|RigidBody3D|CharacterBody3D|Area3D|"
    r"MeshInstance3D|MultiMeshInstance3D|CSG\w+|XR\w+|Marker3D|GridMap|"
    r"Path3D|VehicleBody3D|SoftBody3D|GPUParticles3D|CPUParticles3D|"
    r"Camera3D|\w*Light3D|Skeleton3D|BoneAttachment3D|AudioStreamPlayer3D|"
    r"NavigationRegion3D|ReflectionProbe|VoxelGI|Decal|OccluderInstance3D)$")


def scene_root_type(scene_path):
    """The root node's type as the .tscn declares it, or None when the file is
    missing / inherits its root from another scene (which we cannot judge)."""
    rel = str(scene_path).replace("res://", "")
    f = ROOT / rel
    if not f.exists():
        return None
    try:
        text = f.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return None
    for line in text.splitlines():
        if line.startswith("[node name=") and "parent=" not in line:
            m = re.search(r'type="([^"]+)"', line)
            return m.group(1) if m else None      # no type = inherited root
    return None


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

    placed_tokens = {}          # map -> {token} for the root-type pass
    total_placements = 0
    total_malformed = 0
    malformed_maps = {}
    findings = {}
    unscanned = []
    for name in names:
        mf = MAPS_DIR / name / "map_data.json"
        if mf.exists():
            try:
                with open(mf, encoding="utf-8") as fh:
                    _md = json.load(fh)
                toks = set()
                for _row in (_md.get("layers", {}).get("interactables", []) or []):
                    if not isinstance(_row, list):
                        continue
                    for _c in _row:
                        _raw = (_c or "").strip() if isinstance(_c, str) else ""
                        if _raw and not _raw.startswith("#"):
                            toks.add(_raw.split("#")[0].split(":")[0])
                if toks:
                    placed_tokens[name] = toks
            except Exception:
                pass
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

    # THE ROOT-TYPE PASS: placeable means a 3D root, not merely a file that
    # exists. Reported beside the resolution verdict, never folded into it —
    # these tokens resolve fine and still cannot stand in a room.
    unplaceable = {}
    for _name, _toks in placed_tokens.items():
        for _t in _toks:
            _sc = registry_scenes.get(_t) or registry_scenes.get(_t.lower())
            if not _sc:
                continue
            _rt = scene_root_type(_sc)
            if _rt and not SPATIAL_ROOTS.match(_rt):
                _u = unplaceable.setdefault(_t, {"root": _rt, "maps": set()})
                _u["maps"].add(_name)

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
    if unplaceable:
        print()
        print("UNPLACEABLE ROOTS: %d token(s) resolve to a scene whose root is "
              "not a 3D node - they cannot instantiate in a hall, and the museum "
              "refuses one once per ring-search cell (a single bad token cost 117 "
              "refusals in one bake):" % len(unplaceable))
        for _t in sorted(unplaceable):
            _u = unplaceable[_t]
            _ms = sorted(_u["maps"])
            print("  %-28s root=%-12s in %s%s"
                  % (_t, _u["root"], ", ".join(_ms[:4]),
                     " ..." if len(_ms) > 4 else ""))
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
