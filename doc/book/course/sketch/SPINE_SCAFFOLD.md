# The spine is the course scaffold

Updated 3 October 2026. This corrects the course plan; it does not claim the written draft has already been reordered.

The [subject register](SUBJECT_REGISTER.md) now distinguishes first usable introductions, later applications and deeper study. Sine begins as a small periodic-motion operation in Transformation; bounded randomness begins as variation at an address in Array. Their named sequences deepen those uses. Keep the current order for the first trial. The authored register cross-references the existing hard taxonomy, but does not silently replace its older numeric teaching locations.

The detailed [curriculum through Randomness](CURRICULUM_TO_RANDOMNESS.md) now proposes a role for all 87 halls in the first ten sequences. It distinguishes tutorial construction, critical reading and supplied encounters. Keep the sequence order; trial local tutorial-order changes before changing the museum. Its small Platonic generator also brings a first function returning data into Primitives rather than reserving functions for Colour.

The 25 sequence order in the course already matches `commons/maps/curriculum_spine.json`. The drift was inside the chapters. The map list in each sequence is the starting order, and its existing `tutorial.md` is the starting material.

Read `intent.md` to recover what the hall asks; read `final.md` to keep the encounter and voice in view; use `technical.md` and the implementation to check the construction. The course compresses and teaches that work. It does not replace it with a second set of unrelated examples.

## Where a dependency does not fit

- Teach an essential small operation when the encounter first needs it. Distance belongs with Lines, even though a later pickup also uses it.
- Teach the simple ordered list and its traversal in Trace. Supply the XR movement and drawing infrastructure; the recorder’s more advanced policies can be unfolded later.
- Return to that implementation where the learner has its prerequisites. Mark that return in the plan.
- Let some halls consolidate, compare or reflect. A new room does not owe the reader a new syntax feature.
- Create lesson objects in code and keep their references in variables. Examples must not depend on named scene children through `$`, `get_node()` or another path lookup. Day Zero can supply the camera, room and player context.

## Primitives: the route to recover

All twelve map tutorials exist. The current eight-section short-code draft puts the counter too late, teaches a primitive court before edges and faces, joins line and triangle, and leaves the grid mostly outside the chapter. Reuse its working code, but rebuild its sequence from these sources.

| Map, in spine order | What the learner carries forward | Scope and supplied work |
|---|---|---|
| [Point_Zero](../../../../commons/maps/Point_Zero/tutorial.md) — Arrive in a running scene | Create a text display; set it in `_ready`; change a counter in `_process`. Compare once with repeatedly. | The script creates its own Label3D and keeps its reference. Open the prepared context briefly: move the camera to change apparent size; turn down the directional light and compare the floor with unshaded text. Explain the small uses of a variable, new() and add_child(); Point One develops these through a position and a visible marker. |
| [Point_One](../../../../commons/maps/Point_One/tutorial.md) — Give the point a body | Use a variable to name a position and change its value. The position can remain unseen; create a visible marker, then distinguish its mesh from its contact shape. | A position value and a node displaying it are different kinds of thing. Create the teaching meshes in code. Borrow the feeler and light switch. |
| [Point_Coordinates](../../../../commons/maps/Point_Coordinates/tutorial.md) — Carry a position | Name x, y and z; change one component. Compare local and world positions. Keep a second point. | Borrow XR holding or desktop movement. Do not teach controller setup or a distance arrow here. |
| [Point_Lines](../../../../commons/maps/Point_Lines/tutorial.md) — Keep two ends in relation | Connect the two positions. Subtract them and measure the result. Moving an end changes the relation. | Borrow segment orientation/rendering. Introduce distance here, before the later pickup example uses it. |
| [Point_Trace](../../../../commons/maps/Point_Trace/tutorial.md) — Keep where the point has been | Keep sampled positions in an ordered one-dimensional list. Append a position, inspect the count and one entry, then visit the list with a for loop to show what was kept. | Teach the small list and its traversal here. Borrow XR movement and the segment renderer. Leave the installed recorder’s movement gate, duplicate suppression, memory cap and transfer machinery for later steps. Position order alone does not record elapsed time. |
| [Point_Line_Grid](../../../../commons/maps/Point_Line_Grid/tutorial.md) — Give a position an address | Snap a position to a chosen spacing. Compare its coordinates with a discrete grid address. | Reuse the stored positions and the for loop to compare chosen and snapped positions. Introduce a spatial address without implying that a list of Vector3 values is a three-dimensional array. Full nested grid generation can wait for Array. |
| [Point_Triangle_Context](../../../../commons/maps/Point_Triangle_Context/tutorial.md) — Close three edges, then fill | Reuse three points and segments. A closed outline and a filled face are different constructions. | Reuse the positions and ordered-list vocabulary. Borrow mesh submission to Godot while teaching corners, edges and a face. Buffers, normals and general connectivity need not arrive at once. |
| [Primitives_Polythedra](../../../../commons/maps/Primitives_Polythedra/tutorial.md) — Enclose a region | Add a fourth triangular face. Compare an open corner, a visible enclosure and physical contact. | Reuse points and faces. Collision remains a separate construction; no new physics system is required. |
| [Point_Animatedcube](../../../../commons/maps/Point_Animatedcube/tutorial.md) — Follow a corner through the cube | Inspect which edges and faces share a corner. Distinguish editing that corner from transforming the whole body. | Reuse the list and loop from Trace to inspect corners and their connections. Borrow the connectivity editor; defer a general mesh-editing system. |
| [Primitives_Ignorance](../../../../commons/maps/Primitives_Ignorance/tutorial.md) — Inspect a generated primitive | Use symmetry to generate the octahedron's positions; give the operation a name and a radius, returning a list. Then return to SphereMesh, change its parameters and inspect finite resolution. | Supply the face connections and renderer initially. Generating positions does not itself generate topology. Move one vertex to test what the symmetry rule leaves out. The first sphere was a working instance; this return examines what its convenient name concealed. |
| [Primitives_Portals](../../../../commons/maps/Primitives_Portals/tutorial.md) — Approach a limit | Compare increasingly fine approximations. More segments and mathematical exactness are different claims. | Reuse the loop where it makes the repeated construction clear. Borrow or defer the trigonometry and full perimeter calculation; distinguish geometric approximation from numerical precision. |
| [Primitives_Melencolia](../../../../commons/maps/Primitives_Melencolia/tutorial.md) — Compose with what you know | Arrange known forms; compare the construction with what the tableau asks of geometry. | A synthesis can deepen judgement without introducing another language feature. Preserve its historical and critical register. |

