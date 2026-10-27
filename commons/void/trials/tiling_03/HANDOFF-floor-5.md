# Ribbon_Patterns_02 (floor 5) → Void: HANDOFF

Owner: Claude Opus, 2026-10-21. Files: `floor-5.json` and this note. **No Godot run.**
Static checks:
- With floors 4 and 5 substituted into `rooms.json`, it validates against
  `rooms.schema.json`.
- All 12 IDs appear once, with the original artifact keys, every `#` config,
  `facing = yaw + 180`, token height (0 for all) and token scale. No height corrections.

## Placement

The hall (27 x 31) is turned 180°: `x = 13 - col`, `z = 14 - row`. The spawn (13,2) lands
on the arrival (0, 12).
- **Width.** The hall's two content columns (source cols 5-6 and 20) land at x ±7..8,
  exactly on the shafts' x-range.
- **Depth.** The hall is 31 m deep, which leaves no z slack, so rows 11-16 fall in the
  shaft band.
- **Moves.** Those four pieces move inward to the central strip and keep their side. One
  stick moves off a column line.

| id | at | facing | scale | note |
|---|---|---|---|---|
| `f5_SimultaneousContrast_6_5` | 7, 9 | 180 | 1 | rigid; 7 m wide, x 3.5..10.5, north of the band |
| `f5_MetamerismLab_20_5` | -7, 9 | 180 | 1 | rigid; x -9.75..-4.45 |
| `f5_spherecolors_6_11` | **3.5, 3** | 180 | 0.8 | rigid would be (7, 3), over shaft B. Moved 3.5 m inward: now 2.5 m. |
| `f5_hue_carousel_20_11` | **-4, 3.5** | 180 | 0.8 | rigid would be (-7, 3), over shaft A (radius 1.64 m at 0.8). Moved +3 x, +0.5 z: now 1.86 m from shaft A and 1.9 m from the floor-5 pad (x -9.07..-7.53, z 0.8..3.0). |
| `f5_grabcolorcollection_5_15` | **5.5, -1** | 180 | 1 | rigid would be (8, -1), inside shaft B. Moved 2.5 m inward: now 1.9 m. |
| `f5_color_mixing_20_16` | **-3, -2** | 180 | 0.55 | rigid would be (-7, -2): 6.4 m wide, over shaft A. Moved 4 m inward: x -6.2..0.2, 1.3 m from shaft A. |
| `f5_dark_side_prism_6_19` | 7, -5 | 180 | 0.6 | rigid; 1.85 m south of shaft B and 0.51 m from the riser at (6.5, -4.2) |
| `f5_prism_20_20` | -7, -6 | 180 | 1 | rigid |
| `f5_grab_stick_scanner_2_23` | 11, -9 | 180 | 0.4 | rigid; its scan beam runs x 5.15..11 |
| `f5_two_roads_6_25` | 7, -11 | 180 | 0.45 | rigid; about 1 x 2.7 m |
| `f5_color_scanner_20_25` | -7, -11 | 180 | 0.45 | rigid; 1.65 m from column (-5,-14) |
| `f5_grab_stick_24_28` | **-11, -13** | 270 | 0.4 | rigid would be (-11, -14): its 6 m beam ran along z -14 into column (-5,-14). Moved +1 z: now 0.52 m from the columns. |

**Not transferred:** the walls, including the divider stubs at rows 9 and 21, `s` and `t`.

## Dependencies and fit notes

- **Scan beams.** The long catalog AABBs of `grab_stick` (15 m), `grab_stick_scanner`
  (14.7 m) and `color_scanner` are mostly the visual scan beam:
  - `color_scanner.gd` :5 sets `scan_range` 15, and :135-138 build the beam mesh, so the
    beam is 6.0-6.75 m at scale 0.4-0.45;
  - the raycast mask is all layers (:153), so a beam reads whatever it hits, including
    columns, the slab and players.
- **`color_scanner` display.** It looks for a sibling node named
  `GrabStick_ColorScanner#DisplayScreen` (:77-83). In the Void its parent is the mount, so
  that lookup may come back null. Verify that the colour readout appears; if not, an
  adapter can hand it the display.
- **Possibly sunk AABBs.** `SimultaneousContrast` (7 x 4 x 1), `MetamerismLab` (5.3 x 5 x
  1), `spherecolors`, `dark_side_prism` and `color_scanner` have AABBs centred at or below
  y 0 (catalog measurement). Verify natively that none sinks through the slab. Heights are
  kept at the token's 0.
- **Lesson configs.** `SimultaneousContrast lesson:context`, `MetamerismLab
  lesson:carrier` and `spherecolors label_in_space:true` are kept verbatim; their handlers
  are untraced.

## Focused mouse/XR tests

- **`SimultaneousContrast` (context lesson) and `MetamerismLab` (carrier lesson):** drive
  one control each and read back the swatches.
- **`spherecolors`:** check that the in-space labels are present, and grab a sphere.
- **`hue_carousel`:** spin it and read back the angle.
- **`color_mixing`:** mix two colours and read back the result swatch.
- **`grabcolorcollection`:** grab a colour.
- **Prisms:** dark-side prism and prism, light and colour readback.
- **Scanners:** pick up `grab_stick` and `grab_stick_scanner`, and aim the beam at a known
  colour. Check that the display shows that colour, not the column's or the slab's.
  `two_roads`: walk both roads.
- **Clearances:** the four moved pieces against the shafts (at least 1.3 m), and the
  floor-5 pad egress against the carousel.
