# Polyhedra: solid simplex corners

23 September 2026. The author's request was to cut across the room corners with tetrahedra, fitting and filling the volume back to the cube's walls.

Nine right tetrahedra now form slanted, triangular corner faces in Primitives_Polythedra. Five main-room corners reach 1.5 m along each adjoining wall; the side-room pieces reach 1.1 m, except the one beside a doorway (0.9 m). Every apex meets the museum wall height, currently 4.5 m. These are corner-fitting simplices, not regular tetrahedra. Three faces meet the two walls and the floor; the fourth faces the visitor.

The mesh is closed and the four vertices also define its convex collision solid. Navigation excludes the occupied corner cells. Automatic trim and service props avoid the fills; the fire-hose cabinet that intersected the entry corner no longer hangs there. Actual authored artifact tokens, floor grids, settings, roles and final.md remain unchanged.

The map owns the placement in map_info.museum.simplex_corners. The museum rereads it on hall construction; plan derivation carries the same list. Other maps have no declaration and retain their current architecture. A declaration crossing a doorway or missing a backing wall is rejected rather than creating a floating piece.

## Verification

- 37 geometry/collision/navigation assertions pass.
- Three selected CharacterBody walking segments pass: entrance, main exit and side-room clearance.
- Actual inside Godot images inspected; nine pieces built; process exit 0; no GDScript errors in the final run.
- Source comparison confirms all existing layers, artifacts and non-museum map settings preserved. Plan derivation retains all nine declarations.
- Engine still reports an unrelated unresolved UID, viewport-texture errors and legacy material warnings. This probe pauses museum input/catch logic; it is not a headset or learner test.

No live museum session was restarted and no live bake or visitor save was replaced. Reopen/rebuild the museum hall to load the new source. The frozen full-book packet and parked Collective Knowledge work are untouched.

Run the focused inspection again with `python doc/book/iterations/2026-09-23-polyhedra-corners/check_hall.py`.

## Author follow-up: pink and the book

All nine fills now have their own matte pink material (`#ee5599`); the shared museum wall material and geometry remain unchanged. The chapter adds “A corner makes room” after the tetrahedron/collision encounter and before the prism. It follows the visible pink face to its four points, connects point → segment → triangle → tetrahedron, distinguishes the fitted right tetrahedron from the regular specimen, and asks what fitting one body changes for another. The existing chapter is preserved verbatim around the insertion. The technical companion records the exact construction. The core encounter's text/map hashes are refreshed.

The original white-corner images and manuscript are preserved under `white-*` and `before-pink/`; the page's current captures show pink. Exact follow-up diffs use the `pink-` prefix.
