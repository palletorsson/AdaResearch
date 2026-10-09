You can recognise a cube and change one until it stops being a cube. What happens when the familiar name is “sphere”? How much must the machine build before you are willing to call something round?

<!-- @sphere_low -->

Find the coarsest pair. Walk around one before counting anything. Where does its silhouette most strongly interrupt the word sphere?

Its neighbour has the same vertex positions and triangle connections. One wears an edge overlay; the other has plain shading. Compare the outline against the room beyond them, then compare their interiors. Which differences belong to the mesh, and which to the way we have made it visible?

The low sphere starts with one ring and ten radial segments. It spends detail differently around the axis and along it. A low count is already a distribution, not just a shortage.

<!-- @sphere_mid -->

Move to the middle pair. Choose a ridge you could follow on the coarse example and try to find its counterpart here. Then step back. At what distance does your inspection become a recognition again?

This pair uses seven rings and seven radial segments. Its marked and unmarked members share the same geometry and base material; only the added edge lines differ. Changing the way a surface is read need not change the surface's triangle list.

<!-- @sphere_high -->

Compare the higher-resolution pair from the same distance, then approach it. Look along the silhouette instead of only at the lit centre. More edges need not make more distinctions available from every viewpoint. Check where you can still find a difference.

These meshes use sixteen rings and sixteen radial segments. The three resolutions are not successive doublings of one number. Rings and radial segments divide different directions of the surface.

A mathematical sphere consists of points at a fixed distance from a centre. These mesh boundaries approximate that surface with finite geometry. Interpolated shading can soften the appearance of facets without changing the outline made by their vertices.

The familiar name works well enough to let us proceed. Then a closer view gives us another question. Neither the quick recognition nor the closer inspection needs to be the final account.

<!-- @sphere -->

Compare the ordinary sphere with the three explicit examples. Does a familiar name make you stop inspecting sooner? What would you ask before using it for a close view, a silhouette, or a collision surface?

<!-- @ -->

## Read the invoice

<!-- @budget_of_smoothness -->

At the counter, four numbered spheres turn at the same rate. Leave the counts hidden. Choose one for a distant background object, then move closer and choose one for a visitor to inspect beside their face. You are proposing those uses; the counter's spheres stay on their stands.

Press **SHOW / HIDE COUNTS** after choosing. The tags now reveal the settings and two numbers for each mesh:

| Sphere | Radial segments / rings | Mesh triangles | With area |
|---|---:|---:|---:|
| 1 | 4 / 2 | 24 | 16 |
| 2 | 8 / 4 | 80 | 64 |
| 3 | 16 / 8 | 288 | 256 |
| 4 | 64 / 32 | 4,224 | 4,096 |

Why two counts for one surface? Before reading on, press **SHOW / HIDE EDGES** and follow the lines toward a pole.

The generator brings a row of positions together at each pole. Some triangle entries collapse there instead of covering a patch of surface. They remain in the mesh's index list. The larger number counts every triple in that list:

```gdscript
var arrays = mesh.surface_get_arrays(0)
var triangle_entries = arrays[Mesh.ARRAY_INDEX].size() / 3
```

The smaller number counts triangles with measurable area. The difference is not another ring you can walk around and find. A list can contain a triangle which gives the eye almost nothing to see.

The counter used to calculate the smaller number from the settings. Reading the generated mesh let us discover the second account. Even an instrument teaching us to inspect assumptions had one of its own.

Hide the counts and leave the edges visible, or do the reverse. These controls change what is shown, without rebuilding the sphere surfaces. The overlay itself uses additional geometry; its lines are excluded from the sphere's invoice.

The settings increase together, so the triangle count grows faster than the radial count alone. This is a geometry count, not a measurement of frame time. Materials, shadows, screen coverage and the rest of the running room still matter. The most expensive sphere on the counter is not automatically the most useful one, and the least expensive is not automatically the most interesting.

Return to the choice you made before seeing the numbers. What did the count change? What did your distance change? What feature would you keep even if someone offered to smooth it away?

Resolution is part of the form you receive. A coarse sphere mesh is not, in general, a prism. A prism has two matching polygonal ends joined by side faces; the sphere's rings and poles construct a different boundary. Knowing both shapes lets you ask what the approximation actually made instead of forcing it into the nearest familiar name.

<!-- @ -->

## Further comparisons: the ideal set

Choose a tetrahedron and a cube from the held solids. Turn each until you have inspected more than one face and corner. What kind of sameness repeats within each object? Then compare with another member of the family.

The five convex regular polyhedra have congruent regular polygonal faces and the same arrangement at every vertex. They do not look identical from every possible viewpoint. Their regularity is a specified symmetry of the object, not a promise that the eye sees the same picture everywhere.

Why only five in this family? Regular face angles must fit around a convex vertex with a positive angular defect. Triangles permit three, four or five faces there; squares permit three; pentagons permit three. Six equilateral triangles or four squares already fill a flat turn. Those constraints lead to the tetrahedron, octahedron, icosahedron, cube and dodecahedron.

The list is finite because the question is restrictive. It does not list every useful solid, every beautiful object, or every possible way of making a world.

Count six vertices, twelve edges and eight faces. Compare those numbers with the cube's eight, twelve and six. Vertices and faces exchange roles in their dual relationship. A different way of organising the same comparison reveals a relation the individual names conceal.

Look at what cutting the tetrahedron's corners adds. New faces appear where vertices used to be. A construction can leave the five-member regular family while remaining precise and usable. Exclusion from a catalogue is not exclusion from geometry.

<!-- @ -->

## The one that refuses a half-turn

Watch the five-sided capsule turn. Choose a visible ridge and predict what will face you after half a turn. Check that prediction against the object as it rotates.

With five radial segments, a half-turn around its long axis does not map the cross-section onto itself. An even-sided regular cross-section has a different answer. This is a specific symmetry question, not a claim that the object has become unequal to itself or impossible to know.

The interesting form is already in the standard kit, under the plain name “capsule”. You can value its facets rather than treat them only as a failure to be smooth.

Compare the star's five-point pattern under the same imagined half-turn. A familiar outline can answer one symmetry test and fail another. Name the transformation before saying an object is symmetrical.

Look for a feature on the irregular rock that you would lose by replacing it with a regular solid. Choose a use for that feature: recognition, shelter, a grip, a distinctive silhouette. What resists your first abstraction may be exactly what another task needs to keep.

The right triangle offers an invariant to compare: move or turn a rigid right triangle and the right angle remains. An invariant says which changes you are considering and which relation survives them. It is not a ranking of the objects that possess it.

The cones mark a place that invites you to look for something absent. A marker can preserve an expectation even when the thing it names is no longer there. Read the marking, then check the place.

<!-- @ -->

Now choose a geometry budget as a design proposal. Spend it on the distinctions you want a visitor to encounter. You might keep a deliberately faceted silhouette and use the saved detail elsewhere, or spend more where a hand will inspect an edge. Explain whose viewpoint and purpose made your choice reasonable.

A model keeps by omitting, and the omitted does not vanish. It can become the next question.

The next room takes a finite sequence of round-looking objects and asks what “closer” means when every example still has a count.
