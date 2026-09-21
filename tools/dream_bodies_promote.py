#!/usr/bin/env python3
"""
dream_bodies_promote.py — turn each dream-body builder into its own DNA artifact.

2026-08-29, Palle: "make all these DNA artifacts (see dna galleries) and make them
galleries with surreal variation that do not hold back."

THE PROBLEM THIS SOLVES. The forty-one builders under
commons/artifacts/dream_bodies/bodies/ are static functions behind ONE artifact whose
only axis is `figure`. The DNA sweep (tools/cabinet_sweep.py -> capture_config_sweep.gd)
does not call functions: it SETS EXPORTED PROPERTIES on a scene's root before _ready and
reads them back, and it refuses any axis it cannot reach. So a family with its own axes
needs its own scene carrying its own exports.

DERIVED, NEVER TRANSCRIBED. Each builder declares its axes in code:

    static func axes() -> Dictionary:
        return {
            "skin": ["wave", "scale", "molten"],
            "pose": ["kneel", "arch"],
        }

This tool PARSES that literal and writes, per family:

    commons/artifacts/dream_bodies/figures/<key>.gd     a Node3D with one @export_enum
                                                        per axis, plus seed, calling the
                                                        builder with opts
    commons/artifacts/dream_bodies/figures/<key>.tscn   the scene the sweep loads
    commons/artifacts/registry/dream_figures.json       one token per family, dna.axes
                                                        taken from the same parse

so the registry cannot disagree with the code — the failure CLAUDE.md records for
science_screen, where a hand-typed block declared four values the enum had never heard of
and the sweep published sixteen identical frames.

IT ALSO REWRITES THE PARENT'S TWO LISTS (added 2026-09-03). dream_bodies.gd carried the
family names TWICE by hand — a FIGURES const and an @export_enum — and both had drifted to
37 names while 42 builders sat on disk. The five it never mentioned (botanic_mannequin,
clay_splash, deity_figurine, fetish_idol, type_wrap) were unreachable from any map token,
and nothing said so, because apply_grid_config declined an unknown name in silence. Same
glob, same sorted order, spliced in surgically: a new builder is now reachable the moment
this tool runs, and the artifact's own startup check names the gap until it does.

Sorted, not appended, is safe HERE and was checked before it was done: nothing in the repo
stores `figure` as an enum INDEX. No .tscn writes a `figure` property at all (the per-family
scenes carry their own axes instead), commons/maps has no dream_bodies token, the museum
passes {"figure": "<name>"} as a string, and ada_run/em_inventory.json records the family in
its id as "dream:<name>". Every int-valued "figure" key in the repo belongs to a different
artifact's axis-count table. If that ever changes, APPEND instead — inserting a name in the
middle would silently re-point every stored index.

Usage:
  python tools/dream_bodies_promote.py            # write scenes + registry + parent lists
  python tools/dream_bodies_promote.py --check    # report only, write nothing; exit 1 if
                                                  # the parent's lists are out of sync
"""
from __future__ import annotations
import ast
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
BODIES = REPO / "commons" / "artifacts" / "dream_bodies" / "bodies"
FIGURES = REPO / "commons" / "artifacts" / "dream_bodies" / "figures"
REGISTRY = REPO / "commons" / "artifacts" / "registry" / "dream_figures.json"
PARENT = REPO / "commons" / "artifacts" / "dream_bodies" / "dream_bodies.gd"

