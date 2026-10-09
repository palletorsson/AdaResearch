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

Attach lesson.gd to a unit-scale Node3D named PolyhedronStudy in this hall's working copy. Copy FaceBody, LineSkin and TraceArchive alongside it. All are printed below. No replacement camera, player or room is required.

Create the following files together. The complete main program appears once; the remaining listings name every local code dependency. Earlier files return unchanged unless this lesson explicitly identifies a later edition.

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
    message.text = "Four positions; four faces."
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

### Dependency: line_skin.gd

<!-- student-code:line_skin.gd -->
```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```

### Dependency: trace_archive.gd

<!-- student-code:trace_archive.gd -->
```gdscript
# Supplied transport between museum halls. The lesson owns the drawing.
extends RefCounted

const PATH := "user://ada_student_trace.scn"

static func save_drawing(trail: Node3D, positions: Array[Vector3]) -> Error:
    if positions.size() < 2:
        return ERR_INVALID_DATA
    var saved := Node3D.new()
    saved.name = "SavedTrace"
    saved.set_meta("positions", PackedVector3Array(positions))
    saved.set_meta("frame", "PointStudy local metres")
    saved.set_meta("version", 1)
    for child in trail.get_children():
        if child.is_queued_for_deletion():
            continue
        var segment := MeshInstance3D.new()
        segment.transform = child.transform
        segment.visible = child.visible
        segment.mesh = child.mesh.duplicate()
        segment.mesh.resource_local_to_scene = true
        segment.material_override = child.material_override.duplicate()
        segment.material_override.resource_local_to_scene = true
        saved.add_child(segment)
        segment.owner = saved
    var scene := PackedScene.new()
    var error := scene.pack(saved)
    if error == OK:
        error = ResourceSaver.save(scene, PATH)
    saved.free()
    return error

static func load_drawing() -> Node3D:
    if not FileAccess.file_exists(PATH):
        return null
    var scene := ResourceLoader.load(PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
    if scene == null:
        return null
    var drawing := scene.instantiate() as Node3D
    if drawing == null:
        return null
    if drawing.get_meta("version", 0) != 1 or drawing.get_meta("frame", "") != "PointStudy local metres":
        drawing.free()
        return null
    var record = drawing.get_meta("positions", null)
    if not record is PackedVector3Array or record.size() < 2 or drawing.get_child_count() != record.size() - 1:
        drawing.free()
        return null
    return drawing
```

## Read the construction

`points` holds four positions. `faces` holds four **triples of indices into points**. In `Vector3i(0, 3, 1)`, the renderer reads entries zero, three and one; it does not create three new independent corners.

The fourth position starts at the base triangle's centre and moves DEPTH metres behind its front. Using the base normal means the apex remains off the base plane whichever way the saved triangle faces. A zero-area base cannot define that normal; the guard stops before normalizing it. DEPTH must be positive.

Each of the tetrahedron's six edges belongs to exactly two faces. Adjacent faces traverse their common edge in opposite directions, keeping their fronts outside. The renderer reads the same position again wherever its index occurs. For flat lighting it submits separate render vertices per face, but the construction still has four shared positions.

Change `points[3]`, then call `body.show_faces(points, faces)` again. Three faces move with that one entry. Editing an index changes a connection instead. A closed mesh is still only a visible surface: this program adds no collision shape.

## Make it your own

Replace the selected base with another valid triple, then halve DEPTH. Check that all four faces remain and that the apex is still off the base plane. Explain why a fifth copied point would not automatically become part of the enclosure.

Carry the separation between positions and connectivity into Cube. A longer face list will reuse the same renderer.

## Source and scope

The runnable study is a small reconstruction in the existing Endless Museum. The hall contains additional artifacts; this lesson does not reproduce their complete runtime. Camera, light, player and XR Tools are declared museum infrastructure. Local geometry is generated by the printed files.

Godot documents clockwise front faces and ordered vertex submission in [SurfaceTool](https://docs.godotengine.org/en/4.6/classes/class_surfacetool.html).
