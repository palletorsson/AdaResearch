# Array Tutorial — Curriculum Audit

**Sequence ID:** `array_tutorial`
**Spine order:** (tutorial / beginner, QFEP term F — baseline order)
**Maps:** 8 declared (Tutorial_Pattern, Array_Patterns, Tutorial_Single, Tutorial_Row, Tutorial_2D_Build, Tutorial_3D, Tutorial_Disco, Chamber_Arrays)
**Evolutions written:** 0

## 1. Core Concept

An array is **indexed memory made walkable** — a mapping from an integer position to a stored value, physicalized so that traversing the data structure becomes traversing space. The sequence teaches three nested ideas at once: (a) an **index is a distance** (walking from `[0]` to `[3]` is reading the array), (b) an array is a **function** `index → value` (patterns and wallpaper groups are this mapping amplified), and (c) an array is a **data structure** (the binary table beside the grid is the same object in a second representation). QFEP term F — arrays are *pure order*, zero access entropy, the baseline of structure against which the rest of the curriculum introduces noise, transformation, and emergence.

## 2. The Red Thread

1. **Single element / one address** (Tutorial_Single)
   - A single grabbable cube — array of length one, the zeroth hello.
   - Captures: object-as-value, presence at a location, first VR interaction.
   - Leaks: ordering, addressing, multiplicity — there is no `[0]` yet because there is no `[1]` to contrast with.

2. **1D array — the row** (Tutorial_Row)
   - Four cubes along one axis labelled `[0]..[3]`, each grab flips a cell in a binary table.
   - Captures: index = position, traversal = walking, grab = write, array-as-data.
   - Leaks: a second dimension, the possibility of cross-axis reasoning.

3. **2D array — the grid** (Tutorial_2D_Build)
   - 4×4 grid indexed `[x, z]` alongside a live binary table and the pulsar visualizer.
   - Captures: two-index addressing, row×column matrix, arrays as measurement (pulsar data is a 2D array).
   - Leaks: volumetric stacking, the third coordinate.

4. **3D array — the volume** (Tutorial_3D)
   - 4×4×4 cubes you climb into, each labelled `[x,y,z]`; bar_array and sorting artifacts preview algorithmic use.
   - Captures: three-index reasoning, array as voxel field, volume as indexed memory.
   - Leaks: infinite arrays, time-indexed arrays, functional transformations of an array.

5. **Array as function — patterns** (Tutorial_Pattern)
   - `preview[px, py] = palette[grid[(py%N, px%N)]]` — the mod operation turns a finite tile into an infinite carpet; wallpaper-group transforms applied on top.
   - Captures: array as lookup, modulo arithmetic, symmetry as transformation of index space, edit-once-see-everywhere.
   - Leaks: aperiodic tilings, why specific symmetry groups exist, deeper group theory.

6. **Array as floor — scale & performance** (Tutorial_Disco)
   - 12×12 reactive standalone_disco floor reading player position as index lookup; step_sequencer driving audio.
   - Captures: array as room, index as footstep, temporal arrays (sequencers).
   - Leaks: the compositional grammar of patterns (deferred to Array_Patterns gallery).

7. **Pattern gallery — the historical carpet** (Array_Patterns)
   - Six tile stations plus a VR tile editor with live floor carpet — Italian mosaics, wallpaper groups, brick, herringbone, facade grammar.
   - Captures: arrays as inherited craft (textile, mosaic, tile), 17 wallpaper groups, editor-inhabitant closure (you design the floor you stand on).
   - Leaks: meaning of a pattern beyond symmetry, pattern as cultural memory → fractals, facades.

8. **Chamber — synthesis** (Chamber_Arrays)
   - Catalyst targets plus `proximity_spawner#type:gridagent:copy` — player places obstacles, grid-agent pathfinds around them. Array becomes a thing an *agent* reads.
   - Captures: array + catalyst + agent, data structure as substrate for behavior, narrative closure.
   - Leaks: into algorithms (sorting, search), into physics-driven grids, into memory.

## 3. Map-to-Concept Mapping

