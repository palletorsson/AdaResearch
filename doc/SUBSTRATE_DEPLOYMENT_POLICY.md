# Substrate Deployment Policy

> When does a sequence get a substrate runner, on which map, with which vocabulary?
> Notes from the over-broad-deployment correction of 2026-04-27.

## What went wrong

The first deployment placed `grid_substrate_runner` on 11 maps across 11 sequences
with the **default vocabulary** (`rule_30`, `sierpinski`, `checkerboard`, `rings`).
That vocabulary belongs to cellular automata. Putting it on `LSystems_Grammar_Lab`,
`PG_Genetic_Evolution`, `GT_Foundations`, etc. *polluted* those sequences with
algorithms that aren't the principle the sequence is teaching.

A graph-theory map's floor cycling through Wolfram Rule 30 isn't graph theory —
it's noise.

## Three constraints for any future placement

### 1. Per-sequence vocabulary

Each sequence has its own algorithms-on-the-floor that match its principle.
The substrate runner stays the same; the *expressions registered with it* change.

| Sequence | Visibility vocabulary | Status |
|---|---|---|
| `cellularautomata` | rule_30, sierpinski, checkerboard, rings, conway (todo) | partial — 4 of 5 shipped |
| `fractals` | sierpinski, menger_sponge, sphere_shell, sierpinski_carpet (todo) | partial |
| `lsystems` | l_system_branching, rhizome, double_branches | none — needs new expressions |
| `randomness` | scatter, threshold_boolean_cuts, random_walk_dispersion | none — needs new expressions |
| `noise` | box_noise, crackle, threshold_boolean_cuts | none — needs new expressions |
| `mosaicanalysis` | tessellation_hex, tessellation_tri, voronoi_round, voronoi_straight | none — needs new expressions |
| `patterngeneration` | pattern_from_base_rule, element_repeat, overlay_pattern | none |
| `proceduralgeneration` | wave_function_collapse, ant_nest_caves | none |
| `transformation` | (transform mutator, not visibility) | the runner's `enable_visibility=false`, use transform expressions instead |
| `graphtheory` | bfs_frontier_t1..t8, pathfinding_dijkstra (todo) | partial — 8 of N shipped |
| `searchpathfinding` | bfs_frontier_t1..t8, pathfinding_astar (todo) | partial |
| `qfeplaboratory` | rule_30 → sierpinski → menger_sponge (the F-edge fold) | shipped via FoldTheatreRunner |

**Rule.** Don't deploy a substrate runner on a sequence until its
sequence-appropriate visibility expressions exist. If you only have CA
expressions, only deploy on CA sequences.

### 2. One placement per sequence — usually the chamber

The substrate is a teaching object, not floor decoration for every cell.
Earlier maps in a sequence focus on their specific artifacts; the
**chamber / catalyst map at the end of the sequence is where the principle
returns as a complete grid**.

This matches the existing 17-chamber design: `Chamber_CA`, `Chamber_QFEP`,
etc. The substrate fits the chamber pattern — it is the principle made
floor.

**Default rule.** One substrate runner per sequence, placed on the
chamber map.

**Exceptions.** Two cases warrant placement on a non-chamber map:

- **Foundational introduction** — when the sequence's first map *is* the
  principle (e.g. `CA_Introduction` introduces cellular automata; the
  substrate showing CA on the floor IS the introduction).
- **Specific edge demonstration** — when a particular non-chamber map
  exists to demonstrate one edge (e.g. `Fold_Theatre` in `qfeplaboratory`
  demonstrates the F edge specifically; the chamber will demonstrate the
  whole formula).

### 3. Progressive intensity (optional)

Within a sequence that hosts the substrate on multiple maps, intensity
should grow toward the chamber. First appearance subtle; chamber dominant.
Implementable via:

- `visibility_cycle_seconds` — fast cycle (subtle, background) → slow cycle (foreground)
- `floor_plan_layers` — 1 layer (just floor) → 2 layers (floor + low ceiling)
- `enable_glyph` — false early, true late
- `enable_color_by_role` — false early, true late
- `glyph_max_subdivided_cells` — 0–32 early, 96–256 late

Per-map override via `apply_grid_config({...})` on the runner subclass.

## Current state (post-correction)

Two intentional placements:

| Map | Sequence | Why this map |
|---|---|---|
| `CA_Introduction` | `cellularautomata` | foundational introduction; the substrate IS the principle |
| `Fold_Theatre` | `qfeplaboratory` | specific F-edge first cycle demonstration |

Eleven removed: `Fractal_Recursion`, `Random_Definition`, `Shader_01_Shaping`,
`Random_Noise_Types`, `LSystems_Grammar_Lab`, `Trans_Introduction`,
`PG_Genetic_Evolution`, `Grand_Pattern_Museum`, `GT_Foundations`,
`SearchPathfinding_Intro`. The substrate runner artifact still ships and
the registry still lists those sequences as compatible, but no map
currently places it.

## Re-deployment checklist

For each sequence that wants the substrate:

1. **Author the vocabulary** — write the visibility / transform / glyph
   expressions that match the sequence's principle. Add rows to
   `doc/ALGORITHM_CATALOGUE.md` and ship the GDScript.
2. **Pick the placement** — chamber map by default; introduction or
   specific-edge map only with reason.
3. **Subclass the runner** — like `FoldTheatreRunner`, override
   `_init` to set the sequence's vocabulary on the configured channels.
4. **Place the artifact** — single cell on h=1 floor of the chosen map.
5. **Validate** — run `capture_map_substrate_cycle.gd` and check
   `path OK` for every visibility pattern.
6. **Capture for the cousin diff** — compare against the sequence's
   visual seeds (per `doc/EDGES_OF_ALGORITHM_VISUAL_SEEDS.md`).
7. **Iterate the recipe** — adjust until the floor reads as the principle.

## What's open

- Sequence-vocabulary registries for all sequences listed above as "needs
  new expressions". Eight sequences are unblocked by writing 4–10 new
  expression files; substrate already has the channels.
- Progressive-intensity helpers — a `substrate_strength` field with
  documented effects per channel.
- `apply_grid_config` syntax for per-placement overrides without subclassing
  (so a single runner can be placed on multiple maps with different
  intensities).
- Audit tool `tools/substrate_audit.py` that lists all current placements
  and their per-channel configuration, flagging defaults-on-wrong-sequence.

*Started 2026-04-27 after the over-broad deployment correction.*
*Companion to `doc/ALGORITHM_CATALOGUE.md` and `doc/EDGES_OF_ALGORITHM.md`.*
