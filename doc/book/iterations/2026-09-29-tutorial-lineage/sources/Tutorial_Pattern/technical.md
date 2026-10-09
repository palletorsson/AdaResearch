# Tutorial Pattern — keep the source, change the lookup

Pattern_Foundry separated an editable source from its receiving surfaces. Tutorial_Pattern compares two sampling rules for one source; Array_Patterns next extends repetition through an environment.

## The actual station

The primary `pattern_maker_station` is at grid (22,9), rotation 180, floor offset 0. Its `lesson:fixed_motif` configuration attaches `fixed_motif_lesson.gd`. The original exhibits remain in the recovered grid. A three-cell doorway at x17, z10–12 connects the east comparison bay. The map grows from 18 to 28 columns; its 21 rows and previous structure remain, except those doorway cells.

The lesson replaces this instance's visible editor with a mounted pointer-capable panel. It disables the old touch polling and old editor collision areas. Unconfigured instances retain their original editor. No shared scene or shader resource is overwritten.

Sixteen buttons edit a 4×4 array of palette indices. Eight paint buttons select a colour. P1 and PM select the floor's sampling rule; FLIP X and ROTATE rewrite the source; UNDO restores up to 32 source/rule transactions; RESET restores the asymmetric seed, selected paint and translating floor. Palette selection alone does not add an undo transaction.

## Two fixed references

The framed panels each measure 1.6×1.6 m and show four tile spans per side. The 4×4 m floor shows ten. Both therefore assign 0.4 m to one tile. Each panel owns a separate ShaderMaterial, while both read the same source ImageTexture. The left panel fixes `wallpaper_group=0` (P1); the right fixes `wallpaper_group=2` (PM). Changing the floor's rule leaves these references fixed.

The shader addresses a tile using the integer and fractional parts of scaled UV coordinates:

```glsl
vec2 st = uv * tile_scale;
int tile_x = int(floor(st.x));
vec2 local = fract(st);
```

P1 keeps `local`. PM reverses local x on odd columns:

```glsl
if (imod(tile_x, 2) == 1) {
    local.x = 1.0 - local.x;
}
```

These excerpts are from `commons/resourses/shaders/wallpaper_tile.gdshader`. They describe this rectangular sampling implementation. The PM field has an alternating two-column cycle; the 40 cm tile span is not a claim that its horizontal translational period is 40 cm.

The lesson creates a local copy of that shader with nearest rather than linear source filtering. This makes each indexed cell legible. Other stations retain their own sampling finish. The shader remains a display tool here; the closing shader room will examine it as its principal object.

## Changing the source

`PatternMakerStation._mirror_x()` constructs new rows from reverse x addresses:

```gdscript
row.append(_grid_data[y][tile_size - 1 - x])
```

Its quarter turn uses:

```gdscript
row.append(_grid_data[tile_size - 1 - x][y])
```

Both regenerate the small texture, so both fixed reference fields change. A rule switch regenerates that texture too, but its pixel bytes remain identical. The desktop probe checks this distinction directly. A palette value is converted into RGBA8 storage; comparisons allow one byte's quantisation.

The implemented lesson exposes source edits and P1/PM comparisons. Earlier descriptions of four stations progressing through waves and a free-form expression parser were not grounded in this station and are preserved in the before snapshot. Supporting exhibits remain independently explorable.

## Verification

`commons/testing/probe_fixed_motif.gd` loads the real museum and presses controls through XRTools pointer events. It verifies source/rule separation, paint, undo, reset, double reflection, four rotations, physical spacing, reachable heights and the bay approach. An unconfigured station retains its legacy editor. Headset comfort and tracked-hand interaction remain deferred at the user's request.
