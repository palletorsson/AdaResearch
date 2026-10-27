# L-Systems → Void transfer: HANDOFF

Owner: Claude. Written 2026-10-21. Batch: `doc/void-transfer/2026-10-21-batch-02/`.
Stage: **placed**. Native-tested: no. Headset-tested: no. Curated: no. No Godot run.

## Changed files (all inside `commons/void/trials/lsystems/`)

| file | change |
|---|---|
| `rooms.json` | 8 + 5 original placements; 24 one-metre construction cubes reproducing the maps' structure-2 cells; 15 provenance floor captions |
| `layout.json` | **nine-metre storeys** (levels 0, -9, -18, -27; `storey_height` 9; `landing_max_speed` 14) plus status text. Frame, shafts, columns, pads unchanged |
| `source-inventory.json` | each placement `status: placed` with a `void` record; a `transfer` block with the rule and omissions |
| `transfer-status.json`, `catalog-additions.json`, `HANDOFF.md` | this package |

No adapter scenes or scripts: every token loads through the catalog and the existing
museum-import path. Untouched: shared files, source maps, texts, scenes, scripts,
`doc/.gdignore`, the cellularautomata package, the main tower. No git operations.
`tools/audit_void_transfer.py lsystems` passes 79 / 79 (it wrote `evidence/source-checks.json`).

## Placement rule

Same as the accepted CA package: each grid turned 180° about its centre, 1 cell = 1 m,
`void_x = 9 - cell_x`, `void_z = cz - cell_z` (cz 12.5 for Grammar Lab, 13.5 for Growth),
`facing = token_rotation + 180`. The original entrance (9, 1) lands at z 11.5 / 12.5,
beside the shared spawn (0, 12), so a visitor meets the lesson desk first, console toward
them, as in the museum. Heights are the museum lane's (`em_plan` rows: all 0.0; the
screen `offset 1.5, scale 0.4` from its token). One grounding adaptation below.

| rooms id | map, cell | token | void x, z | facing | height | scale | config |
|---|---|---|---|---|---|---|---|
| `f1_lsystem_editor_9_7` | Grammar Lab (9,7) | `lsystem_editor:180#lesson:true#grammar:koch#depth:1` | 0, 5.5 | 0 | 0 | 1 | lesson, grammar, depth |
| `f1_mesh_grammar_lsystem_tree_5_17` | (5,17) | `mesh_grammar_lsystem_tree` | 4, -4.5 | 180 | **0.45** | 1 | none |
| `f1_science_screen_11_17` | (11,17) | `science_screen:180:1.5:0.4#mode:trace` | -2, -4.5 | 0 | 1.5 | 0.4 | mode |
| `f1_grammar_provenance_6_19` | (6,19) | `grammar_provenance` | 3, -6.5 | 180 | 0 | 1 | none |
| `f1_lsystem_tree_9_19` | (9,19) | `lsystem_tree` | 0, -6.5 | 180 | 0 | 1 | none |
| `f1_fractal_lsystem_string_10_20` | (10,20) | `fractal_lsystem_string` | -1, -7.5 | 180 | 0 | 1 | none |
| `f1_city_bench_12_20` | (12,20) | `city_bench` | -3, -7.5 | 180 | 0 | 1 | none |
| `f1_dark_sphere_8_22` | (8,22) | `dark_sphere` | 1, -9.5 | 180 | 0 | 1 | none |
| `f2_parametric_lsystem_9_7` | Growth (9,7) | `parametric_lsystem:180#lesson:true#iterations:1#base_length:0.8#base_angle:40#angle_variation:0#length_decay:0.72` | 0, 6.5 | 0 | 0 | 1 | all six |
| `f2_ContextSensitiveTree_5_18` | (5,18) | `ContextSensitiveTree:270` | 4, -4.5 | 90 | 0 | 1 | none |
| `f2_AnimatedTree_9_18` | (9,18) | `AnimatedTree:180` | 0, -4.5 | 0 | 0 | 1 | none |
| `f2_lsystem_tree_10_18` | (10,18) | `lsystem_tree:90` | -1, -4.5 | 270 | 0 | 1 | none |
| `f2_modulor_cypress_12_18` | (12,18) | `modulor_cypress` | -3, -4.5 | 180 | 0 | 1 | none |

Config values are the tokens' own strings. 13 of 13 placed; none omitted.

## Adaptations (each visible and reversible)

1. **Nine-metre storeys.** GrowthLesson builds 8 m metre rulers (0.35..8.35 m) and draws
   in unfitted metres (generation 2 reaches about 7.5 m). Storeys are 9 m on every floor;
   a 9 m drop lands at about 13.3 m/s, so `landing_max_speed` is 14 and `storey_height` 9
   keeps the one-floor rule. Curation/fit requirement, main tower unchanged.
