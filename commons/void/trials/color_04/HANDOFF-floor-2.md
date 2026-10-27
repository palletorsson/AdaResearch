# Color_Walls (floor 2) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-2.json`, in the `floors[2]` shape, and this
note. Nothing else was written. **No Godot run.** Static checks:
- The fragment validates against `rooms.schema.json` in memory.
- All 9 IDs appear once with every `#` config. Yaw follows the hall's 180° turn
  (`facing = rotation + 180`), and scale and token heights are kept.
- One height is corrected; see below.

## Why the assemblies are independent

The source hall is 37 x 79 m in three bays: the main hall (rows 0-38), the assembly bay
(rows 39-61) and the wall bay (rows 62-78). Kept rigid, these do not fit 42 x 32 with
both shafts open. With yaws kept:
- **Office** (planes and console, about 11 x 16.2 m): it can cross the shaft band
  (z -3..3) only in the central strip.
- **Wall study** (19 x 12.5 m): it needs a full 13 m north or south band.
- **Assembly** (14 x 12.5 m plate, plus a console 1.2 m beyond its north edge): it needs a
  south band, with its console protruding into the shaft band.
- **Hallway** (8.6 x 16 m cone): it crosses the band only where it is narrow.

Each group is therefore translated as a unit, with all yaws unchanged.

| id | at | facing | height | note |
|---|---|---|---|---|
| `f2_rainbow_hallway_8_9` | -16.7, 13.4 | 0 | 1.0 | West group. The mouth faces north between the columns at (-14,14) and (-20,14). |
| `f2_dark_sphere_6_8` | **-15.3, 15.0** | 180 | 0 | Rigid would be (-14.7, 14.4), inside column (-14,14). Moved 0.6 m W and 0.6 m N. |
| `f2_subpixel_display_12_26` | **-19.0, -2.8** | 180 | **0** | Rigid would be (-20.7, -3.6), 0.3 m from the west edge. Now just past the tube's narrow end. Height corrected; see below. |
| `f2_color_constellation_office_23_20` | 0, 3.4 | 180 | 0 | Central. Bounds x ±5.5, z -4.3..11.9. The console (3.8, 10.95) and the open entrance face the arrival. |
| `f2_color_space_navigator_18_31` | 5, -7.6 | 0 | 1.2 | Rigid relative to the office (source +11 rows beyond it) |
| `f2_gradient_interpolator_28_31` | -5, -7.6 | 0 | 0.95 | Rigid relative to the office and navigator |
| `f2_film_gradient_paths_1_32` | **8.2, -7.6** | 270 | 0 | Rigid would be off the slab, at x 22. Kept at the comparison row's +x end, screen facing -x along the row, in source order (film, navigator, interpolator). |
| `f2_colour_assembly_18_50` | 14.6, -9.5 | 0 | 0 | South-east. The console is at (14.6, -2.5), with its visitor in the band's east segment, 0.15 m from shaft B's edge. |
| `f2_colour_wall_studies_18_70` | -11.5, -9.27 | 0 | 0 | South-west. The plate's north edge is at -3.02, and the wall is at z -13.40. |

**Height correction.** `subpixel_display:0:-0.5` is placed at **0**, the schema minimum,
so the display stands 0.5 m higher than authored. Its parts (swatch at y 0.46, label at
0.54, panel at 0.02) would otherwise sit at about floor level or below. Please measure
whether the original -0.5 was compensating for a grid surface offset. A local child offset
would restore it.

## Clearances, fit and clipping

**Shafts.**
- **Hallway.** Its bounding box (x -21..-12.4, from the 8.6 m mouth) only looks as if it
  reaches shaft A. Where the tube crosses the band (segments 5-7, outer radius 2.51 m or
  less) it spans x -19.2..-14.2, 1.7 m from shaft A.
- **Other pieces.** None overlaps either opening or the floor-2 pad. The closest is the
  assembly console visitor, 0.15-0.5 m east of shaft B.

**Overlaps (recorded, not fixed):**
- The office's rear walls stand on the wall study's thin receiving plate, at about x -5.5..-2,
  z -4.3..-3.02.
- The assembly plate overhangs the east slab edge by **0.6 m** (plate only; the specimen
  is inside). It contains the columns (14,-14) and (20,-14).
- The wall-study plate contains the columns (-20/-14/-5, -14). Its 18 m back wall passes
  **0.03 m** north of them.
