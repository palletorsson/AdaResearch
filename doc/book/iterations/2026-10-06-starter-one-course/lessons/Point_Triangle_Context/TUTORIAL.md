# Three positions become a face

## Learning elements

- Three selected array entries
- A closed boundary and a face
- Clockwise vertex order
- A guard for a collapsed triangle

## In the museum

Your drawing has reached Grid as a sculpture. Here, choose three positions from its original record. The triangle tools in this hall show the difference between connecting corners and giving the space between them a surface. We will make that difference with the point and line classes already used.

The saved record still uses the drawing station's local metres. Grid's rounded copy did not replace it. This lesson reads the original archive and creates three temporary PointBody handles at selected entries. It does not save their later edits back to the drawing.

Lines already connected two positions. The new step is to store a connection as a recipe that refers to entries in a position list. Three Vector3 values alone do not instruct Godot to draw a face. We choose which entries belong together and in which order; the same stored position can later belong to several faces.

## Make this study

Start with CORNERS = Vector3i(0, 1, 2). These are **entry numbers**, not spatial coordinates. If those entries lie on one straight segment of your drawing, lift one handle to make a face, or choose another triple in the record. A trace with fewer than three entries needs another visit to Trace.

Attach lesson.gd to an empty Node3D named TriangleStudy in your working copy of this museum hall. Keep its scale at one; its translation places the study without changing the saved local measurements. The existing museum supplies the player, camera, light and XR pickup functions. This program constructs its own handles, edges, face and label.

Carried unchanged from [Lines](../Point_Lines/TUTORIAL.md): `point_body.gd`, `line_skin.gd`. Carried unchanged from [Trace](../Point_Trace/TUTORIAL.md): `trace_archive.gd`.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const PointBody = preload("point_body.gd")
const FaceBody = preload("face_body.gd")
const Archive = preload("trace_archive.gd")
const CORNERS := Vector3i(0, 1, 2)
var handles: Array[Node3D] = []
var points: Array[Vector3] = []
var face := FaceBody.new()
var message := Label3D.new()

func _ready() -> void:
    add_child(face)
    add_child(message)
    message.position = Vector3(0, 2, 0)
    message.font_size = 32
    message.pixel_size = 0.003
    var drawing := Archive.load_drawing()
    if drawing == null:
        message.text = "Return to Trace; draw and release the point."
        return
    var record: PackedVector3Array = drawing.get_meta("positions")
    drawing.free()
    for index in [CORNERS.x, CORNERS.y, CORNERS.z]:
        if index < 0 or index >= record.size():
            message.text = "Choose three indices inside the saved record."
            return
    for index in [CORNERS.x, CORNERS.y, CORNERS.z]:
        var point := PointBody.new()
        point.position = record[index]
        add_child(point)
        handles.append(point)

func _process(_delta: float) -> void:
    if handles.size() != 3:
        return
    var current: Array[Vector3] = []
    for point in handles:
        current.append(point.position)
    if current == points:
        return
    points = current
    if face.show_faces(points, [Vector3i(0, 1, 2)]):
        message.text = "Three positions; one face."
    else:
        message.text = "Separate the corners; lift one off the line."
```

### Dependency: face_body.gd

<!-- student-code:face_body.gd -->
```gdscript
extends Node3D
## Visible triangular faces and their edges. This class adds no collision.
const LineSkin = preload("line_skin.gd")
var surface := MeshInstance3D.new()
var edges := Node3D.new()

func _init() -> void:
    add_child(surface)
    add_child(edges)
    var paper := StandardMaterial3D.new()
    paper.albedo_color = Color(0.92, 0.91, 0.87)
    paper.roughness = 0.75
    surface.material_override = paper

func show_faces(points: Array[Vector3], faces: Array[Vector3i]) -> bool:
    surface.mesh = null
    for edge in edges.get_children():
        edge.free()
    if faces.is_empty():
        return false
    for face in faces:
        for index in [face.x, face.y, face.z]:
            if index < 0 or index >= points.size():
                return false
        var a := points[face.x]
        var b := points[face.y]
        var c := points[face.z]
        if (c - a).cross(b - a).length() < 0.00001:
            return false
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for face in faces:
        var a := points[face.x]
        var b := points[face.y]
        var c := points[face.z]
        # Godot's front faces use clockwise winding.
        var normal := (c - a).cross(b - a).normalized()
        for point in [a, b, c]:
            builder.set_normal(normal)
            builder.add_vertex(point)
        for pair in [[a, b], [b, c], [c, a]]:
            var edge := LineSkin.new()
            edge.material_override.albedo_color = Color(0.04, 0.04, 0.045)
            edges.add_child(edge)
            var difference: Vector3 = pair[1] - pair[0]
            edge.show_segment(pair[0], difference, difference.length())
    surface.mesh = builder.commit()
    return true
```

## Read the construction

`record[index]` reads one saved position. `PointBody.new()` gives it the same visible, pickable body you already know. The three handles can move independently; their current local positions form a short array.

`Vector3i(0, 1, 2)` tells FaceBody which three entries to visit, in order. Its renderer adds three edges and a triangular surface. The points specify **where**; the triple specifies **how they connect**. This is a face recipe, not another set of positions.

Order matters. Godot treats clockwise vertices, viewed from the front, as a front face. Walk around the triangle: this example keeps normal back-face culling. Reversing the triple to `Vector3i(0, 2, 1)` reverses the front. The outline remains visible from either side.

Three collinear positions enclose no area. FaceBody checks the cross-product magnitude before submitting vertices and clears the previous face when the triangle collapses. The cross product is supplied here as the area-and-normal calculation; vector products return in Forces. The small threshold also rejects nearly collapsed triangles. The helper creates visible geometry, not a physical barrier.

## Make it your own

Choose another three saved entries. Make a valid face, flatten it until it disappears, then restore it. Reverse the order and explain which side is now the front. Keep the original saved drawing unchanged.

Carry forward the position array, its ordered face recipe, and FaceBody. The next hall adds a fourth position and asks whether several faces can enclose a volume.

Godot documents clockwise front faces and ordered vertex submission in [SurfaceTool](https://docs.godotengine.org/en/4.6/classes/class_surfacetool.html).

[Current lesson.gd](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Triangle_Context/lesson.gd) · [Complete working project](http://localhost:3003/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html)
