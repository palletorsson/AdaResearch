#!/usr/bin/env python3
"""
build_spine_artifact_order.py — the curriculum as a dealing order.

The endless museum's fast loop deals artifacts into template slots. Dealt from a
seeded shuffle it is a museum of the collection; dealt in SPINE ORDER it is the
curriculum walked through eight real museums — the book as a building (the wire
named in the 2026-07-31 handover).

Spine order is not invented here, it is read out of the shipped truth files:
  curriculum_spine.json  spine.sequences sorted by `order`   (24 sequences)
  sequences/<seq>.json   sequences[<seq>].maps               (map order)
  <Map>/map_data.json    the ROOM'S THREAD                   (artifact order)

THE ROOM'S THREAD (2026-09-07, Palle: "we need to establish the first order of
artifacts through the whole spine and then base the final.md texts on that ...
harmonize and simplify, not over complicate the order rulings").

Until today the artifact order inside a room was `interactables, row-major` —
the order the cells happen to sit in the JSON file, which has nothing to do with
what a body meets. That made this file a SECOND ordering rule that nobody could
rule: you could drag beads on /necklace/thread all afternoon and this manifest
never heard about it. So the rule is gone. A room's thread is now three sources,
first one wins:

  1. RULED  commons/data/artifact_roles.json, order[<map>][<role>] — what Palle
            dragged on /necklace/thread. 22 maps of 187 carry one, and that is
            the right number: you rule the exceptions, not the corpus.
  2. FLOOR  tools/floor_order.py — the order a body meets them walking from the
            spawn, over map_pathfinder's own walkable set. The honest default
            for a museum you walk through.
  3. FILE   row-major, for anything the walker cannot reach at all.

NOTHING IS DROPPED. Every placement still reaches the manifest whatever its role,
so the museum's dealing loop is untouched; each row now records its `role` and
the `by` that ordered it, and the consumer filters. The red thread is
`role == "primary"`; the noise Palle named — secondaries and decorations in the
text flow — is filtered at the reader, not baked in here.

An artifact placed many times appears ONCE, at its first appearance in the walk
— the same rule /order-of-things uses. Cells strip placement suffixes
(`token:rot:y` and `#key:value` config tokens). No registry filtering happens
here: the manifest records the curriculum's order; the consumer applies its own
liveness rules (map_ready, scene exists) at load.

Output: commons/data/spine_artifact_order.json
  { _meta: {...}, order: [ {lookup, sequence, map}, ... ] }

Usage:
  python tools/build_spine_artifact_order.py               # write the manifest
  python tools/build_spine_artifact_order.py --print       # also list the first 60
  python tools/build_spine_artifact_order.py --seq=forces  # PREVIEW one arc, writes nothing
"""
from __future__ import annotations
import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import floor_order  # noqa: E402  the single producer of the walk — never re-derive it here

REPO = Path(__file__).resolve().parents[1]
SPINE = REPO / "commons" / "maps" / "curriculum_spine.json"
SEQ_DIR = REPO / "commons" / "maps" / "sequences"
MAPS_DIR = REPO / "commons" / "maps"
OUT = REPO / "commons" / "data" / "spine_artifact_order.json"
ROLES_PATH = REPO / "commons" / "data" / "artifact_roles.json"


def _load(p: Path):
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None


ROLES: dict = {}


def spine_sequences() -> list[str]:
    d = _load(SPINE) or {}
    rows = d.get("spine", {}).get("sequences", [])
    rows = sorted(rows, key=lambda r: r.get("order", 999))
    return [r["name"] for r in rows if r.get("name")]


def maps_for(seq: str) -> list[str]:
    d = _load(SEQ_DIR / f"{seq}.json") or {}
    entry = d.get("sequences", {}).get(seq, {})
    return [m for m in entry.get("maps", []) if isinstance(m, str)]


def artifacts_in(map_name: str) -> list[str]:
    """Every placement in the room, row-major — the file's own order."""
    d = _load(MAPS_DIR / map_name / "map_data.json")
    if not d:
        return []
    rows = d.get("layers", {}).get("interactables", [])
    out: list[str] = []
    for row in rows:
        if not isinstance(row, list):
            continue
        for cell in row:
            tok = str(cell).split("#")[0].split(":")[0].strip()
            if tok:
                out.append(tok)
    return out


