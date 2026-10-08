# Colour as partition, coordinate and path

## Office — current layout, 1 October 2026

The active placement is `color_constellation_office:0:0:1#layout:planes#compare:visibility#plinth:0`. It remains at map cell (23,20), seated on the museum floor. `office_planes.gd` supplies twelve independent QuadMesh sheets, 2.75–3.55 m high, with thin matching box colliders. Fine edge strips and foot clamps make the obstacles legible. Three desks, monitors and chairs retain the office association without enclosing eight workstations.

The staggered transverse panes alternate the central route. Three smaller angled screens interrupt the rectangular pattern. A pale floor, interrupted side wings, rear opening and two overhead strips provide a neutral ground for the colour; a central ceiling slot stays open to the museum sky. The display backing is unshaded and does not cast shadows, so the global dark sky cannot erase the comparison. It does not simulate colour transmitted onto the floor by lights.

Each filter uses one double-sided quad, alpha transparency at 0.52, normal blending, unshaded colour and no cast shadow. One quad avoids applying the tint twice as would happen with two faces of a thin glass box. Fog is disabled on the filter itself; the background retains the museum's rendering. FILTER / OPAQUE disables transparency, sets alpha to 1.0 and enables shadow casting, while preserving RGB values, transforms and the exact collision bodies. Colour filtering here is layered RGB tint, not wavelength-dependent glass absorption. A multiplication trial darkened even a white pane in the current Compatibility renderer, and was rejected on visual inspection. The retained alpha mix is order-dependent; transparent sorting is a rendering limit, especially at intersecting sheets.

`layout=cubicles` retains the earlier forty-pane layout. No layout selects the older eighteen-pane installation and its `mixture=bench/light/retina` variants. These are separate configurations; mixture does not modify the active open office. Reapplying the same placement configuration does not rebuild it.

## Colour coordinates

`color_space_navigator:180:1.2:1#mount:comparison#plinth:0` adds an integral support for the two small models. The 0.7-metre RGB cube sits entirely above the support; its 500 seeded samples use colour channels as local coordinates. Another 500 samples populate the HSV cylinder: hue angle, saturation radius, value height. Internal names still say HSL in places, but the code calls `Color.from_hsv` and the displayed label says HSV. This is an inspectable model, not an interactive colour picker or a body-sized room. The black corner is slightly brightened for visibility.

## Interpolation

`gradient_interpolator:180:0.95:1#mount:comparison#plinth:0` adds its own 0.95-metre support and standing canonical control panel. The comparison configuration enlarges the sixteen cubes to 0.045 metres with 0.009-metre gaps. COLOUR A and COLOUR B advance through eight presets; RGB / HSV toggles the calculation while preserving the endpoints. Other placements retain the original rack and dimensions.

RGB mode calls `ca.lerp(cb, t)` at `t = i / (step_count - 1)`. HSV mode wraps the hue difference onto the shorter arc and linearly interpolates saturation and value. Red to blue therefore compares a darker RGB interior with a saturated magenta HSV interior. Other endpoint pairs need not show the same contrast.

## Verification

Replay the focused production-museum probe:

```powershell
python tools/run_encounter_probe.py Color_Walls --sequence color --render --probe doc/book/iterations/2026-10-01-office-open-colour/probe.gd
```

The probe checks the actual placed artifact, pane/furniture count, filter material, ordinary-controller passage along the staggered route and out through the rear opening in both visibility states, refusal at a pane, real pointer press/release callbacks, unchanged collider identity and idempotent placement configuration. See the saved report and native interior comparisons in the review directory. This is a supplied desktop input journey, not a headset or learner trial. Quest performance, tracked-hand reach and first-time navigation remain to be checked.

The 23/28 September reports remain historical evidence for the former cubicles and the two unchanged colour benches. Their forty-pane and eight-entrance claims do not describe this revision. The current probe confirms both benches remain placed; their previous sample/interpolation checks are not presented as rerun here.


<!-- study-spine:colour_assembly -->

## Installed application: Room to gather

`colour_assembly` occupies a new adjoining bay, after the existing encounters. Cell [18, 50], rotation 180°, museum adapter `res://commons/artifacts/spine_studies/assembly.tscn`. Original response to Liam Gillick; no claim of exact reconstruction.

Shift the colour index by one without moving a panel. Reuses coordinates, transform, array, colour; adds no prerequisite node. The display and main-player controls are supplied.


<!-- study-spine:colour_wall_studies -->

## Installed application: Wall relations

`colour_wall_studies` occupies a new adjoining bay, after the existing encounters. Cell [18, 70], rotation 180°, museum adapter `res://commons/artifacts/spine_studies/wall.tscn`. Original response to Liam Gillick; no claim of exact reconstruction.

Change the pitch of 24 rails without changing their count. Reuses line, coordinates, array, colour; adds no prerequisite node. The display and main-player controls are supplied.
