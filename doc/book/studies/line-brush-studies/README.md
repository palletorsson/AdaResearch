# A line acquires a body

Six native Godot 4.6 studies of the same stored gesture. A round section, a flat ribbon, a tapered stroke, a turning ribbon, a translucent wash and a dry-brush surface reveal different consequences of the same path.

For drawing with just coloured lines or luminous dots, run `draw_lines.tscn` instead. Its focused view uses left-drag to draw, right-drag to orbit and B to switch representation. See [DRAWING.md](DRAWING.md).

Open `project.godot` in Godot 4.6, let the font import, and run. The scene creates its geometry, camera and lights in code. No museum autoloads, scene-node lookups or addons are needed. This is a standalone desktop research gallery; it has no walking collision, tracked-hand input or museum placement.

## Compare before drawing

Press **1–6** to inspect a stand, **0** for the gallery. **Left-drag** orbits; the **wheel** changes viewing distance. **P** cycles a spatial loop, three crossing strokes and an authored portrait. The portrait is a composed example, not a reconstructed painting or a captured human drawing.

The six stands share position and colour data. Stands 3, 5 and 6 also share exactly the same mesh; their surfaces differ. The first four use the same surface material, allowing section, taper and twist to be compared without changing gloss.

The section's direction is transported along the path. “Flat” refers to the ribbon's zero-thickness section: a spatial path can still make that surface bend. It does not face the camera automatically. The narrow round line has capped ends; the ribbons have open boundary edges and no solid interior.

## Draw a gesture

Choose a stand, press **C**, then **Shift + left-drag** to draw. Release to lift the pen. Each stroke is stored separately, so a move between strokes does not add a connecting face. All six versions update from the same drawing.

- **Shift + wheel** moves the drawing plane in depth, including during a stroke. A new stroke starts on a plane facing the current camera. Orbit and draw again to work from another side.
- **X** changes the next stroke's colour.
- **[ / ]** change section width; **, / .** change the turning ribbon's total twist.
- **- / =** change wash opacity. **S** compares fine and coarse resampling of the retained input path.
- **Z** undoes the last stroke, clear, example switch or load action; twelve states are retained.
- **R** restores the current example. **P** moves to the next example. **Z** can recover the drawing you had before either action.
- **F5 / F9** save and load the drawing locally. The file is `user://line-brush-drawing.json`. Tests write separate files and never overwrite this save. Width, sampling, twist and opacity are viewing settings and are not stored in that drawing file.

The mouse supplies position, not pressure or wrist rotation. Taper and twist are chosen rules. Holding still adds no extra positions; this is a path brush rather than accumulating spray. At 1,600 recorded positions or 24 strokes, adding data stops; there is no silent removal of old marks. Rendering uses at most 512 distance samples per stroke and 4,096 across the drawing, shared by all six versions. Longer paths automatically use coarser detail; the display announces this and the original recorded positions remain available. The limits keep this small study bounded rather than providing an unlimited painting system.

## Construction

`stroke_geometry.gd` cleans repeated positions, samples by distance and transports an orthonormal section frame along the path. Width, taper and twist are measured along accumulated length, not the number of mouse events. `build_mesh()` then creates triangle surfaces with normals and UV coordinates. Different event densities along the same straight segments give the same distance samples; a sparse recording can still omit a bend that never entered the data.

The wash uses ordinary alpha transparency with soft edges. Overlap is not pigment mixing. Transparent triangle sorting can become ambiguous in intersecting or self-overlapping surfaces. The dry brush discards fragments in longitudinal lanes; it does not remove triangles. Neither shader changes topology or supplies collision. Tapering, smoothing-looking shading and an attractive outline do not certify that a sweep is free of self-intersections. Tight turns can still fold a broad strip.

## What this lets Ada ask

In Trace, the hand leaves positions. After Triangle, two edges can be joined into a face. A profile carried through space then connects to Primitives. Colour can investigate how overlaps alter what we see, while Shaders explains those surface rules. The full gallery can remain a research companion; each hall needs only the comparison that advances its question.

The distinction is felt by moving around the result. A portrait can hold together from one view and separate into disconnected strokes from another. A flat stroke can vanish edge-on and still cast a shadow. Nothing has been erased from the stored gesture. Visibility is a relation between a construction, its surface, the light and where we stand.

See `QUESTIONS.md` for the research questions and `geometry-notes.md` for the geometry contract. The review folder `../../iterations/2026-10-04-line-brush-deep-studies/` contains native captures, an orbit animation and the current test reports. These are geometry and scripted desktop-input tests; no headset or physical pressure-sensitive device has been tested.
