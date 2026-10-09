# Point_Triangle_Context — implementation reference

This reference follows the two primary artifacts in [final.md](final.md). The broader studies remain in [detours.md](detours.md); the preceding technical chapter is preserved in the [source archive](../../../doc/space/point-triangle-focus-2026-09-16/previous/technical.md).

## Puzzle: completion and visibility

Source: [triangle_line_puzzle.gd](../../primitives/line/puzzles/triangle_line_puzzle.gd), its [scene](../../primitives/line/puzzles/triangle_line_puzzle.tscn), and [triangle_experiment_panel.gd](../../ui/triangle_experiment_panel.gd).

The placed token is `triangle_line_puzzle:180:1.5#discovery:1`. The base puzzle fits line endpoints to a three-edge target with connectivity and closed-loop constraints. Completion locks the puzzle. These manipulable edges should not be described as a physical mechanism that preserves three rod lengths while resisting the hand.

Discovery mode installs a small instrument. It reports fitted edges, boundary state and fill visibility. `toggle_discovery_face()` returns without creating a face unless `is_completed` is true. After completion it creates an `ImmediateMesh` from the three local `target_positions`, or toggles the existing mesh's visibility. Reset removes that mesh, but the chapter does not promise a visitor reset button.

The fill material is translucent, unshaded and double-sided. The generated face has no collision shape. Mesh visibility, puzzle completion and physical support are separate properties. A visible patch is not thereby a floor.

Three distinct, non-collinear points determine a plane; collinearity gives zero area. A useful geometric calculation is:

```gdscript
var cross := (b - a).cross(c - a)
var area := 0.5 * cross.length()
```

This is explanatory geometry, not an installed area display. Do not normalize a zero cross product and call it a defined surface orientation.

