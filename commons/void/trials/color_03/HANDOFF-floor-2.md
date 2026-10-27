# Color_Grid_Pallet / Grid as Color Canvas (floor 2) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-2.json`, in the `floors[2]` shape, and this
note. Nothing else was written. **No Godot run; nothing here is native-tested.**
Static checks:
- `floor-2.json` validates against `rooms.schema.json`. I put it into this trial's
  `rooms.json` in memory, with floor 1 neutralised (see the aside at the end).
- All five IDs appear once, with the token's yaw, height, scale and every `#` config.
- All five catalog keys exist and point at the original scenes.

**The primary encounter, `gridcolorizer`, cannot run without a bounded adapter.** See
Dependency 1.

## Placement: rigid and unturned

The hall is used from its high-row end:
- the address console at grid (7,15) faces +z;
- its swatch faces +z;
- the spawn `s` is at (9,15);
- the summary keeps "the approach open" from the row-20 opening.

The Void's direction already matches, so the transform is a pure translation:
`x = col - 9`, `z = row - 3`, `facing = token yaw`. The spawn (9,15) lands exactly on
the arrival (0, 12). Heights are the token's y; the museum support is 0 for all five.

| id | at | facing | height | scale | config |
|---|---|---|---|---|---|
| `f2_dark_sphere_5_5` | -4, 2 | 0 | 0 | 1 | none |
| `f2_film_foundation_class_17_8` | 8, 5 | 270 | 0 | 1 | plinth 0, pin true |
| `f2_spectrum_forest_5_12` | -4, 9 | 0 | 1.0 | 0.22 | plinth 0 |
| `f2_science_screen_15_15` | 6, 12 | 180 | 1.5 | 1 | mode grid |
| `f2_gridcolorizer_6_5` | -3, 2 | 0 | 0 | 1 | lesson addresses |

**No position adjustments.**
- **Film.** At x 8 its case spans z 3.66..6.34, 0.66 m north of shaft B's opening. Its
  buttons are at least 1.22 m from the opening, and the viewer stands at x < 7.5, on the
  slab.
- **Dark sphere.** It is 3.5 m from shaft A's opening and from the floor-2 pad (x
  -9.07..-7.53, z -3..-0.8).
- **Spectrum forest.** At scale 0.22 it is a 4.4 x 4.4 m cloud of 5000 lines,
  1.22-1.88 m up, spanning x -6.2..-1.8 and z 6.8..11.2.
- **Science screen.** About 4 m wide, at x 4..8 and z 12, facing -z into the hall.

**Order.** `gridcolorizer` is listed **last** on purpose; see Dependency 1.

## Dependencies

1. **`gridcolorizer` (lesson addresses): the scene and the receiving floor.**
   - **The root is a plain `Node`.** The root `CubeColorizer3D` is a `Node`, not a
     Node3D. `floor_content._build_artifact` does `instantiate() as Node3D`, which gives
     null, and the next `artifact.name` assignment errors. In a deferred build only this
     job fails. In a synchronous `_build_content` loop the error ends the loop, which is
     why the entry is last. Even when instanced, the child `AddressLesson` (a Node3D
     under a plain Node) is top-level, so it would ignore the floor's level and the mount.
   - **The lesson needs the hall's own grid floor.**
     - `address_lesson._ready` waits up to 3600 frames for
       `colorizer.find_multimesh()`. That needs a `GridMultiMesh` at `../GridMultiMesh` or
       in the parent's subtree.
     - It also needs `grid_structure`, which is typed `GridStructureComponent`. Its
       `cube_positions` must be an Array aligned with the multimesh instances.
     - Without them it calls `push_error("could not find its room floor")` and builds
       **no console**.
     - With them, it keys the interior cells (y 0, x 1..17, z 1..19) and builds the console
       in **absolute grid coordinates**: plinth at (7.2, 0.45, 15), panel at (7, 1.15, 15),
       swatch at (8.15, 1.04, 15.06). It then applies RULE.
   - **Proposed adapter** (a bounded local adapter like `array_tutorial/worksite.gd`'s
     `CellGrid`):
     - A Node3D root holds a child `HallOrigin` at mount-local (-6, 0, -5), so grid
       (0,0) sits at Void (-9, -3) and stays relative to the editable mount.
     - Under `HallOrigin` go: a `GridStructureComponent` stand-in whose
       `cube_positions` are the map's y = 0 cubes; a `MultiMeshInstance3D` named
       `GridMultiMesh`, one instance per cube, with origins at y -0.5 so the lesson's
       marker at +0.515 sits on a top flush with the slab; and the original colorizer.
       Reparent `address_lesson` under `HallOrigin` with local coordinates kept.
   - **Stand-in floor fit:**
     - **12 interior cells lie over the shaft openings** (cols 1 and 17, rows 1-6, at
       x ±8); col 1, rows 1-2 also sits on the floor-2 pad. Leave those cells out, or the
       stand-in floor covers 1 m of each opening.
     - **Row 19 (17 cells) overhangs the north slab edge by 0.5 m.**
     - The source floor has two holes, at (11,7) (the `tc:5:y` lift) and at (13,15) (the
       teleporter). Copy the map and they stay as two uncoloured gaps.
   - **Controls**, once built (handler bodies read):
     - X + and Z + call `step_address`, which cycles x and z through 8..12 independently.
     - COLOUR calls `paint_selected`, which writes the next of 4 inks to one instance.
     - RULE calls `apply_rule`, which colours every interior cell with
       `(x+z) % palette.size()`.
     - PALETTE calls `next_palette`, which moves through stonewall_freedom, starry_night
       and mondrian_grid and applies the rule.
     - The readout shows `(x,z) #hex`; the swatch and outline follow the selection.
     - The selected field (8..12 x 8..12) lands at Void x -1..3, z 5..9. The console
       lands at Void (-2, 12), facing +z. Its plinth ends **0.475 m** west of the
       arrival, as in the source, where it was 0.475 m from the spawn.
