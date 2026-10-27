# randomness_03: Random_Remove (floor 1) and Randomness_10_PRINT_Algorithm (floor 2)

Owner: Claude Opus, batch 24, 2026-10-21. Every result below comes from the final runs:

| Gate | Result |
|---|---|
| Source audit | **83 / 83** |
| Native, desktop + synthetic XR | **147 / 147**, 83.0 s, exit 0, no engine errors |
| GLB export | **49 models, no failures**; all 14 placements have geometry or a labelled marker |
| Editor | **17 / 17**; `rooms.json` hash `104dc5ae…` identical before and after the editor's save/restore |

The tower is the standard one: 42 x 32 m, 6 m storeys. Pillars and shafts are unchanged.
All 14 inventoried IDs appear exactly once, each with:
- its original key and config;
- facing = yaw + 180;
- its token scale.

There is one height exception, the arena, explained below.

| Status | Count |
|---|---|
| Placed | 14 |
| Native verified | 14 |
| Editor verified | 14 |
| Curated | 0 |
| Headset | not tested (synthetic XR only) |

## Placement

Each hall is turned 180° rigidly so that its spawn lands on the arrival (0, 12):
- Random_Remove: `x = 8 - col`, `z = 12 - row`.
- 10 PRINT: `x = 4 - col`, `z = 13 - row`.

| id | at | facing | h / scale | config |
|---|---|---|---|---|
| f1_remove_random_8_5 | 0, 7 | 0 | 0 / 1 | local_grid:true, controls:compact, control_front:1.15 |
| f1_sampling_hoppers_3_6 | 5, 6 | 0 | 0 / 1 | |
| f1_random_removal_arena_8_17 | 0, -5 | 180 | **0** (token 3) / 1 | columns:15 rows:11 full_crossing tesla_coils plinth:0 |
| f2_remove_random_1_2 | 3, 11 | 270 | 0 / 1 | (none in source) |
| f2_pickup_cube_placer_1_3 | 3, 10 | 270 | 0 / 1 | |
| f2_ten_print_structure_11_3 | -7, 10 | 0 | 0 / 1 | form:wall size:1.1 cols:4 rows:3 solid:on seed:1982 count:12 plate:none |
| f2_ten_print_maze_3d_2_5 | **2.2, 13.2** (rigid 2, 8) | 180 | 3 / 1 | impression:character |
| f2_clipboard_7_5 | -3, 8 | 180 | 0 / 1 | ten_print_axioms:194:1.0 |
| f2_ten_print_maze_3d_12_5 | **-7.3, 13.4** (rigid -8, 8) | 180 | 3 / 1 | impression:character |
| f2_film_chance_passage_13_7 | -9, 6 | 90 | 0 / 1 | plinth:0 pin:true |
| f2_composition_stochastique_1_8 | 3, 5 | 270 | 0 / 1 | |
| f2_ten_print_maze_3d_2_15 | **2.8, 2.3** (rigid 2, -2) | 270 | 3 / 1 | impression:character |
| f2_textile_comparison_7_15 | **-3, -11.68** (rigid -3, -2) | 180 | 0 / 1 | controls:compact control_front:-1.7 control_facing:-z |
| f2_nature_system_demo_13_19 | **-21.5, -6** (rigid -9, -6) | 270 | 0 / 1 | |

### The arena and its basin (Palle's choice, 2026-10-21)

In the source, the 165 amber tiles span a 3 m basin with fire at the bottom. The token
height 3 is measured from the basin floor: the museum's 9 October report puts the
removed tile's top at **y 0.0** in hall space.

Floor 1 therefore has a Void `basin` with `depth: 3`, `glass: false` and rect
`[-7.5, -10.5, 15, 11]` under the arena, and the arena stands at height 0. This
preserves the geometry and makes a withdrawn tile a real 3 m drop. The basin has
**no fire**; see R3 under Remaining.

The basin's bottom hangs 2.8 m above floor 2. No floor-2 placement enters it (native fit
check).

