# Four positions enclose a body

## Learning elements

- Shared vertices
- A list of face-index triples
- Tetrahedron connectivity
- Surface enclosure versus collision

## In the museum

A tetrahedron is the smallest closed body made entirely of triangular faces. The museum's polyhedra let you encounter a surface from outside and imagine the volume it encloses. Our construction begins with the same three saved entries used for Triangle and adds one point behind their face.

This lesson reloads the original Trace record. Moving a temporary Triangle handle did not change that file. Use the same CORNERS triple you selected there; the number of stored drawing entries determines which indices are available.

## Make this study

Attach lesson.gd to a unit-scale Node3D named PolyhedronStudy in this hall's working copy. Copy FaceBody, LineSkin and TraceArchive alongside it. No replacement camera, player or room is required.

The body uses a two-sided material so that removing a face lets you see the remaining surfaces from inside. Their winding still defines a front, as in Triangle; this display choice does not add volume or collision.

Carried unchanged from [Lines](../Point_Lines/tutorial.md): `line_skin.gd`. Carried unchanged from [Trace](../Point_Trace/tutorial.md): `trace_archive.gd`. Carried unchanged from [Triangle](../Point_Triangle_Context/tutorial.md): `face_body.gd`.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const Archive = preload("trace_archive.gd")
const FaceBody = preload("face_body.gd")
const CORNERS := Vector3i(0, 1, 2)
const DEPTH := 0.6
var points: Array[Vector3] = []
var faces: Array[Vector3i] = [
    Vector3i(0, 1, 2), Vector3i(0, 3, 1),
    Vector3i(1, 3, 2), Vector3i(2, 3, 0)]
var body := FaceBody.new()
var message := Label3D.new()

func _ready() -> void:
    body.surface.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
    add_child(body)
    add_child(message)
    message.position = Vector3(0, 2, 0)
    message.pixel_size = 0.003
    var drawing := Archive.load_drawing()
    if drawing == null:
        message.text = "Bring a drawing from Trace."
        return
    var record: PackedVector3Array = drawing.get_meta("positions")
    drawing.free()
    for index in [CORNERS.x, CORNERS.y, CORNERS.z]:
        if index < 0 or index >= record.size():
            message.text = "Choose three saved indices."
            return
    for index in [CORNERS.x, CORNERS.y, CORNERS.z]:
        points.append(record[index])
    var normal := (points[2] - points[0]).cross(points[1] - points[0])
    if normal.length() < 0.00001 or DEPTH <= 0.0:
        message.text = "Use a valid triangle and a positive depth."
        return
    var centre := (points[0] + points[1] + points[2]) / 3.0
    points.append(centre - normal.normalized() * DEPTH)
    body.show_faces(points, faces)
    message.text = "%d positions; %d faces." % [points.size(), faces.size()]
```

## Read the construction

`points` holds four positions. `faces` holds four **triples of indices into points**. In `Vector3i(0, 3, 1)`, the renderer reads entries zero, three and one; it does not create three new independent corners.

The fourth position starts at the base triangle's centre and moves DEPTH metres behind its front. Using the base normal means the apex remains off the base plane whichever way the saved triangle faces. A zero-area base cannot define that normal; the guard stops before normalizing it. DEPTH must be positive.

Each of the tetrahedron's six edges belongs to exactly two faces. Adjacent faces traverse their common edge in opposite directions, keeping their fronts outside. The renderer reads the same position again wherever its index occurs. For flat lighting it submits separate render vertices per face, but the construction still has four shared positions.

Change `points[3]`, then call `body.show_faces(points, faces)` again. Three faces move with that one entry. Editing an index changes a connection instead. A closed mesh is still only a visible surface: this program adds no collision shape.

## Make it your own

Replace the selected base with another valid triple, then halve DEPTH. Check that all four faces remain and that the apex is still off the base plane. Explain why a fifth copied point would not automatically become part of the enclosure.

Carry the separation between positions and connectivity into Cube. A longer face list will reuse the same renderer.

Godot documents clockwise front faces and ordered vertex submission in [SurfaceTool](https://docs.godotengine.org/en/4.6/classes/class_surfacetool.html).

[Current lesson.gd](../../../doc/book/iterations/2026-10-06-starter-one-course/lessons/Primitives_Polythedra/lesson.gd) · [Complete working project](../../../doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](../../../doc/book/iterations/2026-10-06-starter-one-course/index.html)