def thread(map_name: str) -> list[tuple[str, str, str]]:
    """The room's thread: what Palle ruled, then what a body meets, then the file.

    Three sources, first one wins. That is the whole rule — one line of logic,
    and every row remembers which source placed it so `--print` can show how much
    of the spine is actually ruled rather than defaulted.
    """
    placed = artifacts_in(map_name)                       # source 3, and the gate
    in_room = set(placed)
    roles = (ROLES.get("roles") or {}).get(map_name) or {}
    ruled_by_role = (ROLES.get("order") or {}).get(map_name) or {}
    ruled = [t for r in ("primary", "secondary", "decoration")
             for t in (ruled_by_role.get(r) or [])]       # source 1
    try:
        floor = floor_order.read_room(map_name, "all").get("floor") or []   # source 2
    except Exception:
        floor = []

    out: list[tuple[str, str, str]] = []
    seen: set[str] = set()
    for src, tokens in (("ruled", ruled), ("floor", floor), ("file", placed)):
        for t in tokens:
            if t in in_room and t not in seen:
                seen.add(t)
                out.append((t, roles.get(t, "unruled"), src))
    return out


def main() -> int:
    global ROLES
    ROLES = _load(ROLES_PATH) or {}
    only = ""
    for a in sys.argv[1:]:
        if a.startswith("--seq="):
            only = a.split("=", 1)[1]
    seqs = spine_sequences()
    if only:
        seqs = [s for s in seqs if s == only]
        if not seqs:
            print("no such spine sequence: %s" % only)
            return 1
    if not seqs:
        print(f"no spine sequences found in {SPINE}")
        return 1
    seen: set[str] = set()
    order: list[dict] = []
    maps_read = maps_missing = 0
    by_count = {"ruled": 0, "floor": 0, "file": 0}
    for seq in seqs:
        for m in maps_for(seq):
            if not (MAPS_DIR / m / "map_data.json").exists():
                maps_missing += 1
                continue
            maps_read += 1
            for a, role, src in thread(m):
                if a in seen:
                    continue
                seen.add(a)
                by_count[src] += 1
                order.append({"lookup": a, "sequence": seq, "map": m,
                              "role": role, "by": src})
    # --seq is a PREVIEW. Writing a one-sequence manifest over the whole spine
    # would silently truncate 918 artifacts to 153, and every consumer reads this
    # file without asking how it was built.
    if only:
        print("spine artifact order — PREVIEW of %s, nothing written" % only)
    payload = json.dumps({
        "_meta": {
            "generated": time.strftime("%Y-%m-%d %H:%M:%S"),
            "generator": "tools/build_spine_artifact_order.py",
            "rule": "first appearance walking the spine: sequence order -> map order -> the room's thread (ruled, else floor, else file)",
            "sequences": len(seqs),
            "maps_read": maps_read,
            "maps_missing": maps_missing,
            "artifacts": len(order),
            "ordered_by": by_count,
            "primary": sum(1 for r in order if r.get("role") == "primary"),
            "unruled": sum(1 for r in order if r.get("role") == "unruled"),
        },
        "order": order,
    }, indent=1)
    if not only:
        OUT.write_text(payload, encoding="utf-8")
        print(f"spine artifact order -> {OUT.relative_to(REPO)}")
    print(f"  {len(seqs)} sequences, {maps_read} maps read ({maps_missing} missing), {len(order)} distinct artifacts")
    print(f"  ordered by: {by_count['ruled']} ruled, {by_count['floor']} floor, {by_count['file']} file"
          f"   |   {sum(1 for r in order if r.get('role') == 'primary')} primary,"
          f" {sum(1 for r in order if r.get('role') == 'unruled')} unruled")
    if "--print" in sys.argv:
        for row in order[:60]:
            print(f"  {row['by']:6} {row['role']:10} {row['map']:32} {row['lookup']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