| Order (sequence JSON) | Map | Concept | Anchor Artifact | Status |
|---|---|---|---|---|
| 1 | Tutorial_Pattern | Array as function / patterns | pattern_tile_puzzle, pattern_tile_plate#p4m | Map exists, rich |
| 2 | Array_Patterns | Pattern gallery (carpet) | vr_tile_editor_mirror, tiling_demo | Map exists, rich |
| 3 | Tutorial_Single | Single address | pick_up_cube | Map exists (minimal, correct) |
| 4 | Tutorial_Row | 1D array | column_3_z | Map exists |
| 5 | Tutorial_2D_Build | 2D array | grid_2d_4x4 + pulsar_visualizer | Map exists, dense |
| 6 | Tutorial_3D | 3D array | grid_3d_4x4x4 | Map exists (note: lookup_name "Tutorial_3D" but `name` field is "Tutorial_3D" — Tutorial_2D_Build has mismatched `name: Tutorial_2D`) |
| 7 | Tutorial_Disco | Array as floor / scale | standalone_disco, step_sequencer#house | Map exists |
| 8 | Chamber_Arrays | Synthesis / agent reads array | gridagent:copy + catalyst_target | Map exists (minimal) |

**Ordering issue:** the sequence JSON lists `Tutorial_Pattern` and `Array_Patterns` *first*, before the `Tutorial_Single → Row → 2D → 3D` foundation. This is almost certainly wrong for a tutorial — you cannot recognize patterns as array equations before meeting arrays. The `position` fields inside `artifact_groups` (intro/foundation/exploration/synthesis) tell the intended pedagogical order, and it contradicts the `maps` array order.

Intended order (from `position` tags):
```
intro       : Array_Patterns, Tutorial_Single
foundation  : Tutorial_Row, Tutorial_2D_Build
exploration : Tutorial_3D, Tutorial_Pattern
synthesis   : Tutorial_Disco
(missing)   : Chamber_Arrays — not in artifact_groups but in maps list
```

The `intro: Array_Patterns` placement is still questionable — a beginner shouldn't meet wallpaper groups before meeting an index.

## 4. Artifact Inventory

### Foundation (dimension ladder) — strong
| Concept | Artifact | File | Identity | Status |
|---|---|---|---|---|
| Single address | pick_up_cube | (commons interactable) | — | works |
| 1D array | column_3_z | algorithms/arrays/column_3_z.gd | yes (rich) | works |
| 1D array + binary | row_3_x | algorithms/arrays/row_3_x.gd | yes (rich) | works |
| 2D array | grid_2d_4x4 | algorithms/arrays/grid_2d_4x4.gd | yes (rich) | works |
| 2D companion (data) | pulsar_visualizer | algorithms/arrays/pulsar/pulsar_visualizer.gd | yes | works |
| 2D companion (compact) | pulsar_compact / pulsar_glass_tubes | algorithms/arrays/pulsar/ | yes | works |
| 3D array | grid_3d_4x4x4 | algorithms/arrays/grid_3d_4x4x4.gd | yes (rich) | works |
| Reference | xyz_coordinates | (primitives/point) | — | works |
| Binary table | binary_table_display | algorithms/arrays/binary_table/ | — | works |
| Index visualizer | IndexVisualizer | algorithms/arrays/index_visualizer/ | — | works |
| Map-as-array | grid_model, grid_model_cube | algorithms/arrays/grid_model/ | yes (rich) | works |

### Patterns (array-as-function) — very strong
| Concept | Artifact | File | Identity | Status |
|---|---|---|---|---|
| Pattern editor (core) | pattern_tile_puzzle | commons/primitives/arrays/pattern_tile_puzzle.gd | yes (rich) | works |
| Pattern variants | pattern_tile_4x4, pattern_tile_mirror, pattern_tile_brick, pattern_tile_herringbone | (via puzzle apply_grid_config) | inherited | works |
| Pattern plate | pattern_tile_plate, pattern_studio_plate | commons/primitives/arrays/ | — | works |
| Pattern cube | pattern_tile_cube | commons/primitives/arrays/pattern_tile_cube.gd | — | works |
| Tiling history | tiling_demo | commons/primitives/arrays/tiling_demo.gd | yes (rich) | works, static gallery (no VR edit) |
| VR editor + carpet | vr_tile_editor, vr_tile_editor_mirror | commons/primitives/arrays/vr_tile_editor.gd | yes (rich) | works |
| Wallpaper groups | wallpaper_groups | commons/primitives/arrays/wallpaper_groups.gd | — | works (17 groups) |
| Tiling engine | tiling_system, tiling_layer, tiling_analyzer | commons/primitives/arrays/ | — | backend, no direct VR |
| Loom | panel_bridge_loom | (textile artifact) | — | works |
| Facade grammar | facade_grammar_demo | (facade system) | — | works |

