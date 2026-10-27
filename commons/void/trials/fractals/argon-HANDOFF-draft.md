# Fractals Trial Handoff (`Fractal_Recursion` & `Fractal_RecursiveTrees`)

## 1. Changed Files in `commons/void/trials/fractals/`
- `commons/void/trials/fractals/rooms.json` — Populated Floor 1 (`Fractal_Recursion`, 10 placements) and Floor 2 (`Fractal_RecursiveTrees`, 12 placements) with all 22 original artifacts, configurations, route captions, and provenance metadata (`source_map`, `source_cell`, `source_token`).
- `commons/void/trials/fractals/layout.json` — Updated `status` to reflect completion of the 22-artifact placement pass; preserved the `42 m × 32 m` two-floor Void scaffold, Shafts A/B, and corner-pad descent geometry.
- `commons/void/trials/fractals/catalog-additions.json` — Proposed `catalog.json` metadata overrides (missing footprints for `dark_sphere` and `synthesis_stand`, lesson-aware footprints for the 6 lesson stations, and the local relocation wrapper scene for `fractal_scene`).
- `commons/void/trials/fractals/fractal_scene_relocated.gd` & `commons/void/trials/fractals/fractal_scene_relocated.tscn` — Local non-destructive wrapper for `res://algorithms/fractals/meshfractal/fractal_scene.tscn` that sets `top_level = true` and `global_transform = Transform3D.IDENTITY` on its `MultiMeshInstance3D` children so `fractal.gd`'s world-space instance transforms do not double-offset when placed away from `(0, 0, 0)`.
- `commons/void/trials/fractals/transfer-status.json` — Updated to `stage: "placed"` with `placed: 22`, `omitted: []`, adaptations, and unresolved dependencies.
- `commons/void/trials/fractals/HANDOFF.md` — This handoff report.

---

## 2. Source-to-Void Placement Mapping (22 / 22 Placed, 0 Omitted)

### Floor 1: `Fractal_Recursion` (10 Placements)
| ID | Artifact | Source Cell | Raw Source Token | Void Station & Offset `[X, Z]` | Facing / Height / Scale | Sub-Receivers & Spatial Notes |
|---|---|---|---|---|---|---|
| `f1_fractal_recursion_2_4_5` | `fractal_recursion_2` | `[4, 5]` | `fractal_recursion_2:180:2.2#initial_size:2.2#depth:1#lesson:true#room:thresholds` | `NW [-8.5, -9.5]` | `180°` / `2.2` / `1.0` | `height: 2.2` grounds `RecursionLesson` console (`local (0, -2.2, 2.0)` -> floor `(-8.5, 0, -11.5)`) and 7-frame `ThresholdWalk` (`local (-4, 0, 1)` rot `PI` -> floor `X = -4.5, Z = -10.5..-4.5`). |
| `f1_example_8_3_recursion_circles_vr_12_5` | `example_8_3_recursion_circles_vr` | `[12, 5]` | `example_8_3_recursion_circles_vr:180:2.4#depth:1#rotation_speed:0#lesson:true` | `NE [8.5, -9.5]` | `180°` / `2.4` / `1.0` | `height: 2.4` grounds `RecursionLesson` console (`local (0, -2.4, 2.0)` -> floor `(8.5, 0, -11.5)`). Outer ring (`R = 2.0 m`) spans `y = 0.4..4.4 m`. |
| `f1_cube_subdivision_4_11` | `cube_subdivision` | `[4, 11]` | `cube_subdivision:180:1.5#seed_value:31415#lesson:true` | `NW [-16.0, -5.5]` | `180°` / `1.5` / `1.0` | `height: 1.5` grounds `RecursionLesson` console at `(-16.0, 0, -7.5)` and `CubePlinth` (`y = 0..1.0 m`) beneath the `1.0 m` `InitialCube` (`y = 1.0..2.0 m`). |
| `f1_recursive_chair_12_11` | `recursive_chair` | `[12, 11]` | `recursive_chair:180:0#lesson:true` | `NE [16.5, -5.5]` | `180°` / `0.0` / `1.0` | Chair grounded at `(16.5, 0, -5.5)`. `RecursionLesson` `SideDesk` (`local (+2, 0, 0)` rot `+90°`) sits at `(14.5, 0, -5.5)` facing West toward the aisle. |
| `f1_science_screen_2_14` | `science_screen` | `[2, 14]` | `science_screen:90:0.04#mode:bars#label:Independent sample` | `SW [-16.5, 4.5]` | `90°` / `0.04` / `1.0` | Faces East (`+X`) across the South-West bay; `mode: "bars"`, `label: "Independent sample"`. |
| `f1_dark_sphere_14_15` | `dark_sphere` | `[14, 15]` | `dark_sphere` | `SE [16.5, 4.5]` | `0°` / `0.0` / `1.0` | Non-recursive foil opposite `science_screen`; built-in plinth grounded at `y = 0`. |
| `f1_recursive_table_4_17` | `recursive_table` | `[4, 17]` | `recursive_table:180:0:0.8` | `SW [-8.5, 6.5]` | `180°` / `0.0` / `0.8` | Menger-subdivided table (`2.0 m × 1.6 m × 2.0 m` at `scale: 0.8`), legs grounded at `y = 0`. |
| `f1_cube_staircase_12_17` | `cube_staircase` | `[12, 17]` | `cube_staircase:180:0:0.6` | `SE [8.5, 6.5]` | `180°` / `0.0` / `0.6` | Recursive staircase (`1.2 m × 1.2 m × 1.2 m` at `scale: 0.6`), first step at `y = 0`. |
| `f1_fibonacci_pagoda_4_22` | `fibonacci_pagoda` | `[4, 22]` | `fibonacci_pagoda:180:0.7:0.55` | `SW [-8.5, 11.5]` | `180°` / `0.7` / `0.55` | Unscaled local AABB has `min_y = -1.215 m, max_y = +8.215 m`; at `scale: 0.55, height: 0.7`, spans `y = 0.03 m..5.22 m` (fits cleanly under the `5.64 m` slab underside). |
| `f1_synthesis_stand_12_22` | `synthesis_stand` | `[12, 22]` | `synthesis_stand#subject:dark_sphere#mode:hero` | `SE [8.5, 11.5]` | `0°` / `0.0` / `1.0` | Synthesis stand (`5.34 m × 1.25 m × 1.31 m`) with `subject: "dark_sphere"`, `mode: "hero"`. Open floor (`Z = 11.5..15.5`) on its `+Z` reader side. |

