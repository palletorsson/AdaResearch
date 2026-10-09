Concept: Three connected edges can close a boundary; rendering a face is another operation. A useful filling method has conditions that the visitor can investigate.

Sequence role: Follows Point_Line_Grid and precedes Primitives_Polythedra. Grid supplies repeatable positions. This hall connects them into boundaries and faces; the next asks how faces enclose volume.

Primary route: triangle_line_puzzle, then draw_triangle_faces. These remain the two hands-on book markers. The same group now includes triangle_construction_plate, a native points/boundary/face illustration whose Godot render also appears in the book. The first separates closure from visible fill. The second lets the visitor construct an outline, inspect a first-vertex triangle fan, and compare two starting corners of the same L-shaped boundary.

Invariant and variation: Keep six coplanar corner positions and the boundary traversal direction fixed; change only where the traversal begins. The intended interior stays the same. The installed fan can overspill it. This varies input order, not the filling algorithm. Choosing another algorithm remains a possible development, not an installed control.

Technical focus: Three non-collinear points and their plane; primitive type; timed, snapped placement; ordered point indices; n-2 logical fan triangles; visibility separate from stored geometry and collision. The readout accumulates all completed loops, including earlier experiments.

Critical opening: A convenient implementation can help us make a surface and fail to respect another intended outline. Learn enough to locate that decision, choose what to preserve, and distinguish repairing the fill from finding another use for its excess. The experiment does not make a concave shape more queer or a convex one less desirable by definition.

Scope: Keep all fourteen existing artifact placements and the text marker, with the reference plate added as a fifteenth artifact. Folding, deformable triangles, quads, measurement, the pink triangle, projection and material remain available through detours.md. Narrowing the first passage does not remove these works.

Evidence and remaining work: The actual-scene primary probe passes 23 checks and the fan comparison reproduces the specified overspill. These supplied-input checks do not establish headset reach, visitor understanding or the ease of drawing the L. No new interaction is installed by this editorial pass. See encounter-reference.md and the dated work record.
