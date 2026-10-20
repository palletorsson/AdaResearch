# Polyhedra: a solid becomes a building piece

Scope: first gradual construction pass in Primitives. The current Polyhedra floor is 06. No tutorial.md or final.md text was rewritten.

## Encounter card

Bring: points, lines, triangular faces. Act: align the pink corner and release. Result: a closed, striped, grabbable solid. Return: the tetrahedron, pyramid and wedge become full-size blockers. Turn to the sloped face: the same wp supports ascent to structure 2, one metre above the slab. Carry: reusable collider-backed pieces and a static walking assembly. Transformation later adds behaviour to this vocabulary.

## Changed

- AlignTetrahedron / AlignWedge: visible fixed vertices and edges, upright target ring, live release cue, accurate counts and completion text. Completed bodies keep pickup and gravity and receive diagonal stripes.
- New striped tetrahedron and square-based pyramid blockers. The tetrahedron reuses the alignment geometry at 1.8 scale. The pyramid has five vertices and five polygonal faces.
- New striped wedge blocker: the original `walkableprism.tscn` mesh and collider, adapted to floor-centred placement. One metre wide, one metre high, two-metre run. The handheld alignment wedge has the same proportions at 55 percent size.
- The obstruction area's old five-prism bank is replaced by the three distinct striped blockers, independently editable as parts.
- The old 0.9 m support assembly becomes a 4 x 4 m deck at +1 m, joined by nine original wp units across three approaches. The column and mouse model remain on its top.
- Six existing props/artifacts in the west wing were repositioned to clear the approaches and retain the rock work area. Their IDs remain. Other floor records are unchanged; before-rooms.json preserves the previous layout.
- Editor palette: Building solids contains tetrahedron, pyramid, wp and a one-metre platform block. The stripes use real mesh vertex colours so Godot and the exported GLB show the same pattern.
- Capacity graph records the static construction as built. The moving Transformation bay remains proposed. A paintable grid layer is still a later step.

## Evidence

`tools/test_polyhedra_building.py --capture` runs the real sources in the isolated Godot test project. The native probe exercises wrong-release rejection, alignment, XR grip, completion, retained physical solids, collision and stripes, every ramp profile and join, desktop/XR traversal and editor part isolation. Synthetic XR is not a physical-headset test.

152 desktop/synthetic XR checks and four screenshot checks passed. Shared editor schema/resource validation passed with no additional spatial warnings compared with the saved baseline. Existing whole-tower placement warnings remain in layout-checks.json. Graph checks passed.

The current full-scene screenshots are in this folder. The editor is `/lab-editor?mode=void&floor=6`. Test play starts from the normal Void game; an already-running game must reload the floor/project to use changed scripts.