# THE TWO ANCHORS in dream_bodies.gd. Both are asserted to match EXACTLY ONCE before
# anything is written: a splice that quietly matches zero times would leave the file
# untouched and still print success, and one that matched twice would rewrite whichever
# block it hit first. Either way the tool would be lying, which is the whole failure
# class it exists to close. `$` with re.M ends the match at the line the block closes on,
# so the non-greedy `.*?` cannot run past the statement into the rest of the file.
FIGURES_ANCHOR = re.compile(r"^const FIGURES: Array\[String\] = \[.*?\]$", re.S | re.M)
ENUM_ANCHOR = re.compile(r'^@export_enum\(.*?\) var figure: String = "([a-z0-9_]+)"$', re.S | re.M)
# Continuation lines in that file run 75-86 columns with the leading tab counted as one.
# Wrapping at 88 reproduces its shape; both blocks take the SAME break points, as the
# hand-written original did, so the two lists stay diffable against each other by eye.
WRAP_COLS = 88

AXES_RE = re.compile(r"static\s+func\s+axes\s*\(\s*\)\s*->\s*Dictionary\s*:(.*?)(?=\nstatic\s|\nfunc\s|\Z)", re.S)
# THE PREDICTION IS DATA TOO. CLAUDE.md's rule is to name the closest pair, the
# number and the arithmetic BEFORE the capture and write it into the registry as
# dna.predicted_degeneracy. A builder that declares predicted() has it carried
# across by the same parse that carries axes(), so nobody retypes a measurement
# into JSON — which is the whole reason this tool exists.
PRED_RE = re.compile(r"static\s+func\s+predicted\s*\(\s*\)\s*->\s*Dictionary\s*:(.*?)(?=\nstatic\s|\nfunc\s|\Z)", re.S)


def parse_axes(src: str) -> dict:
    """The axes() literal, read as data. Returns {} when the function is absent."""
    m = AXES_RE.search(src)
    if not m:
        return {}
    body = m.group(1)
    i = body.find("{")
    if i < 0:
        return {}
    depth = 0
    for j in range(i, len(body)):
        if body[j] == "{":
            depth += 1
        elif body[j] == "}":
            depth -= 1
            if depth == 0:
                lit = body[i:j + 1]
                break
    else:
        return {}
    # GDScript dictionary literals of string keys and string arrays are valid Python
    # literals once trailing commas are allowed (they are) — so this is a parse, not a
    # regex guess at the values.
    try:
        out = ast.literal_eval(lit)
    except Exception as e:  # noqa: BLE001
        raise SystemExit(f"axes() literal did not parse: {e}\n{lit[:400]}")
    clean = {}
    for k, v in out.items():
        if isinstance(k, str) and isinstance(v, (list, tuple)) and all(isinstance(x, str) for x in v):
            if len(v) >= 2:
                clean[k] = list(v)
    return clean


# GDScript keywords and builtins that cannot be a variable name. An axis named for
# one of them generates a scene that will not parse — paik_light declared `signal`
# and its scene died on "Expected variable name after var", which is a fact about
# the generator, not about the artifact. Caught here, at the parse, with the name.
RESERVED = {
    "signal", "func", "var", "const", "class", "class_name", "extends", "enum", "if",
    "elif", "else", "for", "while", "match", "break", "continue", "pass", "return",
    "and", "or", "not", "in", "is", "as", "self", "super", "true", "false", "null",
    "void", "static", "await", "yield", "assert", "breakpoint", "preload", "export",
    "onready", "tool", "when", "namespace", "trait", "name", "position", "rotation",
    "scale", "transform", "basis", "owner", "script", "seed",
}


def parse_predicted(src: str) -> dict:
    """The predicted() literal, read as data.

    GDScript joins long strings across lines with `+`, which is not a Python
    literal, so adjacent string pieces are folded before the parse.
    """
    m = PRED_RE.search(src)
    if not m:
        return {}
    body = m.group(1)
    i = body.find("{")
    if i < 0:
        return {}
    depth, lit = 0, ""
    for j in range(i, len(body)):
        if body[j] == "{":
            depth += 1
        elif body[j] == "}":
            depth -= 1
            if depth == 0:
                lit = body[i:j + 1]
                break
    if not lit:
        return {}
    folded = re.sub(r'"\s*\n?\s*\+\s*\n?\s*"', "", lit)
    try:
        out = ast.literal_eval(folded)
    except Exception:  # noqa: BLE001
        return {}
    return out if isinstance(out, dict) else {}


