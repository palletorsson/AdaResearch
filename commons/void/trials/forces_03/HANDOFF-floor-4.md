# VFM_09_Legs (floor 4) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-4.json` and this note. **No Godot run.**
Static checks:
- With floors 4 and 5 substituted into `rooms.json`, it validates against
  `rooms.schema.json`.
- All 5 IDs appear once, with the artifact key, every `#` config, `facing = yaw + 180`,
  token height (0) and scale 1. No exterior plates are needed.

## Placement

The hall (28 x 40 m, `curation.json` number 9, "What holds the body up") is turned 180°:
`x = 14 - col`, `z = 15 - row`. The spawn (14,3) lands on the arrival (0, 12).

| id | at | facing | notes |
|---|---|---|---|
| `f4_force_hall_11_0_0` | -4, 14 | 180 | Batch-19 convention; uses your local hall adapter. |
| `f4_force_play_support_14_13` | 0, 2 (rigid) | 180 | See the support notes below. |
| `f4_one_leg_5_31` | **9, -9** (rigid 9, -16) | 0 | |
| `f4_four_leg_critter_14_31` | **0, -9** (rigid 0, -16) | 0 | |
| `f4_six_leg_critter_23_31` | **-9, -9** (rigid -9, -16) | 0 | |

**Support bay:**
- **Patch.** 18 x 16 m (`encounter.gd` :483), x ±9, z -6..10. It overlaps the inner 1.5 m
  of both openings, so your batch-19 shaft clipping applies.
- **Core.** The table and four legs are ±2.05 m, with the loads up to about 3.1 m.
- **RESET** is at (-8.3, 9.3).
- **Title** is at y 5.5 (Void z -5.6), just under the 5.64 m clearance.

**Critter row.** The three critters move north 7 m as one unit, keeping x and spacing.
- **Why.** The source rows reach row 39, beyond the 32 m slab, so the rigid row would sit
  on the south slab edge.
- **Clearances:**
  - 0.9 m south of the support patch;
  - 6 m south of the shaft band;
  - 2.5 m or more from the columns at z -14 and the risers at z -4.2.

**Not transferred:** walls, `s`, `t`.

## Dependencies and fit

- **Critter config path.** The tscn roots run `leg_walker_root.gd`, which forwards
  `apply_grid_config` to `Body` (:15). Floats arrive as strings and are parsed by
  `_cfg_num`/`_cfg_bool` in `leg_walker_base.gd` :129-137.
- **Home and leash.** Home is learned on the first frame (`_learn_place`, :195), and the
  Void positions the mount before `add_child`. The leash is `pace_reach` 1.1 m. The floor
  height is refined by a downward ray (`_settle_floor`) that should find the slab.
- **Height, please measure natively.** The catalog AABBs are tall:
  - `four_leg_critter` and `six_leg_critter` are 7.32 m, centred y 3.54, so they reach
    about 7.2 m;
  - `one_leg` is 15.29 m, centred y -0.44.

  If that is real geometry rather than IK targets or markers, the critters clip floor 3's
  slab (5.64 m clearance). The source hall's max_height is 8.

## Focused tests

- **Support:** remove the pink corner leg (`members.leg`) and check that the table
  inherits the load. RESET restores the legs.
- **Critters:** check that all three patrol and stay within about 1.1 m of home, with
  feet planted on the slab and no foot markers (`show_foot_markers` false). With
  `driven_by_player` false, WASD must not drive them.
- **Shafts:** confirm both openings are clear after the support patch clipping.
