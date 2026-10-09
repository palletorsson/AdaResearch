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

Create the following files together. The complete main program appears once; the remaining listings name every local code dependency. Earlier files return unchanged unless this lesson explicitly identifies a later edition.

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

### Dependency: point_body.gd

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```

### Dependency: trace_archive.gd

<!-- student-code:trace_archive.gd -->
```gdscript
# Supplied transport between museum halls. The lesson owns the drawing.
extends RefCounted

const PATH := "user://ada_student_trace.scn"

static func keep_on_release(point: Node3D, trail: Node3D, positions: Array[Vector3]) -> void:
    # Supplied lifecycle boundary: removing a scene is not a request to save.
    point.dropped.connect(func(_body):
        if point.get_meta("ada_release_cleanup", false):
            return
        if not is_instance_valid(trail) or not trail.is_inside_tree():
            return
        await trail.get_tree().process_frame
        if not is_instance_valid(point) or not is_instance_valid(trail):
            return
        if not point.is_inside_tree() or not trail.is_inside_tree():
            return
        if point.is_queued_for_deletion() or trail.is_queued_for_deletion():
            return
        if positions.size() >= 2:
            var error := save_drawing(trail, positions)
            if error != OK:
                push_error("Could not keep the trace: " + error_string(error))
    )

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

`record[index]` reads one saved position. `PointBody.new()` gives it the same visible, pickable body you already know. The three handles can move independently; their current local positions form a short array.

`Vector3i(0, 1, 2)` tells FaceBody which three entries to visit, in order. Its renderer adds three edges and a triangular surface. The points specify **where**; the triple specifies **how they connect**. This is a face recipe, not another set of positions.

Order matters. Godot treats clockwise vertices, viewed from the front, as a front face. Walk around the triangle: this example keeps normal back-face culling. Reversing the triple to `Vector3i(0, 2, 1)` reverses the front. The outline remains visible from either side.

Three collinear positions enclose no area. FaceBody checks the cross-product magnitude before submitting vertices and clears the previous face when the triangle collapses. The cross product is supplied here as the area-and-normal calculation; vector products return in Forces. The small threshold also rejects nearly collapsed triangles. The helper creates visible geometry, not a physical barrier.

## Make it your own

Choose another three saved entries. Make a valid face, flatten it until it disappears, then restore it. Reverse the order and explain which side is now the front. Keep the original saved drawing unchanged.

Carry forward the position array, its ordered face recipe, and FaceBody. The next hall adds a fourth position and asks whether several faces can enclose a volume.

## Source and scope

The runnable study is a small reconstruction in the existing Endless Museum. The hall contains additional artifacts; this lesson does not reproduce their complete runtime. Camera, light, player and XR Tools are declared museum infrastructure. Local geometry is generated by the printed files.

Godot documents clockwise front faces and ordered vertex submission in [SurfaceTool](https://docs.godotengine.org/en/4.6/classes/class_surfacetool.html).

[Current lesson.gd](../../../doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Triangle_Context/lesson.gd) · [Complete working project](../../../doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](../../../doc/book/iterations/2026-10-06-starter-one-course/index.html)
