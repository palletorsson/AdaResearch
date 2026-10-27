# randomness_05: five Random halls

Owner: Claude worker B, batch 25, 2026-10-21. The Claude coordinator ran every Godot job,
serially. **State: native, export and editor gates passed; awaiting Codex review. Not
accepted.** Results quoted below come from those runs. Statements marked *static* come from
reading the source only.

| Gate | Result |
|---|---|
| Source audit | **163 / 163** |
| Schema + editor validator | valid, 0 errors, 5 spatial warnings: neighbouring access squares, as in the sources |
| Parse (`check_compile.gd`) | probe and the 3 adapters, OK |
| Bounds-1..5 (desktop) | all checks pass, every FIT line empty |
| Exit leak (bounds runs) | found and fixed (R4b); `orphans` then exited 0 with no leak lines |
| **Full native, desktop + synthetic XR** | **257 / 257**, 106.7 s, exit 0, no engine errors; FIT empty on all five floors in both modes |
| GLB export | 64 models, no failures; all 26 placements have meshes |
| Editor | **29 / 29** |

Focused cases (desktop unless marked), all passed:

| case | checks |
|---|---|
| field | 7 |
| fieldmove | 6 |
| fieldsleep | 5 |
| crossing | 7 |
| doors | 5 |
| timing | 5 |
| waiting | 5 |
| space | 5 |
| pheromone | 6 |
| darts | 5 |
| seeded | 5 |
| seedlight | 13 desktop + 13 XR |
| arena | 8 desktop + 8 XR |
| orphans | 8 |

Receipts: `evidence/checks.json`, `engine.log`, `measured-bounds.json`,
`editor-checks.json`, and `evidence/debug/<case>-<mode>/`.

R1–R4 are wired by Codex in `floor_content.gd`, scoped to randomness_05, and verified
above. R4b lives inside my wired adapter. R5 and R6 are documented only.

The tower is the standard one: 42 x 32 m, 6 m storeys. Pillars and both shafts are
unchanged. All 26 inventoried IDs appear exactly once, each with its key, its config (strings)
and its token scale. Facing is yaw + 180, except two Random_Game exhibits turned for the fold.

The live museum plan (`em_plan`) holds the same 26 tokens, configs and rotations. It adds
museum dressing that is not transferred: colonnades, carved walk channels, and fire in
Random_Game's basin (R5).

| Status | Count |
|---|---|
| Placed | 26 |
| Native verified (geometry, config, fit, and the interactions below) | 26 |
| Editor verified (independent move, copy, rotation, save/reload) | 26 |
| Curated | 0 |
| Codex accepted | no (review pending) |
| Headset | not tested (synthetic XR only) |

## Placement

Each hall is turned 180 degrees about its spawn (`x = cx - col`, `z = cz - row`):
- spawn `s` for four maps;
- `sp` for Random_Space, which has no `s`.

`place.py` writes `rooms.json` and `placement-ledger.json` (rigid → placed, every reason).
Walls, `s`/`sp`, `t`, `wp` and `an` are not transferred.

