# Mesh Grammar Unification

> Encoding everything we've built — substrate channels, edges of algorithm,
> part-grammars, glyph subdivision, the auto-research loop — in mesh-grammar's
> face-and-tag vocabulary.
>
> The mesh-grammar already has the right architecture. The substrate, the
> 13 edges, the part-grammars, the glyph layer — these can all be expressed
> as mesh-grammar operations on a tagged face structure. The unification
> doesn't require new infrastructure; it requires recognising that the
> mesh-grammar's `MeshData` + `MeshRule` + tag system is general enough to
> hold every other concept we've built.

## The mesh-grammar's deep structure

```
MeshData
├── vertices: PackedVector3Array
├── faces: Array[PackedInt32Array]      # triangles
├── face_tags: Array[PackedStringArray] # per-face string tags
└── face_depth: PackedInt32Array        # generation count

MeshRule (base)
├── selector: String                    # "tag:up", "tag:extruded_top", ...
├── params: Dictionary
└── _execute(mesh, selected_face_indices)
```

Eighteen-plus operations exist already:
`extrude_face`, `inset_face`, `bulge`, `tube_branch`, `split_face`,
`delete_face`, `noise_displace`, `scale_face`, `rotate_face`,
`scallop_edge`, `petal_splay`, `scale_tile`, `edge_decorate`,
`surface_scatter`, `lsystem_branch`, `cellular_surface`, `rd_sim`,
`grid_split`, `profile_extrude`.

The system is config-driven: a JSON describes a chain of `(op, selector, params)`
rules; the interpreter applies them in order over N generations.

## The mapping

Every thing we've built maps onto this structure with no remainder:

| What we've built | Mesh-grammar concept | Mechanism |
|---|---|---|
| Substrate cube | `MeshData` face | Per-face data instead of per-instance |
| Part role ("petal", "thorax") | Face tag | Tag added by an op; selectors use it |
| Glyph subdivision level | Face depth + face splitting | Existing `split_face` + `face_depth` |
| Visibility (cube hidden) | Face deletion | Existing `delete_face` |
| Color (per-cube palette) | Face tag → material lookup | New tag-driven material op |
| Transform (per-cube delta) | Face vertex displacement | Existing `bulge` / `noise_displace` cousins |
| Floor-plan PATH_GUARANTEE | Path-respecting carve | New op: `protect_path(seed, target)` |
| Visibility expression (rule_30, sierpinski, ...) | Selector logic | Custom selector functions |
| 13 edges of algorithm | Recipe templates | Configs that compose ops to *demonstrate* an edge |

## Eight concrete unifying operations

What the mesh-grammar would need to absorb the substrate's vocabulary fully:

### 1. `tag_by_grammar`

**Encodes:** part-grammar (`flower_grammar`, `insect_grammar`, `bird_grammar`).

```json
{"op": "tag_by_grammar", "selector": "tag:floor",
 "params": {"grammar": "flower_grammar"}}
```

For each selected face, computes its centroid in xz, applies the grammar's
distance-banded role assignment, adds the role as a tag. After this op,
faces have tags like `petal`, `pistil`, `sepal`. Selectors downstream can
filter by these.

### 2. `paint_by_tag`

**Encodes:** color-by-role.

```json
{"op": "paint_by_tag", "selector": "tag:floor",
 "params": {"palette": {"petal": "#a63380", "sepal": "#5a9959"}}}
```

For each selected face, looks up its tags against the palette dict, sets
the face's material colour to the first match.

### 3. `hide_by_rule`

**Encodes:** visibility expressions (`rule_30`, `sierpinski`, etc.).

```json
{"op": "hide_by_rule", "selector": "tag:floor",
 "params": {"rule": "rule_30", "row_axis": "z", "col_axis": "x"}}
```

For each face, derives `(row, col)` from its centroid, evaluates the named
rule, deletes the face if the rule says hidden. Implements the visibility
mutator's full expression catalogue as selector predicates.

### 4. `subdivide_by_attention`

**Encodes:** glyph subdivision channel.

```json
{"op": "subdivide_by_attention", "selector": "tag:visible",
 "params": {"viewer": [6, 0, 6], "radius": 4.0, "max_subdivisions": 80}}
```

For each visible face within `radius` of `viewer`, calls `split_face` (which
already exists) once. Recursively subdivides selectively. The face_depth
field tracks how many times each face was split. Compute-budgeted by
`max_subdivisions`.

### 5. `protect_path`

**Encodes:** PATH_GUARANTEE floor-plan mode.

```json
{"op": "protect_path", "selector": "tag:floor",
 "params": {"seed": [2, 0, 0], "target": [10, 0, 15], "width": 1}}
```

BFS-fills faces along the cheapest route from seed to target through
present (non-deleted) faces in the floor strata. Faces along the path
get a `protected` tag so subsequent `delete_face` / `hide_by_rule` ops
that select them are no-ops on them. The walkability guarantee survives
all subsequent ops in the chain.

### 6. `extrude_by_distance`

**Encodes:** transform-by-distance, lift-by-row.

```json
{"op": "extrude_by_distance", "selector": "tag:visible",
 "params": {"axis": "y", "from_centre": true, "max_distance": 3.0}}
```

For each face, computes its distance from the volume centre (or its
row index, depending on params) and extrudes it that far. Combines
existing `extrude_face` with a parameterised distance function.

### 7. `mark_specimen`

**Encodes:** part-grammar centerpiece + label hooks.

