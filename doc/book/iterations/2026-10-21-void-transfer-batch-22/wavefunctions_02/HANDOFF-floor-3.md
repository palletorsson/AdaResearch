# WaveFunctions_Unit_Circle (floor 3) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-3.json` and this note. **No Godot run.**
Static checks:
- With floors 3 and 4 substituted into `rooms.json`, it validates against
  `rooms.schema.json`.
- All 7 IDs appear once, with the artifact key, every `#` config, `facing = yaw + 180`,
  token height and scale.

## Placement

The hall (24 x 29 m) is turned 180°: `x = 11 - col`, `z = 14 - row`. The spawn `sp`
(11,2) lands on the arrival (0, 12). Five pieces are rigid; two move.

| id | at (rigid) | facing | h / scale | notes |
|---|---|---|---|---|
| `f3_unit_circle_advanced_18_10` | **-4, 4** (-7, 4) | 0 | 1.6 / 1 | See the unit-circle notes below. |
| `f3_SimpleOscillatingBridge_6_18` | 5, -4 | 270 | 1 / 0.25 | See the bridge notes below. |
| `f3_OscillationCurve_19_18` | **-8, -6** (-8, -4) | 0 | 1.2 / 0.8 | See the curve notes below. |
| `f3_film_circle_projection_22_20` | -11, -6 | 90 | 0 | The case spans z -7.3..-4.7. The screen faces +x; its viewer stands 1.4 m clear of the curve, 1.7 m south of shaft A's band. |
| `f3_cube_scene_4_24` | 7, -10 | 180 | 0.5 | Inside the colorballs spread, as in the source |
| `f3_colorballs_8_24` | 3, -10 | 180 | 0 | See the colorballs notes below. |
| `f3_dark_sphere_19_24` | -8, -10 | 180 | 0 | |

**Unit circle.** The AABB local x is -1.2..5.16. At the rigid position it crossed shaft
A's band at x -8.2. Moved 3 m east, it now spans x -5.2..1.2, z 1.5..6.5, y 0.4..2.8:
2.3 m from shaft A.

**Bridge.** It is a 10 m miniature: 20 platforms, 2 m apart, at scale 0.25. It runs along
Void x -4.7..5.2 at z -4.7..-3.3. That is 1.2-1.4 m from the risers and 2.3 m from
shaft B.

**Oscillation curve.** It covers x -0.4..4.4 locally. At the rigid position its 4.8 m box
sat on the risers at (-6.5/-6.08, -4.2) and 0.2 m from shaft A. Moved 2 m south, it now
spans z -6.8..-5.2: 1 m from the risers, 0.5 m from the bridge.

**Colorballs.** The spread is about 9.9 x 8.5 m, x -1.7..8.2, z -13.8..-5.3. **Its south
edge overlaps column (5,-14) by about 0.2 m.** The balls are physics, so please measure the
real spread.

**Not transferred:** walls, `sp`, `t`.

## Controls, config and dependencies

- **`unit_circle_advanced`.** `gallery:projection` makes `apply_grid_config` (:379) set
  `gallery_projection` and build **`unit_circle_gallery.gd` controls** (:430).
  `continue_after_build:true` keeps the source and projections running after the graph
  is built. It has collision (`enable_collision`).
- **`SimpleOscillatingBridge`.** It has **no config reader**, so `museum:true` is kept and
  inert. Its StaticBody platforms move in `_process`, which is a moving tabletop model at
  this scale, not a walkable bridge. Animation only; no controls.
- **`OscillationCurve`.** `history_width` 8 is read (:98) to trim the trail. Animation
  only; its own notes list the sliders as missing.
- **`cube_scene`.** Reads `config_*` meta (`solid_color`, `grain`); none is set.
- **`colorballs`.** Uses your batch-14 below-zero-ball adapter.
- **`film_circle_projection`.** The standard `concept_monitor` buttons.

## Focused tests

- **Unit circle:** press each gallery control and read back the projection state.
- **Film:** TURN VIEW.
- **Colorballs:** grab and colour a ball.
- **Bridge and curve:** observation only; confirm their platforms and trail animate.
- **Clearances:** shaft A's band and the risers are clear after the two moves; measure the
  colorballs spread against column (5,-14).
