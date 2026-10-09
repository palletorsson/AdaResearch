# Colour as partition, coordinate and path

## Office

`color_constellation_office` opts in with `#layout:cubicles#compare:visibility`. Four cubicles on each side contain desks, monitors and chairs. The root is at floor height; the occupied office is about 9.6 by 13.8 metres. Forty 2.6-metre panes have matching static box colliders. All walls are orthogonal, entrances are 1.2 metres wide, and the central aisle is open.

The standing entrance console calls `toggle_office_glass()`. This switches material transparency and alpha (0.26 / 1.0). It preserves pane transforms, RGB values and the exact collision bodies. The console has its own solid plinth and is included in the visibility bounds. This is renderer transparency, not wavelength-dependent absorption. The older `mixture` controls belong to the default installation, not this cubicle configuration.

## Colour coordinates

`color_space_navigator:180:1.2:1#mount:comparison#plinth:0` adds an integral support for the two small models. The 0.7-metre RGB cube sits entirely above the support; its 500 seeded samples use colour channels as local coordinates. Another 500 samples populate the HSV cylinder: hue angle, saturation radius, value height. Internal names still say HSL in places, but the code calls `Color.from_hsv` and the displayed label says HSV. This is an inspectable model, not an interactive colour picker or a body-sized room. The black corner is slightly brightened for visibility.

## Interpolation

`gradient_interpolator:180:0.95:1#mount:comparison#plinth:0` adds its own 0.95-metre support and standing canonical control panel. The comparison configuration enlarges the sixteen cubes to 0.045 metres with 0.009-metre gaps. COLOUR A and COLOUR B advance through eight presets; RGB / HSV toggles the calculation while preserving the endpoints. Other placements retain the original rack and dimensions.

RGB mode calls `ca.lerp(cb, t)` at `t = i / (step_count - 1)`. HSV mode wraps the hue difference onto the shorter arc and linearly interpolates saturation and value. Red to blue therefore compares a darker RGB interior with a saturated magenta HSV interior. Other endpoint pairs need not show the same contrast.

## Verification

Run `commons/testing/probe_walls_encounter.gd` in the desktop museum. It checks body sweeps through the aisle and eight entrances in both visibility modes, pane blocking, unchanged collider identity, actual button signals, reachable controls, sample counts and channel-position correspondence. Tracked hands and headset comfort remain untested. Pre-edit map texts and layout are retained in `doc/space/walls-partitions-2026-09-10/before/Color_Walls`.