### Why five floor-2 placements moved

Each move was measured natively first.

**The three 10 PRINT mazes.** Each is a **vertical** 10 x 10 m plane, 0.65 m thick,
standing from 3 m to 13 m.
- At the rigid positions:
  - maze 12_5 stood inside shaft A's opening;
  - mazes 2_5 and 2_15 entered the floor-1 basin box.
- They moved north to clear both.
- Mazes 2_5 and 12_5 stay parallel, as in the source.
- Maze 2_15 lies between the basin edge and the other two, clear of shaft A.

**Textile studio.** It is 9.5 x 2.9 m and 3.02 m tall. Under the basin the clearance is
only 2.8 m, so it moved south into the 3.05 m strip between the basin edge and column
(−5, −14).

**Nature demo.** The anchor moved to the west edge; see the nature section below.

**Not transferred:** walls, `s`/`sp`, `t`.

## Measured native bounds (metres above each floor)

| id | x | y | z |
|---|---|---|---|
| f1_remove_random_8_5 | -1.56..1.44 | 0..1.26 | 6.30..8.12 |
| f1_sampling_hoppers_3_6 | 3.38..6.62 | 0..2.03 | 5.64..7.12 |
| f1_random_removal_arena_8_17 | -7.55..7.55 | -0.60..4.37 | -11.50..1.96 |
| f2_remove_random_1_2 | marker only (no runtime geometry) | | |
| f2_pickup_cube_placer_1_3 | marker only (no runtime geometry) | | |
| f2_ten_print_structure_11_3 | -7.00..-2.60 | 0..2.40 | 10.00..13.30 |
| f2_ten_print_maze_3d_2_5 | 1.60..2.25 | **2.97..13.03** | 3.17..13.50 |
| f2_clipboard_7_5 | -3.20..-2.80 | -0.16..0.16 | 7.79..8.21 |
| f2_ten_print_maze_3d_12_5 | -7.90..-7.26 | **2.97..13.03** | 3.37..13.43 |
| f2_film_chance_passage_13_7 | -9.26..-8.74 | 0..2.51 | 4.66..7.34 |
| f2_composition_stochastique_1_8 | 2.84..3.26 | 0..1.75 | 4.05..5.95 |
| f2_ten_print_maze_3d_2_15 | -7.23..2.83 | **2.97..13.03** | 2.25..2.90 |
| f2_textile_comparison_7_15 | -7.55..1.98 | -0.06..3.02 | -13.48..-10.57 |
| f2_nature_system_demo_13_19 | **-74.4..-17.9** | -4.3..13.4 | -8.7..7.1 (random DNA; varies per boot) |

The fit checks pass on both floors in both modes. No placement geometry enters:
- the whole shaft openings;
- the arrival;
- the default floor sign;
- on floor 2, the floor-1 basin box.

**One measured exception.** The arena's Tesla canopy is 15.1 m wide; the gap between the
shafts is 15.0 m. Its two 0.10 m side rails, at 4.31 m, overhang each shaft opening by
**0.050 m**. That has its own capped check, and nothing was shrunk.

**Probe precision.** The arena's 15.0 m end bank exactly touches the shaft edges. Float
rounding read that contact as overlap, so the test shrinks each box by at most 1 mm per
side before comparing.

## Interactions: what each work does, and the evidence