def wrap_names(keys: list[str], indent: str = "\t") -> list[str]:
    """Break the name list into source lines the way dream_bodies.gd already breaks it.

    Greedy fill to WRAP_COLS, counting the leading tab as one column (which is how the
    existing lines measure). Returns the lines WITHOUT the indent — the callers add it,
    because the first line of each block carries a different prefix.
    """
    groups: list[list[str]] = []
    cur: list[str] = []
    width = len(indent)
    for k in keys:
        tok = '"%s",' % k
        if cur and width + 1 + len(tok) > WRAP_COLS:
            groups.append(cur)
            cur, width = [], len(indent)
        width += (1 if cur else 0) + len(tok)
        cur.append(tok)
    if cur:
        groups.append(cur)
    groups[-1][-1] = groups[-1][-1].rstrip(",")  # no trailing comma before ] or )
    return [" ".join(g) for g in groups]


def _rel(p: Path) -> str:
    """Repo-relative when it can be, absolute otherwise.

    Path.relative_to RAISES on a path outside the repo, and these paths are only ever
    formatted into failure messages — so the plain call turned "the anchor is broken"
    into a ValueError traceback that never named the anchor. Found by the negative test,
    which repoints PARENT at a scratchpad copy. A message that throws while reporting a
    fault is worse than no message.
    """
    try:
        return str(p.relative_to(REPO))
    except ValueError:
        return str(p)


def rewrite_parent(keys: list[str], check: bool) -> bool:
    """Rewrite FIGURES and the @export_enum in dream_bodies.gd from the same glob.

    Returns True when the file already agreed (or now does). Raises loudly rather than
    writing a half-understood file: an anchor that does not match exactly once means the
    parent has been restructured and this generator no longer knows where its own output
    goes — better a stopped tool than a silently skipped stage.
    """
    src = PARENT.read_text(encoding="utf-8")
    figs = FIGURES_ANCHOR.findall(src)
    enums = ENUM_ANCHOR.findall(src)
    if len(figs) != 1:
        raise SystemExit(
            "ANCHOR FAILED: 'const FIGURES: Array[String] = [...]' matched %d times in %s "
            "(want exactly 1). The parent has been restructured; fix the anchor in "
            "%s before trusting anything this tool writes."
            % (len(figs), _rel(PARENT), Path(__file__).name))
    if len(enums) != 1:
        raise SystemExit(
            "ANCHOR FAILED: '@export_enum(...) var figure: String = \"...\"' matched %d times "
            "in %s (want exactly 1). See the note above."
            % (len(enums), _rel(PARENT)))

    default = enums[0]
    if default not in keys:
        # The default is not ours to choose, but it MUST survive the rewrite: an enum
        # whose default is not one of its own values gives the inspector a blank field
        # and the guard a name it will decline.
        raise SystemExit(
            "the parent defaults to figure=\"%s\", which has no builder in %s — either the "
            "default is stale or a builder was deleted; this tool will not write a list that "
            "excludes the running default." % (default, _rel(BODIES)))

    lines = wrap_names(keys)
    tail = "".join("\n\t" + ln for ln in lines[1:])
    figures_block = "const FIGURES: Array[String] = [" + lines[0] + tail + "]"
    enum_block = "@export_enum(" + lines[0] + tail + ') var figure: String = "%s"' % default

    # repl as a callable, so a name containing a backslash or \g could never be read as
    # a group reference. count=1 is belt-and-braces on top of the exactly-once assert.
    out = FIGURES_ANCHOR.sub(lambda _m: figures_block, src, count=1)
    out = ENUM_ANCHOR.sub(lambda _m: enum_block, out, count=1)

    was = re.findall(r'"([a-z0-9_]+)"', figs[0])
    if out == src:
        print("parent lists already in sync: %d name(s)" % len(keys))
        return True
    if check:
        print("OUT OF SYNC: %s carries %d name(s), %d builder(s) on disk"
              % (_rel(PARENT), len(was), len(keys)))
        gap = sorted(set(keys) - set(was))
        if gap:
            print("  unreachable from any map token: " + ", ".join(gap))
        stale = sorted(set(was) - set(keys))
        if stale:
            print("  named but no builder on disk: " + ", ".join(stale))
        return False
    PARENT.write_text(out, encoding="utf-8")
    print("rewrote FIGURES + @export_enum in %s: %d -> %d name(s), sorted, default=%s"
          % (_rel(PARENT), len(was), len(keys), default))
    return True


