# Primitives_Polythedra — enclosure and passage

Follow-up: [the review-containment pass](review-containment/README.md) shortens the main walk and adds three footnotes. The counts and evidence below describe the preceding version; that later pass preserves the map, roles and runtime sources.

16 September 2026. Palle agreed to continue after Triangle with a focused route: an open corner, an enclosed region, and forms supporting or interrupting a body's movement. The existing room already supplies these comparisons. This revision changes the writing and teaching order; all 34 interactable placements, all four utility wedges, every floor cell and all runtime sources remain unchanged.

## The first passage

The [book chapter](../../../commons/maps/Primitives_Polythedra/final.md) moves through five primary artifact types in order: `grab_trihedron`, `grab_tetrahedron`, `prism_block`, `concrete_barrier`, `street_sign`. Repeated instances supply comparisons: three prism grains, twelve barrier sections and five signs. These are 22 primary placements, not five individual objects.

The chapter is 1,082 whitespace-delimited words, down from 1,642. The open corner and closed tetrahedron establish enclosure. The prism's existing solid, quartered and shell configurations then expose a retained collision surface beneath different visible constructions. The utility wedges and barrier make the relation bodily; STOP and the arrows distinguish instruction from collision. A proposal to move a fixture is explicitly a proposal, not a promised control.

The collision note uses official Godot 4.6 documentation for [ConvexPolygonShape3D](https://docs.godotengine.org/en/4.6/classes/class_convexpolygonshape3d.html) and [ConcavePolygonShape3D](https://docs.godotengine.org/en/4.6/classes/class_concavepolygonshape3d.html), read during this pass. The prism has a retained triangle-based static collision surface, while the trihedron uses a convex hull. The book does not claim that an unconstrained tracked hand must stop at either.

## Keep the other questions available

`pyramid_edit`, `cube_scene`, `diamonds`, `rock_spawner` and `rock_scanner` move from primary to secondary without moving on the floor. Their return visits are written in [tutorial.md](../../../commons/maps/Primitives_Polythedra/tutorial.md), reachable from the live book through its tutorial section. The remaining catalyst and path-game nodes and gallery request retain their place. The ten secondary placements and two decorative cones remain accounted for.

[technical.md](../../../commons/maps/Primitives_Polythedra/technical.md) keeps regular-solid counts, Euler characteristic, angular defect and volume as distinct calculations. The earlier tutorial's claim that angular defect is where a solid keeps its volume is corrected. General folded embeddings need more care than equating zero angle defect with coplanarity. The regular tetrahedron is also distinguished from the general tetrahedral family.

The scanner's own ready/process path creates and moves a cyan plane and its thin collider; it does not call the separate cross-section display functions. Its unused display routine is approximate. Return-visit prose now says what is active and records a future controlled section experiment. No scanner implementation was changed or claimed repaired.

The old inventory and summary described a 7×9 layout and an absent tetrahedron puzzle. The new inventory records the actual 13×28 map and all placements. The critical text and eye-shot are untouched. Historical walked and field-note bodies remain intact beneath a current-status notice. Fourteen pre-edit files are archived byte for byte under `previous/`, identified in [before-sha256.json](before-sha256.json).

## Agreement and evidence

Only this room's roles, groups and order change in `artifact_roles.json`; all user notes, saved canvas positions and other rooms remain unchanged. The shared spine artifact manifest receives a scoped refresh of its existing fifteen room entries using the current producer's ordering function. Its first-occurrence membership and every other room's entries remain unchanged; aggregate role/order counts are recalculated. This is not a whole-spine rebuild.

[validation.json](validation.json) records sixteen passing editorial/data checks: archives, preserved map and documents, current book text, primary card order, inventory, return visits, manifest agreement and 31 local document links. [render-validation.json](render-validation.json) records six passing checks using the encyclopedia's installed Markdown renderer, including the footnote, backlink and tutorial link.

The existing [component probe](../../../commons/testing/probe_polyhedra_flow.gd) passes all 37 checks under Godot 4.6: current-map stamping, configured barriers and signs, an isolated supplied-capsule movement comparison, and the sign's lack of collision. [component-checks.json](component-checks.json) holds its result; [runtime-retry.log](runtime-retry.log) holds the run. The first launch failed while opening its default user log; supplying a workspace log path allowed the successful run. Existing startup UID and certificate-store messages remain in the log and did not prevent completion.

The probe does not validate full-room accessibility, live headset movement or the open-corner collision experiment. [encounter-reference.md](../../../commons/maps/Primitives_Polythedra/encounter-reference.md) records the next walk: plinth reach, the backtrack to the prisms, floor joins, sign legibility and whether a visitor can distinguish the mechanisms without an explanation arriving first. No room-wide completion claim, commit or push is made.

The next hall is Point_Animatedcube, where the closed surface can be followed through its construction.
