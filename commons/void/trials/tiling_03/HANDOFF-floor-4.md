# Ribbon_Patterns_01 (floor 4) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-4.json` and this note. **No Godot run.**
Static checks:
- With floors 4 and 5 substituted into `rooms.json`, it validates against
  `rooms.schema.json`.
- All 11 IDs appear once, with the original artifact keys, every `#` config,
  `facing = yaw + 180`, token height (0 for all) and scale 1. No height corrections.

## Placement

The hall (25 x 25) is turned 180°: `x = 12 - col`, `z = 15 - row`. The source spawn (12,2)
lands at (0, 13), 1 m behind the arrival.
- **Why z = 15 - row, not 14.** That puts the xyz gadget in shaft B's band, 0.48 m from the
  opening.
- **Width.** The hall is 25 m wide, so its side aisles (source cols 5-6 and 18) land at
  x ±6..7, on the shaft lines. No z offset keeps both the row-11/12 pair and the row-17
  pair out of the shaft band, so four pieces move individually.

| id | at | facing | note |
|---|---|---|---|
| `f4_grid_2d_4x4_2_4` | 10, 11 | 180 | rigid |
| `f4_grid_3d_4x4x4_7_4` | 5, 11 | 180 | rigid; 1.65 m from the arrival |
| `f4_column_3_z_18_4` | -6, 11 | 180 | rigid |
| `f4_row_3_x_18_11` | **-5.5, 6.4** | 90 | rigid would be (-6, 4), inside shaft A's band 0.5 m from the opening. Moved +0.5 x, +2.4 z: now 1.0 m from shaft A's corner and 0.9 m from `column_3_z`. |
| `f4_xyz_coordinates_5_12` | **7, 4.0** | 270 | rigid would be (7, 3), at shaft B's corner. Moved +1 z: now 1.09 m. |
| `f4_grid3d_6_17` | **4, -2** | 180 | rigid would be (6, -2), in the band 0.6 m from shaft B. Moved 2 m inward: now 2.6 m. |
| `f4_bar_array_18_17` | **-4, -2** | 180 | rigid would be (-6, -2), 0.8 m from shaft A and beside the floor-4 pad (x -9.07..-7.53, z -3..-0.8). Moved 2 m inward: now 2.8 m. |
| `f4_bar_array_bubble_sort_6_20` | 6, -5 | 180 | rigid; 0.57 m from the riser at (6.5, -4.2) |
| `f4_sorting_algorithm_race_18_20` | -6, -5 | 180 | rigid; 0.66 m from the riser at (-6.08, -4.2) |
| `f4_shelf_5_22` / `f4_shelf_with_stickers_19_22` | 7, -7 / -7, -7 | 180 | rigid |

Clearances come from catalog AABBs (measured 2026-04/08). `grid_2d_4x4.gd`,
`grid_3d_4x4x4.gd` and `row_3_x.gd` are modified in the working tree, so please re-measure
natively. Content spans z -7.1..11.4 and keeps at least 2.2 m from every column.

**Not transferred:** the walls, including the divider stubs at rows 10 and 16, `s` and `t`.

## Dependencies

- **`grid_2d_4x4`:**
  - `show_binary_table` arrives as the string `"false"`. `apply_grid_config` (:243) tests
    `is bool and ...`, which gives false, so the table built in `_ready` is removed. This
    matches the source.
  - `notation` "none" is normalised the way `column_3_z` does it.
  - The grid is 16 `pick_up_cube` instances. Check whether walking through them collects
    them into the trial score.
- **`grid_3d_4x4x4`.** `lesson: layer_pattern` loads `layer_pattern_lesson.gd` in
  `apply_grid_config` (:116), after ready. That is fine.
- **`grid3d`** (substrate). The catalog AABB is centred at y 0 (±0.79), so it may sit half
  under the slab. Verify, and lift only if natively confirmed.
- **`sorting_algorithm_race`.** The catalog AABB is only 0.28 x 0.72 m, which is probably
  stale. Measure it against the riser at 0.66 m.
- No cross-artifact lookups found.

## Focused mouse/XR tests

- **`grid_2d`:** grab a cube and check that its index label and `_cube_refs` update. Check
  that there is no BinaryTable.
- **`grid_3d` layer lesson:** step a layer and read back the lesson state.
- **`column_3_z`, `row_3_x`, `xyz_coordinates`:** grab and move, then check that the
  readouts change.
- **Bar arrays:** run a bubble-sort step and read back the bar order. Start the sorting
  race and check that it progresses.
- **Shelves:** pick up a sticker or colour item and drop it.
- **Clearances:** the four moved pieces against the shafts (at least 1.0 m), and the
  floor-4 pad egress.