def builder_arity(src: str) -> int:
    m = re.search(r"static\s+func\s+build\s*\(([^)]*)\)", src)
    if not m:
        return 0
    return len([a for a in m.group(1).split(",") if a.strip()])


SCRIPT_TMPL = '''extends Node3D

## {key} — one dream body as its own DNA artifact (generated by
## tools/dream_bodies_promote.py; edit the builder, not this file).
##
## The sweep sets EXPORTED PROPERTIES on a scene root before _ready and reads them
## back; it cannot call a function. So each family gets this thin scene, whose
## exports are exactly the axes its builder declares in axes(), and whose _ready
## hands them to the builder as opts.
##
## Axes: {axis_line}

const BUILDER := preload("res://commons/artifacts/dream_bodies/bodies/{key}.gd")

{exports}
@export var seed: int = 1


func apply_grid_config(config: Dictionary) -> void:
{cfg}
	if config.has("seed"):
		seed = int(config.get("seed", 1))
	if is_inside_tree():
		_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	var root := Node3D.new()
	root.name = "Body"
	add_child(root)
	BUILDER.build(root, seed, {{{opts}}})
'''

SCENE_TMPL = '''[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://commons/artifacts/dream_bodies/figures/{key}.gd" id="1_{key}"]

[node name="{node}" type="Node3D"]
script = ExtResource("1_{key}")
'''


def node_name(key: str) -> str:
    return "".join(p.capitalize() for p in key.split("_"))