### Floor 2: `Fractal_RecursiveTrees` (12 Placements)
| ID | Artifact | Source Cell | Raw Source Token | Void Station & Offset `[X, Z]` | Facing / Height / Scale | Sub-Receivers & Spatial Notes |
|---|---|---|---|---|---|---|
| `f2_recursive_tree_2_4_5` | `recursive_tree_2` | `[4, 5]` | `recursive_tree_2:180#lesson:true#room:canopy` | `NW [-8.5, -9.5]` | `180°` / `0.0` / `1.0` | Spawns `TreeLesson` desk at `(-8.5, 0, -11.5)`, `HandFork` at `(-10.15, 0, -11.5)`, `TreeReadings` at `(-6.85, 0, -11.5)`, and `BranchCanopy` (`scale: 1.8`, max height `~5.5 m`) at `(-5.5, 0, -7.5)`. |
| `f2_recursive_tree_12_5` | `recursive_tree` | `[12, 5]` | `recursive_tree:180:0:0.42#lesson:true` | `NE [8.5, -9.5]` | `180°` / `0.0` / `0.42` | 3D voxel tree scaled `0.42x` (`~6.5 m` span, `~3.4 m` tall); `TreeLesson` counter-scales (`1 / 0.42`) and places its desk at `local (0, 0, 4.2)` -> floor `(8.5, 0, -11.26)`. |
| `f2_living_paper_7_11` | `living_paper` | `[7, 11]` | `living_paper:180#algorithm:mandelbrot` | `NW [-3.5, -4.5]` | `180°` / `0.0` / `1.0` | Grounded posts (`y = 0..1.55 m`) along the West edge of the central spine. |
| `f2_fractal_lsystem_tree_11_11` | `fractal_lsystem_tree` | `[11, 11]` | `fractal_lsystem_tree:0:0:0.4` | `NE [3.5, -4.5]` | `0°` / `0.0` / `0.4` | L-system turtle tree along the East edge of the central spine. See seating note in Section 4. |
| `f2_small_subdivision_cube_2_14` | `small_subdivision_cube` | `[2, 14]` | `small_subdivision_cube` | `SW [-16.5, 3.5]` | `0°` / `0.0` / `1.0` | Grabbable `0.1 m` `XRToolsPickable` cube that subdivides into 8 smaller cubes on pickup/touch. |
| `f2_small_subdivision_cube_3_14` | `small_subdivision_cube` | `[3, 14]` | `small_subdivision_cube` | `SW [-15.0, 3.5]` | `0°` / `0.0` / `1.0` | Second grabbable `0.1 m` subdivision cube beside Cube A. |
| `f2_inverted_tree_cloud_3_15` | `inverted_tree_cloud` | `[3, 15]` | `inverted_tree_cloud:0:3:0.32#freeze_cloud:true` | `SW [-15.5, 7.0]` | `0°` / `2.5` / `0.32` | Clamped token height `3.0 -> 2.5` for `rooms.schema.json` (`max: 2.5`) and ceiling clearance (`y = 0.90..5.47 m`). |
| `f2_dark_sphere_8_16` | `dark_sphere` | `[8, 16]` | `dark_sphere` | `SE [3.5, 5.5]` | `0°` / `0.0` / `1.0` | Non-branching foil on the East edge of the central walking route. |
| `f2_cube_desk_2_17` | `cube_desk` | `[2, 17]` | `cube_desk` | `SW [-16.5, 11.5]` | `0°` / `0.0` / `1.0` | Recursive cube desk (`2.4 m × 0.8 m × 1.2 m`), grounded at `y = 0`. |
| `f2_inverted_tree_cloud_13_17` | `inverted_tree_cloud` | `[13, 17]` | `inverted_tree_cloud:0:3:0.32#freeze_cloud:true#aftermath:strata` | `SE [15.5, 7.5]` | `0°` / `2.5` / `0.32` | Strata-colored inverted tree cloud opposite the form variant (`y = 0.90..5.47 m`). |
| `f2_fractal_scene_5_20` | `fractal_scene` | `[5, 20]` | `fractal_scene:0:1:0.65` | `SW [-5.5, 7.5]` | `0°` / `1.0` / `0.65` | 3D sphere `MultiMeshInstance3D` fractal (`1.66 m` span at `scale: 0.65`). See wrapper note in Section 4. |
| `f2_mobius_world_3_22` | `mobius_world` | `[3, 22]` | `mobius_world:0:1.25:0.06` | `SW [-9.5, 11.5]` | `0°` / `1.25` / `0.06` | Continuous-twist topological foil (`4.10 m × 0.96 m × 4.29 m` at `scale: 0.06`, centered at `y = 1.25 m`). |