- The gradient interpolator stands on the wall study's plate, in its audience area, 6.5 m
  from the console.

**Ceiling (5.64 m clearance; the source hall was 8 m):**
- **Assembly.** The canopy beams (y 6.25), posts (6.2) and wires (6.23) pass through floor
  1's slab and **protrude about 0.2-0.3 m above Color_Paint's floor** at about x 8.9..20.3,
  z -12.2..-6.8. Please check this against your floor 1.
- **Wall study.** The wall (5.8 m) ends 0.16 m inside the slab, hidden.
- **Hallway.** The cone is centred 1.0 m up with an outer radius of up to 4.3 m. Its top is
  5.3 m, which fits. Its lower half hangs **up to 3.3 m below the slab**, into the catch
  floor's airspace along the west edge, with a bottom 2.7 m above floor 3. This is as
  authored: in the source the lower half was below the grid floor.

**Not transferred:** the structure (perimeter, the corridor rails at cols 4 and 14, the
row-34 end wall, the hole at (9,32), the bay walls), spawn `s` at (4,4) and teleporter
`t` at (18,77).

## Parent-context dependencies and minimal adapters

- **`colour_assembly` and `colour_wall_studies`** use `spine_studies/station.gd`, the same
  adapter as earlier witness placements.
  - **Buttons.** `StudyButton` StaticBody3Ds on layers 21 and 23, inside `POINTER_MASK`.
    `pointer_event` fires when `event_type == 2`.
  - **Geometry changes.** They are refused while the camera is inside `guard_rect` or a
    body overlaps the occupancy Area. COLOUR and RESET are exempt from that check.
  - **Assembly buttons.** CANOPY, SCREENS, GATHER, COLOUR, RESET.
  - **Wall buttons.** SPACING (0.11/0.21), DEPTH (0.18/0.52), OMIT/RESTORE, COLOUR,
    RESET.
  - **No adapter needed.**
- **`rainbow_hallway`.**
  - **Scene extras.** It carries a Camera3D, a sun, a WorldEnvironment and a hidden UI;
    `floor_content` neutralises them.
  - **Collision.** The tube is CSGCombiner3D segments with `use_collision`, so the walk
    inside is real.
  - **Export.** GLB export must bake the CSG.
  - **Lights.** It has 3 OmniLights (energy 3.0).
  - **No adapter needed.**
- **`color_constellation_office`.** `_ready` reads meta `config_layout` "planes" and
  `config_compare` "visibility"; the Void stamps them before `add_child`. After ready,
  `apply_grid_config` is a no-op because planes is already set. The console "A VIEW / A
  WAY THROUGH", button FILTER / OPAQUE, calls `toggle_office_glass` on the 12 panes. Each
  pane's thin collider remains.
- **`subpixel_display`.** It has its own R/G/B slider panel at local y 0.02. A minimal
  adapter is needed only if native measurement wants the authored -0.5 seat restored.
- **`color_space_navigator` and `gradient_interpolator`.** `mount: comparison` is kept
  verbatim; I did not trace its handler, so please verify it natively.
- **Film.** The standard `concept_monitor` buttons.
- **Dark sphere.** No config.

## Useful interaction test targets

1. **Hallway.** Walk from the mouth (-16.7, 13.4) to the narrow end, z -2.6. Check that
   the body stays supported on the slab inside the CSG tube without snagging, and that the
   exit lands beside the subpixel display.
2. **Office.** Check FILTER / OPAQUE flips every pane's transparency and the readout
   "FILTER/OPAQUE / SAME PASSAGES", with a readback on `office_panes[i].material_override`.
   Walk through the open side passages.
3. **Assembly.** From the console, press SCREENS and check `specimen.arrangement == 1`.
   Then stand inside `guard_rect` and press GATHER; the refusal text must show. Check that
   COLOUR cycles `colour_rule`.
4. **Wall study.** Check that DEPTH changes `specimen.projection` 0.18 → 0.52 and that
   OMIT/RESTORE toggles `omitted`.
5. **Subpixel, navigator, interpolator.** Drive one control each and read back the
   displayed colour.
6. **Clearances.** Measure:
   - the assembly console visitor zone against shaft B (0.15-0.5 m);
   - the wall's 0.03 m gap to the columns;
   - the assembly protrusion above floor 1;
   - the office and plate overlap.
