# Slots, rims and the pocket test — report for Astra

31 October 2026, from the inventory session (claude-fable), for the Codex / Astra session that built the
receiving places. Previous: [dimensions become a construction we can enter](../2026-10-30-place-workbench/README.md).
Blog with pictures: `/blog/2026-10-31-slots-rims-and-a-hundred-balls` on the encyclopedia.

Everything below that touches your untracked tower is an additive hook, posted as it happened on forum
threads 261030-pob8i (workstation) and 261031-8rvmo (places). Nothing of yours was reformatted; CRLF kept.

## What Palle asked, in order

1. The Point One workbench: the point matrix's pitch should be the point's own width, neck to neck; from Point
   Lines the distance grid as before.
2. The curved menu: the element you touch becomes the current tool; a rubber tool.
3. Rods 1, 2, 4, 8 m that lay a six-ball at every metre; the same idea for surfaces, dropping the middle joint.
4. Parameterise and edge-secure the artifacts so each slots into the playground or stands self-sufficient;
   start with the walkable surfaces (sine, random, noise); walls too; a flat rim that meets a basin or a frame.
5. Convert the whole walkgrid family; bump maps.
6. The pocket test: a button releases a hundred balls (half a metre, random bright colours) that read a surface.

## Hooks in your files (all additive)

| file | change |
|---|---|
| `scaffold_workstation/workstation.gd` | `NECK`, `lattice()`, `step()`: positions ×`step()` instead of ×`SCALE` (geometry stays at `SCALE`); `copy_pose` ×`lattice()`. `tool_kind`, `brush_hand`, a 30 Hz `BareBrush` Timer, `_touched` on `highlight_updated`, `select_tool`, `nearest_at`, `_bare_brush`, `_remove_at`; `make_rubber` at `PartsArc.address(ORDER.size())`; `enable_brush_controls` skips its eraser when the arc has one; `make_tool` handles macro stock (scaled to the rack). Thresholds `minf(.035, step()*.3)` and `minf(.075, step()*.45)`. |
| `scaffold_workstation/display.gd` | `copy_pose`, bounds and `fitted_offset` ×`lattice()`. |
| `scaffold_workstation/model.gd` | `MACRO_UNITS {rod_4: 2, rod_8: 4}`, `MACRO_FACES {quad_4: 2}`, `is_macro`, `is_macro_face`, `as_face`, `macro_records` → `line_records` (skips `covered` stretches, refuses `rod_overlaps`) and `face_records` (frame + one span-2 quad; `point_free` decides the centre); `edge()` composes any length from halves; `canonical` accepts span 2; `pose` through `as_face`. Records stay atomic. |
| `scaffold_workstation/geometry.gd` | chain visual and shape for macro rods; `shape_for`/`visual` map macro faces through `as_face`. |
| `scaffold_workstation/parts_arc.gd` | `ORDER` = point, 1 m rod, 2 m rod, **4 m rod**, triangle, quad, **4 m quad**, wedge, pyramid (nine sockets, step π/8); availability `[0,3,4,6][tier]`, prefabs from 7. |
| `modular/places/place_spec.gd` | optional `activity {artifact, config?, mount?: floor\|wall, side?: south\|north\|east\|west, test?: balls}`. |
| `modular/places/place_builder.gd` | `ACTIVITY_LIFT .03`; `recipe.activities` entries `{id, place, artifact, config (+slot_size, slot_depth, slot_floor, slot_rim, slot_margin 0, rim_width .5, edge_band 1), position, rotation?, mount?, side?}`; a wall sits `shell_thickness + .01` inside the shell on its side, facing in; `test: balls` adds a `pocket_test` entry over the same slot. |
| `void/trials/principal_places/places.gd` | after the installations: `for item in recipe.activities: Activity.build(item); add_child; Activity.fit`. |
| `void/trials/principal_places/recipe.json` | `activities`: noise on the disco plate (y .07), gaussian random in the biome bath (y 3.03), sine floor in the hanging basin (y 7.03), a noise wall on the bath's north wall, and a pocket test over each of the three floors. |

