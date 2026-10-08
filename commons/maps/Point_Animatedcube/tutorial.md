# Eight corners, twelve triangles

## Learning elements

- A reusable CubeBody class
- Shared corner data
- Two triangles per square side
- Connectivity versus object position

## In the museum

The cube appears simple enough to arrive ready-made. The diagonal study in this hall exposes a decision hidden by that familiar outline: a square surface is represented here by two triangles. Build one cube, then a second with the other diagonal on its front side.

We keep FaceBody from the preceding halls. CubeBody adds a particular set of eight positions and twelve index triples. It is the cube we can carry into Transformation and Arrays.

## Make this study

Attach lesson.gd to an empty unit-scale Node3D named CubeStudy in the museum hall. CubeBody constructs its visible mesh itself. The placements in lesson.gd leave room between two one-metre cubes; they do not alter their local vertex data.

Carried unchanged from [Lines](../Point_Lines/tutorial.md): `line_skin.gd`. Carried unchanged from [Triangle](../Point_Triangle_Context/tutorial.md): `face_body.gd`.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const CubeBody = preload("cube_body.gd")
var first := CubeBody.new()
var second := CubeBody.new()

func _ready() -> void:
    first.position = Vector3(-0.7, 0.7, 0)
    second.position = Vector3(0.7, 0.7, 0)
    add_child(first)
    add_child(second)
    second.other_diagonal()
```

### Dependency: cube_body.gd

<!-- student-code:cube_body.gd -->
```gdscript
extends "face_body.gd"
# Eight shared positions; each triple addresses three entries.
var points: Array[Vector3] = [
    Vector3(-0.5, 0, -0.5), Vector3(0.5, 0, -0.5),
    Vector3(0.5, 1, -0.5), Vector3(-0.5, 1, -0.5),
    Vector3(-0.5, 0, 0.5), Vector3(0.5, 0, 0.5),
    Vector3(0.5, 1, 0.5), Vector3(-0.5, 1, 0.5)]
var faces: Array[Vector3i] = [
    Vector3i(4, 7, 5), Vector3i(5, 7, 6),
    Vector3i(0, 4, 1), Vector3i(1, 4, 5),
    Vector3i(2, 6, 3), Vector3i(3, 6, 7),
    Vector3i(1, 2, 0), Vector3i(0, 2, 3),
    Vector3i(0, 3, 4), Vector3i(4, 3, 7),
    Vector3i(5, 6, 1), Vector3i(1, 6, 2)]

func _init() -> void:
    super()
    show_faces(points, faces)

func other_diagonal() -> void:
    faces[0] = Vector3i(4, 6, 5)
    faces[1] = Vector3i(4, 7, 6)
    show_faces(points, faces)
```

## Read the construction

CubeBody extends FaceBody, so it inherits the face renderer. Its `_init()` first calls `super()` to attach the parent's surface and edge container, then calls the renderer with this cube's recipe. Each call to `CubeBody.new()` creates a new object with its own position array, face array and mesh.

The corners use x and z values of −0.5 or 0.5 and y values of zero or one. The first two triples cover the positive-z side. `other_diagonal()` changes those two triples, keeping the four corner positions fixed. The black internal line moves to the other diagonal; the square's boundary and area stay the same.

Node position and vertex position do different jobs. `second.position` places the whole cube in the study. `second.points[6] += Vector3(0, 0, 0.35)` changes one local corner; call `second.show_faces(second.points, second.faces)` afterward to redraw it. Every face using entry six changes. A formerly square side can become two angled planes, making the diagonal matter to the surface itself.

These cubes have visible edges and faces, without colliders.

## Make it your own

Make a third CubeBody and place it somewhere else. Change one corner on that instance and redraw it. Verify that the first two cubes keep their shapes. Then explain the difference between moving a body and editing the data from which it is made.

Keep CubeBody. The next hall asks whether a short rule can generate a position list that we have so far written out.

Godot documents clockwise front faces and ordered vertex submission in [SurfaceTool](https://docs.godotengine.org/en/4.6/classes/class_surfacetool.html).

[Current lesson.gd](../../../doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Animatedcube/lesson.gd) · [Complete working project](../../../doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](../../../doc/book/iterations/2026-10-06-starter-one-course/index.html)
