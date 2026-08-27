#!/usr/bin/env python3
"""necklace_order.py — the spine's dealing order, with the curator's hand on it.

2026-08-26, Palle: "Can we build a tool in godot where we can horizontally
scroll the current order of the artifacts as a necklace showing 10 artifacts at
the time, we can add artifacts from a list and we can remove artifacts."

This is the half of that tool which is not in Godot. The Godot scene scrolls and
edits; this file is the single source of truth for what "the order, with hand
edits applied" actually IS, and it owns every file that answer is written to.

WHY A HAND LAYER AND NOT AN EDITED FILE. commons/data/spine_artifact_order.json
is generated: tools/build_spine_artifact_order.py walks 23 sequences, 261 maps
and every interactables cell, and rewrites all 810 rows from scratch. It has been
regenerated twice; each regeneration is triggered by an ordinary event, an edit
to any interactables layer in any of those 261 maps (25 ribbon halls landed this
month alone). An edit made directly in that file survives until the next run and
then vanishes with no error. So the hand does not edit the order, it edits a LIST
OF OPS that is replayed over the generated order every time anyone asks. That is
the same separation commons/data/map_authored.json + tools/em_map_halls.py
already carry, for the same reason.

WHY OPS AND NOT A SNAPSHOT. The web editor at /spine-order-editor writes the
whole 810-row list into spine_artifact_order_hand.json. A snapshot is worse than
no hand at all after a regeneration: the museum keeps dealing the artifacts that
existed the day it was saved, and the new ones are invisible forever, silently.
An op list absorbs a regeneration — a `move` still moves, an `add` is still added,
and an op whose token has left the corpus is REPORTED by name rather than dropped.

WHY POSITIONS ARE ANCHOR-RELATIVE AND NEVER INDICES. em_map_halls.py carries the
scar verbatim: cropping a tile to its content bbox moved (0,0) and "silently
re-addressed every saved ruling". `{"lookup": "origin", "index": 4}` is exactly
that failure — insert one artifact upstream and the op is about a different
neighbour, with no error and nothing visible until someone walks it.

  THREE FILES, ONE OWNER

  commons/data/spine_order_ops.json           THE HAND. Input. The Godot scene
                                              writes it; this tool reads it.
                                              Tracked, hand-readable, indent 1.

  commons/data/spine_order_effective.json     THE ANSWER. Output. The Godot
                                              scene reads it and nothing else.
                                              Carries the effective order, the
                                              chapter bands, the liveness of
                                              every row, the add-candidate pool,
                                              and the report.

  commons/data/spine_artifact_order_hand.json THE MUSEUM'S COPY. Output, in the
                                              exact shape /api/spine-order
                                              already writes, because
                                              endless_museum.gd:2324 reads that
                                              path FIRST when it exists and that
                                              file may not be edited.

  python tools/necklace_order.py                        summary, writes nothing
  python tools/necklace_order.py --apply                writes the two outputs
  python tools/necklace_order.py --check                gate: outputs vs sources
  python tools/necklace_order.py --init                 create an empty ops file
  python tools/necklace_order.py --add T --sequence S --after L
  python tools/necklace_order.py --remove T --why "..."
  python tools/necklace_order.py --move T --first-in S
  python tools/necklace_order.py --list-ops / --undo / --json

An edit writes the ops file only. Add --apply to the same command line to write
the derived outputs too. This is em_map_halls.py's probe-isolation rule: bare
runs touch nothing a live session reads, and Palle plays the desktop museum while
tools run.


                   THE CONTRACT WITH THE GODOT SCENE

The scene READS ONE FILE and WRITES ONE FILE. It never reads
spine_artifact_order.json and never writes anything else.

READ  res://commons/data/spine_order_effective.json   (schema "spine_order_effective/1")

  _meta.base_generated      str   the generated order's stamp this was built on
  _meta.base_artifacts      int   rows in the generated order
  _meta.ops_state           str   "absent" = there is no ops file, so the effective
                                  order IS the generated order. "ok" = the ops file
                                  was read and parsed. THERE IS NO THIRD VALUE IN A
                                  WRITTEN FILE: an empty, unparseable or wrong-shape
                                  ops file aborts this tool before anything is
                                  written or deleted. Before that distinction
                                  existed, a truncated hand and a missing hand
                                  printed the same sentence and --apply DELETED the
                                  museum's copy on the strength of the misread.
  _meta.ops_exists          bool  ops_state == "ok". Kept for the scene's contract.
  _meta.ops_revision        int   the ops revision this was derived from -- the
                                  ONE number the scene compares (see STALENESS).
                                  MONOTONE: a writer takes max(its own, the ops file
                                  on disk, its .bak, this file) + 1, so the number
                                  cannot travel backwards and re-agree at a lower
                                  value after a loss.
  _meta.ops_digest          str   16 hex chars over the op list, for humans
  _meta.ops_total/_applied/_stale/_refused/_degraded   int
  _meta.added/removed/moved int   how much the hand actually changed
  _meta.artifacts           int   rows in `order` -- the necklace's length
  _meta.alive/dead          int
  _meta.non_body_roots      [str] alive tokens whose scene root is NOT a Node3D.
                                  BADGE THESE, DO NOT MOUNT THEM: `instantiate()
                                  as Node3D` returns null, not an error, and a
                                  null body reads as an empty slot with no reason
                                  attached. Three today -- gridcolorizer,
                                  boid_flocking (also the headless-hang
                                  artifact), ecosystem_simulation.
  _meta.plan_note           str   print this in the HUD verbatim on save
  _report.applied/stale/degraded/refused/notes  [str]  human sentences, show them

  chapters[]   the bands, in the order they stand ON THE STRING
    sequence   str    chapter name
    i0         int    index of its first row in `order`
    n          int    how many rows
    in_spine   bool   false = a dissolved chapter still in the generated order
                      (array_tutorial, 31 rows, today). Draw it, say what it is.

  order[]      the necklace, bead 0 first
    lookup     str    the artifact token -- the identity of the bead
    sequence   str    its chapter. THE CHAPTER IS THE MUSEUM BUILDING: a bead may
                      be reordered inside its band and may NEVER cross a band.
                      Refuse the drop; do not write the op.
    map        str    the map where the spine first meets it; "" for a hand add
    origin     str    "spine" | "moved" | "hand"
    seq_i      int    its position within its chapter
    seq_n      int    the chapter's length -- status line: "412 / 810 - fractals 18 / 46"
    alive      bool   the museum's own rule (scene + map_ready + file on disk)
    dead       str    present only when alive is false: WHY, in words
    scene      str    res:// path to instantiate, delegate already resolved
    delegate_to str   present only when the scene is borrowed from another token
    root       str    the .tscn root node type ("instance" = inherited, unknown)
    body       bool   false = root is not a 3D node, see _meta.non_body_roots
    fp         int    footprint in cells, the museum's _footprint_of
    size_m     float|null   registry max_dimension_m. Ranges 0.00 to 300.00 over
                      the corpus, a 175x spread, so the beads CANNOT share one
                      scale -- normalise each into the bead volume and put the
                      real metres on the label.
    category   str
    desc       str    the description's first sentence, capped at 160
    why        str    present when a hand op gave a reason

  candidates[] the ADD LIST, sorted by lookup: every token the museum would deal
               that is not already on the string (1,875 today). Same fields minus
               the order-only ones, plus:
    hint_sequences [str]  the registry's map_sequences -- a HINT for defaulting
                          the palette to the focused bead's chapter, never the
                          chapter itself. The curator picks that when they add.

WRITE res://commons/data/spine_order_ops.json   (schema "spine_order_ops/1")

  Read the whole document, append to `ops`, bump `_meta.ops_revision` by one, set
  `_meta.ops` to len(ops) and `_meta.generator` to the scene's own path, keep
  `_readme` and `_meta.base_generated` as they were, write it back. Never
  reorder or rewrite existing ops: the list is a SCRIPT replayed in file order,
  which is what lets an edit be appended instead of the history rewritten.

  {"op": "add",    "lookup": T, "sequence": S, <one position>, "why": "..."}
  {"op": "remove", "lookup": T, "why": "..."}                    no position
  {"op": "move",   "lookup": T, <one position>, "why": "..."}

  <one position>, exactly one, and never an index:
     "after": <lookup>   "before": <lookup>       both must be in T's chapter
     "first_in": <seq>   "last_in": <seq>         must be T's own chapter

  "add" requires the token to be in `candidates`. "remove" means DROP FROM THE
  DEAL, never delete: the artifact stays in its map, the player still meets it
  walking the grid, and the next run of build_spine_artifact_order.py will put it
  back in the generated order -- which is exactly why removal has to be a
  persistent op. Label the button "drop from the deal", the wording the web
  editor already uses.

STALENESS -- the scene must say this out loud.

  After writing ops, spine_order_effective.json is BEHIND. Detect it with two
  integers, no hashing: ops file `_meta.ops_revision` != effective file
  `_meta.ops_revision`. While they differ the scene shows

      "saved -- run `python tools/necklace_order.py --apply` to derive it"

  and on every save it also shows `_meta.plan_note`, because the museum's shipped
  default is plan mode and the dealing order does not reach a planned hall until
  the plan is rebuilt. Silence there is the failure this project keeps writing
  memory files about.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

GEN = os.path.join(ROOT, "commons", "data", "spine_artifact_order.json")
OPS = os.path.join(ROOT, "commons", "data", "spine_order_ops.json")
EFFECTIVE = os.path.join(ROOT, "commons", "data", "spine_order_effective.json")
HAND = os.path.join(ROOT, "commons", "data", "spine_artifact_order_hand.json")

REGISTRY_DIR = os.path.join(ROOT, "commons", "artifacts", "registry")
SPINE = os.path.join(ROOT, "commons", "maps", "curriculum_spine.json")

SCHEMA = "spine_order_effective/1"
OPS_SCHEMA = "spine_order_ops/1"

# The four verbs. `pin` was in the design sketch and is not here: "hold this at
# the head of its chapter" is `move ... first_in`, replayed from the generated
# order every run, which is the same thing with one fewer rule for the scene
# author to implement wrongly.
VERBS = ("add", "remove", "move")

# Exactly one position clause per op, and every one of them names a LOOKUP or a
# SEQUENCE. No integers. See the docstring.
POSITIONS = ("after", "before", "first_in", "last_in")

OPS_README = (
    "THE NECKLACE'S HAND - ordered edits replayed ON TOP OF the generated spine "
    "order (commons/data/spine_artifact_order.json), never a copy of it. The "
    "generated order is rewritten from 261 maps whenever any interactables layer "
    "changes, so a snapshot would freeze the walk at the artifacts that existed "
    "the day it was saved. Ops are replayed in file order by "
    "`python tools/necklace_order.py --apply`, which re-reads the generated "
    "order every run and derives commons/data/spine_order_effective.json (read by "
    "the Godot necklace scene) and commons/data/spine_artifact_order_hand.json "
    "(read FIRST by endless_museum.gd:2324). Delete the ops, re-apply, and the "
    "generated order returns. Positions are anchor-relative - `after`/`before` "
    "name a lookup, `first_in`/`last_in` name a sequence - never an index, "
    "because an index re-targets in silence when the order regenerates."
)


# --------------------------------------------------------------------------
# reading


def read_json(path, default=None):
    """TOLERANT. For the 223 registry files and the generated order, where a
    single unreadable file must not stop the tool.

    NEVER for the ops file, the effective file or the museum's hand file. Those
    three go through read_json_state, because for them "absent" and "damaged"
    are DIFFERENT ANSWERS and this function returns the same one for both. That
    conflation is what let a truncated 3-op hand print "no ops" and exit 0.
    """
    try:
        with open(path, encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, ValueError):
        return default


# The states read_json_state can report. Only ABSENT and OK are survivable for
# the ops file; the rest abort before any write.
ST_ABSENT = "absent"          # the file is not there. A real, legible answer.
ST_OK = "ok"                  # parsed
ST_EMPTY = "empty"            # zero bytes or whitespace - an interrupted write
ST_UNPARSEABLE = "unparseable"  # truncated, half-written, or not JSON
ST_UNREADABLE = "unreadable"  # a lock, a permission, a device error


def read_json_state(path):
    """(doc, state) -- the four ways a file can fail to be a document, kept apart.

    Reads bytes rather than handing the path to json.load, so a zero-byte file
    (the exact residue of a killed write, and this repo wraps runs in
    godot_watchdog.py, which kills the process TREE) is reported as EMPTY and
    not as a parse error, and a parse error is never reported as absence.
    """
    if not os.path.exists(path):
        return None, ST_ABSENT
    try:
        with open(path, "rb") as fh:
            raw = fh.read()
    except OSError:
        return None, ST_UNREADABLE
    if not raw.strip():
        return None, ST_EMPTY
    try:
        return json.loads(raw.decode("utf-8")), ST_OK
    except (UnicodeDecodeError, ValueError):
        return None, ST_UNPARSEABLE


def write_json_atomic(path, doc, indent=1, keep_backup=False):
    """Write via a sibling .tmp and os.replace, which is atomic on NTFS.

    `open(path, "w")` TRUNCATES BEFORE IT WRITES, so the window between the open
    and the close is a window in which the file on disk is zero bytes. That is
    not hypothetical here: the standing rule of this repo is to wrap runs in
    tools/godot_watchdog.py, which kills the process TREE, and a kill in that
    window manufactures exactly the empty ops file the reader above now has to
    have a name for. Writing elsewhere and swapping means the reader sees the
    old document or the new one and never a half of either.

    keep_backup also copy2s the outgoing document to `<path>.bak` FIRST, so the
    previous good hand survives even a bad new one. Order matters and is:
    write .tmp -> copy the live file to .bak -> replace. A kill at any point
    leaves at least one complete document on disk.
    """
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        if indent is None:
            json.dump(doc, fh, ensure_ascii=False, separators=(",", ":"))
        else:
            json.dump(doc, fh, ensure_ascii=False, indent=indent)
        fh.write("\n")
        fh.flush()
        os.fsync(fh.fileno())
    if keep_backup and os.path.exists(path):
        try:
            shutil.copy2(path, path + ".bak")
        except OSError as exc:
            # A backup that cannot be taken is a reason to STOP, not to carry on
            # and overwrite the only copy. The .tmp is left in place on purpose:
            # it is the new document, complete, for a human to move by hand.
            raise SystemExit(
                "FATAL: could not back up %s before overwriting it (%s).\n"
                "  Nothing was overwritten. The new document is complete at %s -\n"
                "  move it into place by hand once you know why the copy failed."
                % (_rel(path), exc, _rel(tmp)))
    os.replace(tmp, path)
    return path


def _rel(path):
    return os.path.relpath(path, ROOT).replace("\\", "/")


def spine_sequences():
    """The chapters in curriculum order.

    Never a hardcoded list. symmetry and array_tutorial were dissolved into
    color on 2026-08-24, and every tool carrying its own copy of the spine still
    deals 13 halls that no longer exist.
    """
    doc = read_json(SPINE) or {}
    rows = doc.get("spine", {}).get("sequences", [])
    rows = sorted(rows, key=lambda r: r.get("order", 999))
    return [str(r["name"]) for r in rows if r.get("name")]


def registry():
    """token -> entry, over every commons/artifacts/registry/*.json.

    `data.get("artifacts", {})` is the museum's own reader (endless_museum.gd
    :2126), and it is not a formality: 222 of the 223 registry files wrap their
    tokens under that key and substrate_vectors.json does not. Its tokens are
    invisible to the museum, so they are invisible here too - a palette built by
    a looser rule would offer tokens that vanish the moment they are dealt.
    """
    out = {}
    if not os.path.isdir(REGISTRY_DIR):
        return out
    for fname in sorted(os.listdir(REGISTRY_DIR)):
        if not fname.endswith(".json"):
            continue
        data = read_json(os.path.join(REGISTRY_DIR, fname))
        if not isinstance(data, dict):
            continue
        arts = data.get("artifacts")
        if not isinstance(arts, dict):
            continue
        for token, entry in arts.items():
            if isinstance(entry, dict):
                out[str(token)] = entry
    return out


def res_path(scene):
    """res:// -> an absolute path on this disk, or "" if it is not a res:// path."""
    s = str(scene or "").strip()
    if not s.startswith("res://"):
        return ""
    return os.path.join(ROOT, s[len("res://"):].replace("/", os.sep))


def footprint_of(entry):
    """The museum's _footprint_of (endless_museum.gd:2229) - the widest
    horizontal dimension in cells, from parameters.footprint [x, y, z]."""
    params = entry.get("parameters")
    if isinstance(params, dict):
        fp = params.get("footprint")
        if isinstance(fp, list) and len(fp) >= 3:
            try:
                return max(1, int(fp[0]), int(fp[2]))
            except (TypeError, ValueError):
                return 1
    return 1


def live_index(reg):
    """token -> {scene, fp, delegate_to} for everything the museum will deal.

    This replicates endless_museum.gd _load_pool exactly, INCLUDING the second
    pass. Getting the rule slightly wrong here is the whole failure: the palette
    offers a token, the curator adds it, the museum drops it at load, and the
    only symptom is a bead that never appears.

      alive = scene != "" and map_ready and the scene file exists   (:2139)
      then: 49 entries carry delegate_to and no scene of their own, and their
      targets do have one. One hop only - a delegate pointing at a delegate
      stays unresolved rather than risking a cycle.                 (:2178)
    """
    live = {}
    delegates = []
    for token, entry in reg.items():
        scene = str(entry.get("scene", "") or "").strip()
        if scene and bool(entry.get("map_ready", False)) and os.path.exists(res_path(scene)):
            live[token] = {"scene": scene, "fp": footprint_of(entry), "delegate_to": ""}
        elif not scene and str(entry.get("delegate_to", "") or "").strip():
            delegates.append((token, str(entry["delegate_to"]).strip(), entry))
    for token, target, entry in delegates:
        tgt = live.get(target)
        if tgt is not None:
            live[token] = {"scene": tgt["scene"], "fp": footprint_of(entry),
                           "delegate_to": target}
    return live


_ROOT_TYPE_CACHE = {}


def root_type(scene):
    """The type of the .tscn's first [node] line, or "instance" when the root is
    an inherited/instanced scene, or "" when the file cannot be read.

    THE NECKLACE MUST NOT MOUNT A NON-3D ROOT. Three of the 810 are
    `map_ready: true` and still cannot stand up - gridcolorizer (Node),
    boid_flocking (CanvasLayer, and the documented headless-hang artifact) and
    ecosystem_simulation (Node2D). `instantiate() as Node3D` on those returns
    null rather than raising, so a scene that trusts map_ready shows an empty
    slot and no reason for it. Recorded per row as `root`, checked by the scene
    before it builds a body.
    """
    key = str(scene)
    if key in _ROOT_TYPE_CACHE:
        return _ROOT_TYPE_CACHE[key]
    path = res_path(scene)
    found = ""
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            for line in fh:
                if not line.startswith("[node "):
                    continue
                if ' type="' in line:
                    found = line.split(' type="', 1)[1].split('"', 1)[0]
                else:
                    found = "instance"
                break
    except OSError:
        found = ""
    _ROOT_TYPE_CACHE[key] = found
    return found


NON_3D_ROOTS = {"Node", "Node2D", "CanvasLayer", "Control", "CanvasItem"}


def one_line(text):
    """The first sentence of a registry description, capped.

    The corpus's descriptions are essays - accord_swarm's runs past 1,200
    characters - and 2,685 of those in one file is half a megabyte of prose the
    scene will never fit under a bead. The first sentence is the artifact's own
    one-liner and it is already written.
    """
    s = " ".join(str(text or "").split())
    if not s:
        return ""
    head = s.split(". ")[0]
    if len(head) > 160:
        head = head[:157].rstrip() + "..."
    return head


def is_body(rt):
    """True when the root will survive `instantiate() as Node3D`. "instance" and
    "" are unknown, not false - an inherited root usually is a Node3D, and only
    an instantiate proves it either way, so the scene badges rather than hides."""
    return rt not in NON_3D_ROOTS


def token_facts(token, reg, live):
    """The per-row facts the necklace needs to draw a bead and refuse a bad one."""
    entry = reg.get(token) or {}
    row = live.get(token)
    meas = entry.get("measurements") if isinstance(entry.get("measurements"), dict) else {}
    size = meas.get("max_dimension_m")
    facts = {
        "alive": row is not None,
        "scene": row["scene"] if row else str(entry.get("scene", "") or ""),
        "fp": row["fp"] if row else footprint_of(entry),
        "category": str(entry.get("category", "") or ""),
        "size_m": round(float(size), 3) if isinstance(size, (int, float)) else None,
        "desc": one_line(entry.get("description")),
    }
    if row and row.get("delegate_to"):
        facts["delegate_to"] = row["delegate_to"]
    facts["root"] = root_type(facts["scene"]) if facts["scene"] else ""
    facts["body"] = is_body(facts["root"])
    if not facts["alive"]:
        # WHY it is dead, not just that it is. 44 of the 810 are already dead and
        # the museum prints only a count, so nobody has ever met one by name.
        if token not in reg:
            facts["dead"] = "no registry entry"
        elif not facts["scene"]:
            facts["dead"] = "no scene declared"
        elif not os.path.exists(res_path(facts["scene"])):
            facts["dead"] = "scene file missing on disk"
        elif not entry.get("map_ready", False):
            facts["dead"] = "map_ready is false"
        else:
            facts["dead"] = "not dealt by the museum's rule"
    return facts


# --------------------------------------------------------------------------
# the ops file


def empty_ops():
    return {
        "schema": OPS_SCHEMA,
        "_readme": OPS_README,
        "_meta": {
            "generated": time.strftime("%Y-%m-%d %H:%M:%S"),
            "generator": "tools/necklace_order.py",
            "base_generated": str((read_json(GEN) or {}).get("_meta", {}).get("generated", "")),
            # Bumped by EVERY writer on every save, including the Godot scene.
            # The effective file records the revision it was derived from, so the
            # scene can tell "my edits are not applied yet" by comparing two
            # integers - no hashing, no canonical serialisation to get wrong on
            # the GDScript side.
            "ops_revision": 0,
            "ops": 0,
        },
        "ops": [],
    }


def _recovery(reason):
    """The sentence every refusal to read the hand ends with.

    A refusal that does not carry its own way out is a refusal the curator
    resolves by deleting the file, which is the loss the refusal existed to
    prevent.
    """
    lines = [
        "FATAL: %s is %s." % (_rel(OPS), reason),
        "  THIS IS THE HAND - the only irreplaceable file of the three, and the",
        "  one an --apply used to DELETE the museum's copy on the strength of.",
        "  Nothing has been written. Nothing has been deleted.",
        "",
        "  RECOVER the previous good copy, written before every save:",
        "      copy %s %s" % (_rel(OPS + ".bak"), _rel(OPS)),
    ]
    tmp_state = read_json_state(OPS + ".tmp")[1]
    if tmp_state == ST_OK:
        lines += [
            "",
            "  OR: %s parses and is newer - it is a write that was killed after"
            % _rel(OPS + ".tmp"),
            "      the document was complete but before the swap. Read it, then move it.",
        ]
    elif tmp_state != ST_ABSENT:
        lines += [
            "",
            "  (%s exists and is %s - an interrupted write. It is NOT a fallback.)"
            % (_rel(OPS + ".tmp"), tmp_state),
        ]
    lines += [
        "",
        "  OR START THE HAND OVER, losing every op in it:",
        "      del %s   &&   python tools/necklace_order.py --init" % _rel(OPS),
    ]
    return "\n".join(lines)


def load_ops():
    """(doc, state) with state ST_ABSENT or ST_OK -- or SystemExit.

    THE THIRD STATE IS THE WHOLE POINT. This used to return (empty_ops(), False)
    for a missing file AND for a damaged one, so a golden three-op hand truncated
    to half its bytes printed "no ops - the effective order is the generated
    order" and exited 0; the next ordinary --add then truncated it to one op and
    said "revision 1" over a file that had been at revision 3; and --apply, seeing
    added == removed == moved == 0, DELETED spine_artifact_order_hand.json, after
    which --check certified the result. Four states shared one sentence and it was
    false in three of them.

    So: only an ABSENT file falls through to empty_ops(). Empty, unparseable,
    unreadable and wrong-shape raise, before any caller can write or delete.
    """
    doc, state = read_json_state(OPS)
    if state == ST_ABSENT:
        return empty_ops(), ST_ABSENT
    if state == ST_EMPTY:
        raise SystemExit(_recovery(
            "zero bytes - a write that was killed between the truncate and the "
            "flush"))
    if state == ST_UNREADABLE:
        raise SystemExit(_recovery("there but could not be read"))
    if state == ST_UNPARSEABLE:
        raise SystemExit(_recovery(
            "not parseable as JSON (%d bytes on disk) - truncated, half-written, "
            "or hand-edited into invalid JSON" % os.path.getsize(OPS)))

    # Shape. A document that parses is not yet a hand. Each of these was a way
    # to reach empty_ops() with a file full of ops sitting on the disk.
    if not isinstance(doc, dict):
        raise SystemExit(_recovery(
            "valid JSON but a %s, not an object" % type(doc).__name__))
    schema = doc.get("schema")
    if schema is not None and str(schema) != OPS_SCHEMA:
        raise SystemExit(_recovery(
            "stamped schema %r, not %r - this is a different document"
            % (str(schema), OPS_SCHEMA)))
    ops = doc.get("ops")
    if ops is None:
        raise SystemExit(_recovery(
            "an object with no `ops` key - the op list did not survive whatever "
            "wrote this"))
    if not isinstance(ops, list):
        raise SystemExit(_recovery(
            "carrying `ops` as a %s, not a list" % type(ops).__name__))
    bad = [i for i, o in enumerate(ops) if not isinstance(o, dict)]
    if bad:
        raise SystemExit(_recovery(
            "carrying %d op(s) that are not objects, at index %s - the replay "
            "used to DROP those silently"
            % (len(bad), ", ".join(str(i) for i in bad[:8]))))
    meta = doc.get("_meta")
    if meta is None:
        doc["_meta"] = {}
    elif not isinstance(meta, dict):
        raise SystemExit(_recovery(
            "carrying `_meta` as a %s, not an object - the revision cannot be "
            "read, so the next save could not be made monotone"
            % type(meta).__name__))

    # A GOOD FILE WITH A STALE .tmp BESIDE IT IS SAID OUT LOUD, NOT CONSUMED.
    # It is the residue of a killed write. It may hold ops this file does not.
    if os.path.exists(OPS + ".tmp"):
        print("WARN: %s exists beside a good ops file - an interrupted write. It "
              "is NOT being read and it is NOT a fallback. Read it now if you "
              "want it: the next save overwrites it."
              % _rel(OPS + ".tmp"), file=sys.stderr)
    return doc, ST_OK


def ops_digest(ops):
    """A stable fingerprint of the op list, for the report and for --check.

    Computed over the ops re-serialised with sorted keys, so a reformat of the
    file is not mistaken for an edit.
    """
    blob = json.dumps(ops, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return hashlib.sha1(blob.encode("utf-8")).hexdigest()[:16]


def _int_or(value, default=0):
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def revision_floor(meta):
    """The highest ops_revision anything on this disk has ever admitted to.

    THE REVISION MUST NOT TRAVEL BACKWARDS. Staleness is a two-integer test -
    the ops file's revision against the effective file's - and that test only
    works while the number climbs. Increment over a fresh empty_ops() and a hand
    at revision 3 is written back as revision 1; both files then re-agree at 1 on
    the next --apply and the scene's staleness HUD goes quiet FOREVER, which is
    the state in which a curator saves work into a file nobody derives.

    So a writer never trusts the revision it is holding. It takes the maximum
    over every copy that still exists - the in-memory document, the ops file on
    disk, its backup, and the last derivation recorded in the effective file -
    and adds one.
    """
    floor = _int_or(meta.get("ops_revision"), 0)
    for path in (OPS, OPS + ".bak", EFFECTIVE):
        doc, state = read_json_state(path)
        if state != ST_OK or not isinstance(doc, dict):
            continue
        m = doc.get("_meta")
        if isinstance(m, dict):
            floor = max(floor, _int_or(m.get("ops_revision"), 0))
    return floor


def write_ops(doc, ops):
    doc["schema"] = OPS_SCHEMA
    doc["_readme"] = OPS_README
    meta = doc.setdefault("_meta", {})
    meta["generated"] = time.strftime("%Y-%m-%d %H:%M:%S")
    meta.setdefault("generator", "tools/necklace_order.py")
    meta["base_generated"] = str((read_json(GEN) or {}).get("_meta", {}).get("generated", ""))
    meta["ops_revision"] = revision_floor(meta) + 1
    meta["ops"] = len(ops)
    doc["ops"] = ops
    write_json_atomic(OPS, doc, indent=1, keep_backup=True)
    return meta["ops_revision"]


def op_faults(op, i):
    """What is wrong with an op as WRITTEN, before anything is replayed. A
    malformed op from the scene must be named here rather than half-applied."""
    bad = []
    verb = str(op.get("op", ""))
    if verb not in VERBS:
        bad.append("op %d: verb %r is not one of %s" % (i, verb, ", ".join(VERBS)))
        return bad
    if not str(op.get("lookup", "")).strip():
        bad.append("op %d (%s): no lookup" % (i, verb))
    clauses = [k for k in POSITIONS if str(op.get(k, "")).strip()]
    if verb == "remove":
        if clauses:
            bad.append("op %d (remove %s): a remove takes no position clause (%s)"
                       % (i, op.get("lookup"), ", ".join(clauses)))
    else:
        if len(clauses) != 1:
            bad.append("op %d (%s %s): exactly one of %s is required, found %d"
                       % (i, verb, op.get("lookup"), "/".join(POSITIONS), len(clauses)))
    if verb == "add" and not str(op.get("sequence", "")).strip():
        # sequence is not decoration: endless_museum.gd:2341 reads `lookup` and
        # `sequence` per row and nothing else, and the chapter IS the museum
        # building the token is dealt into. A blank one deals the bead into
        # nowhere.
        bad.append("op %d (add %s): `sequence` is required - the chapter is the "
                   "building it is dealt into" % (i, op.get("lookup")))
    return bad


# --------------------------------------------------------------------------
# the replay


class Report:
    def __init__(self):
        self.applied = []
        self.stale = []
        self.degraded = []
        self.refused = []
        self.notes = []
        # index -> the lines this one op produced. THE KEYSTROKE PATH AND THE
        # REPLAY PATH READ THE SAME VERDICT out of this, rather than each
        # carrying its own copy of the rules and drifting. Before it existed the
        # liveness rule bit at the keystroke and the chapter rule only at replay,
        # so `--move T --after <a token in another chapter>` was accepted, written
        # to the file, and refused on every run from then until someone read the
        # report and used --undo.
        self.by_op = {}

    def as_dict(self):
        return {"applied": self.applied, "stale": self.stale,
                "degraded": self.degraded, "refused": self.refused,
                "notes": self.notes}


def _index_of(rows, lookup):
    for i, r in enumerate(rows):
        if r["lookup"] == lookup:
            return i
    return -1


def _chapter_span(rows, seq):
    """(first, last_exclusive) of a chapter's contiguous run, or None."""
    first = last = -1
    for i, r in enumerate(rows):
        if r["sequence"] == seq:
            if first < 0:
                first = i
            last = i
    return None if first < 0 else (first, last + 1)


def _chapter_gap(rows, seq, spine):
    """Where a chapter that currently has no rows WOULD start.

    Only reachable when every artifact of a chapter has been removed by hand.
    Without it, `first_in <empty chapter>` would append to the end of the whole
    order and put a primitives bead after postfoundationscrisis.
    """
    if seq not in spine:
        return len(rows)
    pos = spine.index(seq)
    for i, r in enumerate(rows):
        s = r["sequence"]
        if s in spine and spine.index(s) > pos:
            return i
    return len(rows)


def _resolve_position(rows, op, seq, spine, rep, label):
    """The insert index for one op, or None when the op must be refused.

    Two different failures with two different answers, and conflating them is
    how an edit disappears:
      - the anchor names a token in ANOTHER chapter: the curator asked for
        something the museum cannot honour (the chapter is the building), so the
        op is REFUSED and stays in the file.
      - the anchor has VANISHED since the op was written: a regeneration ate it,
        which is the exact hazard the ops layer exists to survive, so the op
        DEGRADES to last_in its own chapter and says so.
    """
    for clause in ("after", "before"):
        anchor = str(op.get(clause, "") or "").strip()
        if not anchor:
            continue
        j = _index_of(rows, anchor)
        if j < 0:
            span = _chapter_span(rows, seq)
            rep.degraded.append("%s: anchor %s `%s` is gone from the order - "
                                "degraded to last_in %s" % (label, clause, anchor, seq))
            return span[1] if span else _chapter_gap(rows, seq, spine)
        if rows[j]["sequence"] != seq:
            rep.refused.append("%s: anchor `%s` is in chapter %s, not %s - a token "
                               "cannot leave its chapter, that is a "
                               "curriculum_spine.json decision"
                               % (label, anchor, rows[j]["sequence"], seq))
            return None
        return j + 1 if clause == "after" else j
    for clause, at_end in (("first_in", False), ("last_in", True)):
        target = str(op.get(clause, "") or "").strip()
        if not target:
            continue
        if target != seq:
            rep.refused.append("%s: %s names chapter %s but the token belongs to %s"
                               % (label, clause, target, seq))
            return None
        span = _chapter_span(rows, seq)
        if span is None:
            rep.notes.append("%s: chapter %s currently holds no artifacts - "
                             "inserted where the chapter would begin" % (label, seq))
            return _chapter_gap(rows, seq, spine)
        return span[1] if at_end else span[0]
    return None


def replay(gen_rows, ops, live, spine):
    """The generated order with the hand replayed over it, in file order.

    Each op sees the result of the one before it, so the file is a script rather
    than a set - which is what lets the scene APPEND an edit instead of rewriting
    history, and what makes `move A after B; move B after A` mean something.
    """
    rows = [{"lookup": str(r.get("lookup", "")),
             "sequence": str(r.get("sequence", "")),
             "map": str(r.get("map", "")),
             "origin": "spine"}
            for r in gen_rows if str(r.get("lookup", "")).strip()]
    rep = Report()
    counts = {"add": 0, "remove": 0, "move": 0}

    for i, op in enumerate(ops):
        mark = (len(rep.refused), len(rep.stale), len(rep.degraded), len(rep.notes))
        _replay_one(rows, op, i, live, spine, rep, counts)
        rep.by_op[i] = {
            "refused": rep.refused[mark[0]:], "stale": rep.stale[mark[1]:],
            "degraded": rep.degraded[mark[2]:], "notes": rep.notes[mark[3]:],
        }

    return rows, rep, counts


def _replay_one(rows, op, i, live, spine, rep, counts):
    """One op against the running order, mutating `rows`, `rep` and `counts`.

    Extracted from `replay` for one reason: so the caller can bracket it and
    record which report lines belong to which op (Report.by_op), which is what
    lets the KEYSTROKE path ask the replay itself "would this op be refused?"
    instead of re-implementing the chapter rule and getting it different.
    """
    faults = op_faults(op, i)
    if faults:
        rep.refused.extend(faults)
        return
    verb = str(op["op"])
    token = str(op["lookup"]).strip()
    label = "op %d (%s %s)" % (i, verb, token)
    why = str(op.get("why", "") or "")

    if verb == "remove":
        j = _index_of(rows, token)
        if j < 0:
            # NOT an error to keep removing something that is already gone -
            # but it must be visible, because the generated order will put
            # the token back on the next run of build_spine_artifact_order.py
            # if the map still holds it, and a `remove` that has stopped
            # matching anything is usually a token that left the corpus.
            rep.stale.append("%s: not in the order - nothing removed%s"
                             % (label, (" (" + why + ")") if why else ""))
            return
        rows.pop(j)
        counts["remove"] += 1
        rep.applied.append("%s: dropped from the deal%s"
                           % (label, (" - " + why) if why else ""))
        return

    if verb == "add":
        seq = str(op["sequence"]).strip()
        if _index_of(rows, token) >= 0:
            # ABSORBED: a regeneration has since put this token in the
            # curriculum by itself. The add is redundant, not broken; saying
            # so is how the curator learns the op can be deleted.
            rep.notes.append("%s: already in the order - the add is absorbed, "
                             "the op can be deleted" % label)
            return
        if token not in live:
            rep.refused.append("%s: not alive by the museum's rule (scene + "
                               "map_ready + file on disk) - it would be dealt "
                               "and dropped" % label)
            return
        if seq not in spine:
            rep.refused.append("%s: chapter %s is not in the spine" % (label, seq))
            return
        at = _resolve_position(rows, op, seq, spine, rep, label)
        if at is None:
            return
        rows.insert(at, {"lookup": token, "sequence": seq,
                         # THE MUSEUM NEVER READS `map` (endless_museum.gd
                         # :2341 takes lookup and sequence only). An added
                         # token has no spine map, and inventing one would be
                         # a claim about where the player first meets it.
                         "map": "", "origin": "hand", "why": why})
        counts["add"] += 1
        rep.applied.append("%s: added to %s%s" % (label, seq, (" - " + why) if why else ""))
        return

    # move
    j = _index_of(rows, token)
    if j < 0:
        rep.stale.append("%s: not in the order - the token has left the "
                         "corpus or was removed by an earlier op" % label)
        return
    seq = rows[j]["sequence"]
    row = rows.pop(j)
    at = _resolve_position(rows, op, seq, spine, rep, label)
    if at is None:
        rows.insert(j, row)
        return
    rows.insert(at, row)
    if row["origin"] == "spine":
        row["origin"] = "moved"
    if why:
        row["why"] = why
    counts["move"] += 1
    rep.applied.append("%s: moved within %s%s" % (label, seq, (" - " + why) if why else ""))


# --------------------------------------------------------------------------
# the documents


def chapters_of(rows, spine):
    """The bands as they stand ON THE STRING: sequence, first index, count.

    Ordered by where the chapter actually starts, NEVER by curriculum_spine.json.
    The two disagree right now: the generated order still carries array_tutorial
    (31 artifacts at index 97, between transformation and color), which was
    dissolved into color on 2026-08-24 and is no longer one of the spine's 22.
    Listing the spine first and the strays after would draw that band at the far
    end of a necklace whose beads are sitting in the middle.
    """
    out = []
    for i, r in enumerate(rows):
        seq = r["sequence"]
        if out and out[-1]["sequence"] == seq:
            out[-1]["n"] += 1
            continue
        out.append({"sequence": seq, "i0": i, "n": 1,
                    # A GHOST CHAPTER IS NAMED. em_map_halls.py had to learn this
                    # from the other end - Palle walked past transformation
                    # expecting colour and met 13 halls of two dissolved
                    # chapters. The band still draws; it just says what it is.
                    "in_spine": seq in spine})
    return out


def build(reg=None, live=None, ops_doc=None, ops_state=None):
    """The whole answer: the effective order, its report, and everything the
    scene needs to draw it. Nothing here writes.

    ops_doc/ops_state are for two callers: the CLI, which has already loaded the
    hand and must not read it twice, and the keystroke guard, which rehearses a
    NOT-YET-WRITTEN op list to ask the replay whether the new op would be refused.
    """
    gen = read_json(GEN)
    if not isinstance(gen, dict) or not isinstance(gen.get("order"), list):
        raise SystemExit("FATAL: %s is missing or unreadable - run "
                         "`python tools/build_spine_artifact_order.py`"
                         % os.path.relpath(GEN, ROOT).replace("\\", "/"))
    if ops_doc is None:
        ops_doc, ops_state = load_ops()
    if ops_state is None:
        ops_state = ST_OK
    ops = [o for o in ops_doc.get("ops", []) if isinstance(o, dict)]
    spine = spine_sequences()
    if reg is None:
        reg = registry()
    if live is None:
        live = live_index(reg)

    rows, rep, counts = replay(gen.get("order", []), ops, live, spine)

    base_stamp = str(gen.get("_meta", {}).get("generated", ""))
    declared_base = str(ops_doc.get("_meta", {}).get("base_generated", ""))
    if ops and declared_base and declared_base != base_stamp:
        # DRIFT IS ANNOUNCED, NEVER SILENT - the same field /api/spine-order
        # stamps. It is not a failure: an op list is built to survive exactly
        # this. It is the sentence that tells a curator why an anchor moved.
        rep.notes.append("the ops were written against a generated order stamped "
                         "%s; the generated order is now %s - every op below was "
                         "replayed against the new one" % (declared_base, base_stamp))

    # contiguity: a chapter must occupy ONE run, or the museum walks into a
    # building twice. Only reachable through a hand-edited ops file, which is
    # exactly why it is checked rather than assumed.
    seen_runs = {}
    for i, r in enumerate(rows):
        s = r["sequence"]
        if s in seen_runs and seen_runs[s] != i - 1:
            rep.refused.append("chapter %s is split: it resumes at row %d after "
                               "row %d - the hand file has been edited by "
                               "something that does not keep chapters contiguous"
                               % (s, i, seen_runs[s]))
        seen_runs[s] = i

    order_out = []
    chapters = chapters_of(rows, spine)
    ghosts = sorted({c["sequence"] for c in chapters if not c["in_spine"]})
    for g in ghosts:
        rep.notes.append("chapter %s is in the order (%d artifacts) but not in "
                         "curriculum_spine.json - it was dissolved and the "
                         "generated order has not been rebuilt since; rerun "
                         "tools/build_spine_artifact_order.py to retire the band"
                         % (g, sum(1 for r in rows if r["sequence"] == g)))
    seq_total = {}
    for r in rows:
        seq_total[r["sequence"]] = seq_total.get(r["sequence"], 0) + 1
    seq_seen = {}
    for r in rows:
        s = r["sequence"]
        seq_seen[s] = seq_seen.get(s, 0) + 1
        facts = token_facts(r["lookup"], reg, live)
        row = {"lookup": r["lookup"], "sequence": s, "map": r["map"],
               "origin": r["origin"],
               "seq_i": seq_seen[s] - 1,
               "seq_n": seq_total[s]}
        if r.get("why"):
            row["why"] = r["why"]
        row.update(facts)
        order_out.append(row)

    in_order = {r["lookup"] for r in rows}
    candidates = []
    for token in sorted(live):
        if token in in_order:
            continue
        facts = token_facts(token, reg, live)
        entry = reg.get(token) or {}
        seqs = entry.get("map_sequences") or entry.get("sequences") or []
        candidates.append({
            "lookup": token,
            # A HINT, NOT A CHAPTER. The curator picks the chapter when they add;
            # this is only what the registry says the token is used by, so the
            # palette can default to the focused bead's chapter instead of
            # opening on 1,858 rows.
            "hint_sequences": [str(s) for s in seqs if str(s)][:6],
            "category": facts["category"], "scene": facts["scene"],
            "root": facts["root"], "body": facts["body"],
            "fp": facts["fp"], "size_m": facts["size_m"], "desc": facts["desc"],
        })

    dead = [r["lookup"] for r in order_out if not r["alive"]]
    nonbody = [r["lookup"] for r in order_out if r["alive"] and not r["body"]]

    doc = {
        "schema": SCHEMA,
        "_readme": (
            "THE EFFECTIVE ORDER - the generated spine order with "
            "commons/data/spine_order_ops.json replayed over it. DERIVED: never "
            "hand-edit this file, edit the ops. The Godot necklace scene reads "
            "this and writes ops; `python tools/necklace_order.py --apply` "
            "rebuilds it; `--check` gates it."
        ),
        "_meta": {
            "generated": time.strftime("%Y-%m-%d %H:%M:%S"),
            "generator": "tools/necklace_order.py",
            "base_generated": base_stamp,
            "base_artifacts": len(gen.get("order", [])),
            "ops_file": "commons/data/spine_order_ops.json",
            # THREE STATES, NOT TWO. write_outputs gates the deletion of the
            # museum's hand file on this, and only "absent" or "ok" may reach it -
            # a damaged hand aborted in load_ops long before here.
            "ops_state": ops_state,
            "ops_exists": ops_state == ST_OK,
            "ops_revision": _int_or(ops_doc.get("_meta", {}).get("ops_revision"), 0),
            "ops_digest": ops_digest(ops),
            "ops_total": len(ops),
            "ops_applied": len(rep.applied),
            "ops_stale": len(rep.stale),
            "ops_refused": len(rep.refused),
            "ops_degraded": len(rep.degraded),
            "added": counts["add"], "removed": counts["remove"], "moved": counts["move"],
            "artifacts": len(order_out),
            "alive": sum(1 for r in order_out if r["alive"]),
            "dead": len(dead),
            "non_body_roots": nonbody,
            "sequences": len(chapters),
            "candidates": len(candidates),
            # SAID OUT LOUD, because silence here is the failure this project
            # keeps writing memory files about. endless_museum.gd:27 defaults to
            # a PLAN (ada_run/em_plan.json, 210 rows carrying their own tokens);
            # the dealing order only decides what a template hall receives. So a
            # hand edit reaches the museum's POOL immediately and reaches a
            # planned hall only after the plan is rebuilt - and no planner reads
            # the hand file today.
            "plan_note": ("the museum's shipped default is plan mode "
                          "(endless_museum.gd:27 -> ada_run/em_plan.json); this "
                          "order deals template halls now, and planned halls only "
                          "after the plan is regenerated"),
        },
        "_report": rep.as_dict(),
        "chapters": chapters,
        "order": order_out,
        "candidates": candidates,
    }
    return doc, rep


def hand_doc(doc):
    """The museum's copy, in /api/spine-order's exact shape.

    endless_museum.gd:120 declares this path and :2324 reads it FIRST when it
    exists. That file may not be edited, so the shape is not ours to choose:
    _meta with provenance/derived_from_generated, and rows of {lookup, sequence,
    map}. `origin` rides along on hand rows only - the museum ignores unknown
    keys, and the web editor's GET spreads the row, so the extra field is
    visible there rather than lost.
    """
    gen_n = int(doc["_meta"]["base_artifacts"])
    rows = []
    for r in doc["order"]:
        row = {"lookup": r["lookup"], "sequence": r["sequence"], "map": r["map"]}
        if r["origin"] != "spine":
            row["origin"] = r["origin"]
        rows.append(row)
    return {
        "_meta": {
            "generated": doc["_meta"]["generated"],
            "generator": "tools/necklace_order.py (the necklace's hand)",
            "provenance": "hand",
            "rule": "the curator's dealing order; a token absent here is not dealt",
            "derived_from_generated": doc["_meta"]["base_generated"],
            "note": "derived from commons/data/spine_order_ops.json - edit the ops, not this file",
            "artifacts": len(rows),
            "dropped": max(0, gen_n - sum(1 for r in doc["order"] if r["origin"] != "hand")),
            "added": doc["_meta"]["added"],
            "ops_revision": doc["_meta"]["ops_revision"],
        },
        "order": rows,
    }


# --------------------------------------------------------------------------
# writing


def write_outputs(doc):
    state = str(doc.get("_meta", {}).get("ops_state", ""))
    if state not in (ST_ABSENT, ST_OK):
        # THE GATE ON THE DELETION. Reachable only if some future caller builds a
        # document without going through load_ops. The deletion below is the
        # single most destructive thing this tool does - it removes the file
        # endless_museum.gd:2324 reads FIRST - and it used to fire on
        # added == removed == moved == 0, a condition a MISREAD ops file
        # guarantees. It is never allowed to fire on a state nobody parsed.
        raise SystemExit(
            "FATAL: refusing to derive anything from an ops file in state %r. "
            "Only %r (there is no hand) or %r (the hand was read and parsed) may "
            "reach the outputs, because the branch below DELETES %s."
            % (state, ST_ABSENT, ST_OK, _rel(HAND)))

    written = []
    # Compact: 810 rows plus ~1,850 candidates at indent 1 is over a megabyte of
    # whitespace for a file only a machine opens.
    write_json_atomic(EFFECTIVE, doc, indent=None)
    written.append(EFFECTIVE)

    if doc["_meta"]["ops_total"] == 0 or (doc["_meta"]["added"] == 0
                                          and doc["_meta"]["removed"] == 0
                                          and doc["_meta"]["moved"] == 0):
        # NO HAND, NO HAND FILE - and this is the most important branch here.
        # With nothing to say, a derived hand file is a 810-row SNAPSHOT of
        # today's curriculum, and endless_museum.gd:2324 prefers it forever.
        # Every artifact added to any of the 261 maps after that moment would be
        # invisible to the museum with no error anywhere. Removing the file
        # returns the museum to the generated order, which follows regeneration.
        #
        # THE COUNTS ARE ONLY TRUSTWORTHY BECAUSE THE STATE IS. Zero here now
        # means one of exactly two things - there is no ops file at all, or there
        # is one, it parsed, and its ops genuinely changed nothing. It can no
        # longer mean "the ops file is three ops of hand work that this tool
        # failed to read", which is the reading under which this line deleted the
        # museum's copy and --check then certified the result.
        if os.path.exists(HAND):
            os.remove(HAND)
            written.append("(removed) " + HAND)
        return written, False

    write_json_atomic(HAND, hand_doc(doc), indent=1)
    written.append(HAND)
    return written, True


def strip_stamp(d):
    """A copy without the wall-clock stamps, so --check compares CONTENT."""
    out = json.loads(json.dumps(d))
    for path in (("_meta", "generated"),):
        node = out
        for k in path[:-1]:
            node = node.get(k, {})
        node.pop(path[-1], None)
    return out


def diff_docs(fresh, have, limit=15):
    """Where the written file and a fresh derivation disagree, most-load-bearing
    first: the counts, then the chapter bands, then the row."""
    out = []
    a, b = strip_stamp(fresh), strip_stamp(have)
    if a.get("schema") != b.get("schema"):
        out.append("schema: file %r, sources %r" % (b.get("schema"), a.get("schema")))
    # The UNION of the keys, not the fresh document's. A written file carrying a
    # key the builder no longer emits is a file from an older version of this
    # tool, and comparing only the new keys would call it identical.
    for k in sorted(set(a.get("_meta", {})) | set(b.get("_meta", {}))):
        if a.get("_meta", {}).get(k) != b.get("_meta", {}).get(k):
            out.append("_meta.%s: file %r, sources %r"
                       % (k, b.get("_meta", {}).get(k), a.get("_meta", {}).get(k)))
    ac, bc = a.get("chapters", []), b.get("chapters", [])
    if len(ac) != len(bc):
        out.append("chapters: file %d, sources %d" % (len(bc), len(ac)))
    for x, y in zip(bc, ac):
        if x != y:
            out.append("chapter %s: file %r, sources %r" % (y.get("sequence"), x, y))
    ao, bo = a.get("order", []), b.get("order", [])
    if len(ao) != len(bo):
        out.append("order rows: file %d, sources %d" % (len(bo), len(ao)))
    for i, (x, y) in enumerate(zip(bo, ao)):
        if x.get("lookup") != y.get("lookup"):
            out.append("row %d: file %s, sources %s" % (i, x.get("lookup"), y.get("lookup")))
        elif x != y:
            keys = sorted(set(x) | set(y))
            for k in keys:
                if x.get(k) != y.get(k):
                    out.append("row %d %s.%s: file %r, sources %r"
                               % (i, y.get("lookup"), k, x.get(k), y.get(k)))
    if len(a.get("candidates", [])) != len(b.get("candidates", [])):
        out.append("candidates: file %d, sources %d"
                   % (len(b.get("candidates", [])), len(a.get("candidates", []))))
    return out[:limit], len(out)


# --------------------------------------------------------------------------
# the command line


def summary(doc, rep):
    m = doc["_meta"]
    print()
    print("  #  chapter                  from     n  added  moved   dead")
    for n, c in enumerate(doc["chapters"], 1):
        rows = doc["order"][c["i0"]:c["i0"] + c["n"]]
        print("  %2d  %-22s %5d %5d %6d %6d %6d%s"
              % (n, c["sequence"], c["i0"], c["n"],
                 sum(1 for r in rows if r["origin"] == "hand"),
                 sum(1 for r in rows if r["origin"] == "moved"),
                 sum(1 for r in rows if not r["alive"]),
                 "" if c["in_spine"] else "   not in the spine"))
    print("      %-22s %5s %5d %6d %6d %6d"
          % ("TOTAL", "", m["artifacts"], m["added"], m["moved"], m["dead"]))
    print()
    print("  base %s (%d artifacts) + %d op(s) rev %d [%s]  ops file: %s"
          % (m["base_generated"], m["base_artifacts"], m["ops_total"],
             m["ops_revision"], m["ops_digest"],
             "ABSENT - the generated order stands unedited"
             if m["ops_state"] == ST_ABSENT else "read and parsed"))
    print("  effective: %d artifacts in %d chapters, %d alive, %d dead, %d add candidates"
          % (m["artifacts"], m["sequences"], m["alive"], m["dead"], m["candidates"]))
    if m["non_body_roots"]:
        print("  %d alive row(s) whose scene root is NOT a 3D node - the necklace "
              "must badge, not mount: %s"
              % (len(m["non_body_roots"]), ", ".join(m["non_body_roots"])))
    for name, lines in (("APPLIED", rep.applied), ("DEGRADED", rep.degraded),
                        ("STALE", rep.stale), ("REFUSED", rep.refused),
                        ("NOTE", rep.notes)):
        for line in lines:
            print("  %-8s %s" % (name, line))
    print()
    print("  %s" % m["plan_note"])


def find_op_targets(ops, verb, token):
    return [i for i, o in enumerate(ops)
            if str(o.get("op")) == verb and str(o.get("lookup")) == token]


def main():
    ap = argparse.ArgumentParser(
        description="the spine's dealing order, with the curator's hand replayed over it")
    ap.add_argument("--apply", action="store_true",
                    help="write commons/data/spine_order_effective.json and the museum's hand file")
    ap.add_argument("--check", action="store_true",
                    help="verify the written outputs against the sources; non-zero on any disagreement")
    ap.add_argument("--init", action="store_true",
                    help="create an empty ops file (refuses to overwrite one that exists)")
    ap.add_argument("--json", action="store_true", help="print the effective document to stdout")
    ap.add_argument("--base", metavar="PATH", default=None,
                    help="replay the ops over a DIFFERENT generated order - the only way to "
                         "rehearse a regeneration before it happens; refuses --apply")
    ap.add_argument("--list-ops", action="store_true", help="print the ops file, numbered")
    ap.add_argument("--undo", type=int, metavar="N", default=None,
                    help="delete op N from the ops file")
    ap.add_argument("--add", metavar="TOKEN", help="add a token to the deal")
    ap.add_argument("--remove", metavar="TOKEN", help="drop a token from the deal")
    ap.add_argument("--move", metavar="TOKEN", help="reposition a token inside its chapter")
    ap.add_argument("--sequence", metavar="SEQ", help="the chapter an --add lands in")
    ap.add_argument("--after", metavar="LOOKUP")
    ap.add_argument("--before", metavar="LOOKUP")
    ap.add_argument("--first-in", metavar="SEQ", dest="first_in")
    ap.add_argument("--last-in", metavar="SEQ", dest="last_in")
    ap.add_argument("--why", metavar="TEXT", default="", help="the reason, kept in the file")
    args = ap.parse_args()

    if args.base:
        # REHEARSING A REGENERATION IS THE POINT OF AN OPS LAYER, so it has to be
        # possible to do without regenerating anything: point --base at a copy of
        # the generated order with the change you fear already in it, and read the
        # report. Never with --apply - a derived file built from a hypothetical
        # base is a lie that outlives the experiment, and the museum reads the
        # hand file first.
        if args.apply or args.init or args.undo is not None \
                or args.add or args.remove or args.move:
            print("--base is a rehearsal and writes nothing: no --apply, no --init, "
                  "no edit. A derived file built over a hypothetical order would be "
                  "read by the museum as the real one, and an op stamped with a "
                  "base that does not exist reports drift forever.", file=sys.stderr)
            return 1
        global GEN
        GEN = os.path.abspath(args.base)
        print("BASE: %s (rehearsal - nothing will be written)" % args.base)

    if args.init:
        if os.path.exists(OPS):
            # ANY existing file, including a damaged one. --init is not a repair:
            # over a truncated hand it would destroy the ops the .bak can still
            # give back. load_ops names the recovery route; this only refuses.
            print("%s already exists - refusing to overwrite the hand" % _rel(OPS),
                  file=sys.stderr)
            return 1
        doc = empty_ops()
        # Monotone even at --init: a file deleted after a loss and re-inited must
        # not restart the revision at 1 while the effective file still says 7.
        doc["_meta"]["ops_revision"] = revision_floor(doc["_meta"])
        write_json_atomic(OPS, doc, indent=1, keep_backup=True)
        print("wrote %s (0 ops, revision %d)" % (_rel(OPS), doc["_meta"]["ops_revision"]))
        return 0

    ops_doc, ops_state = load_ops()
    ops = [o for o in ops_doc.get("ops", []) if isinstance(o, dict)]
    ops_rev = _int_or(ops_doc.get("_meta", {}).get("ops_revision"), 0)

    if args.list_ops:
        # FOUR STATES NEVER AGAIN SHARE ONE SENTENCE. Absent and parsed-but-empty
        # are different facts about the world and they now read differently; the
        # other two never get here, because load_ops has already refused.
        if ops_state == ST_ABSENT:
            print("no ops FILE at %s - the effective order IS the generated "
                  "order. `--init` starts a hand." % _rel(OPS))
        elif not ops:
            print("%s parsed: 0 ops at revision %d - the effective order is the "
                  "generated order" % (_rel(OPS), ops_rev))
        else:
            print("%s: %d op(s) at revision %d" % (_rel(OPS), len(ops), ops_rev))
        for i, o in enumerate(ops):
            pos = " ".join("%s=%s" % (k, o[k]) for k in POSITIONS if o.get(k))
            print("  %2d  %-7s %-34s %-28s %s"
                  % (i, o.get("op"), o.get("lookup"), pos, o.get("why", "")))
        return 0

    edited = False
    reg = live = None      # the registry scan is ~2,600 scene stats; do it once
    if args.undo is not None:
        if not (0 <= args.undo < len(ops)):
            print("no op %d (the file holds %d)" % (args.undo, len(ops)), file=sys.stderr)
            return 1
        gone = ops.pop(args.undo)
        print("dropped op %d: %s %s" % (args.undo, gone.get("op"), gone.get("lookup")))
        edited = True

    verb_token = [(v, getattr(args, v)) for v in VERBS if getattr(args, v)]
    if len(verb_token) > 1:
        print("one edit at a time: %s" % ", ".join(v for v, _ in verb_token), file=sys.stderr)
        return 1
    if verb_token:
        verb, token = verb_token[0]
        op = {"op": verb, "lookup": token}
        if verb == "add":
            if not args.sequence:
                print("--add needs --sequence: the chapter is the museum building "
                      "the token is dealt into", file=sys.stderr)
                return 1
            op["sequence"] = args.sequence
        for clause in POSITIONS:
            v = getattr(args, clause)
            if v:
                op[clause] = v
        if args.why:
            op["why"] = args.why
        faults = op_faults(op, len(ops))
        if faults:
            for f in faults:
                print(f, file=sys.stderr)
            return 1
        reg = registry()
        live = live_index(reg)
        if verb == "add" and token not in live:
            # PRE-FLIGHT, not just replay. The replay refuses a dead add too, but
            # it refuses it again on every run forever - an op the file keeps and
            # nothing can ever honour is noise the curator has to re-read. Caught
            # at the keystroke it is a typo; caught at replay it is a mystery.
            print("--add %s: not alive by the museum's rule (a scene, map_ready "
                  "true, and the file on disk, endless_museum.gd:2139) - it would "
                  "be dealt and dropped, so the op is not written" % token,
                  file=sys.stderr)
            return 1
        # A REMOVE CANCELS AN ADD rather than stacking on it: the pair would
        # otherwise sit in the file forever, replayed on every run, and read as
        # two contradictory intentions.
        if verb == "remove":
            prior = find_op_targets(ops, "add", token)
            if prior:
                for i in reversed(prior):
                    ops.pop(i)
                print("removed %d earlier add(s) of %s instead of stacking a remove"
                      % (len(prior), token))
                edited = True
                verb = ""
        if verb:
            # THE CROSS-CHAPTER GUARD, IN THE PATH THAT WRITES. Liveness was
            # checked at the keystroke above; the chapter rule was not, so
            # `--move T --after <a token in another chapter>` used to be written
            # and then refused on every replay from then on - a permanently dead
            # op sitting in the file, which is the one thing an ops list must
            # never accumulate. There is no second copy of the rule here: the op
            # is rehearsed through the REAL replay and the real report is read.
            new_i = len(ops)
            probe_doc = dict(ops_doc)
            probe_doc["ops"] = ops + [op]
            _, probe_rep = build(reg, live, probe_doc, ops_state)
            said = probe_rep.by_op.get(new_i, {})
            if said.get("refused"):
                for line in said["refused"]:
                    print("REFUSED: %s" % line, file=sys.stderr)
                print("the op is NOT written - %s is byte-identical to what it was."
                      % _rel(OPS), file=sys.stderr)
                return 1
            for line in said.get("stale", []):
                print("WARN: %s" % line, file=sys.stderr)
            for line in said.get("degraded", []) + said.get("notes", []):
                print("NOTE: %s" % line)
            ops.append(op)
            print("op %d: %s %s" % (len(ops) - 1, op["op"], op["lookup"]))
            edited = True

    if edited:
        rev = write_ops(ops_doc, ops)
        print("wrote %s (%d op(s), revision %d)" % (_rel(OPS), len(ops), rev))

    if reg is None:
        reg = registry()
        live = live_index(reg)
    doc, rep = build(reg, live, ops_doc, ops_state)

    if args.json:
        # ASCII-ESCAPED ON STDOUT ONLY. The written files are utf-8 and keep
        # their characters; this stream does not, because Windows hands a
        # cp1252 stdout to a piped python and the first registry description
        # carrying a curly quote killed the dump mid-row at byte 11,987 - a
        # truncated document that still looks like JSON until it is parsed.
        json.dump(doc, sys.stdout, ensure_ascii=True, separators=(",", ":"))
        sys.stdout.write("\n")
        return 0

    if args.check and args.base:
        # A REHEARSAL HAS NO WRITTEN FILE TO COMPARE AGAINST. Diffing the real
        # derived file against a hypothetical base produces 842 lines of "these
        # two bases are different", which is true and useless, and it buries the
        # one line anybody rehearses for. So --check --base gates the OPS alone:
        # would this regeneration break the hand?
        for line in rep.stale:
            print("STALE: %s" % line, file=sys.stderr)
        for line in rep.refused:
            print("REFUSED: %s" % line, file=sys.stderr)
        for line in rep.degraded:
            print("WARN degraded: %s" % line)
        if rep.stale or rep.refused:
            print("rehearsal FAILED: %d op(s) would go stale and %d would be refused "
                  "against %s - fix them before that order is real"
                  % (len(rep.stale), len(rep.refused), args.base), file=sys.stderr)
            return 1
        print("rehearsal OK: all %d op(s) still apply against %s (%d degraded)"
              % (doc["_meta"]["ops_total"], args.base, len(rep.degraded)))
        return 0

    if args.check:
        # A GATE MUST REFUSE TO CERTIFY WHAT IT COULD NOT READ. The ops file is
        # already handled - load_ops raised before we got here if it was damaged,
        # which is the first half of "exit non-zero when the ops file exists and
        # did not parse". These two are the same rule for the derived files: a
        # tolerant read returned None for both "absent" and "shredded", so a
        # corrupt hand file that the museum reads FIRST scored a silent pass.
        have, have_state = read_json_state(EFFECTIVE)
        if have_state == ST_ABSENT:
            print("MISSING: %s - run `python tools/necklace_order.py --apply`"
                  % _rel(EFFECTIVE), file=sys.stderr)
            return 2
        if have_state != ST_OK or not isinstance(have, dict):
            print("UNREADABLE: %s is %s - it cannot be checked, only rebuilt. Run "
                  "`python tools/necklace_order.py --apply`."
                  % (_rel(EFFECTIVE), have_state), file=sys.stderr)
            return 1
        # THE REVISION MUST NOT HAVE TRAVELLED BACKWARDS. Ordinary staleness is
        # ops > effective and shows up in the diff below as one _meta line. The
        # OTHER direction is not staleness: it means the ops file was rewritten
        # from a lower number than a derivation has already seen, which is the
        # signature of the hand having been lost and restarted.
        derived_rev = _int_or(have.get("_meta", {}).get("ops_revision"), 0)
        now_rev = _int_or(doc["_meta"].get("ops_revision"), 0)
        regression = []
        if now_rev < derived_rev:
            regression.append(
                "the ops file is at revision %d but %s was derived from revision "
                "%d - the revision has TRAVELLED BACKWARDS. The hand was lost and "
                "rewritten from a lower number; %d op-revision(s) of curation are "
                "unaccounted for. Look at %s before doing anything else."
                % (now_rev, _rel(EFFECTIVE), derived_rev, derived_rev - now_rev,
                   _rel(OPS + ".bak")))
        for line in regression:
            print("REGRESSION: %s" % line, file=sys.stderr)
        shown, total = diff_docs(doc, have)
        for line in shown:
            print("DIFF: %s" % line, file=sys.stderr)
        if total > len(shown):
            print("DIFF: ... and %d more" % (total - len(shown)), file=sys.stderr)
        # The museum's copy is checked as a FILE, not assumed from the builder:
        # its presence is a claim ("the hand has something to say") and its
        # absence is a claim too ("follow the generated order"), and a stale one
        # either way is the snapshot trap.
        wants_hand = doc["_meta"]["added"] or doc["_meta"]["removed"] or doc["_meta"]["moved"]
        hand_have, hand_state = read_json_state(HAND)
        hand_faults = []
        if hand_state not in (ST_ABSENT, ST_OK) or (
                hand_state == ST_OK and not isinstance(hand_have, dict)):
            # A DAMAGED HAND FILE IS NOT AN ABSENT ONE. endless_museum.gd:2324
            # reads this path FIRST when it EXISTS, so a shredded file here is a
            # museum that deals nothing, and the tolerant read this used to do
            # scored it as "no file, no hand edits, fine".
            hand_faults.append("%s exists and is %s - the museum reads this path "
                               "FIRST when it exists, so it must be a document or "
                               "not be there. Re-derive it with --apply."
                               % (_rel(HAND), hand_state if hand_state != ST_OK
                                  else "not an object"))
        elif wants_hand and hand_state == ST_ABSENT:
            hand_faults.append("%s is missing but the hand has %d add / %d remove / "
                               "%d move to say"
                               % (_rel(HAND), doc["_meta"]["added"],
                                  doc["_meta"]["removed"], doc["_meta"]["moved"]))
        elif not wants_hand and hand_state == ST_OK:
            hand_faults.append("%s exists with no hand edits behind it - the museum "
                               "would deal a frozen snapshot of today's curriculum"
                               % _rel(HAND))
        elif wants_hand:
            fresh = hand_doc(doc)
            if [r["lookup"] for r in fresh["order"]] != \
                    [str(r.get("lookup")) for r in (hand_have.get("order") or [])]:
                hand_faults.append("%s disagrees with the ops"
                                   % os.path.relpath(HAND, ROOT).replace("\\", "/"))
        for f in hand_faults:
            print("HAND: %s" % f, file=sys.stderr)
        for line in rep.stale:
            print("STALE: %s" % line, file=sys.stderr)
        for line in rep.refused:
            print("REFUSED: %s" % line, file=sys.stderr)
        bad = (total + len(hand_faults) + len(rep.stale) + len(rep.refused)
               + len(regression))
        if bad:
            print("check FAILED: %d disagreement(s) with the sources, %d hand fault(s), "
                  "%d stale op(s), %d refused op(s), %d revision regression(s)"
                  % (total, len(hand_faults), len(rep.stale), len(rep.refused),
                     len(regression)),
                  file=sys.stderr)
            return 1
        for line in rep.degraded:
            print("WARN degraded: %s" % line)
        m = doc["_meta"]
        # The ops STATE is in the pass line, because "0 ops" and "no ops file" are
        # different certifications and this line used to make them the same one.
        print("check OK: %d artifacts (%d added, %d removed, %d moved) from %d ops "
              "rev %d [ops file: %s] over a base stamped %s; %d dead, %d degraded op(s)"
              % (m["artifacts"], m["added"], m["removed"], m["moved"], m["ops_total"],
                 m["ops_revision"], m["ops_state"], m["base_generated"], m["dead"],
                 len(rep.degraded)))
        return 0

    summary(doc, rep)

    if not args.apply:
        print()
        print("  nothing derived. --apply to write %s (+ the museum's hand file)"
              % os.path.relpath(EFFECTIVE, ROOT).replace("\\", "/"))
        return 0

    written, hand_written = write_outputs(doc)
    print()
    for p in written:
        name = p.replace(ROOT + os.sep, "").replace("\\", "/")
        if p.startswith("(removed) "):
            print("  removed %s" % p[len("(removed) "):].replace(ROOT + os.sep, "").replace("\\", "/"))
        else:
            print("  wrote %s (%.1f KB)" % (name, os.path.getsize(p) / 1024.0))
    if not hand_written:
        print("  no hand file: with no edits it would be a frozen snapshot and the "
              "museum reads it first - the generated order stays in charge")
    return 0


if __name__ == "__main__":
    sys.exit(main())
