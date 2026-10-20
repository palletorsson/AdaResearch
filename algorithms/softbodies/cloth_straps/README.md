# Cloth straps

The curtain mesh is generated at rest size with unit scale. The frame uses the
same dimensions: its inner width is the strip envelope plus 2 cm each side;
the top edge meets the crossbar underside; a full-length strip starts 8 cm
above the floor. There is no hidden, scaled SoftBody3D template.

`apply_grid_config` accepts these optional map settings:

| Setting | Values |
|---|---|
| `suspension` | `none`, `gantry`, `wall`, `hoop`, `mast` |
| `hanging` | `row`, `corners`, `single`, `staggered`, `arch` |
| `palette` | `foil`, `coral`, `rose`, `violet`, `blue`, `mint` |
| `strap_count` | 2–16 |
| `strap_width` | 0.1–1 m |
| `strap_height` | 0.4–5 m |
| `strap_overlap` | 0–40% of width |
| `walkway` | Coloured runner, two readable beam captions, lighter strips, no ball-throw shortcut |

`row` pins the full top edge. `corners` pins its two ends. `single` alternates
one top corner per strip. `staggered` alternates full and 62% lengths, and
`arch` shortens the centre to 30%; both keep the full top edge pinned. All
tops remain at the same height. Unsupported cloth remains dynamic under Jolt.

Carusell has five ten-strip gates at map cells (7,13), (7,16), (7,19), (7,22),
and (7,25), followed by the retained rear doorway. These use 3 m maximum
strip length and 32 cm width. The procession is beside the carousel, with
space to walk around it. It shares the hall's existing light and camera.

Default and Cloth Physics lesson instances retain their 6×12 subdivision
settings, eight top-row mesh entries, and .34 stiffness. Walkway instances
use 4×16 subdivisions, six top-row entries and .7 stiffness. These are engine
parameters rather than calibrated fabric properties.

Changing only the suspension preserves the existing soft bodies and pins.
Changing a strip dimension, hanging pattern or palette reconstructs them.
The Cloth Physics desk retains its separate pin, release and rebuild controls.

Native regression probes: `tools/probes/curtain_walkway.gd` and
`tools/probes/cloth_boundary_room.gd`. Reports distinguish supplied collision
and input tests from physical headset or Quest performance testing.
