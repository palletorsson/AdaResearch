# randomness_04: Random_Cubes, Random_Rotate_Random_XYZ, Random_Walk, Random_Gaussian, Random_Mushrooms

Owner: Claude worker A, batch 25, 2026-10-21. **Draft before native runs**: every claim
below is a static reading of source and data unless it says "measured". The coordinator
completes the native, export and editor sections.

| Gate | Result |
|---|---|
| Schema (`rooms.schema.json`) | pass |
| `validate_void_rooms.py --trial=randomness_04 --editor` | valid; warnings only (source-dense access footprints on floor 1, the two structure blocks under the spawners, and the legacy default checkpoint (-6, 4.5), which this trial does not use: its spawn points are (0, 0.06, 12)) |
| Source audit (`audit_void_transfer.py`) | **362 / 362** |
| Native, desktop + synthetic XR | pending (coordinator) |
| GLB export | pending (needs R4 markers) |
| Editor | pending |

Standard tower: 42 x 32 m, 6 m storeys, pillars and both 5 x 6 m shafts unchanged. No
walls or ceilings added. All 75 inventoried IDs appear once, with their key, every token
config key, facing = (yaw + 180) mod 360, and the token scale.

| Status | Count |
|---|---|
| Placed | 75 |
| Native verified | pending |
| Editor verified | pending |
| Curated | 0 |
| Headset | not tested |

## Placement

Each hall turns 180° rigidly so its spawn lands on the arrival (0, 12):
Random_Cubes and Random_Rotate `x = -col, z = 12 - row`; Random_Walk `x = 9 - col`;
Random_Gaussian `x = 5 - col`; Random_Mushrooms `x = 8 - col` (all `z = 12 - row`).
`place_randomness_04.py` (this folder) writes floors 1-5 and `moves.json`.

**Moves (53 IDs, two vectors, all recorded in `moves.json`):**
- **Floor 1, the 48 edge profiles, +2 m x as one block.** Rigidly, the field's eighth
  column (x -8.5..-7.5, z -3..3) stood inside shaft A, over the drop to floor 2's pad.
  The 6 x 8 field keeps its 1 m pitch; 1 m clearance to shaft A. The other seven works
  stay rigid.
- **Floor 2, the whole hall, +5 m x.** `random_decay_multimesh #study:rotation` fits its
  two stacks to a 10 m display (x -11..-1 at the rigid anchor: through shaft A), and
  RotateGridCubes stood 7.5 cm from shaft A. One vector keeps every relation; the wall
  now ends 1.5 m short of shaft A.

**Heights other than the token's y field (recorded):**
- `random_object_spawner` x 2: **1.0**, on the source's structure `2` cells, restored as
  two `platform_block` props (1 x 1 x 1 m, "structure 2") at (-5, 6) and (-6, 6). Museum
  plan: `support_height_m 1.0`.
- `random_walk_collection`: **0.75**, the `#plinth:0.75` deck where the museum stands the
  root (a plinth erases the hover). Its six frozen sheets hang 0.28-0.40 m below the
  root, so height 0 would bury them in the slab. **Missing support:** no plinth is built.
- `bubbles_random`: token 0.85 (= its `#plinth:0.85`). **Missing support:** no plinth.
- Token heights kept: pixel_cloud 0.1, GaussianPaintSplatter 1.5, galton_board 0.9,
  distribution_comparator 0.83 (the last two hang their own cabinets below the origin by
  exactly that height x scale, so they meet the slab).

**Floor 3 moat basin (source structure `0`).** The ring around random_walk_128 is the
museum's basin (`depth 2.5, glass false, fire false`), transferred rigidly as a Void
basin with six rects. It abuts both shaft openings at x ±7.5 (the ring is 15 m; the gap
is 15 m) and hangs 2.34 m below floor 3's slab into floor 4's storey (bottom 3.3 m
above floor 4; floor-4 works under it reach 2.3 m). Same decision pattern as
randomness_03's basin; flag for review.

**Floor sign** moved on floors 3 and 5 only (`layout.json` `floor_sign_positions`,
-14, -5.5): the default board at (3.5, -7.8) stands inside random_walk_128's glass and
lattice (floor 3) and across couture_comparison's third figure (floor 5, static).

Not transferred: walls, `s`/`sp`, `t`, `an`.

## Per work: action, evidence, fit, remaining

