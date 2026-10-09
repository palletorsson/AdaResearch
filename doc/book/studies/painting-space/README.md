# Painting space

Eight native Godot studies ask how a body becomes visible: a solid, points, lines, nested shells, a trail of translucent stamps, paint on a nearly invisible surface, stacked slices, and moving points with short tails. In this second pass the free-space example becomes a coloured knot; the same marks can be viewed as soft colour, bubbles or light points.

Open `project.godot` in **Godot 4.6**, let the font import, and run the project. It uses Forward+. No addons, museum autoloads, scene-node lookups or external assets are required. JetBrains Mono and its OFL license are included.

## Explore

| Control | Effect |
| --- | --- |
| 1–8 | Approach a station and hide the others for a clear view |
| 0 | Return to the overview |
| Left-drag | Orbit, except at the drawing stations |
| Shift + left-drag | Orbit at either drawing station |
| Right-drag | Look around |
| Right mouse + WASD / QE | Fly horizontally / vertically in camera coordinates |
| Wheel | Approach or withdraw; at station 5, move the drawing plane instead |
| G | Toggle screen glow while retaining the geometry |
| Space | Pause/resume the moving traces |
| B | At station 5, cycle soft colour / bubbles / light points without changing the drawing |
| X | Change the next stroke's colour: pink, cyan, amber, lilac |
| [ / ] | Make the brush smaller / larger |
| Z | Undo the last drawing, clear, restore-example or load action; up to 12 steps |
| F5 / F9 | Save / load both drawings locally |

## Draw

**5 — A brush in space.** Left-drag to leave coloured marks. The circular cursor shows brush size; its guide drops to the floor to make depth legible. Scroll to change depth. Each stroke starts on a plane facing the camera; moving that plane and drawing from another viewpoint creates depth. This is a desktop depth control, not tracked hand input. Moving the pointer adds interpolated samples to keep a quick stroke connected; holding it still adds a mark every 45 milliseconds. At 900 marks, new marks replace the oldest. B changes how all stored marks appear, retaining their position, colour and base radius; the light-point view uses a smaller visible radius.

**6 — A surface found.** Left-drag across the hidden sphere. A ray from the camera meets the sphere mathematically; its direction gives the location of the mark. A faint rim keeps the untouched sphere discoverable. The paint texture wraps around its longitude seam and the brush handles both poles. Marks stay attached as the camera moves. You cannot paint its far side through the front: orbit to reach it.

At either drawing station, **C clears** the work and **R restores** the example. **Z** brings the previous state back. Surface strokes also interpolate between pointer samples, following a spherical arc rather than cutting through the sphere.

Losing window focus ends the current stroke, so switching to another app cannot leave the brush depositing marks. A new press starts a separate stroke when you return.

**F5** writes both drawings, their stored colours and sizes, and the selected brush material to `user://painting-space-v2.save`. **F9** restores that file. The file is local to Godot's user-data folder for this study and is overwritten by the next F5 save. This is an explicit save, not autosave. Nothing is uploaded. A load can itself be undone. Test runs use a separate temporary file and never overwrite this save.

## What the pictures are made of

- Solid: a shaded `SphereMesh`, radius 1.3 metres.
- Points: 420 small spheres placed on the same radius with a Fibonacci distribution.
- Lines: 1,440 short cylinder segments form latitude and longitude circles. Emission and environment glow make the traces luminous.
- Shells: three slightly offset nested surfaces with additive colour and an angle-dependent sheen. The colour bands are a stylised shader, not physically simulated thin-film interference, glass or a filled fog volume.
- Space brush: three fixed-size `MultiMesh` views of the same samples. Soft colour uses radial falloff on camera-facing quads; bubbles use spherical shells; light points use small emissive spheres. The soft view is a volume impression made by overlapping stamps. It is not raymarched fog, a Boolean union or a meshed solid.
- Surface paint: a 512 × 256 image stores colour and opacity. A custom spherical mapping is shared by the brush and shader. There is no collision mesh; ray–sphere intersection constrains the brush.
- Slices: 13 thin discs have the radius of a sphere at their height.
- Memory: 24 moving points, each displayed with 24 samples of its recent analytic path. Tails shrink and darken with age. This is a deterministic trace study, not a fluid simulation or general particle physics.

The common spherical envelope remains a comparison scaffold for seven stations. The knot at station 5 shows what happens when the brush leaves that boundary. Marks have their own thickness; slices and samples approximate a boundary at different resolutions. Emission does not itself illuminate the room. G exposes the additional contribution of screen glow.

## Lines as a way to make form

A line can outline a body, become its structure, or acquire a body of its own when given thickness. It belongs alongside points, surfaces, profiles and volumes in our vocabulary of form.

| Approach | What it can make |
| --- | --- |
| Contours and rings | Cross-sections, wireframes and open shells; the latitude and longitude study already makes a sphere legible this way. |
| Ribs and woven lines | Lattices, screens, cages and canopies; spacing determines how much remains open. |
| Straight lines between curves | A curved envelope assembled from straight segments; changing a guiding curve changes the whole arrangement. |
| A profile along a line | Tubes, ribbons, rails and knots; the path supplies direction, the profile supplies width and section. |
| Traces and branches | Drawings accumulated into bodies, or paths growing into networks; order and duration contribute to form. |

The rings, moving traces and free-space brush are working studies here. Woven structures, straight-line surfaces and branching networks are proposed next experiments. The companion glyph-form atlas already explores profiles carried along paths.

A visible line needs a width. Our rings use thin cylinder segments; the brush's light view uses a chain of points. An implied surface is not automatically a filled mesh or a collision boundary, and visible crossings do not automatically join the parts. These are separate construction decisions.

## Relation to Ada

The experiment returns to Point, Line and Trace. A collection of locations can become a perceived body; a stored history can stand in for a surface. The paint station reverses this: a surface already exists mathematically and becomes visible where it receives marks. The distinction is carried by the interaction.

The example privileges a spherical boundary and a camera-facing desktop brush. Those are chosen constraints. `stamp_space(world_position)` and `paint_direction(direction)` separate placement from input so an XR adapter could later supply tracked positions. Neither tracked-hand use nor Quest performance has been tested here.

This remains a standalone research gallery, with a free camera and no walking collisions. It is not yet an artifact registered or placed in a museum hall.

## Verification

Native Godot checks cover the point radius, analytic ray hits/misses, the paint seam and pole, bounded brush storage, mouse-event drawing, interpolation, material switching with retained positions, undo, disk save/load, invalid-state rejection, depth control, pause, glow and screenshots. The second-pass review contains 52 passing checks and a 120-frame native animation at approximately live speed.

The subsequent freehand test adds 32 passing checks. An actual desktop mouse session drew separate strokes, changed colour and depth, and switched materials. A repeatable mouse-event replay drew an irregular portrait with 584 marks across 0.9 metres of depth, checked pen lifts, undo, saving, material changes and drawing cancellation on focus loss. The portrait is a scripted input test, not a claimed human hand drawing or a Mona Lisa reconstruction.

Related work: `../glyph-form-atlas/` explores outlines and sweeps; this study explores how samples, material and duration make a body appear.
