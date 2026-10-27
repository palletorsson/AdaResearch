# randomness_03: shared-code requests (Claude Opus, batch 24)

All requests are trial-scoped. No source files are touched.

**State (final).** Codex installed R1, R2, R4 and R5, and native acceptance
(147/147), export and the editor test (17/17) passed with them. R3 is recorded, not
requested. The sections below keep the original request text; "static" there meant
"before the native diagnostic". Every one of those diagnoses was later confirmed
natively.

## R1. random_removal_arena must be configured before `_ready` (static)

**Placement:** `f1_random_removal_arena_8_17`. Token config:
`columns:15 rows:11 full_crossing:true tesla_coils:true plinth:0`.

**Problem.** `removal_arena.gd` builds everything in `_ready()`: tiles, colliders,
side banks, the coil canopy and the trigger zone. It reads `columns`, `full_crossing` and
`tesla_coils` only in `apply_grid_config()`, which never rebuilds. The catalog entry has
no `configure_before_ready`, so `floor_content.gd` calls `apply_grid_config` after
`add_child`. In the Void the arena therefore builds:
- the default 9 x 11 = **99** tiles instead of the source's 15 x 11 = **165** (the
  museum chapter text says 165);
- no Tesla canopy;
- the legacy side banks.

The readout still prints 165 because it reads the updated variables.

**Request.** Add `"configure_before_ready": true` to `catalog.json` →
`random_removal_arena`, or do the same in a trial-scoped `floor_content` branch.
`apply_grid_config` is safe before `_ready`: `set_speed` and `_update_readout` guard
null `remover` and `readout`.

## R2. Arena never recognises the Void visitor (static)

**Problem.** `removal_arena.gd: is_player()` walks up for a museum ancestor with
`_basin_burned`. With none (the Void case) it returns `body.is_in_group("player")`.
`game.gd:133` puts the Void body (desktop walker or XR PlayerBody) in group
**`player_body`**, not `player`. So entering the arena never starts a removal, and
neither walking nor the Tesla timer withdraws any support.

**Request.** Add a trial-scoped adapter (for example `removal_arena_local.gd`) whose
`is_player(body)` also accepts `body.is_in_group("player_body")`, or the Void game
body. It should keep the original seed, timing, tiles, coils and readout, and be wired
in `floor_content.gd` for `randomness_03` / `random_removal_arena`.

## R4. Hook for the nature demo adapter (adapter written; needs wiring)

**Measured, native diagnostic `nature`.**
- `spawner.gd:93` sets `entity.global_position = world_position`, and the demo passes
  its *local* grid. All 48 critters therefore stood at world y 0, x 0..10.5,
  z 0..50.5: the roof level, outside the tower.
- The demo's `UI` CanvasLayer is visible.
- `_unhandled_input` is live. Its R, Space and C keys also randomize, respawn and
  clear the population when the visitor presses R (last floor) or Space (jump).

**Adapter**, my trial folder: `commons/void/trials/randomness_03/nature_demo_local.gd`.
It maps only the demo's own grid and single spawns into the demo's frame; offspring
already spawn between their parents. It also:
- hides `UI`;
- disables `_unhandled_input`;
- adds a rack panel `VoidKeyPanel` with the original key actions as pointer buttons:
  TREE, CREATURE, FLOWER, FUNGUS, RANDOMIZE, EVOLVE, REPOPULATE, CLEAR, LOD, HYBRID.

**Exact hook.** In `floor_content.gd`, before `add_child`, with the other trial swaps.
The scene overrides `grid_rows = 3` and `grid_spacing = 3.5`, so keep the exported
values across the swap:

```gdscript
if trial_id == "randomness_03" and item.artifact == "nature_system_demo":
	var keep := {}
	for p in ["grid_rows", "grid_cols", "grid_spacing", "initial_lod", "auto_populate", "auto_evolve", "evolve_interval"]:
		keep[p] = artifact.get(p)
	artifact.set_script(preload("res://commons/void/trials/randomness_03/nature_demo_local.gd"))
	for p in keep: artifact.set(p, keep[p])
```

**Not shrunk.** The source strip is 10.5 x 50.5 m in demo space, and creature body
chains reach further. With the source facing (270) it cannot fit the 42 x 32 m floor
anywhere. At the rigid anchor (−9, −6) it would cross shaft A. I placed the anchor at
the west edge (−21.5, −6), so the strip runs outward over the void from x −21.5 to
about −72. That is unsupported, and an exterior platform is needed (curation). The
panel stands about 2 m inside the edge.

## R5. Editor markers for the two measured-empty utilities (scripts written; need wiring)

The export gave **no GLB** (`url` missing, 0 meshes) for:
- `f2_remove_random_1_2`: `remove_random:90` with no `local_grid`, so no board binds.
- `f2_pickup_cube_placer_1_3`: no GridSystem in the museum or the Void ("No GridSystem
  found!").

`test_void_transfer_editor.cjs:20` then fails with `path` undefined. The batch-23
`pipe_empty_preview` mechanism fits: `export_void_editor.gd:73` calls
`prepare_editor_preview()`.

**Exact hooks.** In `floor_content.gd` (no exported overrides in either scene):

```gdscript
if trial_id == "randomness_03" and item.artifact == "remove_random" and not item.get("config", {}).has("local_grid"):
	artifact.set_script(preload("res://commons/void/trials/randomness_03/remover_unbound_preview.gd"))
if trial_id == "randomness_03" and item.artifact == "pickup_cube_placer":
	artifact.set_script(preload("res://commons/void/trials/randomness_03/placer_no_grid_preview.gd"))
```

The floor-1 `local_grid:true` remover is untouched and builds its board (native
checks). In `tools/test_void_transfer_editor.cjs:27`, extend `geometryLabel`. For
`randomness_03`, `f2_remove_random_1_2` and `f2_pickup_cube_placer_1_3` should read
"declared dependency marker", not "real geometry".

## R3. The basin has no fire; recorded, not requested yet

Palle chose (2026-10-21) to transfer the source's 3 m basin as a Void floor basin
(`glass:false`) under the arena, which now stands at height 0. The museum burns a
visitor at the basin floor (`_basin_burned` → death, then back to the save point).
The Void basin builds a bottom and walls but no fire. A visitor who falls stays in a
3 m pit until retry (B). If the encounter should end the run, the Void basin needs a
`fire`/kill option: a shared `basin.gd` / `game.gd` change. Decide after review.