| id | rigid | placed | facing | h (token) / scale | note |
|---|---|---|---|---|---|
| f1_seeded_room_5_7 | -5, 5 | **-1.5, 4.5** | 180 | 0 (0) / 1 | off shaft A and the floor-1 pad exit |
| f1_perlin_noise_bridge_6_16 | -6, -4 | = | 180 | **0** (-0.5) / 1 | grids stand at 1 m on their own |
| f1_env_one_5_17 | -5, -5 | = | 180 | 4 (4) / 0.5 | see Fit |
| f1_curl_noise_particles_9_17 | -9, -5 | = | 180 | **0.25** (-0.5) / 1 | centred 0.5 m volume set on the slab |
| f1_random_transformations_geometric_3_18 | -3, -6 | = | 180 | 1 (1) / 0.2 | |
| f1_sculpt_one_2_19 | -2, -7 | = | 180 | 0 / 1 | |
| f1_dark_sphere_6_20 | -6, -8 | = | 180 | 0 / 1 | |
| f2_pollock_painting_in_3d_7_6 | 0, 6 | = | 0 | 0 / 1 | |
| f2_monte_carlo_dartboard_4_12 | 3, 0 | = | 0 | 0 / 1 | |
| f2_pipe_dream_10_15 | -3, -3 | = | 0 | 1.15 / 0.25 | |
| f2_extreme_randomness_5_20 | 2, -8 | **2, -10** | 0 | 1.5 / 0.2 | particle gallery crossed the floor sign |
| f3_pheromone_terrain_6_3 | -6, 9 | = | 180 | 0 / 1 | comparison mode: a 4.8 m display |
| f3_dark_sphere_2_5 | -2, 7 | = | 180 | 0 / 1 | |
| f3_clipboard_2_6 | -2, 6 | = | 180 | 0 / 1 | `pheromone_axioms:194:1.0` |
| f3_clipboard_3_7 | -3, 5 | = | 180 | 0 / 1 | `queer_energy:194:1.0` |
| f4_noise_mixer_4_3 | 1, 11 | **2.25, 0** | 180 | **0.9** (-0.5, plinth 0.9) / 1 | hall shift; floats (R6) |
| f4_worley_noise_8_4 | -3, 10 | **-1.75, -1** | 180 | **0.4** (-0.5, plinth 0.4) / 1 | hall shift; floats (R6) |
| f4_random_space_6_6 | -1, 8 | **0.25, -3** | 180 | **0** (-0.3, offset +0.2) / 1.4 | see Fit |
| f4_dark_sphere_5_7 | 0, 7 | **1.25, -4** | 180 | 0 / 1 | hall shift |
| f4_shannon_entropy_meter_4_9 | 1, 5 | **2.25, -6** | 180 | **1.05** (-0.5, plinth 1.05) / 1 | hall shift; floats (R6) |
| f5_r_c_9_6 | 0, 6 | = | 180 | **0** (3) / 1 | over the 5 x 3 m basin rect |
| f5_random_removal_arena_9_17 | 0, -5 | = | 180 | **0** (3) / 1 | over the 9 x 9 m basin rect |
| f5_random_doors_9_29 | 0, -17 | **-16.5, -6.5** | **0** | 0 / 1 | fold, west wing |
| f5_door_timing_trials_9_38 | 0, -26 | **-13.4, 9.5** | **0** | 0 / 1 | fold, west wing |
| f5_cube_projectile_spawner_9_51 | 0, -39 | **14.5, 7.5** | 180 | 0 / 1 | fold, east wing |
| f5_waiting_profile_9_61 | 0, -49 | **16, -8** | 180 | 0 / 1 | fold, east wing |

### Heights

- **Legacy `-0.5`.** This is the half-cube grid offset, and the schema floor is 0. Perlin is
  at 0. Curl's flow volume is centred on its origin, so it is lifted 0.25 m to rest on the
  slab.
