# Borrowed outlines

A native Godot 4.6 study of six bodies made from font profiles. Open `project.godot` and run. Everything is created in code. The included JetBrains Mono font is distributed with its OFL license.

Drag to orbit and scroll to approach. Keys 1–6 inspect individual bodies; 0 returns to the gallery. Hold the right mouse button and use WASD/QE to fly. This camera has no collision. The gallery is an isolated study, not a placement in the museum or an XR scene.

## Six experiments

| Source | Operation | Result | What the shape does not yet solve |
|---|---|---|---|
| O | Straight depth at a height of 5.4 m | An opening at bodily scale | Its lower stroke forms a sill. The opening needs another operation to become a level doorway. |
| O | Narrow, widen and turn sections while rising | A flared hollow vessel | The lower opening remains. It cannot hold liquid without a base. |
| B | Raise and turn sections | A body with two winding wells | Openings preserve their separation; they are not a branching network. |
| C | Carry a section along an open circular arc | A curved, open-sided channel | An apparent enclosure is not necessarily a topological hole. |
| I | Carry a section around a complete circle and join it | A ring with an I-shaped section | Its new hole belongs to the path, not to the original character. |
| : | Raise and bend both dots along the same frames | Two separate leaning bodies | One character and one mesh resource do not make them physically connected. |

The source profile stays beside each body. Its purpose is to make the origin of the form inspectable, not simply to name the result.

## The shared construction

`profile_sweep.gd` extracts a flat triangulated TextMesh, welds coincident points and finds the boundary edges. This reuses the engine's treatment of a glyph's inner contours and disconnected parts. Each section frame supplies a location, orientation and positive scale. Matching boundary points in successive sections form the side walls. Open paths get end caps; the circular I sweep joins its last section to its first and has no end caps.

There are two independent inputs: **the region to carry** and **the route along which to carry it**. `atlas.gd` keeps the six frame recipes together for comparison. This is a small generator for the tested shapes, not a general CAD kernel. Its curved routes use explicit circular frames, not a general arbitrary-path framing algorithm.

## Topology, carefully

We interpret “type 2 topologies” here as compound 2D profiles: regions with holes or disconnected pieces. It is not a technical classification used by this study.

For the tested non-intersecting extrusions, a hole in a connected planar profile becomes a handle in the closed boundary surface: O has one, B has two. B's resulting surface is genus two; that is distinct from merely calling an input two-dimensional. C's extrusion has no handle. The colon has two components. Closing I's path creates a handle even though its initial planar profile has no hole.

Tapering and twisting do not by themselves add or remove holes when the mapping remains non-folding. Do not interpolate B into O by pairing whichever points happen to share an index: the outlines differ in their number of contours. Merging channels, adding a branch, closing the bottom of the vessel or cutting through the O sill requires explicit new geometry, triangulation, a Boolean operation or a field-based construction.

## What could follow

The same interface could accept a triangulated SVG drawing, a traced outline or a hand-drawn profile, provided its holes and components are represented correctly. Symbol fonts widen the starting vocabulary; glyph support and usable vector contours still need checking. Other scripts should be approached as designed writing systems, not treated as a neutral supply of exotic motifs.

Useful next studies are an O that becomes an accessible passage through a deliberate cut; B's two channels opening into a shared room; and one cross-section reused as a handle, column and inhabitable enclosure. A lathe is another related operation: rotating a profile around an axis. The circular I sweep already has that interpretation. Profiles that cross the axis require additional care.

## What the shortcut inherits

The font supplies decisions made by a type designer: stroke thickness, counters, spacing and an intended scale of reading. Godot supplies curve sampling and triangulation. We choose the sweep, dimensions, shading and use. A body made this way is not without a history just because it was inexpensive to generate.

The most useful question is therefore not only “What forms can this produce?” but “Which inherited decision becomes visible when we try to use this form differently?”

## Verification

The paired review folder contains `verify.gd` and `verification.json`. Native checks cover finite nondegenerate triangles, paired edges, consistent winding, welded components and Euler characteristics. Physics queries check the O's empty centre, solid sill, and clearance for a 1.7 m capsule above the sill. The same capsule at floor level intersects the sill. These checks do not certify arbitrary self-intersection freedom, physical fabrication, collision-based locomotion or VR comfort.

All eight illustrations are native Godot captures of this code. No generated raster substitutes are used.

References: [TextMesh](https://docs.godotengine.org/en/4.6/classes/class_textmesh.html), [TextServer glyph contours](https://docs.godotengine.org/en/4.6/classes/class_textserver.html#class-textserver-method-font-get-glyph-contours).