2. **`mesh_grammar_lsystem_tree` at height 0.45.** The preset's seed is centred on the
   origin (seed_scale 0.5), half under the museum deck; the grid lane grounded it. The
   grown preset may reach lower: measure, and raise if the body dips below the slab.
3. **Structure-2 cells as construction cubes** (`construction`, kind `cube`, 1 m, y 0):
   Grammar Lab rows 15-16 at cols 4-8 and 10-11, the threshold platforms that leave the
   one-cell passage at x 0 (z -4..-2); Growth col 4 rows 17-22 and col 7 rows 17-19, 22,
   the walled corridor the context-sensitive tree stands in (x 2.5..4.5, z -9..-3). These
   are the original 1 m raised cells; delete the arrays to remove them. Cube origin
   assumed at the base (array_tutorial uses y 0 for floor-standing cubes).
4. **Fifteen provenance captions** (`route`), removable.

## Not transferred

- The inner partition walls (structure `w` at Grammar Lab row 14 and Growth row 16, open
  at cols 8-10) and the perimeter. Both lessons were on the entrance side of that wall.
- Utilities: spawn, teleporter, the `an` cells at (7,16) and (11,18).
- Lighting, sky, `nature_layer.json`, the museum's open roof.

## Coupled instruments and relocation dependencies

- **Lesson desks are children of their artifact.** `lsystem_editor#lesson:true` installs
  `GrammarLesson` (NEXT / TURN / HOLD / PRESET / RESET / RULE, LIVE and HELD displays, the
  carried reading point on a rail at local z 2.55: move = TURN 30/60/90/120°, held trigger =
  NEXT). `parametric_lsystem#lesson:true` installs `GrowthLesson` (STEP / RATIO / HOLD /
  TREE / RESET / RULE, two 8 m rulers, the branch point: move = RATIO 0.45/0.72/1.0/1.15,
  held trigger = STEP). Both move with their artifact; nothing else references them.
- **Both hands preload `res://doc/book/studies/lsystems-through-the-hands/LSystems_Grammar_Lab/point_body.gd`,
  under a tracked `doc/.gdignore`** (since 28 Sept, commit 968cfa4b1). The file exists and
  is tracked; three other live hands (architecture, competition, living) and
  `impatient_river` preload from the same folder, so desktop runs from the project folder
  presumably resolve it, while an export without `doc/` would lose all five hands. Your
  probe tests the exact preload; I changed nothing there. If it fails, the lesson `_ready`
  errors after the console and displays are built and before the hall lights, so the desk
  would stand with buttons but no point.
- **Hall-frame lights.** `GrammarLesson._light_hall` and `GrowthLesson._stage_hall` find
  the ancestor with `em_map` (the Void floor root carries it), hide any
  `DirectionalLight3D` under it, and add OmniLights at museum-hall coordinates
  (5, 4.5, 9), (14, 4.5, 9), (9.5, 4.5, 22) and (5, 5, 10), (16, 5, 10), (10.5, 5, 25),
  which in the turned Void frame fall on the east side and partly off the slab (z 22, 25).
  Harmless, but the lesson lighting is not where it was. `_stage_hall` also sets every
  camera in the hall non-current and shrinks oversized captions on sibling artifacts.
- **`science_screen#mode:trace`** scans `get_parent().get_children()` for a sibling whose
  lookup name contains `draw`. In the Void each artifact sits under its own mount, so it
  finds nothing; in the Grammar Lab map there was no draw dot either, so the screen shows
  its TRACE RECORDER label with nothing tracked in both lanes. No coupling to satisfy; it
  floats at 1.5 m on a 0.4-scale stand with no backing, as the token placed it.
- **`ContextSensitiveTree`** raycasts every F step against the whole physics world and
  prunes on contact; it also builds two small obstacles of its own. The corridor cubes,
  the slab, columns and any collider nearby shape it. It generates once, two frames after
  `_ready`, so a body that arrives later does not reshape it.
- `AnimatedTree.tscn` carries a WorldEnvironment, DirectionalLight3D and Camera3D; the Void
  neutralises all three on import. `grammar_provenance` has a DEPTH stepped slider and
  ignores config. `city_bench` sways on `rotation.y` in `_process`. `lsystem_editor._input`
  is disabled by the lesson; no other keyboard handlers.

## Uncertain extents for the native pass

