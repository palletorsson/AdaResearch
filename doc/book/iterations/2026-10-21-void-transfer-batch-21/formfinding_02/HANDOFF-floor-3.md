# FormFinding_Equilibrium (floor 3) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-3.json` and this note. **No Godot run.**
Static checks:
- With floors 3 and 4 substituted into `rooms.json`, it validates against
  `rooms.schema.json`.
- All 4 IDs appear once, with the artifact key, empty config (as in the source),
  `facing = yaw + 180`, height 0 and scale 1.

## Placement: rigid, no adjustments

The hall (14 x 12 m) is turned 180°: `x = 2 - col`, `z = 13 - row`. The source spawn (2,2)
lands at (0, 11), so the arrival (0, 12) is 1 m toward the entrance. The hall then spans
x -11..2, z 2..13, entirely north of the shaft band.

| id | at | facing | footprint (catalog AABB) |
|---|---|---|---|
| `f3_calder_mobile_5_3` | -3, 10 | 180 | 5.93 x 0.5 m, y 0.16..3.68. Its west tip is 1.75 m from the arrival. |
| `f3_fractal_truss_tower_9_4` | -7, 9 | 180 | 7 x 7 m (x -10.5..-3.5, z 5.5..12.5), up to 4.16 m. 2.5 m north of shaft A and of the floor-3 pad (z 0.8..3.0); 1.05 m from column (-5,14). |
| `f3_tensegrity_triangle_4_6` | -2, 7 | 180 | 1.35 m |
| `f3_science_screen_8_7` | -6, 6 | 180 | 3.14 m wide; faces south (-z). The viewer stands at z 4.5-5.5, north of the band. |

**Source overlaps, kept as authored.** The mobile's AABB overlaps the truss tower's
(x -6.06..-3.5). The science screen stands at the truss AABB's south edge. Both overlaps
exist in the source cells too. The truss AABB is 7 m square; its actual members may be
sparser, so please measure natively.

**Not transferred:** walls, the wall stubs in rows 3 and 7, `s` and `t`.

## Supports and dependencies

- **`calder_mobile`.**
  - **Mount.** It builds its own **ceiling mount**, a 0.5 x 0.08 m plate at
    `top_y` 3.6 + 0.04 (`calder_mobile.gd` :23 and :100). It hangs the tree from that
    plate. In the Void the plate floats 2 m below the 5.64 m slab. A rod to the slab would
    be architecture, so I added none.
  - **Config.** `seed`, `use_objects`, `depth` and `emissive` are read in
    `apply_grid_config`; none is set here.
- **`fractal_truss_tower`** and **`tensegrity_triangle`** stand on their own bases (the
  embodied-prop and Node3D roots). No outside lookups.
- **`science_screen`, no `#mode`.** It auto-detects a source among its parent's children
  within `scan_radius`. In the Void its parent is the mount, so it finds nothing. This is
  the coordinator's science_screen binding.

## Focused tests

- **Mobile:** nudge a leaf and check that the rods re-level (lever "solved") and that the
  plaque values are present.
- **Truss tower:** check its members against the mobile and the screen (native AABB).
- **Tensegrity:** check the triangle holds its form.
- **Science screen:** after binding, it shows the intended source.
- **Clearances:** walk around every piece without entering shaft A's band.
