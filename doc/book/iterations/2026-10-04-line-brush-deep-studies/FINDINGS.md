# A line acquires a body

4 October 2026. Six standalone Godot constructions, controlled native captures, and a freehand input test.

## What was built

One stored gesture becomes a capped round tube, an untapered ribbon, a tapered ribbon, a turning ribbon, an alpha wash or a dry-brush surface. Three authored examples test different demands: a spatial loop, depth-separated crossing strokes and a portrait. New drawings use the same six constructors. Independent strokes retain their separation, colour and depth.

This extends the earlier point-stamp brush into continuous triangle surfaces. It does not replace or modify the earlier painting-space project or any museum hall.

## Findings

**A face can disappear while the construction remains.** A planar ribbon viewed exactly edge-on becomes invisible. Its shadow remains because the light approaches from another direction. The test changes only the camera. This is a strong possible encounter after Triangle: visible extent, surface and solid volume are different properties.

**A shader can open the image without opening the geometry.** The loaded stroke, wash and dry brush use identical vertices. The wash changes alpha coverage; the dry brush discards fragments. This differs from a hole carried through a glyph extrusion, where the boundary geometry is different. The gallery has no collision shapes.

**A drawing can remain available beneath its representation.** Width, taper, twist and material changes do not rewrite the recorded path. Coarse and fine surface sampling draw from the same stored positions. That does not recover unrecorded bends: the record has its own sampling decisions.

**A portrait is also an arrangement.** Eight separate authored paths form a face from the front. Turning around it exposes the deliberately different depths of eyes, nose, outline, hair and shoulders. The full orbit moves only the camera. This is a test composition, not a Mona Lisa reconstruction or a captured human portrait drawing.

**Transparency still needs a situated test.** For three separated-depth strokes, reversing creation order produced a pixel-identical image from the same camera. A camera move changes which colour is in front. This does not certify correct sorting for arbitrary intersecting ribbons.

## Repairs during the study

Switching presets or restoring an example now retains an undo state, so unsaved drawing is recoverable with Z. A valid but extremely long path exposed the need for a rendering budget beyond the recorded-point limit. Rendering is now capped at 512 samples per stroke and 4,096 across a drawing. The display announces adaptation and retains the original points. Losing window focus ends drawing.

## Evidence

- 71 geometry checks passed: finite data, orthonormal frames, winding, normals, nondegenerate triangles, tube caps and welded closure, UVs, taper, twist, duplicate positions, reversal and resampling.
- 46 integration checks passed, including 22 successful native image captures. These cover shared geometry/material comparisons, pen lifts, mid-stroke depth changes, independent colours, controls preserving data, undo, save/load, malformed input and the render budget.
- A 96-frame native orbit leaves the portrait data unchanged.
- The download contains the complete standalone project and is compared byte-for-byte against its packaged source files; the current inventory is recorded in `source-manifest.json`.

The desktop drawing test is a scripted replay through the real input handler. No pressure-sensitive device, tracked controller or Quest test was performed. Broad strips may fold through themselves at tight turns; this is not a self-intersection solver or a physical paint simulation.

## Where it can return

Trace retains positions; Triangle turns a path into a face; Primitives carries sections through space; Colour compares overlaps; Shaders examines the image-making rules. These are proposed teaching returns. Nothing has yet been installed in those halls or promoted into their final manuscripts.