def main() -> int:
    check = "--check" in sys.argv
    keys = sorted(p.stem for p in BODIES.glob("*.gd"))
    rows, missing, bad = {}, [], []
    preds: dict = {}
    arity: dict[str, int] = {}
    for key in keys:
        src = (BODIES / f"{key}.gd").read_text(encoding="utf-8")
        axes = parse_axes(src)
        ar = builder_arity(src)
        arity[key] = ar
        if not axes:
            missing.append(key)
            continue
        if ar != 3:
            bad.append(f"{key}: build() takes {ar} args, want 3 (root, seed, opts)")
            continue
        clash = sorted(n for n in axes if n in RESERVED)
        if clash:
            bad.append(f"{key}: axis name(s) {', '.join(clash)} are GDScript keywords — "
                       "the generated scene would not parse; rename in the builder")
            continue
        rows[key] = axes
        preds[key] = parse_predicted(src)

    print(f"{len(rows)} builder(s) declare axes; {len(missing)} without; {len(bad)} malformed")
    if missing:
        print("  no axes(): " + ", ".join(missing))
    for b in bad:
        print("  " + b)

    # FIGURES gets the WHOLE directory, not just the families with axes. The artifact's
    # own startup check diffs FIGURES against exactly this listing, so a filtered list
    # would make that gate warn on every boot about names it was never going to carry.
    # A stray .gd here with no build() is therefore listed too — and said out loud, since
    # a map naming it gets past the guard and then finds nothing to build.
    nobuild = [k for k in keys if arity.get(k, 0) == 0]
    if nobuild:
        print("  WARNING: no static build() in " + ", ".join(nobuild)
              + " — listed in FIGURES anyway (the artifact's disk check compares against the "
                "whole directory), so the guard accepts the name and _build() warns instead")
    synced = rewrite_parent(keys, check)

    if check:
        for k, ax in rows.items():
            print(f"  {k}: " + "; ".join(f"{n}({len(v)})" for n, v in ax.items()))
        # Exit 1 on drift, so --check is a GATE and not a paragraph nobody reads.
        return 0 if synced else 1
    if not rows:
        return 1

    FIGURES.mkdir(parents=True, exist_ok=True)
    for key, axes in rows.items():
        exports, cfg, opts = [], [], []
        for name, vals in axes.items():
            enum = ", ".join(f'"{v}"' for v in vals)
            exports.append(f'@export_enum({enum}) var {name}: String = "{vals[0]}"')
            cfg.append(f'\tif config.has("{name}"):\n\t\t{name} = String(config.get("{name}", "{vals[0]}"))')
            opts.append(f'"{name}": {name}')
        axis_line = "; ".join(f"{n} ({', '.join(v)})" for n, v in axes.items())
        (FIGURES / f"{key}.gd").write_text(SCRIPT_TMPL.format(
            key=key, exports="\n".join(exports), cfg="\n".join(cfg),
            opts=", ".join(opts), axis_line=axis_line), encoding="utf-8")
        (FIGURES / f"{key}.tscn").write_text(SCENE_TMPL.format(
            key=key, node=node_name(key)), encoding="utf-8")

    doc = {
        "id": "dream_figures",
        "name": "Dream Bodies — the families",
        "description": ("Each dream body as its own artifact with its own two axes of surreal "
                        "variation, so every family can be swept into a DNA gallery. The scenes "
                        "under commons/artifacts/dream_bodies/figures/ are GENERATED from each "
                        "builder's own axes() by tools/dream_bodies_promote.py — edit the builder."),
        "category": "dream_bodies",
        "artifacts": {},
    }
    for key, axes in sorted(rows.items()):
        tok = f"dream_{key}"
        first = {n: v[0] for n, v in axes.items()}
        doc["artifacts"][tok] = {
            "lookup_name": tok,
            "name": "Dream Body — " + key.replace("_", " "),
            "scene": f"res://commons/artifacts/dream_bodies/figures/{key}.tscn",
            "category": "dream_bodies",
            "artifact_type": "sculpture",
            "complexity": "intermediate",
            "include_in_map_data": True,
            "map_ready": True,
            "map_sequences": [],
            "footprint": [1, 2, 1],
            "tags": ["sculpture", "procedural", "stable-diffusion", "dream-bodies"],
            "description": (f"The {key.replace('_', ' ')} family, grown from a seed and varied along "
                            + " and ".join(f"{n} ({', '.join(v)})" for n, v in axes.items()) + "."),
            "dna": {
                "promoted": "2026-08-29",
                "stage": "2 - variation",
                "axes": {n: list(v) for n, v in axes.items()},
                "default": ", ".join(f"{n}={w}" for n, w in first.items()),
                # THE SWEEP CAMERA FITS THE WHOLE AABB, and a 1.6 m statue framed that
                # way is a small figure in a large black square: measured on the first
                # gallery, the body filled about a fifth of the frame's width, which is
                # both a bad picture and a diluted measurement (the corpus's own
                # "subject under ~6% of frame" trap, from the other end). 0.62 steps the
                # camera in without cropping the tallest variants.
                "framing": 0.62,
                **({"predicted_degeneracy": preds[key]} if preds.get(key) else {}),
                "note": ("axes DERIVED from commons/artifacts/dream_bodies/bodies/%s.gd axes() by "
                         "tools/dream_bodies_promote.py; the scene is generated from the same parse, "
                         "so registry and code cannot drift." % key),
            },
        }
    REGISTRY.write_text(json.dumps(doc, indent="\t", ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote {len(rows)} scene(s) to {FIGURES.relative_to(REPO)} and {REGISTRY.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