## Two tracks, one encounter

tutorial.md teaches how to construct, change and inspect the encounter. final.md follows its critical, poetic and associative questions. They share artifacts and accurate claims, but need not carry the same explanations, pace or code. Adding a programming concept to a tutorial does not require adding it to final.md.

Mark three different teaching states: **encountered** (the learner meets it), **supplied** (its role and use are named, its implementation borrowed), and **taught** (the learner can construct or change it with explained code). Add a specific **return** where supplied work will be opened later. A declared interface permits a useful beginning inside a world whose construction is already complex.

Point gives the variable something to hold. Trace gives the list something to remember and the loop something to revisit. An ordered list can contain three-dimensional positions: its single index and each position’s three coordinates describe different structures.

Godot calls `_process` repeatedly through time. A `for` loop traverses the currently stored values during one execution. Teach those as two different forms of repetition. First make a short, finite record the learner can inspect; then revisit the policies of sampling, capacity and deletion. The museum’s recorder is not identical to this reduced teaching example.

Array and Tiling remain necessary returns. Their new work is generation by counted and nested indices, spatial organisation, palette lookup, editing a shared source and propagation through copies. Do not move the first list back there simply because those sequence names suggest it.

## Use the notes precisely

The research notes offer productive questions rather than ready technical claims. Keep a mathematical point separate from its visible marker; a segment separate from a sampled trace; and sample order separate from timestamps. A triangle needs three non-collinear positions, not trigonometry. Finite curve approximation and the numerical representation of pi are different limits. Treat “nature has a code” as a proposition to investigate, and a fixed seven-item mental capacity as an oversimplification rather than a design threshold. Verify recording cadence from the actual recorder, not the headset refresh rate alone.

## Next writing step

Point Zero's current pilot distinguishes ready once from process repeatedly, creates its own display and separates the engine clock from the node's count. The prepared room supplies only viewing context. Review this one lesson before revising Point One around the absent, visible and solid point. Coordinates receives the component-by-component explanation afterward.

Keep the current `functional/ch01.md` as a working draft until these replacements are checked one lesson at a time. Do not silently renumber its prerequisite declarations without revising the corresponding examples.

## Source coverage for the whole course

This is a file-existence and order check, not an editorial review of every tutorial. The full path index is stored under each chapter’s `source_scaffold` in `sketch.json`. Missing tutorials are explicit gaps, not permission to infer a lesson from a map name.

| Chapter | Sequence | Maps | tutorial.md present | Missing |
|---|---|---:|---:|---|
| 1 | primitives | 12 | 12 | — |
| 2 | transformation | 7 | 7 | — |
| 3 | array_tutorial | 5 | 4 | Array |
| 4 | color | 8 | 8 | — |
| 5 | tiling | 8 | 5 | Ribbon_Patterns_01, Ribbon_Patterns_02, Ribbon_Patterns_03 |
| 6 | change | 2 | 2 | — |
| 7 | forces | 13 | 13 | — |
| 8 | formfinding | 6 | 6 | — |
| 9 | wavefunctions | 12 | 12 | — |
| 10 | randomness | 14 | 14 | — |
| 11 | noise | 9 | 9 | — |
| 12 | shaders | 6 | 2 | Shader_01_Shaping, Shader_11_QueerRubber, Shader_09_FBM, Shader_10_ReactionDiffusion |
| 13 | cellularautomata | 8 | 8 | — |
| 14 | fractals | 7 | 7 | — |
| 15 | lsystems | 8 | 7 | LSystems_Shape_Grammars |
| 16 | proceduralgeneration | 7 | 7 | — |
| 17 | softbodies | 9 | 9 | — |
| 18 | isosurfaces | 13 | 12 | ISO_RhizomeBody |
| 19 | boolean_surfaces | 3 | 3 | — |
| 20 | swarmintelligence | 7 | 7 | — |
| 21 | machinelearning | 8 | 8 | — |
| 22 | graphtheory | 8 | 8 | — |
| 23 | foundationscrisis | 8 | 8 | — |
| 24 | qfeplaboratory | 8 | 8 | — |
| 25 | postfoundationscrisis | 8 | 8 | — |