### Synthesis / extensions — mixed
| Concept | Artifact | File | Identity | Status |
|---|---|---|---|---|
| Array transforms (rotate/scale) | array_rotate, array_scale, array_transform_staircase | commons/primitives/arrays/ | partial | present but not routed into tutorial maps |
| 2.5D glass planes | glass_planes_2_5d | commons/primitives/arrays/glass_planes_2_5d.gd | yes | not placed in any tutorial map |
| Array sequencer | array_sequencer | commons/primitives/arrays/ | — | not placed |
| Mondrian (array-as-art) | mondrian_grid, mondrian_spawner, mondrian_generator_3d | algorithms/arrays/mondrian_grid/ | — | not placed |
| Grid editor (meta) | grid_editor_main, GridEditorCube, GridEditorManager | algorithms/arrays/grid_editor/ | — | not placed (works standalone) |
| Sort preview | sorting_algorithm_race, bar_array, bar_array_bubble_sort | algorithms/arrays/sorting_race/, elsewhere | yes (race) | leaked into Tutorial_3D |
| Reactive floor | standalone_disco | (disco artifact) | — | works |
| Audio array | step_sequencer#house | (music system) | — | works |
| Agent reading array | gridagent:copy, proximity_spawner | (behavior artifact) | — | works |
| Catalyst | catalyst_target | (bracelet system) | — | works |
| Grammar | script_runner#array | (scripting) | — | in Tutorial_Pattern |
| Elementary CA | 7_1_elementary_ca_vr | (wavefunctions crossover) | — | placed in Tutorial_Pattern structure (unusual location) |

## 5. Gap Analysis

### Ordering (high priority)
- **Sequence `maps` array is in the wrong order.** It lists `Tutorial_Pattern, Array_Patterns` first, before the single→row→2D→3D ladder. Either (a) reorder `maps` to `Tutorial_Single → Tutorial_Row → Tutorial_2D_Build → Tutorial_3D → Tutorial_Pattern → Tutorial_Disco → Array_Patterns → Chamber_Arrays`, or (b) move `Array_Patterns` + `Tutorial_Pattern` to a later "patterns & tilings" chapter sequence.
- **Chamber_Arrays is in `maps` but not in `artifact_groups`** — its position is undocumented. Should be `synthesis` with `grammar: chamber`, explicitly last.

### Naming / metadata
- **Tutorial_2D_Build map_info inconsistency:** `map_info.name = "Tutorial_2D"` but `lookup_name = "Tutorial_2D_Build"`. This is a data bug — map_info.name should match the folder / lookup. (See also `doc/journal/` note if relevant.)
- The sequence also has legacy sibling directories `Tutorial_2D`, `Tutorial_2D_Color`, `Tutorial_Col`, `Tutorial_Game`, `Tutorial_Room`, `Tutorial_Start`, `Tutorial_App` outside the canonical 8 — unclear if deprecated; worth an explicit deprecation marker.

### Missing concepts without maps (medium)
- **Array-of-arrays / nested indexing** — the jump from grid to pattern-as-function skips over the idea of arrays *containing* arrays (matrix of matrices). Could be a bridge map before Tutorial_Pattern.
- **Array mutation / transforms as first-class** — `array_rotate`, `array_scale`, `array_transform_staircase` all exist in `commons/primitives/arrays/` but aren't placed in any tutorial map. An `Array_Transforms` map would make transformation-of-array a taught concept, setting up the next sequence cleanly.
- **Array as timeline** — step_sequencer appears in Tutorial_Disco but is not foregrounded as "array indexed by time." A dedicated concept map or doc note would close the loop with wavefunctions / sequencing later.
- **Nested 3D array / voxel editing** — `grid_editor` and `grid_model` are strong artifacts but only `grid_model` appears (in Tutorial_Pattern and Array_Patterns, not in the volumetric Tutorial_3D where it logically belongs).