- **`#plinth:H`.** The museum builds a station plinth of H and stands the body on it ("the
  plinth IS the height claim"). Placed at H, with no plinth (R6).
- **r_c and the arena, token 3.** Measured from the basin floor of the source pits, as in
  randomness_03. Floor 5 carries `basin {depth 3, glass false}` with rects
  `[-2.5, 4.5, 5, 3]` (map cols 7-11, rows 5-7) and `[-4.5, -9.5, 9, 9]` (cols 5-13,
  rows 13-21). Both bodies stand at 0.
  - r_c lowers itself 0.28 m (`_prepare_crossing`), so its stones stand 0.22 m proud. Its
    own bed is 1.02 m down, with a WayOut ramp.
  - The basin bottoms hang 2.9 m above the catch floor, which has no content.
- **random_space.** Token -0.3 plus `#offset:0,0.2,0` is net -0.1, which the schema cannot
  hold. At 0, its ±0.17 m relief stands 0.1 m higher than that sum. The Void does not read
  `offset`; it is kept as config.

### Random_Game folded (66 m source, 32 m floor)

Source order, one loop:

1. **Centre band, heading north from the arrival.** Crossing (rigid), then the arena
   (rigid).
2. **North strip, heading west.** Into the west wing.
3. **West wing, heading south.**
   - **Fire doors.** Turned 180 so the chooser side faces the visitor. The bypass east of
     them is kept.
   - **Door timing.** South of shaft A, also turned 180.
4. **South strip, heading east.** Past the arrival.
5. **East wing, heading north.** The falling field (south of shaft B), then the waiting
   profile (north of shaft B).

Floor 5's sign moves from (3.5, -7.8) to **(8.5, -12.5)**: the default stands inside the
arena's glass box over the basin. This is `layout.json` `floor_sign_positions`, the existing
trial mechanism; the layout is otherwise unchanged.

## Measured bounds (coordinator, bounds-1..5, desktop; metres above each floor)

| floor | id | x | y | z |
|---|---|---|---|---|
| 1 | seeded_room | -5.87..2.87 | 0..3.58 | 0.13..10.26 |
| 1 | perlin_noise_bridge | -6.29..-5.70 | 0.66..1.15 | -4.25..-3.87 |
| 1 | env_one | **-19.92..9.94** | **-3.56..11.46** | **-20.17..9.66** |
| 1 | curl_noise_particles | -9.35..-8.65 | 0..0.50 | -5.35..-4.65 |
| 1 | random_transformations_geometric | -3.61..-2.02 | 0.39..1.52 | -6.20..-5.80 |
| 1 | sculpt_one | -4.33..-0.01 | **-1.40**..2.59 | -9.61..-4.11 |
| 1 | dark_sphere | -6.46..-5.54 | | -8.47..-7.53 |
| 2 | pollock_painting_in_3d | -2.17..2.17 | 0..0.12 | 4.53..7.47 |
| 2 | monte_carlo_dartboard | 2.42..4.48 | -0.38..1.78 | -0.12..1.30 |
| 2 | pipe_dream | -3.52..-2.25 | 1.11..1.67 | -3.28..-2.33 |
| 2 | extreme_randomness | 0.92..3.10 | 0.48..2.59 | -11.03..-8.96 |
| 3 | pheromone_terrain | -8.40..-3.60 | 0..1.19 | 5.74..11.40 |
| 3 | dark_sphere | -2.42..-1.58 | | 6.58..7.42 |
| 3 | clipboards | at (-2, 6), (-3, 5) | -0.16..0.16 | |
| 4 | noise_mixer | 1.85..2.65 | 0.83..1.01 | -0.61..0.40 |
| 4 | worley_noise | | 0.40 (flat) | |
| 4 | random_space | -7.45..7.95 | -0.17..0.17 | **-17.00**..11.00 |
| 4 | dark_sphere | | | -4.42..-3.58 |
| 4 | shannon_entropy_meter | 1.69..2.81 | 0.79..1.31 | -6.01..-6.00 |
| 5 | r_c | -2.50..2.50 | -1.15..1.34 | 3.50..9.23 |
| 5 | random_removal_arena | -5.55..5.55 | -0.60..4.55 | -10.68..1.63 |
| 5 | random_doors | -20.83..-12.18 | 0..3.30 | -11.13..-6.25 |
| 5 | door_timing_trials | -20.92..-5.88 | 0..3.60 | 5.76..10.64 |
| 5 | cube_projectile_spawner | 8.40..18.52 | **-0.66**..1.64 | 3.48..13.13 |
| 5 | waiting_profile | 13.20..18.70 | 0..2.73 | -9.35..-5.67 |

No placement enters a whole shaft opening, the arrival, a floor sign or a basin, apart from:
- env_one, exempt and measured, visual only;
- random_space's capped 0.45 m into shaft B.

Below the slab, by source construction:
- sculpt_one's base deformations (the sculpture is centred on its origin);
- the field emitter, a 1.2 m box centred on its origin (token without height);
- the crossing's bed and the arena tiles, which hang into their basins.

**The field stand is mirrored.** It is `top_level`, set after `add_child`, so it keeps the
mount's 180° turn. Its readout stands west of the field, at x about 9.2, outside shaft B.

## Fit and dependencies (static unless measured above)

- **env_one (floor 1).**
  - Its kitbash cloud is world-scale: modules ±7.5 m and ambient/atmosphere MultiMeshes
    ±15 m at scale 0.5, around (-5, 4, -5). It crosses shaft A's opening, the floor sign
    and both neighbouring storeys.
  - It has no colliders (source has no bodies), so it cannot block a shaft. `fit_checks`
    exempts it and `env_report` measures it.
  - Its seed console rides the kitbash origin, **4.00 m up (measured)**, out of reach by
    hand. A real pointer press from the floor 2 m in front does reach it (`seedlight` and
    acceptance).
  - Nothing shrunk. Needs curation.
- **random_space (floor 4).**
  - It is 15.4 m wide at token scale 1.4; the gap between the shafts is 15.0 m. Offset
    0.25 m east: shaft A (the descent shaft and its pads) is clear, and shaft B is entered
    by **0.45 m** at z -3..3 (capped measured check).
  - It runs 1 m past the z = -16 floor edge (measured: z -17.00), and columns (±5, -14)
    stand through it.
  - The other four keep their places on it (hall shift +1.25, -11).
  - Its edge rises up to 0.17 m above the slab. Real walking from the arrival reaches a
    raised point at (-6, 6), 0.15 m above the slab, and stands on it, in both modes.
- **noise_mixer, worley, shannon.** Float at plinth height with no support (R6).
- **Random_Game.**
  - The open fire door's top reaches 5.65 m, 1 cm into the upper slab's underside. It is
    only up while open.
  - The arena's glass box is 4.5 m tall (R1).
- **Overlaps that the sources also have.**
  - Floor 1: perlin / env_one / sculpt / random_transformations.
  - Floor 3: dark_sphere / clipboards.
  - Floor 4: random_space / dark_sphere.
- **Clipboards.** They lie at floor level, as in randomness_03. `194:1.0` reads like the
  yaw:height shorthand that `clipboard.gd` ignores.

## Interactions: what each work does, and the evidence

In the evidence column, **real** means real mouse or synthetic-XR input (pointer, walking),
**API** means a script readback, and **geom** means a ray or bounds measurement. All rows
below are from the passed full acceptance (desktop and XR) unless a focused case is named.

| id | action | evidence | fit / dependency | remaining |
|---|---|---|---|---|
| seeded_room | 8 x 8 seeded plan extruded; REPLAY / NEXT SEED / FLAT-RAISE / INDEPENDENT / PERLIN / FREQUENCY; blue passage | 64 cells, seed 42 (API). **Real pointer** NEXT SEED → seed 43, blue passage still open | moved off shaft A | walk-through, the other 5 buttons |
| perlin_noise_bridge | white vs Perlin 16 x 16 columns; 3 sliders, RESAMPLE | geometry and config only | grids 1 m up, no table (as source) | sliders, RESAMPLE |
| env_one | 30-module kitbash, seed console | no colliders outside its console (geom). **R4 path 2:** real pointer NEXT from the floor → seed 42→43 and a different module draw. No visible sun or live environment under it; tower suns 1→1; visitor environment unchanged | R4; cloud spans all three storeys (measured); console 4 m up | curation |
| curl_noise_particles | 300 particles, curl flow | geometry, y 0..0.50 | lifted 0.25 | |
| random_transformations_geometric | CSG set re-rolled every 2 s | geometry | | |
| sculpt_one | seeded still life, seed console | **R4 path 1:** real pointer NEXT → seed 42→43 and a different composition. No visible sun or live environment under it; tower suns 1→1; visitor environment unchanged. `orphans`: no leak, orphan list unchanged after rebuild | R4; R4b leak fixed | |
| dark_sphere x3 | witness sphere | geometry | | |
| pollock_painting_in_3d | live drip painting on the floor (SubViewport) | geometry (frame panels) | no collision, as source | brush motion not asserted |
| monte_carlo_dartboard | sample-budget console, keys off | lesson and keys off (API). **Real pointer** THROW → +1 sample (101 of 500) | `controls:compact` has no rack panel to move | dial, FILL, 8 SEEDS |
| pipe_dream | bounded pipe growth | geometry | | |
| extreme_randomness | five rotating particle chapters | geometry | moved 2 m (floor sign) | |
| pheromone_terrain | paused comparison: ATTRACT / AVOID / +1 / +20 / REPLAY | 4.8 m display, seed 190919 (API). **Real pointer** +20 STEPS → 20, REPLAY → 0 | | ATTRACT / AVOID |
| clipboard x2 | held tutorial documents | geometry; case `clipboard` (real grab) not run | at floor level, y -0.16..0.16 | grab |
| noise_mixer | OCT / LAC / PER, SEED | geometry; case `mixer` not run | R6, floats at 0.83..1.01 m | SEED, sliders |
| worley_noise, shannon_entropy_meter | Worley quad; entropy gauge | geometry | R6 | |
| random_space | walkable random heightfield | collision above the slab (geom). **Real walking** from the arrival onto a raised point; stands on it | 0.45 m into shaft B (capped); to z -17.0 | |
| r_c | chasm crossing: 3 stones, bed, ramp, stele, tablet, idol; REPLAY / NEW SEED / CUE | crossing staged (API). Pit opens onto its bed 1.02 m down (geom; floor-5 basin). **Real pointer** CUE switches the advance notice off | R1 console (`control_fixed`) | crossing and fall |
| random_removal_arena | 81 tiles over the basin, glass box | 81 tiles (R2); glass box and compact console (R1); basin 3 m under the tiles (geom). **Real walking** withdraws tiles (log 74, 67, 65), desktop and XR. **Real pointer** REPLAY restores all tiles and colliders | basin without fire (R5) | fall; SLOWER / FASTER / NEW SEED |
| random_doors | one passage, two fire jets | **Real pointer** on the drawn passage (door 1) → passage and unlocked; REPLAY closes all | jets harmless here (R5) | fire door |
| door_timing_trials | three matched walk-through trials | **Real walking** onto plate A of SHOWN FIRST → chooses A (Void body). **Real pointer** REPLAY → new round | | trials 2 and 3 |
| cube_projectile_spawner | 8 x 8 m falling field, RUN / STOP, CLEAR | see R3 below | R3 effective height; C key off | panel buttons |
| waiting_profile | two arrival slots of wooden cubes; RUN / STOP / REPLAY / PROFILE | **Real pointer** RUN / STOP toggles; an arrived wooden cube is in the grab mask (preflight) | | grab, REPLAY, PROFILE |

### R3: the falling field is an effective-height adaptation

The token configures an 8 m launch (`field_height:8`) and the adapter keeps it as
`source_field_height = 8.0`. In the Void a storey has 5.64 m of clear height, so cubes
launch at an **effective 5.19 m**: the underside of the slab above, less the cube's half
size and a margin. Falls are therefore shorter than in the museum. This is not unchanged
behaviour. All other source values are kept: field mode, 8 x 8 m, 24 cubes, 0.5 s
interval, fall speeds, drift and jitter.

| case | measured |
|---|---|
| `field` | 2 of 2 real source spawns in 316 frames, both launched 5.19 m above floor 5. The first cube came to rest 0.23 m above floor 5 (half-cube 0.25), so it landed on the intended floor. |
| `fieldmove` | Mount raised 1 m: launches 4.19 m above the mount, 5.19 m above the floor. Moved 2.5 m and turned 90°: launches lie inside the 8 x 8 m field around the moved emitter at (13, 5.5); the source samples x/z in world axes, so turning the mount does not turn the field. `field_center_offset.y` +0.6: launches 4.59 m above the lifted field origin, 5.19 m above the floor. All under the slab. |
| `fieldsleep` | The cubes are children of the current scene, not of floor 5. Leaving for floor 4 puts the emitter to sleep: 0 launches in 2 s away. The 3 cubes already in flight kept processing and were freed within their 10 s lifetime (0 live after 11 s). |

**The first cube waits about 6 s. This is source behaviour, unchanged.**
`cube_spawner.tscn` authors `spawn_interval = 6.0`, and `activate_spawner()` starts the timer
in `_ready`, before the token's `spawn_interval:0.5` arrives. The first cube falls about 6 s
after the floor builds, then one every 0.5 s. The first native `field` and `fieldmove` runs
sampled for only 2.5 s and saw nothing. The probe now waits up to 8 s.

**Falling field and the visitor (static, not tested).** `ProjectileCube` reports a hit
through an Area3D on layer 21, or a `player` group / `Player` name. The Void walker is on
layer 20 and in `player_body`, and the rigid cube has no contact monitor. The cubes
therefore probably register no hit here.

## Screenshots (`evidence/`, desktop, native Mobile renderer)

| # | file | what it shows |
|---|---|---|
| 01 | `01-geometry-arrival-eye.png` | seeded room at eye height: plan board at seed 43, console, blue passage |
| 02 | `02-geometry-bench.png` | env_one's kitbash cloud fills the frame; sculpt_one and its seed console are visible |
| 03 | `03-examples-arrival-eye.png` | Pollock floor painting, pipe_dream (pink) and the Monte Carlo cabinet |
| 04 | `04-examples-pipe-particles.png` | pipe_dream and the Monte Carlo cabinet with its sample console (101 of 500) |
| 05 | `05-pheromone-console-eye.png` | pheromone comparison console and its 4.8 m display (step 0 after REPLAY), dark_sphere |
| 06 | `06-space-arrival-eye.png` | random_space walk surface from the arrival, dark_sphere, floor sign |
| 07 | `07-space-instruments.png` | walk surface, worley and noise_mixer quads, dark_sphere, floor sign |
| 08 | `08-game-crossing-eye.png` | the crossing: CUE / REPLAY console, stones, pit, braziers, stele and tablet; arena glass box behind |
| 09 | `09-game-arena-glass.png` | arena inside its glass box: 81 LEFT readout, compact console, tiles |
| 10 | `10-game-doors-west.png` | the three fire doors and their compact console, amber line |
| 11 | `11-game-door-timing.png` | the DRAWN AFTER trial: doors A / B, plates, round controls |
| 12 | `12-game-field-waiting.png` | the falling field: cubes in flight and resting, field lines, RUN / STOP / CLEAR console |

**Exhibits no screenshot clearly shows:**
- **Floor 1:** perlin_noise_bridge, curl_noise_particles, random_transformations_geometric
  and dark_sphere. In 02 env_one's cloud covers them.
- **Floor 2:** extreme_randomness. In 04 the camera stands at the Monte Carlo console and
  the small 0.2-scale gallery is not readable.
- **Floor 3:** both clipboards; they lie flat at floor level, outside the 05 view.
- **Floor 4:** shannon_entropy_meter is not identifiable in 06 or 07.
- **Floor 5:** waiting_profile appears only small and distant in 12.

These are recorded, not re-shot. Mirrored text in 10 and 12 is a shaft label and the
emitter's own label, seen from behind.

## Requests (`REQUESTS.md`)

| | What | State |
|---|---|---|
| R1 | exhibit staging for `randomness_05` | wired by Codex; verified (glass box, consoles) |
| R2 | arena configured before ready, and accepting `player_body` | wired by Codex; verified (81 tiles, real walking withdrawal, desktop and XR) |
| R3 | `cube_field_local.gd`: effective launch height (5.19 m vs configured 8 m), offset-y included; debug keys off | wired by Codex; verified (`field`, `fieldmove`, `fieldsleep`, acceptance) |
| R4 | `env_one_local.gd` / `sculpt_one_local.gd`: re-hide suns after a seed rebuild | wired by Codex; verified (both paths, real pointer, desktop and XR) |
| R4b | SculptOne's never-parented `base_mesh`, removed in `sculpt_one_local.gd` | verified (`orphans`; full run clean) |
| R5 | fire jets and basins not lethal | documented only, no new behaviour |
| R6 | `#plinth:H` pedestals | documented missing support, no guessed pedestal |

## Commands used (coordinator; runners queue on the OS lock)

```
python tools/audit_void_transfer.py randomness_05
python tools/test_transfer_native.py randomness_05 --focus <case> --mode desktop|xr
python tools/test_transfer_native.py randomness_05
python tools/export_void_trial.py randomness_05
node tools/test_void_transfer_editor.cjs randomness_05
```

Focused cases defined in `probe.gd`:
- bounds-1..5, orphans;
- seeded, seedlight, envone, darts, pheromone, clipboard, space, mixer;
- crossing, arena, doors, timing, field, fieldmove, fieldsleep, waiting.

envone, clipboard and mixer were not run.

## Untested and open

- Physical headset (synthetic XR only).
- The stepping-stone crossing and falls into either basin.
- Fire, which is not present (R5).
- Projectile hits on the visitor.
- Buttons named in the "remaining" column; listening.
- **Curation:**
  - env_one's cloud spans all three storeys and both shaft openings, with its console 4 m
    up;
  - random_space enters shaft B by 0.45 m and runs 1 m past the floor edge;
  - the floor-4 instruments float without plinths (R6);
  - the clipboards lie at floor level;
  - sculpt_one's base and the field emitter extend below the slab, as built by the source.

## Exact files (mine, all in `commons/void/trials/randomness_05/`)

- `rooms.json` (floors 1–5, floor-5 basin), written by `place.py`
- `placement-ledger.json`
- `layout.json`: added only `floor_sign_positions["5"]`
- `probe.gd`
- `cube_field_local.gd`, `env_one_local.gd`, `sculpt_one_local.gd`: adapters, selected by
  Codex's R3/R4 hook in `floor_content.gd`. `sculpt_one_local.gd` also drops the source's
  leaked orphan (R4b).
- `REQUESTS.md`, `STATUS.json`, `HANDOFF.md`, `transfer-status.json`

**Generated by the runners:** `evidence/*`, `../ada_encyclopedia/public/void-trials/randomness_05/*`.

**Codex's shared hooks (not mine):** `floor_content.gd` R1–R4.

**Untouched by me:** sources, maps, texts, catalog, `playable.json`, shared code, other
trials.
