# Primitives, refined — the June canon was already good; the engine rungs were missing

> Third run of the COLOR_TAXONOMY recipe (2026-08-27). Cheat-code: **a thing must have a
> surface to be** — `MeshInstance3D` + the primitive meshes.

Unlike color (map-blurbs) and graphtheory (algorithm soup), primitives' June canon was
CONFIG-authored and nearly in existence order already: Point → Line → Triangle → Plane →
the solids, with truths worth keeping ("a point is a decision: here, not there — but
only inside a system"). So this pass REFINED instead of replacing: four engine rungs
inserted, six heroes built, everything else untouched. Live at
**localhost:3003/primitives-concepts** — 266 tiles, 25 sections.

## The four inserted rungs

| rung | engine cheat-code | why it was missing |
|---|---|---|
| **The normal** (after Plane) | `cull_mode = CULL_BACK` is the default | a surface has a FRONT; the back of a one-sided face is not dark but UNRENDERED |
| **The seven words** (before Cube) | `PrimitiveMesh`'s complete vocabulary | Plane, Box, Sphere, Cylinder, Capsule, Prism, Torus — everything here is sentences made of these |
| **The budget of smoothness** (after Prism) | `radial_segments`, `rings` | a sphere is a polyhedron in a trench coat; smoothness is a purchase |
| **Everything is triangles** (the confession, closing) | `surface_get_arrays()` | under every solid, triangles all the way down |

## The six heroes (probe 0 broken, captured, registered in primitives.json 259→265)

1. **the_invisible_point** *(Point)* — a vitrine exhibiting NOTHING: brass arrows and
   crossing lasers mark a `Vector3` the engine cannot draw; the stand-in sphere blinks
   out on a seeded cycle and the readout testifies: *the address remains*.
2. **first_shadow** *(Triangle)* — three vertices by `SurfaceTool`, the smallest surface
   the engine accepts, casting the room's first real shadow beside a line that casts none.
3. **seven_words_choir** *(The seven words)* — the whole vocabulary on choir risers,
   breathing in turn, name plates at their feet.
4. **backface_curtain** *(The normal)* — a theatre curtain sumptuous from the front and
   absent from behind: hand-built one-sided pleats, honest `cull_back`, floor arrows
   inviting the walk that proves it.
5. **budget_of_smoothness** *(The budget)* — the same sphere at segments 4/8/16/64 with
   triangle invoices under each; the last two look alike, their bills do not.
6. **wireframe_confession** *(Everything is triangles)* — a torus beside its own arrays
   undressed: every edge extracted at runtime from `surface_get_arrays()` and lit. The
   loop closes: rung 1's point had no body, and every body since was points, wired.

One scorer fix on the way: the vitrine's brass arrows out-voted its point ("Arrow /
vector" claimed it); `invisible_point` added to Point's primary keywords — fixed at the
source, per the judgment-stays-at-source rule. `coordinate_readout` is the sequence's
one remaining unphotographed body.
