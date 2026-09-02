Everything you have seen so far was drawn in triangles.

The sphere in the first room. The hammer. The plinths, the walls, the floor you are standing on. Not the lines, which are their own thing, but every *surface*: each one is a closed outline filled with triangles, because that is the only shape the machine knows how to fill. This room is where you meet the unit.

<!-- @triangle_line_puzzle -->

Three ends to drag, and the room asks for an equilateral. That is the door in, and it is the previous chapter's last sentence: two points have a distance, and a third point has a decision to make, whether to close.

It closes. Three points, three segments, and for the first time a *between* that is not a line but a region.

<!-- @ -->

## The unit

```gdscript
func triangle_normal(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
    return (b - a).cross(c - a).normalized()
```

Why triangles, and not squares, or anything else? Because three points always share a plane. There is no fourth point to disagree, so a triangle is flat by necessity, and a flat face is something the renderer can light with one direction. Two edges out of a corner, crossed, and the face has a way it is looking. The `.normalized()` at the end is the vector room's old move, keep the which-way and throw the how-far.

<!-- @draw_triangle_faces -->

Draw a loop in the air, any shape you like, and bring the line back to where it started. The machine fills it, and watch *how*: it picks one corner and fans out from it, triangle after triangle, until the outline is a surface.

```gdscript
func fan_triangulate(loop: Array[Vector3]) -> Array:
    var tris: Array = []
    for i in range(1, loop.size() - 1):
        tris.append([loop[0], loop[i], loop[i + 1]])
    return tris
```

A loop of n points becomes n minus two triangles, every time, whatever you drew. This is not a rendering trick. It is what a surface *is* in here, and every wall in the museum was made by exactly this operation on a rectangle: two triangles, and a seam you were never meant to see.

<!-- @triangleprofiles -->

A pleated profile you can pull at. Every pleat is a face, and every face is the unit, and the folds are where one face ends and the next begins. Once you know that, you cannot stop seeing it.

<!-- @ -->

## Three numbers, one shape

```gdscript
func third_vertex(a: float, b: float, c: float) -> Vector2:
    # first side laid along x, from (0, 0) to (a, 0)
    var x := (a * a + b * b - c * c) / (2.0 * a)
    var y := sqrt(maxf(b * b - x * x, 0.0))
    return Vector2(x, y)   # Vector2(x, -y) is the same triangle, mirrored
```

Give a triangle its three lengths and the third corner has exactly one place it can be, plus its reflection. Nothing in that function but Pythagoras used twice. No polygon with more sides has this property. Four rods with hinges lean; three rods with hinges hold, and that is why every truss, every bicycle frame and every roof that has stayed up is triangles under the skin.

<!-- @pythagorean_triangle_angles -->

Three squares grown from three sides, and the two smaller ones sum to the largest exactly when the corner between them is square. Watch the labels as you pull: the theorem is a fact about *lengths*, and the right angle is what the lengths produce, not what produces them.

Hold on to that order. Fix the three lengths and you have fixed all three angles without measuring one. A length and an angle are one fact seen from two sides, and this chapter only ever looks at it from the side of length. Another chapter looks from the other side, and a great deal follows.

<!-- @interactivetriangle -->

Drag a corner. The panel follows, pink on one face, black on the other, and it reports its area every time you let go. Notice what you are actually doing: you cannot change the shape without changing a length. There is no other handle. That is rigidity said exactly, not that the triangle resists you, but that it has no way to move except through its sides.

<!-- @triangle -->

The same object with its presets: equilateral, right, isosceles. Three families of one unit, each a different set of three numbers.

<!-- @ -->

## Which side you are on

```gdscript
func faces_you(a: Vector3, b: Vector3, c: Vector3, eye: Vector3) -> bool:
    return triangle_normal(a, b, c).dot(eye - a) > 0.0
```

<!-- @parasol_triangle -->

A triangle on a stick, pink from here. Walk round it. Blue.

A face has a front, and the front is decided by nothing more than the order its three corners are listed in. Swap two and the same three points face the other way. The renderer, by default, draws only the front and throws the back away unseen, so most of the triangles you have ever looked at were visible from one side and did not exist from the other. This parasol was built to show both, which is a decision somebody had to make, and the two colours are that decision made visible.

<!-- @ -->

## Four points, and a fold

```gdscript
func is_planar(p: Array[Vector3], tol: float = 0.001) -> bool:
    var n := (p[1] - p[0]).cross(p[2] - p[0]).normalized()
    return absf((p[3] - p[0]).dot(n)) < tol
```

Three points pass by construction. A fourth may not, and when it sits off the plane there is no face to draw, so the machine does the only thing it can: it splits the quad into two triangles, and the line it splits along is a fold.

<!-- @quad_line_puzzle -->

Four ends, and the room asks for a square. You will find it harder than the triangle was, and the reason is the one this room has been making: four lengths do not fix a shape.

```gdscript
func quad_from_rods(a: float, b: float, lean: Vector2) -> Array[Vector2]:
    lean = lean.normalized() * b   # any direction at all: the rods do not care
    return [Vector2.ZERO, Vector2(a, 0.0), Vector2(a, 0.0) + lean, lean]
```

Every value of `lean` is a different quad with the same four sides. The square is one member of a family that leans, and nothing in the four lengths prefers it.

<!-- @quad -->

Here it is, already split: pink triangle, black triangle, a diagonal between them. Drag a corner off the plane and watch the diagonal become a crease. The quad did not exist as one face. It was two faces agreeing to lie flat, and when they stop agreeing the seam appears.

<!-- @folded_strip -->

Twenty-four faces in a strip, pleated like paper, and every fold is where two triangles meet at an angle. Fold it further. Nothing tears, because nothing here was ever one surface. It was always this many, and the folds were only hidden while they were flat.

<!-- @ -->

## What a triangle is for

It is the unit because it is the only shape that cannot lie: always flat, always one shape for its lengths, always facing one way. Everything larger is made by agreeing triangles together, and every fold, crease and seam you will ever see in here is a place where the agreement ends.

The next room takes three of them and stands them up so they meet at a point. That is a corner, and a corner is the first thing in this chapter that has an inside.