| body | predicted floor-local extent | uncertain |
|---|---|---|
| Grammar lesson | pedestals x -3.9..3.9, z 5.28..5.72, 1 m high; drawings to about 4.75 m; captions to 4.6 m; console (0, 7.5) with legs 0..0.89; point rail (0, 8.05) at 1.18 m | which pedestal faces carry colliders (`box(..., solid=true)`) |
| Growth lesson | pedestals x -4.8..4.8, 0.35 m; rulers x -5 and 1, 0.35..8.35 m; console (0, 8.5); rail (0, 9.05); generation-2 trunk to about 7.9 m | ruler labels at x -5.25 are the westernmost mark; 2.3 m from the A landing's slab edge |
| ContextSensitiveTree | registry 7.04 x 9.52 x 1.0, centre x -1.08 (turned onto z), i.e. z about -7..0.1 at x 4 | 0.9 m above a 9 m storey's clear height; the raycast pruning against the slab above may trim it |
| modulor_cypress | 4.3 m crown, 19.5 m trunk at x -3, z -4.5 | passes through the slab of floor 1 and the canopy; no collision claimed by its meshes |
| science_screen | 1.2 x 0.88 face about 2.2..3.1 m up at (-2, -4.5), stand hanging under it | the `_support_lift` at scale 0.4 |
| mesh_grammar_lsystem_tree | 0.9 m seed at 0.45 | the grown preset's real AABB |
| grammar_provenance | trees x 1.8..4.2, header at 1.7 m, controls at (3, -8.2) 0.86 m up facing -z | the DEPTH slider reach |
| construction cubes | 1 m cubes at the listed cells, 0..1 m | platform_block origin at base |

Shafts (x in ±[7.5, 12.5], z in [-3, 3]) and the A landings ((-8.3, ±1.9)) are clear by
at least 2.2 m from everything below head height. Both floors keep the central aisle at
x about 0 from the spawn to the collection; on floor 1 the one-cell passage between the
platforms is at x -0.5..0.5, z -4..-2.

## Controls to test

Floor 1: GrammarLesson buttons NEXT / TURN / HOLD / PRESET / RESET / RULE; carry the
reading point along its rail (angle 30-60-90-120 by position, held trigger = NEXT);
readout changes; LIVE and HELD drawings; "SAME SENTENCE / DIFFERENT SENTENCES". The
provenance DEPTH slider (1-6). Observe the mesh grammar tree, screen, string, bench, orb.
Floor 2: GrowthLesson STEP / RATIO / HOLD / TREE / RESET / RULE; carry the branch point
(ratio by position, held trigger = STEP); readout SAVE / RESTORE / DRAW / TURN with next
length and stack depth; TREE to generation 2 reaches the ruler's 7 m marks. Observe the
pruned context tree inside its corridor (red stubs), the animated tree growing every 1.5 s
with wind, the small tree, the cypress.

Commands: `python tools/audit_void_transfer.py lsystems` (passes);
`python tools/export_void_trial.py lsystems`; your `tools/probes/lsystems_transfer_probe.gd`.
Editor: `http://localhost:3003/lab-editor?mode=void&trial=lsystems&floor=1`. None of the
thirteen declares editor parts; desks, hands, rulers and consoles travel with their artifact.


## Coordinator acceptance — 21 October 2026

The worker record above is retained as provenance; these findings supersede its
untested assumptions. Claude delivered the files and then reached its quota.
Codex completed integration and acceptance.

- 13/13 source placements, 79 source checks, 73 native checks, 16 editor checks pass.
- Void catalog `lsystem_editor.configure_before_ready = true` is necessary:
  applying `lesson:true` only after `_ready` leaves GrammarLesson uninstalled.
  The original museum script is unchanged. Both original hand preloads succeed.
- Desktop mouse and synthetic tracked XR both operate NEXT/TURN/HOLD/RULE/RESET
  and STEP/RATIO/HOLD/TREE/RULE/RESET, preserve held witnesses, descend to Growth,
  sleep the previous floor and restart at the current checkpoint. Secondary
  controls have not all been exhaustively exercised. Physical headset untested.
- 48 editor models exported: 13 original placements, 4 structure snapshots and
  31 common props. Every artifact can be independently copied, moved, turned and
  saved. A temporary save reached native rooms and the Desktop mirror; the
  baseline was restored using its revision. Stale saves return conflict.
- Native captures are in evidence/01-grammar.png through 04-growth-collection.png.
  A separate photo pass corrected a camera obscured by a pillar; photos.log
  has no script/engine errors.

### Fit remains pending, not silently corrected

The cypress is 19.52 m tall and penetrates the slabs. Grammar Provenance contains
drawing geometry 5.53 m below the deck at the original depth. Both are present
and editable, but not fully fitted. The context-sensitive tree really prunes
against the upper slab at about 8.64 m. The lesson rulers fit the nine-metre
storeys; landing pads absorb that tested descent. The three-cell corridor and
threshold cubes were preserved from the source. `evidence/bounds.json` records
measured scene geometry, excluding private viewports; bounds are observations,
not a claim that every shape fits. Curation should resolve tall trees, drawing
grounding, overlapping labels, the source-relative hall lamps and circulation.

Native acceptance ended cleanly apart from the existing Jolt solver-bias warning.
The separate compatibility-renderer GLB exporter completed all models, then
reported two retained viewport textures and ObjectDB instances at shutdown.
Packaged headset exports remain untested. Main tower and chapter texts unchanged.