Godot uses clockwise winding to identify triangle front faces. Vertex normals participate in shading; changing a normal is not the same as reversing the submitted vertex order. Materials can disable culling, as here. The old tutorial's geometric `faces_you` example is not a test of Godot's front-face convention. [Godot SurfaceTool documentation](https://docs.godotengine.org/en/stable/classes/class_surfacetool.html).

## Drawing: when a point is accepted

Source: [draw_triangle_faces.gd](../../primitives/point/draw_triangle_faces.gd) and its [scene](../../primitives/point/draw_triangle_faces.tscn). The placement enables `#discovery:1` and sits on a plinth; it retains its existing rotation and offset.

`_process(delta)` returns before sampling when `_is_grabbed` is false. While held, it rounds the drawing sphere's world position, identifies a nearby stored point, and advances the placement timer. At the defaults, a held sample needs one elapsed second and at least 0.15 metres from the previous path point. An empty path accepts its first point without that travel requirement. Acceptance resets the timer; waiting at the same last corner does not add repeated points.

The world-grid pitch is 0.1 metres. `_find_nearby_point()` reuses the first stored point within the 0.15-metre radius; it is not a nearest-neighbour minimization. In a crowded drawing that distinction can matter. The comparison uses well-separated corners.

`_on_grab_point_dropped()` can place the released position even before the next timed sample. It then ends held sampling and clears the active preview. Releasing at the closing corner avoids introducing an unintended next corner. There is no claim of a perfect hand trajectory or a configurable sampling control on this panel.

Point handles, boundary lines and completed meshes use world positions with top-level transforms, avoiding a second application of the artifact's rotation and translation. Releasing an edited corner snaps it, updates `placed_points`, and rebuilds boundaries and completed faces. The filled mesh does not continuously follow a held corner; its edit is committed on release.

## Closing a path and keeping earlier work

`current_path` is an ordered list of indices into `placed_points`. Returning to a previously visited index can close the cycle from that earlier occurrence. The duplicate closing index is removed before triangulation, and a cycle needs at least three entries. The chapter's simple loops return to DRAW START, avoiding ambiguous partial cycles. DRAW START marks the first corner of an unfinished outline; START marks the fan anchor of the last completed loop.

`begin_new_outline()` clears the active path and starts a new drawing gesture while preserving stored points and completed meshes. The physical NEW OUTLINE button calls it. Release, press, then pick up again is the taught sequence. It neither erases earlier practice nor deletes a malformed fill.

`shift_start()` operates on `completed_triangles[-1]`, cyclically moving its first stored corner index to the end. `_rebuild_triangle()` replaces the mesh resource on that loop's existing mesh node, and `_rebuild_lines()` retains the same boundary edges. Stored positions, other completed loops, material and fill visibility stay unchanged. The panel identifies the selected loop and its START corner; `get_experiment_state()` supplies that selection and the control's readiness.

`_shift_start_block_reason()` permits the action only when a completed loop exists, the pen and all editable corners are released, and there is no unfinished outline. The single continuation anchor retained after closure is allowed; a newly drawn first corner is an unfinished outline. The panel reports the blocking reason. NEW OUTLINE clears an unfinished path without removing the last completed loop, so it can make that loop available again once the pen is released.

The panel counts `completed_triangles` entries as filled loops and sums `points.size() - 2` as logical triangles. A practice triangle followed by one six-corner L gives two loops and five triangles; SHIFT START leaves those totals unchanged. Manually retracing a second L gives three loops and nine triangles, provided no extra loops were created. Visibility toggling does not change these totals.

## What the fan submits

`_create_triangles_from_path()` uses the first loop point with every successive pair. For six corners it creates four logical triangles. It submits both vertex orders for each triangle and also disables culling in the material. Thus the display's logical count is not a count of every submitted triangle copy or GPU vertex. The current implementation contains redundant double-sided rendering; simplifying it would be a separate runtime change with visual checks.

The algorithm does not validate planar simple polygons, detect self-intersections, or test fan diagonals against an interior. Convex planar polygons work; suitable concave ones can work from particular starting vertices. Arbitrary nonplanar loops do not specify a unique planar interior to triangulate.

The [supplied-input fan probe](../../../tools/probes/museum_triangle_fan.gd) runs the actual drawing scene and its pointer-button callback. It reuses six coplanar world points for the L described in the book. Both starts have boundary area 0.8 square metres. Starting at A produces four triangles with summed area approximately 0.8; starting at B produces four with summed area approximately 1.44, two of whose centroids lie in the excluded notch. The latter sum includes overlaps; it is not the union area of the rendered patch. Counting alone does not establish coverage correctness.

On the manual route, the two L fills coexist. Inspect the first before creating the second; after adding the second, look for new coverage in the notch. NEW OUTLINE preserves the first fill, so this is not a side-by-side display of independently movable polygons. SHIFT START instead replaces the selected loop's fill: one L retains four triangles while its start advances from A to B. Six shifts return its order and emitted fan to A.

## A connected surface is not yet an enclosed volume

The optional `quad` splits four source positions along one chosen diagonal. Moving a corner can put its two triangles in different planes. The `folded_strip` shares source positions across twenty-four triangles and, in this placement, runs its hinge study. Its programmed rotations preserve edge lengths; manual vertex edits can change them. Neither example makes the editable face into a fixed-length rod mechanism.

Three triangular faces meeting at one vertex form a corner with an open boundary. Four correctly connected triangular faces can enclose a tetrahedron. The next hall investigates these constructions; the earlier assertion that a trihedron is already a minimal closed surface was incorrect.

## Verification and practical limits

The 16 September run of [probe_triangle_primary.gd](../../testing/probe_triangle_primary.gd) passed 23 checks against actual endpoint and pointer events, transformed scenes, supplied held motion, corner-release updates and the panel. The fan probe passed the manual two-start comparison. Their compact results are retained with the [dated work record](../../../doc/space/point-triangle-focus-2026-09-16/README.md).

The 19 September [museum test report](../../../ada_run/test-results/museum/20260919T114824Z-3f7651db/report.md) passes all 123 Godot checks and nine authored checks. Its Triangle case uses [triangle_shift_check.gd](../../../tests/museum/triangle_shift_check.gd) and passes 60 Godot checks plus two authored checks. It exercises the production scene with supplied hand positions and actual pickup, release and pointer callbacks: unchanged points and edges, in-place replacement and counts, A/B overspill, return to A, readiness guards, corner edits, manual retracing and other loop lengths.

The [isolated-scene capture record](../../../doc/book/iterations/2026-09-19-triangle-shift-start/triangle-shift-observation.json) and plan views from [A](../../../doc/book/iterations/2026-09-19-triangle-shift-start/triangle-start-a-plan.png) and [B](../../../doc/book/iterations/2026-09-19-triangle-shift-start/triangle-start-b-plan.png) show the production drawing scene and discovery panel with supplied positions. They do not test the authored museum placement or a headset.

These checks verify specific engine behavior. They do not verify reach in a headset, hand-drawn coplanarity, comfort, learning or the room's secondary interactions. Engine notices are retained in the test report. The first-vertex fan algorithm remains the same; SHIFT START adds a runtime control for changing its input order.
