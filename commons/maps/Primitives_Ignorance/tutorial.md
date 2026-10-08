# A rule produces positions

## Learning elements

- Functions and typed return values
- Parameters and arguments
- Symmetry as a construction rule
- Independent generated results

## In the museum

Among the Platonic solids, the octahedron offers a compact rule: put a position at each end of three perpendicular axes. Six positions replace a long list of coordinates. The geometry courtyard gives the result a place; this lesson makes its construction available to you.

In Cube, you wrote the corner positions into a list. Here you write a rule that returns a list for each radius you give it. Arrays, loops and the face renderer return; a named function makes their work reusable. We supply the eight face triples so that the lesson stays with generating positions.

You can still work out every coordinate. What changes is where you make the decision: choose the rule and its input, then inspect the positions they produce. Later generators can produce more than you would want to place one point at a time.

## Make this study

Attach lesson.gd to a Node3D named GeneratorStudy in this museum hall. FaceBody and LineSkin are unchanged. The two calls deliberately use different radii and store their results separately.

Carried unchanged from [Lines](../Point_Lines/tutorial.md): `line_skin.gd`. Carried unchanged from [Triangle](../Point_Triangle_Context/tutorial.md): `face_body.gd`.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const FaceBody = preload("face_body.gd")
# Connectivity is supplied; this lesson generates the positions.
const FACES: Array[Vector3i] = [
    Vector3i(2, 0, 4), Vector3i(2, 4, 1),
    Vector3i(2, 1, 5), Vector3i(2, 5, 0),
    Vector3i(3, 4, 0), Vector3i(3, 1, 4),
    Vector3i(3, 5, 1), Vector3i(3, 0, 5)]
var small_points: Array[Vector3] = []
var large_points: Array[Vector3] = []

func _ready() -> void:
    small_points = octahedron_positions(0.3)
    large_points = octahedron_positions(0.6)
    var small := FaceBody.new()
    var large := FaceBody.new()
    small.position = Vector3(-0.7, 1.1, 0)
    large.position = Vector3(0.7, 1.1, 0)
    add_child(small)
    add_child(large)
    small.show_faces(small_points, FACES)
    large.show_faces(large_points, FACES)

func octahedron_positions(radius: float) -> Array[Vector3]:
    assert(radius > 0.0)
    var result: Array[Vector3] = []
    for axis in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
        result.append(axis * radius)
        result.append(-axis * radius)
    return result
```

## Read the construction

`radius` is the function's parameter. The numbers 0.3 and 0.6 are arguments supplied by two calls. `-> Array[Vector3]` names the kind of value returned: a list of positions. The positive-radius assertion states the function's domain.

For each positive axis, the loop appends one position and its opposite. The order is +X, −X, +Y, −Y, +Z, −Z. The supplied face list depends on that order. Rearranging the list without changing the faces would make a different set of connections.

The function builds a fresh `result` on every call and returns it. It does not place a body in the room or draw anything. FaceBody takes the returned data and renders it. This separates generating positions from displaying them without introducing a general-purpose factory.

Changing a returned position changes one result. Changing the rule changes future results. Neither operation makes a claim about which sculpture is better. Radius, geometric relationship and aesthetic judgment are different decisions.

## Make it your own

Call the function with 0.45. Use the returned array to display a third body. Move one entry in that array, redraw only that body, and verify that the other two remain unchanged. Describe the symmetry your edit broke.

Carry the idea of a parameter controlling a construction. In Godot Primitives, return to your original sphere and make two of the engine's construction parameters available while holding it.


[Current lesson.gd](../../../doc/book/iterations/2026-10-06-starter-one-course/lessons/Primitives_Ignorance/lesson.gd) · [Complete working project](../../../doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](../../../doc/book/iterations/2026-10-06-starter-one-course/index.html)