| id | action / animation | evidence planned (probe) | fit / dependency | remaining |
|---|---|---|---|---|
| f1_dice_throw_3_2 | grabbed die, settled face read, reward balls; RESET / CLEAR | real pickup + drop, face read; real pointer RESET | | CLEAR not pressed |
| f1_coin_toss_8_2 | 8 coins; disclosure:origin launch gauges | gauges built (API); real pointer REFILL | | coin throw not run |
| f1_paired_dice_column_5_4 | two tray dice, pair sum column | real pointer RETURN DICE (both trays signal); diagnostic `paired`: real throw into tray A | | CLEAR RECORD; full pair |
| f1_continuing_die_2_5 | six-again chain | real pointer NEW CHAIN | | throw |
| f1_dark_sphere_9_5, f2_dark_sphere_9_7 | ambient egg | geometry; gestation rung "" as in the museum (API) | | |
| f1_random_object_spawner_5_6, _6_6 | cubes arrive 0.3-1.3 s, capacity 20, wood knock | arrivals (API); block under it (geometry ray); knock at the spigot (needs R4) | 1 m block restored as props; knock was at world (0,1,0) (R4) | |
| f1_random_edge_profile x 48 | one random 5-point relief each, every boot | all 48 built, relief, 5 points (API) | moved +2 m x as a block | |
| f2_hardware_entropy_decay_1_6 | hand/head motion drives shader decay | real pointer PAUSE; Space ignored (needs R2) | facing 270 | RESET |
| f2_Random_Rotate_Random_XYZ_3_10 | **none: no grid floor** | no geometry, `multimesh_instance == null` (API) | source-empty; editor marker (R4) | marker, not a rotation |
| f2_random_decay_multimesh_6_10 | rotation study, 10 m display | two layers, no drift/sink (API); real pointer TOGGLE; Space ignored (R2) | prism stack ~5.5 m tall vs 5.64 m clear (static); current camera (R3 if needed) | RESET |
| f2_RotateGridCubes_6_11 | compact 5 x 5 half-wave | 25 cubes at 0.75 m (API) | | |
| f3_random_walk_collection_3_5 | six walk-law sheets, grabbable | 6 sheets above the slab (API, geometry) | plinth missing | grab not run |
| f3_random_walk_terrarium_9_5 | five walkers; logbook stand | logbook + named seed (API); console (R1); real pointer 2D | | 3D, LONG STEP, RESET, logbook buttons |
| f3_random_walk_leash_15_5 | tugged orb on a leash | real pointer drag IMPULSE | leash line drawn as if local (right at facing 0) | orb grab, RESET |
| f3_random_draw_dot_6_8 | held dot + seeded walk | real pointer HAND / RANDOM | | dot grab and drawing |
| f3_random_position_rails_13_8 | lever draws one number, two rails | real lever (pointer drag / grip), one draw; real pointer REPLAY | | RUN, prediction slider |
| f3_pixel_cloud_3_9 | seeded self-avoiding cloud (101) | Space does not rebuild it (R2) | | |
| f3_random_walk_128_9_17 | 32 x 32 lattice walk, 10 000 steps | lattice grows (API); glass + rails (R1); moat 2.5 m deep (geometry ray); real walk over the bridge to the doorway | moat basin; rails ~0.025 m into each shaft opening (measured check, cap 0.03) | |
| f4_distribution_sampler_5_6 | four laws, falling histogram; cabinet + wing | cabinet, wing, seed (API); console (R1); real pointer UNIFORM; Space ignored (R2) | | other laws, cabinet buttons |
| f4_GaussianPaintSplatter_2_7 | Gaussian paint on a 640 px canvas | canvas + 0.65 scale (API) | unscripted root, script on child | |
| f4_galton_board_2_10 | pegs, bins, bell curve | real pointer AUTO; ball spawn height (R5); that ball counted in a bin | 1.5x scale spawn seam (R5) | DROP, RESET, SPEED |
| f4_distribution_comparator_8_10 | three laws side by side | real pointer RESAMPLE | SAMPLES slider dead in the source | |
| f5_bubbles_random_3_5 | rising bubbles in a dish | bubbles alive at 0.25 (API) | plinth missing | |
| f5_mushrooms_8_11 | 6 m specimen bed, table, three edibles | bed + table + 3 edibles (API); glass + console (R1); real pointer NEW SEED; real grab of an edible | edibles heal the museum GameManager | eating, SHOW/KIND/SIZE/REGROW |
| f5_silhouette_arrivals_13_17 | six arrivals without replacement | real pointer REPLAY then ARRIVE | | AUTO, DRESS, FORMS |
| f5_couture_comparison_8_20 | three seeded couture figures | real pointer NEXT SEED, RESET | | GARMENT |