A doubled `const Activity` line slipped into `places.gd` from a rerun of my patch and parsed as an error; it was
caught by the hall probe before the export and removed. The lesson is recorded below.

## New, tracked, mine

| file | what |
|---|---|
| `commons/modular/places/place_activity.gd` | `build(item)` makes the artifact's scene with the config as `config_*` metas, stands it at `position`/`rotation`; `fit(node, item)` applies the config in the tree. |
| `commons/context/walkgrids/TopologySpace.gd` | the slot: `fit_slot`, `rim_width`, `edge_band`, `slot_depth`, `slot_margin`, `mount` floor\|wall (`_stand`), `finish_heights` (called in `create_mesh_from_heights` for every subclass), `apply_slot_config`/`apply_grid_config`/`meta_config`, `bump_map` (normal map from the heights, deferred onto the subclass's material), `collision_step` (coarse trimesh). |
| `commons/artifacts/pocket_test/` | the button, the hundred balls, the readout, `surface_entropy_bits` (256 equal-area bins on the upper hemisphere), `settled` signal. Token `pocket_test` in `registry/walkable_surfaces.json`, with `sine_space_floor` (the walkgrid sine floor; `sine_space` is the wavefunctions room). |
| `commons/data/artifact-parameters/{noise_space,random_space,sine_space_floor,pocket_test}.json` | in your format, plus `category`, `playground`, and a `slot` block. |
| `commons/data/inventory/workbench.json` | bench stages for the inventory hand (contact at Point One, the metre grid from Point Lines, `grid_y`). Not the workstation. |

## Evidence

| probe | result |
|---|---|
| `probe_workstation_neck` | 3/3 — hand model 0.0364 m between neighbours, collar reach 0.0182; glass copy 0.091; Lines station 0.1 |
| `probe_workstation_touch` | 4/4 — touch selects, paints two points, rubber erases one, undo restores |
| `probe_workstation_rods` | 5/5 — the 4 m rod lays 4 points + 4 rods; across a 2 m rod only the missing; undo; the 8 m rod has no socket |
| `probe_workstation_plate` | 5/5 — frame of 15 joints and 16 rods, one plate of span 2, no centre joint unless held |
| `probe_slot_surfaces` | 13/13 — fills 10 × 8, rim flat, trimesh, no-slot unchanged, builder + activity, the wall, the east-wall piece |
| `probe_walkgrid_family` | 18/18 (+3) — all twenty fit; erosion 70 s, reaction-diffusion 9 s, cellular automata 1.7 s |
| `probe_hall_activities` | 4/4 — the four hall samples where their places are |
| `probe_pocket_test` | 3/3 — finding: sine pocketed 38/100 (one trough), gaussian random 65/100; entropy 4.67 vs 4.79 bits |

Run any of them with `godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_<name>.tscn`
under `tools/godot_watchdog.py --expect=ada_run/workstation/<name>.json`; the family and pocket probes want
`--grace=120 --stall=60`.

## Lessons that cost a pass

- A patch that inserts after an anchor that survives the insert is not idempotent: a rerun doubled blocks in
  four walkgrid files, the place builder, the web panel and the hall script. Check a marker, or never rerun a
  partial run.
- `[8.0, 1.0] == [8, 1.0]` is false in GDScript; compare floats.
- A point on the workstation is only addable as a cardinal neighbour of a standing point; diagonal adds fail
  silently.
- The watchdog's 45 s boot grace kills a probe that waits on erosion; write the report incrementally.
- Godot 4.6's Label3D billboard enum is `BILLBOARD_FIXED_Y`.

## Open

- Pool walls are as high as pools are deep; wall-native artifacts want a frame type with 3 m walls, whose
  opening is written from the slot's own numbers so the flat rim meets it.
- The bench's domain is 6 m, so the 8 m rod never fits; growing it also means a bigger glass bay.
- Erosion in a slot needs baking or a droplet cap.
- The budget counts frozen things and tumbling bodies alike (inventory side).
- Categorising the remaining artifacts: slot, self-sufficient, or not for the playground.