2. **`science_screen` (mode grid)** scans only its parent's children for a `grid_size`
   property. Its parent here is the mount, and nothing in the source hall has that
   property either, so both engines show the generic "GRID VIEW" with no tracked source.
   Its own controls are unchanged.
3. **Imported extras.** `spectrum_forest.tscn` carries a `WorldEnvironment`, a sun and a
   camera; `floor_content` nulls, hides and un-currents them. `gridcolorizer.tscn`'s 2D
   `UI` overlay is hidden by the lesson branch.
4. **`dark_sphere`** has no config, the same as your floor-1 placements, and no grid
   dependency.

**Not transferred** (utilities and structure):
- the six `el` lights at cols 5 and 13, rows 5, 9 and 13: the field loses its side
  lighting;
- the `tc:5:y` transport cube at (11,7), which the summary calls secondary context;
- spawn `s` and teleporter `t`;
- the walls (structure 8).

The source hall is 8 m tall; nothing here exceeds about 3 m.

## Suggested focused tests

```gdscript
if level == 2:
	var gc: Node = station("f2_gridcolorizer_6_5")          # the original GridColorizer, through the adapter
	var lesson: Node3D = gc.address_lesson                   # set in GridColorizer._ready (unnamed node)
	check(tag+"lesson bound to a receiving floor", lesson != null and lesson.ready_for_input and lesson.cells.size() > 300)
	check(tag+"console at grid (7,15) on this floor", absf(lesson.buttons[0].global_position.y - (game.building.spec.levels[level] + 1.15)) < .2)
	var before: Color = gc.multimesh.get_instance_color(lesson.cells[lesson.selected])
	await press(lesson.buttons[2])                           # COLOUR
	check(tag+"COLOUR writes one instance, swatch follows", gc.multimesh.get_instance_color(lesson.cells[lesson.selected]) != before and lesson.swatch.material_override.albedo_color == gc.multimesh.get_instance_color(lesson.cells[lesson.selected]))
	var kept: Color = gc.multimesh.get_instance_color(lesson.cells[lesson.selected])
	await press(lesson.buttons[0])                           # X +
	check(tag+"moving the selection keeps the stored colour", gc.multimesh.get_instance_color(lesson.cells[Vector2i(lesson.selected.x-1 if lesson.selected.x>8 else 12, lesson.selected.y)]) == kept)
	await press(lesson.buttons[4])                           # PALETTE → rule rewrites the field (readback of two diagonal cells)
	check(tag+"no stand-in cell covers a shaft opening", not lesson.cells.has(Vector2i(1,3)) and not lesson.cells.has(Vector2i(17,3)))
	check(tag+"science screen in GRID VIEW", station("f2_science_screen_15_15")._generic_mode_name == "grid")
```

Use `monitor_press(film, "route")` for the film's TURN VIEW.

**Aside for floor 1, outside my scope:** your `rooms.json` floor 1 has
`f1_visual_color_mixing_9_7` at height -0.4 and `f1_color_sets_overview_26_32` at -0.5.
Both fail the current `rooms.schema.json` (`height` minimum 0).