```json
{"op": "mark_specimen", "selector": "tag:pistil",
 "params": {"specimen_id": "centre_specimen", "label_text": "PISTIL"}}
```

Tags the selected faces as `specimen:<id>` plus their original tags. A
downstream renderer can attach floating labels using the centroid of
the specimen-tagged faces. Bridges substrate's part channel to the
SpecimenLabel artifact concept.

### 8. `compose_edges`

**Encodes:** the 13 edges of algorithm as recipe templates.

```json
{"op": "compose_edges", "selector": "all",
 "params": {"edge": "F_folding",
            "primary": "rule_30", "secondary": "menger_sponge",
            "transition_generation": 3}}
```

A meta-op that emits a sequence of sub-ops demonstrating the chosen
edge. F_folding emits `[hide_by_rule(rule_30), advance_generation,
hide_by_rule(menger_sponge)]` so the player sees one principle become
another. Each of A–M edges has a canonical recipe template.

## How this unifies the auto-research loop

Once the mesh-grammar absorbs these eight ops:

1. **One config schema** drives substrate, mesh-grammar, and edge-driven
   recipes. The current three separate `research_configs.json` files
   (`mesh_grammar/`, `substrate_research/`, `artifact_research/`) collapse
   to one schema with a `seed_type` discriminator.
2. **One renderer** (`render_mesh_grammar.gd`) drives all three. The
   substrate's MultiMesh-based renderer becomes a special case: a seed
   that's a quad-grid instead of a single cube.
3. **One `propose_next_gen.py`**'s heuristics become richer because all
   ops are in one vocabulary. Hint *"pair with flower_grammar"* maps
   directly to *"add `tag_by_grammar` op with grammar:flower_grammar"*.
4. **Edge-driven research** becomes possible: configs tagged with
   `edge: F_folding` can be queried, compared, iterated. The 13 edges
   become first-class units of research output.

## What's already there vs. what's missing

| Capability | Status |
|---|---|
| `MeshData` + `MeshRule` + tag system | ✅ shipped |
| 18+ existing ops | ✅ shipped |
| `delete_face`, `split_face`, `extrude_face` (foundations) | ✅ shipped |
| Selector by tag | ✅ shipped |
| Generation-depth tracking | ✅ shipped |
| Config-driven recipe execution | ✅ shipped |
| `tag_by_grammar` | ❌ scoped (this doc) |
| `paint_by_tag` | ❌ scoped |
| `hide_by_rule` | ❌ scoped |
| `subdivide_by_attention` | ❌ scoped |
| `protect_path` | ❌ scoped |
| `extrude_by_distance` | ❌ scoped |
| `mark_specimen` | ❌ scoped |
| `compose_edges` (edges as recipe templates) | ❌ scoped |

**The substrate's whole vocabulary is eight ops away from being one with
the mesh-grammar.**

## A first cycle on the unification

Smallest concrete first step:

1. Implement `paint_by_tag` (~50 lines, mirrors existing op shape).
2. Implement `tag_by_grammar` with one grammar (flower) (~80 lines).
3. Write a mesh-grammar config that uses both:
   ```json
   {"id": "gen00_unified_flower",
    "seed": "tile_grid", "seed_size": [13, 13],
    "rules": [
      {"op": "tag_by_grammar", "selector": "all",
       "params": {"grammar": "flower_grammar"}},
      {"op": "paint_by_tag", "selector": "all",
       "params": {"palette": {"pistil": "#ffd633", "stamen": "#f288d8",
                              "petal": "#a63380", "sepal": "#5a9959"}}}
    ]}
   ```
4. Render via `render_mesh_grammar.gd` (the existing renderer).
5. Compare against substrate-gallery's `gen00_flower_tabletop`.

If the mesh-grammar version reads as the same flower (or close), the
unification is proven on one example. From there the other six ops are
analogous additions, and the substrate's GDScript machinery becomes
optional/legacy — kept for runtime use in maps but not duplicating the
research-time vocabulary.

## What it changes about the methodology

Three structural shifts:

1. **The mesh-grammar's tag system becomes the project's universal
   "anatomy" layer.** `petal`, `thorax`, `extruded_top`, `inset_inner`,
   `protected`, `specimen:centre` — all the same kind of metadata,
   queryable by selectors.

2. **Edges of algorithm become recipes, not abstractions.** Each of
   A–M is a `compose_edges` template. Configs say "I demonstrate edge F"
   and the system knows what that means concretely.

3. **The auto-research loop unifies.** Three galleries become one with a
   `category` field (mesh / substrate / artifact / edge). Cross-gallery
   comparison stops being a wishlist and starts being a SQL-like query:
   *"show me all configs that demonstrate edge F using fewer than 10 ops."*

## Status as of 2026-04-27

This is a *proposal* doc, not yet implemented. The substrate work
(commit history through `f151b927f`) and the mesh-grammar work (commit
history through earlier sessions) are in their separate vocabularies.
The unification is one-to-three sessions of work — eight new ops, one
schema migration, one config-format conversion.

**The good news:** nothing breaks. The substrate keeps working at
runtime. The mesh-grammar keeps working at research time. The unification
is *additive* — new ops in mesh-grammar that *can* express substrate
concepts without forcing a rewrite of the substrate's runtime path.

*Started 2026-04-27. Companion to `doc/SUBSTRATE_STATE_BASELINE.md` and
`doc/ARTIFACT_AUTO_RESEARCH.md`.*