| id | action | evidence (native, desktop and XR) | fit / dependency | remaining |
|---|---|---|---|---|
| remove_random (floor 1) | 8x8 owned board; RANGE / ROW / COLUMN / ALL; REMOVE ONE; RESET; NEW SEED | **real pointer**: RANGE, REMOVE ONE deletes one eligible cube, RESET restores; board 64 | | ROW/COLUMN/ALL/NEW SEED not pressed |
| sampling_hoppers | two 8-member sets; lever draws with / without replacement; REPLAY BOTH | lever pull, desktop: **real pointer drag on the handle** (layer 19; the bar is on layer 1); XR: **real grip and swing** of the handle (preflight passed). Draws from the withdrawal hopper (8 → 7). **Real pointer** REPLAY BOTH refills it. | | left lever not pulled |
| random_removal_arena | 165 tiles; entry, walking and Tesla timer withdraw support; SLOWER / FASTER / REPLAY / NEW SEED | 165 tiles and canopy (R1). **Real walking** onto the crossing withdraws tiles (R2; log 74, 88, 69, 2 at seed 17031). The withdrawn cell opens a drop into the basin (geometry ray). **Real pointer** REPLAY restores every tile and collider. | basin without fire (R3); canopy rails 0.05 m | the fall itself (body into the pit) not run; SLOWER/FASTER/NEW SEED not pressed |
| remove_random (floor 2) | none: no `local_grid`, no board binds | runtime has no geometry; editor marker (R5) | source is empty | marker, not a remover |
| pickup_cube_placer | none: needs a GridSystem (absent in museum and Void) | runtime has no geometry; editor marker (R5) | dependency missing | marker, not cubes |
| ten_print_structure | 12-character wall, seed 1982 | wall form, 4 x 3, seed 1982 (API) | no screen channel in source | |
| ten_print_maze_3d x 3 | churning 10 PRINT maze, character impression | `impression == character` (API) | vertical 10 m planes pierce floor 1's slab and reach 1 m above the canopy floor | curation |
| clipboard | held document with the `ten_print_axioms` tutorial | grab preflight passed; **real mouse / grip pickup** of its GrabPlane | lies at floor level, half sunk (−0.16..0.16); `194:1.0` reads like a yaw:height shorthand that the museum plan also ignores | curation |
| film_chance_passage | concept monitor | **real pointer** PAUSE stops the stage | | |
| composition_stochastique | Molnár-style deal; RESEED | **real pointer** RESEED advances `draw_index` | | |
| textile_comparison | three prints, one seed; costume | **real pointer** SEED + (seed +1) and STITCH (mark 1) | | WEAR/SHAPE not run |
| nature_system_demo | Nature System test scene: 48 critters, evolution | trial adapter (R4). 48 critters in the demo frame (3 x 4 x 4 at 3.5 m); UI hidden; keys off. **Real pointer** CLEAR (0) and REPOPULATE (48 in frame). | oversized strip, see below | EVOLVE/RANDOMIZE/LOD/HYBRID buttons wired, not run; strip needs an exterior platform |

Shared chain, both modes: safe arrival, original geometry and config meta, open shafts,
visitor camera, shaft-pad descent, sleeping floor 1, return, retry.

### Nature demo: source seam fixed in the trial, strip recorded as oversized

`spawner.gd` wrote the demo's local grid as world positions. All 48 critters therefore
stood at world y 0 near the origin: on the roof, outside the tower (diagnostic
`nature`).

`nature_demo_local.gd`, in this folder, maps only the demo's own spawns into its frame.
Exported `grid_rows = 3` and `grid_spacing = 3.5` are preserved by Codex's hook. The
adapter also:
- hides the standalone `UI` CanvasLayer;
- disables the key handler, whose R, Space and C collided with the Void's own keys;
- adds a `VoidKeyPanel` carrying the original actions.

The strip is 10.5 x 50.5 m in demo space. With the source facing it cannot fit the
42 x 32 m floor; at the rigid anchor it crossed shaft A. Anchored at the west edge, it
runs outward over the void:
- critter origins: x −72..−21.5 at floor-2 level;
- geometry: as tall as 18.5 m, and below the floor by up to 4 m, varying with the
  random DNA.

It is unsupported and needs an exterior platform (curation). Nothing was shrunk.

### Cross-floor visibility (diagnostic `crossfloor`, measurement)

From floor 1:
- mazes 12_5 and 2_15 are **visible** where they pass through floor 1;
- they are frozen, not processing;
- they have **no collision at body height**;
- a real walk across maze 2_15's line onto the arena's north bank succeeds.

So the intrusion is visual only. Photo 03 shows it.

