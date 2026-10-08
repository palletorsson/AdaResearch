# Point One — implementation reference

The active corridor contains point_absent, point_visible, point_solid and point_pedestal, built by commons/primitives/point/point_condition.gd. The absent condition creates no sphere. Visible and solid have radius 0.14 m; only solid adds a fixed collision sphere. The final sphere has radius 0.65 m, centre height 1.40 m and a pedestal whose top is 0.75 m.

point_sun_switch.gd adds a directional light for the study spheres on visual layer 18, distinct from collision layers. The existing museum floor receives this light on an additional visual layer 17; no extra floor plates are added. Its material and normal lighting remain. The sun's caster mask includes only the study bodies, so the lesson is not accidentally shadowed by a streamed roof. A low, unshadowed local fill keeps the bodies readable when the sun is hidden. Other lights exclude only the dedicated sphere layer. Light and floor masks are restored when the study unloads.

The wall lever uses the production XRTools area button with pointer support: near-hand entry or pointer press toggles sun.visible. Its 1.28 m control height is a design value, not a headset comfort certification. The plate sits on the inside face of the corridor's right wall. The entry door remains.

## Tutorial in the existing corridor — 3 October 2026

The canonical `tutorial.md` now reads and edits `point_condition.gd`, which already constructs the absent, visible, solid and pedestal stations. No teaching artifacts or alternate room have been added. The learner edits `CENTRE` (1.12 to 1.7), `RADIUS` (0.14 to 0.3), and the existing collision assignment (`radius` to `radius * 2.0`), restoring each experiment. The pedestal has its own centre and mesh radius, so the first two edits leave it unchanged; the collision assignment is shared and doubles its boundary too.

The lesson introduces named values, constants and variables, Vector3 as a position, resources and scene nodes, mesh construction and a separate physical boundary. Station selection, labels, materials, subdivision and the light rig remain supplied. Grabbing and reference frames remain in Coordinates. The excerpts identify existing code; students do not replace the complete artifact with the fragments.

Native checks exercise the printed edits in memory at the original museum placements. The actual desktop player crosses the absent and visible stations and meets the solid one. Increasing only its boundary moves contact earlier; the existing sun switch does not change contact. Screenshots come from inside the museum. The saved artifact source, map and critical text are unchanged. Physical headset use and beginner comprehension remain untested.

The earlier portable three-script study remains available as a separate companion; it is no longer the canonical tutorial's starting environment.

Pickup, WORLD/LOCAL cards, frame, L-shaped basin and target now belong to Point_Coordinates. See its technical.md for the maintained point_one_main channel and all moved placements. Distance is first calculated in the Point_Lines tutorial.
