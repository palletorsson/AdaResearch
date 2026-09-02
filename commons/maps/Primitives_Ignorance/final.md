The words over Plato's door were *let no one ignorant of geometry enter here*.

<!-- @3t -->

This room puts them halfway down a hall you have already walked into, which is the joke and also the argument. You are not ignorant of geometry any more; you have built it from a point to a solid. What you are about to find out is what the building left out, and that ignorance is not a lack. It is a structure. A model keeps by omitting, and the omitted does not vanish. It stands around in here, on plinths.

<!-- @ -->

## What the menu offers first

<!-- @cube_scene -->

A cube. You know this one to the corner.

<!-- @sphere -->

And a sphere, which you do not, because there is no such thing in here. Look closely: thirty-two segments round, sixteen rings up, and every one of its faces is flat. The machine's sphere is a polyhedron that has agreed to be called round, and the menu has been calling it that since the first room.

<!-- @ -->

## The ideal set

```gdscript
func regular_corner_defect(face_sides: int, faces_at_vertex: int) -> float:
    var interior := 180.0 * (face_sides - 2) / face_sides
    return 360.0 - interior * faces_at_vertex
```

<!-- @platonic_grabbables -->

Five solids, three of each, on one table. They are the ideal because every face is the same, every corner is the same, and every one of them looks the same from anywhere you stand.

Why five? Not because someone chose. Two rooms ago you learned that a corner must be missing something, and that a closed solid has 720 degrees of missing to spend. Ask for regular faces and the same number at every corner, and the arithmetic leaves exactly five ways to do it: three, four or five triangles at a corner, three squares, three pentagons. Six triangles lie flat. Four squares lie flat. Three hexagons lie flat. And 720 divided by what each corner is missing is how many corners the solid has: four, six, twelve, eight, twenty. The ideal set is not a list. It is a remainder.

<!-- @grab_octahedron -->

Six corners, twelve edges, eight faces. Now say the cube's numbers backwards: eight corners, twelve edges, six faces. The octahedron is the cube with its corners and faces exchanged, and the exchange is called duality. Put one inside the other and every corner of one points at a face of the other. Two of the five are one shape read two ways.

<!-- @snap_octahedron_puzzle -->

Join six points and you have made it yourself. What it spawns when it closes is a prism you can walk on, and that is the room's next argument standing up before the room has made it.

<!-- @truncatedtetrahedron -->

Cut the corners off the smallest one. Each corner becomes a triangle, four new faces, and the solid is no longer ideal. It belongs to a bigger family, the Archimedean, indexed by how deep the cut goes. The ideal set is one cut away from a family the menu never mentions.

<!-- @ -->

## Resolution produces form

Walk on, and watch the sphere come apart in halves.

<!-- @sphere_high -->

Thirty-two rings, thirty-two segments. Round, to the eye.

<!-- @sphere_mid -->

Sixteen. You can begin to count the facets.

<!-- @sphere_low -->

Eight. It is not a rougher sphere. It is a different solid, one with eight-fold symmetry and no name in the menu, and the only thing that changed between the three plinths is an integer.

```gdscript
func prism_from_segments(n: int) -> Dictionary:
    # a "round" body drawn with n sides is a prism: n side faces, two n-gon caps
    return {"faces": n + 2, "vertices": 2 * n, "edges": 3 * n}
```

The machine has no circle. Every cylinder, every capsule, every sphere it has ever drawn is a number of segments, and at any finite number a round body is a prism: n side faces and two caps, and vertices minus edges plus faces is two, the way it always is. Lower the number far enough and the sphere is a prism with a name: triangular, square, hexagonal. Resolution is not detail laid on a form. It *is* the form, and the form was decided by whoever typed the integer.

Keep that for the next room, where the number tries to go to infinity and does not arrive.

<!-- @ -->

## The one that refuses

```gdscript
func has_centre_of_symmetry(n: int) -> bool:
    # rotate the regular n-gon by half a turn: does it land on itself?
    for i in n:
        var p := Vector2.RIGHT.rotated(TAU * i / n)
        var back := -p
        var hit := false
        for j in n:
            if back.distance_to(Vector2.RIGHT.rotated(TAU * j / n)) < 0.0001:
                hit = true
        if not hit:
            return false
    return true
```

<!-- @capsule -->

A pill, turning. Five segments round, five rings up, and it is in every engine's menu under the plainest name there is.

Watch it turn and watch what faces you. A vertex, then an edge, then a vertex. With an even number of segments the far side of a body is the near side turned half round, and you could draw the back from the front without walking there. With five you cannot. Turn it half round and it does not land on itself. An edge faces away where a vertex faced you, and the silhouette from behind is not the silhouette from the front. The back of this thing is genuinely unknown from here, which is the name of the room.

The five ideal solids are ideal because they are equal to themselves from everywhere. This one is a body the machine's own limit made unequal to itself, and it ships in the same menu, and nobody thought to call it anything. Hold on to that. The thing that refuses the ideal is not outside the set. It is in the standard kit, under the dullest name in it, and one integer away from the ones that comply.

<!-- @star_primitive -->

The same fact, flat: five points. Turn it half round and it does not land on itself either. Odd is a way of not equalling yourself.

<!-- @ -->

## What resists

<!-- @roughrock -->

A solid whose corners were pushed off their ideal places. It is the remainder made into an object: everything the ideal set left out, standing on a plinth. What resists abstraction is not noise. It is signal.

<!-- @righttriangle -->

And the thing that does not resist, for contrast. Move it anywhere, turn it any way, and the right angle survives, the way it did three rooms ago. An invariant is what a model keeps. This room has been about what it drops.

<!-- @hole_with_cones -->

Three cones around nothing. There was a hole here, in the code, and it is no longer drawn; the cordon stayed. That is the room's emblem, and it is exact: a marker for the thing the model left out, standing where the thing was. Every primitive in this hall is three cones around something.

<!-- @ -->

## What a primitive knows

The tutorial for this room is not about shapes at all. It is about objects that keep their own state and know nothing of the scene, that report some facts and hide others, that can learn and forget. That is what a primitive is in a machine: not the simplest thing but the most *enclosed*, an interface that shows you a sphere and keeps thirty-two integers behind it. Calling something primitive is a move, not a description.

The next room takes the integer this one kept turning down and turns it up instead, toward the circle, and finds out whether it ever gets there.