---

## 3. Exact Controls & Interactions to Test in Native Pass

1. **Floor 1 — `RecursionLesson` Consoles (`f1_fractal_recursion_2_4_5`, `f1_example_8_3_recursion_circles_vr_12_5`, `f1_cube_subdivision_4_11`, `f1_recursive_chair_12_11`)**:
   - **Step Button (`ButtonArea` on console desk)**: Press/poke or click to advance recursion depth (`1 -> 2 -> ... -> max_depth -> 1`) and verify the live call readout (`call_label`) and `CodeEvolutionScreen` stage advance in sync.
   - **ThresholdWalk (`f1_fractal_recursion_2_4_5`)**: Walk through the 7 shrinking cyan doorframes (`Term1`..`Term7` along `X = -4.5, Z = -10.5..-4.5`); verify each `Area3D` gate lights up when entered and highlights the active depth when stepping the console.
2. **Floor 1 — `synthesis_stand` (`f1_synthesis_stand_12_22`)**:
   - Verify the 3-button synthesis console and hero `dark_sphere` specimen render cleanly at `SE [8.5, 11.5]`.
3. **Floor 2 — `TreeLesson` Consoles (`f2_recursive_tree_2_4_5` & `f2_recursive_tree_12_5`)**:
   - **`f2_recursive_tree_2_4_5` (NW)**:
     - **Step Button**: Advances generation `1..5` on both the main binary tree and the overhead `BranchCanopy` at `(-5.5, 0, -7.5)`.
     - **Mode Button**: Cycles `SPLIT` (`15° / 28° / 42° / 58°`), `RATIO` (`0.60 / 0.68 / 0.75 / 0.82`), and `SWAY` (`STILL / BREATH / WIND`).
     - **`HandFork` (`(-10.15, 0, -11.5)`)**: Grab the left or right handle (`XRToolsPickable`) to steer `angle_left` and `angle_right` live on both the tree and the overhead canopy.
     - **`TreeReadings` (`(-6.85, 0, -11.5)`)**: Touch/press any of the three specimen pedestals (`NARROW 18°`, `BALANCED 30°`, `WIDE 52°`) to snap the main tree and canopy to that specimen's parameters.
   - **`f2_recursive_tree_12_5` (NE)**:
     - **Step Button**: Rebuilds the 3D voxel tree across depths `1..4`.
     - **Mode Button**: Cycles `SPREAD` (`tight / natural / wide`), `SEED` (`seed 12 / 42 / 108 / 314`), and `READ` (`form / strata / envelope / apparatus` aftermath wireframes/bands).
