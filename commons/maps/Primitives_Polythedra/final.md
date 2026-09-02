Volume does not begin as a container.

It begins as a corner. Three faces, each of them the unit from the last room, tilted off the plane until they meet at a single point, and for the first time in this chapter the faces have a side that is *in*. Nothing is enclosed. You could put your hand through it from three directions. But there is an inside now, and there was not before.

<!-- @grab_trihedron -->

Pick it up. Three triangles, one shared vertex, and a base to stand on.

The last room said a triangle cannot lie: flat by necessity, one shape for its lengths, one front. Here is what three of them can do together that one cannot. Turn it in your hands and find the apex, and notice that the corner is not any of the faces. It is what they agree on. A corner is a place where three flat things have stopped being flat *together*.

<!-- @ -->

## What the corner is missing

```gdscript
func corner_defect(apex: Vector3, ring: Array) -> float:
    var total := 0.0
    for i in ring.size():
        total += face_angle_at(apex, ring[i], ring[(i + 1) % ring.size()])
    return 360.0 - total
```

Lay six equilateral triangles around a point and their angles come to 360. They lie flat, and there is no corner, because nothing had to give. Take one away. Five come to 300, and the point rises, because the faces can only meet by tilting, and the sixty degrees they no longer cover is the corner.

That number is the *defect*, and it is the whole argument of this room in one word: a corner is how much of a full turn the faces had to give up to meet in a point instead of a plane. A cube's corner is three right angles, ninety short. The sharper the corner, the more is missing.

<!-- @pyramid_edit -->

Take the apex and move it. Every face tilts to follow, because each one still has to end at the point you are holding, and the corner sharpens or flattens under your hand. Pull it high and the three faces close in, the defect grows, the corner becomes a spike. Push it down toward the base and the faces open, the defect shrinks, and at the moment the apex touches the base plane you have six angles summing to 360 and no corner at all. A pyramid is a corner with a handle on it.

<!-- @ -->

## Closing it

```gdscript
func close_corner(apex: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Array:
    var faces := trihedron(apex, a, b, c)
    faces.append([a, c, b])   # the base, wound to face outward
    return faces
```

One more face, across the bottom, and the corner is closed. Four vertices, four faces, six edges. The first solid, and the smallest one possible, and every one of its corners is the trihedron you were just holding.

<!-- @grab_tetrahedron -->

Here it is, closed. Notice that it has no top and no bottom; put it down any way you like and it is the same object. Every vertex is a corner of 180, three sixties, and there are four of them.

Now the fact this room exists to say.

```gdscript
func total_defect(corners: Dictionary) -> float:
    var sum := 0.0
    for apex in corners:
        sum += corner_defect(apex, corners[apex])
    return sum
```

Add up every corner of a closed solid and the answer is **720**. Four corners of 180. Eight corners of 90. Twelve corners of 60. It does not matter what you built: every closed solid there is carries exactly 720 degrees of corner, and the only freedom is how it spends them. Move one vertex of the tetrahedron and its four corners change, one sharpening as another flattens, and the sum does not move. This is Descartes' theorem, and it is the closest thing this chapter has to a conservation law. A solid keeps its volume not in its faces but at its corners, and in a fixed amount.

The next rooms will spend it in more and more places. The last of them will try to spend it everywhere at once, and find that a shape with corners everywhere has corners nowhere, and is a circle, and is never reached.

<!-- @cube_scene -->

The solid that spends it eight ways, three right angles at every corner. It is also what this museum is made of: the floor under you, the walls beside you, the plinth this stands on, all of them the same object at different sizes. You have been inside a polyhedron since the first room. The next room is about that.

<!-- @ -->

## Two numbers that do not care

```gdscript
func euler_check(V: int, E: int, F: int) -> bool:
    return V - E + F == 2
```

Vertices minus edges plus faces. Four minus six plus four. Eight minus twelve plus six. Two, and two. Whatever you build, if it closes, the count comes out the same, the way the corners came out to 720.

That is what a solid is, underneath the faces: two numbers that do not care which solid you built. The faces are where you look. The corners and the count are where it is kept.

The next room takes the eight-cornered one apart and shows you what it was made of, which you already know. Twelve of the unit, and six seams.
