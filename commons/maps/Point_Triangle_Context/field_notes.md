# Point_Triangle_Context — field notes

> Field notes hold what the wall text cannot carry: the ruling and why, the
> exactness decisions, what was rejected, the neighbours in the literature, and
> what the next writer needs. `final.md` is for the visitor. This is for us.

## The ruling (Palle, 2026-09-02)

The triage found three arguments competing: closure (inherited from the
dissolved `Point_Triangle`, whose directory still exists and whose name the
sequence's `content` list still carries), rigidity (the blurb: "no deformation
without rupture"), and context (the tutorial: "place a triangle among other
shapes"). Ruled: **everything is built by triangles.** Rigidity is *why* the
triangle is the unit, not the argument. The angle stays a hint. Wavefunctions
names sine and triangulation; this room only lets you feel that a length and an
angle are one fact seen from two sides.

## Exactness decisions in the text

- **Rigidity is not resistance.** `interactivetriangle` lets you drag a vertex
  freely. So the room says it exactly: you cannot change the shape without
  changing a length, because there is no other handle. Three lengths, one
  shape, plus its mirror. `third_vertex` does it with Pythagoras twice and
  nothing else, so no trigonometry enters the room.
- **Flat by necessity.** Three points always share a plane; the fourth may not.
  That is the mechanical reason the renderer uses triangles, and it is why a
  quad is always two faces with a seam. Every wall in the museum is two
  triangles. Say that; it is literally true of the engine.
- **Sidedness is a renderer fact.** `parasol_triangle` sets
  `cull_mode = CULL_DISABLED` to show both faces. By default the engine draws
  the front only, decided by winding order. The text uses that rather than a
  metaphor of orientation.
- **The closure artifacts get one beat.** `triangle_line_puzzle` is the door in,
  the previous chapter's last sentence (two points have a distance, a third
  decides whether to close). The catalysts are not stations and are untagged.
- **Two claims tightened after reading the code:** the panel reports its area
  *when you let go*, not live; `draw_triangle_faces` fills the loop when the
  line *returns to its first point*, not on release.

## The tutorial was rewritten

Its nine blocks were convex hulls and AABB overlap, code that never touched a
triangle's constraint. Now seven functions carry the argument
(`triangle_normal`, `triangle_area`, `fan_triangulate`, `third_vertex`,
`quad_from_rods`, `is_planar`, `faces_you`) and every one is proven by
`commons/testing/probe_triangle_tutorial.gd` against a known answer: the 3-4-5
lands at (0, 4); the mirror keeps its lengths; four rods lean with all sides
kept; a lifted fourth point fails planarity; swapping two corners flips the
face; a 5-point loop fans into 3. A tutorial that can fail a probe is the
standard now.

## Neighbours

Jacob Gaboury, *Image Objects* (2021): a history of computer graphics that
treats the mesh as an ontological choice. It is the closest thing in print to
this room's argument. Read it before revising, so the room is in conversation
with it rather than beside it.

## Open

- The old `commons/maps/Point_Triangle/` directory and the `content` reference
  in `sequences/primitives.json` are leftovers of the dissolution. Remove when
  convenient; nothing reads them for this room.
- `interactivetriangle`'s area is reported as a status string on drop. Whether
  that reaches a visible label in the hall was not verified.