4. **Floor 2 — `fractal_lsystem_tree` (`f2_fractal_lsystem_tree_11_11`)**:
   - Test the two `ParameterController3D` horizontal sliders (`angle_controller` and `generation_controller`).
5. **Floor 2 — `small_subdivision_cube` (`f2_small_subdivision_cube_2_14` & `f2_small_subdivision_cube_3_14`)**:
   - Grab or touch the `0.1 m` cubes to trigger octree subdivision (`subdivide()`) into 8 child cubes with outward impulse.

---

## 4. Bounds, Seating & Lifecycle Concerns for Coordinator Validation

1. **`fractal_scene` (`f2_fractal_scene_5_20`) MultiMesh Double-Transform**:
   - In `algorithms/fractals/meshfractal/fractal.gd` (`setup_fractal()` L97 and `update_fractal()` L123-130), `MultiMeshInstance3D` nodes are added as direct children of `Fractal` (inheriting `Fractal.global_transform`), and `update_fractal()` also sets each instance's transform using `global_position`, `global_transform.basis.get_rotation_quaternion()`, and `global_transform.basis.get_scale().x`.
   - When placed away from `(0, 0, 0)`, this applies `global_transform` twice.
   - **Adapter provided**: `res://commons/void/trials/fractals/fractal_scene_relocated.tscn` (proposed in `catalog-additions.json`) instantiates the original scene and sets `mmi.top_level = true` and `mmi.global_transform = Transform3D.IDENTITY` on each `MultiMeshInstance3D` child.
2. **`inverted_tree_cloud` (`f2_inverted_tree_cloud_3_15` & `f2_inverted_tree_cloud_13_17`) Height Clamping (`3.0 -> 2.5`)**:
   - The source tokens specify `:0:3:0.32` (`height = 3.0`), which exceeds `commons/void/rooms.schema.json` (`maximum: 2.5`) and would push the top of `CubeCloud` (`local +9.28 m` -> `+2.97 m` at `scale: 0.32`) to `5.97 m`, clipping into the `5.64 m..6.0 m` ceiling slab.
   - At `height: 2.5` and `scale: 0.32`, the lowest downward branch tip (`local -5.0 m` -> `-1.60 m`) sits at `y = +0.90 m` above the floor and the top of `CubeCloud` sits at `y = 5.47 m` (below the `5.64 m` ceiling slab underside).
3. **`fractal_lsystem_tree` (`f2_fractal_lsystem_tree_11_11`) Vertical Seating (`height: 0.0` at `scale: 0.4`)**:
   - `example_8_9_lsystem_tree_vr.gd` positions `turtle` at `local y = -0.4` (`-0.16 m` at `scale: 0.4`) and `angle_controller` / `generation_controller` (`ParameterController3D`) at `local y = -0.6` (`-0.24 m` at `scale: 0.4`).
   - Because `floor_content.gd` does not run `GridInteractablesComponent._auto_ground_artifact`, `height: 0` places those sliders `0.24 m` below the floor slab surface. If confirmed in the native pass, set `"height": 0.35` (or `0.6`) on `f2_fractal_lsystem_tree_11_11`.
4. **`small_subdivision_cube` (`f2_small_subdivision_cube_2_14` & `3_14`) Seating**:
   - Centered `0.1 m` `RigidBody3D` (`XRToolsPickable`) at `height: 0`. If physics depenetration at `y = 0` causes jitter on spawn, raise `"height"` to `0.06` or `0.85` (tabletop height).
5. **`recursive_tree_lesson.gd` Hall Light Check**:
   - `recursive_tree_lesson.gd:_use_hall_light()` checks `get_meta("em_map") == "Fractal_RecursiveTrees"` on ancestors; in Void it safely returns `null` (no-op) so Void's own floor lighting remains in charge.

---

## 5. Coordinator Validation Commands

```powershell
# 1. Static schema + placement count verification (already run by Argon):
python -c "import json; r=json.load(open('commons/void/trials/fractals/rooms.json', encoding='utf-8')); print('Floors:', len(r['floors']), 'Counts:', [len(f['artifacts']) for f in r['floors']])"

# 2. Native Godot headless FloorContent load & bounds probe (for coordinator GPU queue):
godot --headless --path . --script res://commons/testing/probe_void_floor.gd -- --layout=res://commons/void/trials/fractals/layout.json --rooms=res://commons/void/trials/fractals/rooms.json
```