## Screenshots (`evidence/`, desktop, native Mobile renderer)

| # | file | view |
|---|---|---|
| 01 | `01-random-remove-arrival-eye.png` | Random_Remove arrival |
| 02 | `02-remover-and-hoppers.png` | remover and hoppers |
| 03 | `03-arena-from-north-bank.png` | arena tiles and Tesla canopy; maze 2_15's glyph plane in the foreground (cross-floor, visual) |
| 04 | `04-tenprint-arrival-eye.png` | 10 PRINT arrival |
| 05 | `05-mazes-into-slab.png` | basin bottom overhead; maze planes and works beyond |
| 06 | `06-film-and-clipboard.png` | film and clipboard |
| 07 | `07-textile-under-basin.png` | textile studio, dressing room, mannequin and three prints |

## Commands (runners queue on the OS lock)

```
python tools/audit_void_transfer.py randomness_03
python tools/test_transfer_native.py randomness_03 --focus <case> --mode desktop|xr
python tools/test_transfer_native.py randomness_03
python tools/export_void_trial.py randomness_03
node tools/test_void_transfer_editor.cjs randomness_03
```

Focused cases: bounds-1, bounds-2, nature, remover, hoppers, arena, film, composition,
textile, clipboard, crossfloor. Receipts are in `evidence/debug/<case>-<mode>/`;
failures are archived under `evidence/debug/*/failures/` and `evidence/failures/`.

## Remaining and limitations

- **R3. The basin has no fire.** A body that falls through a withdrawn tile lands in a
  3 m pit and needs retry (B). It is not lethal, and I don't claim it is. The fall
  itself was not run.
- **Oversized works.**
  - Nature strip: needs an exterior platform.
  - Maze planes: pierce floor 1's slab; visible there, without collision.
  - Canopy rails: 0.05 m into each shaft opening.
  - All recorded; nothing scaled.
- **Clipboard:** lies half-sunk at floor level, and its `194:1.0` config looks like a
  yaw:height shorthand. Both are recorded for curation.
- **Museum plan differs.** The live museum plan (`em_plan`) for 10 PRINT holds a
  different arrangement, with a `ten_print`, a `dark_sphere` and a second structure.
  The inventory and this transfer follow `map_data.json`.
- **Untested:** physical headset, listening, the uncovered buttons named in the table,
  the fall into the pit.
- **My probe errors along the way, each fixed and rerun:**
  - wrong board-count field;
  - aiming the lever's layer-1 bar instead of its layer-19 handle;
  - a missing `stand_local` helper, caught by the parse check;
  - a 1 mm `grow(-…)` that produced negative AABBs and engine errors.

## Exact files

**Mine:**
- `commons/void/trials/randomness_03/rooms.json` (floors 1–2, floor-1 basin)
- `commons/void/trials/randomness_03/probe.gd`
- `commons/void/trials/randomness_03/nature_demo_local.gd`
- `commons/void/trials/randomness_03/remover_unbound_preview.gd`
- `commons/void/trials/randomness_03/placer_no_grid_preview.gd`
- `commons/void/trials/randomness_03/REQUESTS.md`
- `commons/void/trials/randomness_03/STATUS.json`
- `commons/void/trials/randomness_03/HANDOFF.md`
- `commons/void/trials/randomness_03/transfer-status.json`
- `doc/void-transfer/2026-10-21-batch-24/GPU_SLOT.json` (released)

**Generated by the runners:**
- `commons/void/trials/randomness_03/evidence/*`
- `../ada_encyclopedia/public/void-trials/randomness_03/*`
- `commons/void/line_parts.json`, if the exporter touched it
- the Desktop mirror, written and restored by the editor test

**Codex's shared hooks, not mine:**
- `floor_content.gd` (R1, R2, R4, R5)
- `removal_arena_local.gd`
- `test_void_transfer_editor.cjs` (labels)

**Untouched:** sources, maps, chapter texts, catalog, `playable.json`, `layout.json`.