Shared chain, both modes: safe arrival, geometry and config meta for all 75, open
shafts, visitor camera, shaft-pad descent through five floors, sleeping floors, return,
retry. Fit (all floors): whole shaft openings, arrival, floor sign at its trial position,
and on floor 4 the floor-3 moat basin.

## Requests (REQUESTS.md)

R7 (new, measured): dice RESET does not move a die that has left its spawn, because the
XR pickable freezes kinematically and the source unfreezes deferred;
`dice_throw_local.gd` teleports in static freeze. Galton source defects recorded: the
pool is counted once in the centre bin at build (50), and balls resting in the side gaps
beyond the nine bins are never counted.

R1 museum exhibit stage (glass, consoles, moat rails), R2 keyboard fallbacks off the
Void's keys, R4 spawner + no-grid adapters with editor markers and R5 galton spawn
adapter: wired by Codex (20:38). R3 conditional camera retirement: deferred; bounds-2
passed the visitor-camera check. R6 (optional): shared walker/exporter should skip
zero-surface meshes. Trial adapters in this folder:
`random_object_spawner_local.gd`, `rotate_no_grid_preview.gd`, `galton_board_local.gd`.

## Measured bounds and screenshots

bounds-1..5, desktop (coordinator): 117 / 17 / 22 / 15 / 15 checks, all passing, no
engine errors, every FIT line empty. Highlights (metres above floor):
random_decay_multimesh y 0..5.46 (0.18 m under the 5.64 m ceiling); random_walk_128
with glass and rails x -7.53..7.53, y -0.14..5.05, z -12.52..2.52; mushrooms glass
y -0.14..4.55; spawners on their blocks y 1.06..1.48; walk sheets y 0.35..0.48.
`random_draw_dot_6_8` first measured x 0..3.25, y 0..18: an empty top-level trail mesh
at the world origin, not geometry (REQUESTS R6); the probe now skips zero-surface meshes.
Screenshots: pending the full run.
Planned photos: 01-03 floor 1, 04-06 floor 2, 07-09 floor 3, 10-11 floor 4, 12-14 floor 5
(`capture_floor()`), eye-height arrival views on every floor.

## Commands

```
python commons/void/trials/randomness_04/place_randomness_04.py      # only on an empty rooms.json; --force rewrites floors 1-5
python tools/validate_void_rooms.py --trial=randomness_04 --editor
python tools/audit_void_transfer.py randomness_04
python tools/test_transfer_native.py randomness_04 --focus bounds-1 --mode desktop   # ... bounds-5
python tools/test_transfer_native.py randomness_04 --focus <case> --mode desktop|xr
python tools/test_transfer_native.py randomness_04
python tools/export_void_trial.py randomness_04
node tools/test_void_transfer_editor.cjs randomness_04
```

Focused cases: bounds-1..5, dice (with coin, continuing die and floor-1 identity),
paired, spawner, decay, hardware, walk, rails, moat, gaussian, galton, comparator,
mushrooms, arrivals.

## Untested or static only

Physical headset; listening (wood knock, walk audio, bubbles are silent in the source);
eating a mushroom; the paired-dice full pair; any button named under "remaining";
prism-stack top height; spawner audio before R4.

## Exact files

**Mine (this folder):** `rooms.json` (floors 1-5, floor-1 props, floor-3 basin),
`layout.json` (`floor_sign_positions` 3 and 5 only), `place_randomness_04.py`,
`moves.json`, `probe.gd`, `random_object_spawner_local.gd`, `rotate_no_grid_preview.gd`,
`galton_board_local.gd`, `dice_throw_local.gd`, `REQUESTS.md`, `STATUS.json`, `HANDOFF.md`,
`transfer-status.json`, `evidence/source-checks.json` (audit output).

**Untouched:** sources, maps, chapter texts, catalog, `playable.json`, `trial.tscn`,
`source-inventory.json`, shared runtime and tools.
