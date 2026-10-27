# FormFinding_Annealing (floor 4) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-4.json` and this note. **No Godot run.**
Static checks:
- With floors 3 and 4 substituted into `rooms.json`, it validates against
  `rooms.schema.json`.
- All 5 IDs appear once, with the artifact key, every `#` config, `facing = yaw + 180`,
  height 0 and scale 1.

## Placement

The mapping is the same as floor 3: `x = 2 - col`, `z = 13 - row`. The spawn (2,2) lands
at (0, 11), next to the arrival. The hall lies north of the shaft band.

| id | at | facing | notes |
|---|---|---|---|
| `f4_energy_landscape_bench_3_2` | -1, 11 | 270 | 1.1 x 0.7 m; 0.8 m from the arrival, as at the source spawn |
| `f4_simulated_annealing_10_2` | -8, 11 | 270 | about 1.9 m square; deck datum 0.9 m |
| `f4_max_q_basin_room_6_3` | -4, 10 | 180 | See the basin notes below. |
| `f4_impossible_end_table_9_5` | -7, 8 | 180 | 0.15 m from the tank wall, as in the source |
| `f4_science_screen_8_9` | **-6, 5** (rigid -6, 4) | 270 | See the screen notes below. |

**Basin room:**
- **Tank.** Open, 4.9 m square (`floor_size` 4.9): x -6.45..-1.55, z 7.55..12.45, with
  1.05 m walls.
- **Console.** The INTERPRET console stands at (-2.4, 7.05) on the far side.
- **Clearances.** 1.55 m from the arrival; 1.1 m from column (-5,14).

**Science screen:**
- **Facing.** Its screen faces -x, toward shaft A.
- **Why it moved.** At the rigid position its 3.14 m width spans z 2.4..5.6, putting the
  viewer at the corner of shaft A's band.
- **Moved +1 z.** The screen now spans z 3.4..6.6, so the viewer stands north of the band,
  0.5 m or more beyond shaft A's z edge.

**Not transferred:** walls, the row-7 stubs, `s` and `t`.

## Supports and dependencies

- **`max_q_basin_room`.** The catalog AABB (y -2.25..0.86) is **stale**. The script builds
  everything from y 0 up ("the whole body starts at y=0", `max_q_basin_room.gd` :21):
  - four 1.05 m tank walls;
  - wells hanging from a stage at `deck_h`, with the deep well bottom at about y 0.1;
  - a live soft-body jelly (`SBShapes.make_jelly_grid`, gravity -2.6, in the stage
    frame).

  So no slab cut is needed. `reveal_on_request:true` hides the interpretation until
  INTERPRET is pressed (:198-210). `floor_size` arrives as the string "4.9", which is read
  as a float.
- **`simulated_annealing`.** The visualization reads `config_*` meta before `add_child`
  (:244); none is set. It stands on its own deck, with the relief below the datum and the
  peaks flush with the table top.
- **`energy_landscape_bench`** and **`impossible_end_table`.** Embodied props with no
  outside lookups.
- **`science_screen`, no `#mode`.** It auto-binds only to its parent's children, so it
  needs the coordinator's science_screen binding.

## Focused tests

- **Basin:** INTERPRET toggles the interpretation, and the jelly settles in the shallow
  well while the cube stays in the deep one.
- **Annealing:** run or step it, then read back temperature and energy.
- **Bench:** move it and check that the landscape responds.
- **End table:** check its brackets hold, with no collision drift.
- **Screen:** after binding.
- **Clearances:** walk from the arrival past the bench and tank without contact, and check
  that the screen's viewer zone is clear of shaft A.
