# Tutorial_Pattern (floor 2) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-2.json`, in the `floors[2]` shape, and this
note. Nothing else was written. **No Godot run.** Static checks:
- The fragment validates against `rooms.schema.json` in memory.
- All 12 IDs appear once. Artifact keys, `facing = token yaw + 180`, token heights and
  scale are all kept.
- The config matches the audit's own parse. The bare `#p4m` becomes `{"p4m": "true"}`,
  which is also the grid's reading (`GridInteractablesComponent` :1738); the museum plan
  had dropped it.
- **No height corrections**: every token height is 0 or more.

## Placement

The main room (cols 0-18) is turned 180° rigidly: `x = 9 - col`, `z = 13 - row`. The spawn
(9,1) lands on the arrival (0, 12). Main-room content spans x -4.4..5.5, at least 1.9 m from
both shaft openings, and 3.8 m from the floor-2 pad.

| id | at | facing | height | config |
|---|---|---|---|---|
| `f2_pattern_studio_plate_5_3` | 4, 10 | 180 | 0 | none |
| `f2_pattern_tile_plate_4_7` / `_8_7` / `_12_7` | 5,6 / 1,6 / -3,6 | 0 | 0.51 | p4m |
| `f2_pattern_tile_mirror_4_12` | 5, 1 | 180 | 1.35 | none |
| `f2_pattern_tile_puzzle_7_12` | 2, 1 | 180 | 1.35 | none |
| `f2_grid_model_13_12` | -4, 1 | 0 | 0 | none |
| `f2_panel_bridge_loom_12_16` | -3, -3 | 180 | 0 | shafts 8 |
| `f2_script_runner_4_17` | 5, -4 | 180 | 1.1 | none |
| `f2_dark_sphere_8_17` | 1, -4 | 180 | 0 | none |
| `f2_pulsar_compact_13_17` | -4, -4 | 180 | 1.1 | none |
| `f2_pattern_maker_station_22_9` | **-16, 9** (rigid -13, 4) | 0 | 0 | lesson fixed_motif |

**Fit exception: the annex unit (the maker station).**
- **Footprint.** With `lesson: fixed_motif`, the station spans the lesson bounds x ±3,
  z ±2.5, 3 m tall (`fixed_motif_lesson.gd` :51). That includes a 4 x 4 m carpet at y 0.005
  and a 1.34 m tilted panel at y 1.25, facing station-local -z.
- **Why it moved.** At its rigid position (-13, 4), the carpet and the panel's standing
  area overlap shaft A's opening.
- **Moved by (-3, +5)** to (-16, 9), with facing kept. It still stands west of the main
  room, as the annex did.
- **New clearances.** The panel faces south over its own carpet, and the visitor at
  z ≈ 7.5-8.5 is 4.5 m north of shaft A. The station spans x -19..-13, z 6.5..11.5, 2 m
  from the column at (-14,14).

**Not transferred:** the walls and the annex walls (structure 8), `s`, `sp` at (13,15) and
`t` at (9,19).

## Dependencies and minimal adapters

1. **`grid_model`, adapter required.** It mirrors the hall's own GridSystem. `_ready` looks
   up the first node in group `"grid_system"` (`grid_model.gd` :74). That lookup is
   global, not hall-scoped. It needs `data_component` and `structure_component`, and
   picking up a mini cube calls `stack_add`/`stack_remove` on the full-size grid.
   - **In the Void**, with no GridSystem, it builds **nothing** (the catalog measured a 0
     AABB) and keeps a `node_added` listener on the whole tree.
   - **Hazard.** Any other trial's `"grid_system"` node would be adopted.
   - **Minimal adapter.** A hall-scoped grid facade built from `Tutorial_Pattern`'s
     structure layer, in the same spirit as your color_03 `CellGrid`. Its edits stay
     local.
2. **`panel_bridge_loom`** (`test_panel_bridge.tscn`):
   - **Desktop overlay.** `_create_info_label` (:321) adds a **CanvasLayer "InfoOverlay"**,
     a 2D "Panel Bridge Demo" text block at screen position (12,12). It sits on top of the
     Void desktop HUD whenever floor 2 exists, on any floor.
   - **Keys.** `_unhandled_input` (:170) reloads examples on keys 1-4 and **R**, and R is
     also the Void's retry key.
   - **Shaft count.** `shafts` reaches `config_data.get("shafts", 4) as int` as the string
     `"8"`. Please verify that it picks `loom_overshot_layout.json`; it should, because
     8 > 4.
   - **Temp file.** The config is written to `user://tmp/capture_data.json`, which any
     other panel bridge also uses. Check whether Foundry floor 1 has one.
   - **Layout.** The loader builds 3 panels on an arc 1.4 m up and 0.65 m in front (Void z
     -2.35). It also adds a `CaptureCamera` during config; that runs before
     `floor_content`'s camera pass, so it ends up un-current.
   - **Minimal adapter:** hide `InfoOverlay` and drop `_unhandled_input` in the Void,
     keeping the 3D panels.
3. **`pattern_tile_mirror` / `pattern_tile_puzzle`** share `pattern_tile_puzzle.tscn`. The
   variant comes from registry defaults (`repeat_mode`, `tile_size`) and needs your
   before-ready fix (mirror/brick/herringbone). Until that lands, the two are identical.
4. **`pattern_tile_plate` `p4m`.** The shorthand sets `wallpaper_group = 11` (:677), which
   is already the default (:61), so it has no visible effect. That matches the source.
5. **`pattern_maker_station`.** `apply_grid_config` after ready adds `FixedMotifLesson`
   (:155). The lesson hides the legacy panel, disables its Areas and process, and installs
   its own buttons. No external dependencies.
6. **Self-contained:**
   - **`pattern_studio_plate`**: a carpet of 3 x 2.1 m toward the arrival, and a plate at
     1 m.
   - **`script_runner`**: script "point", auto loop, objects spawned locally; reads
     `scripts.json`.
   - **`pulsar_compact`**: a static grid of tubes; up to about 2000 small cylinders, so a
     performance note for Quest.
   - **`dark_sphere`**.
   - The imported Camera3D and DirectionalLight3D in the pulsar and loom scenes are
     neutralised by `floor_content`.

## Focused test targets

- **Maker station:** press a `FixedMotifLesson.buttons["cell_1_1"]`, and check that
  `station._grid_data[1][1]` changes and the carpet shader updates. Then press "PM" and
  check `station._group_index == 2`, then UNDO.
- **Tile plate:** paint one cell, and check `get_cell`/`_grid_data` and the carpet
  readback. `wallpaper_group == 11` on all three.
- **Studio plate:** a palette press, then a cell paint, then a carpet update.
- **Mirror against puzzle:** after your fix, check that their `repeat_mode` differs.
- **Loom:** check that the overshot layout is loaded, with 8 shafts in the data store, and
  that `InfoOverlay` is hidden after the adapter.
- **Script runner:** the play button toggles, and the spawned objects stay under the
  runner.
- **Grid model:** after the facade, check that the mini-model cubes are built and that a
  lift/drop changes only the facade.
- **Shafts:** confirm the maker carpet (x -18..-14, z 7..11) and the visitor zone are clear
  of shaft A.