### Missing anchors inside existing maps (medium)
- **Tutorial_Single** has only `pick_up_cube` + `xyz_coordinates`. It could host a single-cell `column_3_z#count:1` or a single `IndexVisualizer` glyph to explicitly frame "this is `array[0]`."
- **Tutorial_Row** has `column_3_z` but no companion binary table artifact (the row variant is `row_3_x`, which is not placed here — it's in Tutorial_2D_Build instead). The map teaches a Z-column but labels the objective "linear array traversal"; placing `row_3_x` or keeping `column_3_z` but adding `binary_table_display` directly would strengthen the *array-as-data* reveal.
- **Tutorial_3D** has `grid_3d_4x4x4` and somewhat eccentric companions (`sorting_algorithm_race`, `bar_array`, `bar_array_bubble_sort`, `grid3d`). The sort artifacts leak the *next* sequence (algorithms) — fine as a teaser, but no identity card explains why sorts appear here. Consider adding `index_visualizer` for address reveal.
- **Tutorial_Pattern** places `7_1_elementary_ca_vr` (a wavefunctions artifact) — a forward leak into CAs. This is pedagogically rich but uncommented; consider an @identity-grade placard or a `science_screen` explaining the connection.
- **Chamber_Arrays** has catalyst targets and a proximity spawner but no science_screen explaining what the chamber "synthesizes." The narrative arc promised (place obstacles → agent adapts) has no feedback display — needs at least a Label3D outcome readout.

### Documentation gaps
- **No map has a blurb.md or intent.md** in `commons/maps/<Map>/` for any of the 8 (based on typical project state — worth verifying with `ada-task-manager` / garden listener).
- **No evolution written** for any map in this sequence.
- Sequence `qfep_connection` mentions "F-baseline" but no map surfaces the F term anywhere.

### Redundancies
- `Tutorial_Pattern` and `Array_Patterns` both teach pattern/tile/wallpaper concepts. Tutorial_Pattern is indoor-focused on index math, Array_Patterns is a gallery — the distinction is real but undocumented. Either merge, or make the division explicit ("Patterns = index math; Array_Patterns = cultural history").

## 6. Forward Leaks

What this sequence raises but cannot resolve — where each question goes:

- **Transformation of arrays** (rotate, scale, reshape) → Transformation sequence (`Trans_*`)
- **Sorting & searching** → algorithms sequence (previewed by `sorting_algorithm_race` in Tutorial_3D)
- **Aperiodic / non-repeating patterns** → fractals (self-similarity), randomness (noise)
- **Wallpaper groups as group theory** → a dedicated symmetry / graph-theory sequence (not built)
- **Arrays as measurement / signal** (pulsar) → wavefunctions, signal processing
- **Cellular automata on an array** (`7_1_elementary_ca_vr`) → wavefunctions / CA sequence
- **Arrays as memory across time** → memory / persistence sequence
- **Agent-reading-array** → nature_system, pathfinding, AI (Chamber_Arrays teases this)
- **Array as room / inhabitable data** → Pokemon Studio, ecosystems, map_studio reflexivity (grid_model already closes this loop slightly)
- **Infinite arrays / streams** → deferred, not currently in spine

## 7. Proposed Ordering

```
1. Tutorial_Single     — one cube, one address (intro to VR + array[0])
2. Tutorial_Row        — 1D array, index = distance, grab = write (binary table on the wall)
3. Tutorial_2D_Build   — 2D array [x,z], pulsar as measurement
4. Tutorial_3D         — 3D array [x,y,z], climb volumetric memory
5. Tutorial_Pattern    — array as function: preview[px,py] = palette[grid[py%N,px%N]]
6. Array_Patterns      — the historical carpet: tiles, wallpaper, facades, textile
7. Tutorial_Disco      — array at room-scale; temporal arrays (step_sequencer)
8. Chamber_Arrays      — synthesis: catalyst + agent reads the array you shaped
```

**Actions to match intent:**
1. Reorder `sequences.array_tutorial.maps` to the list above.
2. Add Chamber_Arrays to `artifact_groups` with `position: synthesis`, `grammar: chamber`.
3. Fix `Tutorial_2D_Build/map_data.json` — set `map_info.name` to `"Tutorial_2D_Build"`.
4. Either delete or mark-deprecated the orphan `commons/maps/Tutorial_2D*`, `Tutorial_Col`, `Tutorial_Game`, `Tutorial_Room`, `Tutorial_Start`, `Tutorial_App` directories (not referenced by sequence).
5. Place `binary_table_display` directly in Tutorial_Row for the data-model reveal.
6. Consider building an `Array_Transforms` bridge map (rotate/scale/staircase) between Tutorial_3D and Tutorial_Pattern, using the unplaced `array_rotate`, `array_scale`, `array_transform_staircase` artifacts.
7. Write evolutions for at least Tutorial_Row (red-thread anchor) and Tutorial_Pattern (array-as-function turning point).

## Summary

Array_Tutorial has unusually strong artifact coverage — the dimension ladder (`column_3_z → row_3_x → grid_2d_4x4 → grid_3d_4x4x4`) is clean, each file carries a rich @identity block, and the pattern cluster (`pattern_tile_puzzle`, `vr_tile_editor`, `tiling_demo`, `wallpaper_groups`) is among the most developed in the project. The main weakness is **sequence ordering**: the `maps` list puts patterns before foundation, contradicting the `artifact_groups` `position` tags. Secondary issues: one map_info naming bug, a bunch of orphan Tutorial_* folders, Chamber_Arrays missing from artifact_groups, no evolutions written, and a significant library of built-but-unplaced array artifacts (`array_rotate`, `array_scale`, `array_transform_staircase`, `glass_planes_2_5d`, `mondrian_grid`, `grid_editor`) that would fill real gaps if routed into the tutorial maps.
