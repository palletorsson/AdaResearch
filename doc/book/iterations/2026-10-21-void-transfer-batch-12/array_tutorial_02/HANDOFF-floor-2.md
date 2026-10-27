# Tutorial_Tiling_Floor / A rule underfoot (floor 2) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-2.json`, in the `floors[2]` shape, and this
note. Nothing else was written. **No Godot run; nothing here is native-tested.**
Static checks: `floor-2.json` substituted into this trial's `rooms.json` validates against
`rooms.schema.json`. Both inventoried IDs appear once with their `#` configs. Both
catalog keys already exist and point at the original scenes, so **no adapter is needed**.

## Placement

The hall (21 x 29) is turned 180°: `x = 10 - col`, `z = 13 - row`,
`facing = rotation + 180`. The source spawn (10,1) lands on the arrival (0, 12).
All heights are floor-relative 0, as in the source. The tallest part is the reading
board, whose top is at 3.23 m, so the taller frame for floor 1's flight enclosure does not
affect this floor.

| id | at | facing | height | config |
|---|---|---|---|---|
| `f2_tiling_principles_10_15` | 0, -2 (rigid) | 180 | 0 | mode floor |
| `f2_film_tiling_rule_1_12` | **9, 5.5** (rigid 9, 1) | 270 | 0 | plinth 0, pin true |

**Fit exception: the film.** Its rigid position (9, 1) is inside shaft B's hole
(x 7.5..12.5, z -3..3). I moved it 4.5 m north; x and facing are unchanged.
- **Size.** The 2.68 m case spans z 4.16..6.84, and the screen still faces -x across the
  patterns.
- **Viewer.** The viewer, at x of about 7.5-8, stands at least 1.16 m from the hole edge.
  This is the batch-09 film precedent.
- **Neighbours.** The film is 2.1 m from the reading board.
- **Relation to the patterns.** It now stands beside the first pattern pair
  (TRANSLATE / ALTERNATE) instead of the second.

**Actual footprint of `tiling_principles` in floor mode, from the code.** It covers
x -5.7..7.3 and z -10.5..11.25, which is 13.0 x 21.75 m. It fits the 42 x 32 frame.
The catalog's `footprint` [19, 28, 7] is the hall reservation, not this mode.

| part | where in the Void |
|---|---|
| Six 5 x 5 m pattern quads at y 0.025 (visual only; the slab is the floor) | x ±0.7..5.7; centred at z 4, -2 and -8 |
| Pattern titles (at the arrival-facing edge of each pair) | z 6.5, 0.5, -5.5 |
| ONE MOTIF / SIX RELATIONS panel, on a solid stand | (0, 8.1) |
| Rule-study reading board, 5.8 m wide, solid | x 1.5..7.3, z 9 |
| Rule-study controls | (4.4, 9.7) |
| 16 x 16 floor field | x -5.65..-1.35, z 6.85..11.15 |

**Clearances:**

| from | to | gap |
|---|---|---|
| Patterns | both shaft holes | 1.8 m |
| Patterns | floor-2 landing pad (x -9.07..-7.53, z -3..-0.8) | 1.83 m |
| Arrival | corner of the walkable floor field | 1.6 m |
| Arrival | ONE MOTIF panel | 3.6 m (source: 3.9 m) |
| REFLECT and QUARTER TURN quads | service risers at z -4.2 | 0.66 m (water), **0.38 m** (electrical, x -6.08) |

The risers are close to the quads but do not overlap them.

## Controls and config (handler bodies read)

- **`tiling_principles`, panel ONE MOTIF / SIX RELATIONS.**
  - TURN MOTIF calls `turn_motif()`: phase + 1 (mod 4), which redraws all six rule
    textures and the readout and emits `patterns_changed`.
  - EXCEPTION calls `toggle_exception()`.
- **Linked `LocalRuleStudy` (`tiling_rule_study.gd`).** It is built as a child in
  `_ready`, not as a separate placement. Panel CHANGE ONE INSTRUCTION:
  - NEXT RULE calls `next_rule()`.
  - APPLY / UNDO calls `toggle_rule()`.
  - NEXT TILE calls `next_cell()`.

  These redraw the before/after 4 x 4 samples, the cell readout and the 16 x 16 field. The
  study follows TURN MOTIF through `patterns_changed`. It starts on QUARTER TURN,
  unapplied, because `applied = study.walls`. The walls-mode eye chart is correctly not
  built.
- **`mode` is read once in `_ready`** from meta `config_mode`, which the Void stamps before
  `add_child`. `apply_grid_config()` is a no-op. An editor change of `mode` therefore
  takes effect only on re-instantiation.
- **Raster cost.** Rasters are built only on a press; nothing runs per frame. One press
  rebuilds six 256² images plus a 512² field on the CPU, which may hitch briefly on a
  headset.
- **`film_tiling_rule` (`concept_monitor.gd`).**
  - The buttons PAUSE, REPLAY, STEP and TURN VIEW call `film_stage` `toggle_pause()`,
    `replay()`, `step_sample()` and `next_route()`. `tiling_rule.gd` overrides none of
    them.
  - It plays on gaze within 14 m. The line of sight uses mask 1, so the reading board's
    trimesh blocks views from behind the desk.
  - `plinth` and `pin` are museum keys; they are retained and have no effect here.
- **Not transferred:** the perimeter walls (structure 6), spawn `s` at (10,1) and the
  teleporter `t` at (10,27).

## Focused checks (shared probe helpers)

```gdscript
if level == 2:
	var t: Node3D = station("f2_tiling_principles_10_15")
	var s: Node3D = t.rule_study
	check(tag+"floor mode with linked rule study", not t.walls and t.surfaces.size()==6 and s.field != null and s.chart == null)
	var field_before: PackedByteArray = s.field_texture.get_image().get_data()
	await approach(s.apply_button, 1.2)
	await press(s.apply_button)                      # APPLY: QUARTER TURN onto the 16 x 16 field
	check(tag+"APPLY rewrites the floor field (readback)", s.applied and s.field_texture.get_image().get_data() != field_before)
	var quad_before: PackedByteArray = t.surfaces[0].material_override.albedo_texture.get_image().get_data()
	# press TURN MOTIF on the ONE MOTIF panel (first button of t's control_panel child)
	check(tag+"TURN MOTIF turns the hall and the linked study", t.phase==1 and t.surfaces[0].material_override.albedo_texture.get_image().get_data() != quad_before)
	var film: Node3D = station("f2_film_tiling_rule_1_12")
	check(tag+"film case clear of shaft B", film.global_position.z - 1.34 > 3.0 + 1.0)
```

Use `monitor_press(film, "route")` for TURN VIEW, as on the other film placements.
