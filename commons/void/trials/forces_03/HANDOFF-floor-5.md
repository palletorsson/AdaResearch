# VFM_08_Arena (floor 5) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-5.json` and this note. **No Godot run.**
Static checks:
- With floors 4 and 5 substituted into `rooms.json`, it validates against
  `rooms.schema.json`.
- All 9 IDs appear once, with the artifact key, every `#` config, `facing = yaw + 180`,
  token height and scale 1. No exterior plates are needed.

## Placement

The hall (28 x 64 m, `curation.json` number 10, "One push reaches another body") uses the
180° turn (`x = 14 - col`, `z = 15 - row`), with the spawn on the arrival (0, 12). It is 64
m deep, so groups are translated as units. Their internal spacing and yaw are kept.

| id | at (rigid) | facing | height | notes |
|---|---|---|---|---|
| `f5_force_hall_12_0_0` | -4, 14 | 180 | 0 | Batch-19 convention; local hall adapter |
| `f5_force_play_bowling_8_17` | **2.5, -1.8** (6, -2) | 180 | 0 | See the bowling notes below. |
| `f5_sentry_turret_19_11` | **-16, 4** (-5, 4) | 0 | 0.82 | Turret column moved 11 m west as a unit; z rigid. |
| `f5_ball_dropper_19_16` | **-16, -1** (-5, -1) | 180 | 2.8 | Same unit; 5 m south of the turret, as in the source. |
| `f5_queer_cylinder_target_19_23` | **-16, -8** (-5, -8) | 0 | 1.35 | Same unit. |
| `f5_force_play_recoil_9_41` | **15, 8.5** (5, -26) | 180 | 0 | See the recoil notes below. |
| `f5_force_punching_bag_20_39` | **16, -9** (-6, -24) | 180 | 0 | Zone 6 x 7 (x 13..19, z -12.5..-5.5): 2.5 m from shaft B, 1 m from columns. |
| `f5_momentum_cradle_8_55` | **-8, -11** (6, -40) | 0 | 0 | Cradle pair moved as a unit; newton stays 10 m west. |
| `f5_newton_cradle_18_55` | **-18, -11** (-4, -40) | 0 | 0.82 | Same unit; 3 m from the west edge. |

**Bowling** (`encounter.gd` :210):
- **Footprint.** Patch 10 x 25 m: x -2.5..7.5, z -14.3..10.7, on slab.
- **Why it moved.** The lane and banks span x -1.0..6.0 and cross the shaft band 1.4 m from
  shaft B. Rigid x 6 put them over shaft B. The z shift of +0.2 keeps the back wall
  (z -13.3) 0.1 m off column (5,-14).
- **Shafts.** The patch touches shaft B's x edge in the band; your clipping applies.
- **Front.** Ball, ROLL and the club rack are at z 7.7; RESET is at (-1.8, 10.0), 2 m from
  the arrival.
- **Risers.** The banks are 0.38 m from the riser at (6.5, -4.2).

**Turret column.** At the rigid x -5 the dropper sits in shaft A's band beside the bowling
banks. At x -16 the column is 3.5 m from shaft A and 7 m from the floor-5 pad
(x -9.07..-7.53, z 0.8..3.0).

**Recoil** (`encounter.gd` :229):
- **Footprint.** Patch 12 x 10 m: x 9..21, z 3.5..13.5. That is 0.5 m north of shaft B and
  0.05 m from column (14,14).
- **Layout.** Carts at x 10.3..19.7, FIRE at (15, 11.9), RESET at (9.7, 12.8).
- **Lost relation.** The source bag-beside-recoil pairing is not kept.

**Not transferred:** walls, `s`, `t`.

## Dependencies and fit

- **Pedestals.** Curation marks `pedestal: true` for the turret, the cylinder target and
  `newton_cradle`; `hall_display.gd` :49 builds a 1.9 x 0.82 x 1.4 m block at their old
  cells. Their token heights (0.82 / 1.35 / 0.82) assume those pedestals. Your local hall
  adapter should place them under (-16, 4), (-16, -8) and (-18, -11), or the instruments
  float.
- **`sentry_turret`:**
  - `target: balls`, read from meta (:200), sets `target_player = false`. Laser damage
    to the player (GameManager :772) cannot fire.
  - `_find_balls` collects every `ball_dropper` and `colorballs` in the whole tree
    (:448-454), filtered by `detection_range` 6. Floors are 6 m apart, so balls from
    another floor should stay out of range; check natively.
- **`ball_dropper`.** It drops 8 balls from 2.8 m every 2-3 s. With no hall walls, rolling
  balls can reach shaft A (3.5 m east of the drop point) or the west slab edge (5 m).
  The source walls contained them.
- **Bowling, recoil, punching bag.** Force_play patches, clipped where they touch an
  opening. No outside lookups.

## Focused tests

- **Bowling:** ROLL, then count pins down. Check the club rack is grabbable and RESET
  restores the pins.
- **Turret and dropper:** check that balls drop 8 times, the turret tracks and lasers only
  balls within 6 m, the visitor takes no damage, and the target reacts.
- **Recoil:** FIRE, then compare the free cart moving against the braced one.
- **Punching bag:** strike and swing.
- **Cradles:** lift and release a ball on each; check momentum transfers.
- **Clearances:** dropped balls do not end up in shaft A (watch for 60 s); both openings
  are clear after clipping.
