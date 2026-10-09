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

Put the four printed files in one lesson folder and attach lesson.gd to an empty unit-scale Node3D named CubeStudy in the museum hall. CubeBody constructs its visible mesh itself. The placements in lesson.gd leave room between two one-metre cubes; they do not alter their local vertex data.

Create the following files together. The complete main program appears once; the remaining listings name every local code dependency. Earlier files return unchanged unless this lesson explicitly identifies a later edition.

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

## Read the construction

CubeBody extends FaceBody, so it inherits the face renderer. Its `_init()` first calls `super()` to attach the parent's surface and edge container, then calls the renderer with this cube's recipe. Each call to `CubeBody.new()` creates a new object with its own position array, face array and mesh.

The corners use x and z values of −0.5 or 0.5 and y values of zero or one. The first two triples cover the positive-z side. `other_diagonal()` changes those two triples, keeping the four corner positions fixed. The black internal line moves to the other diagonal; the square's boundary and area stay the same.

Node position and vertex position do different jobs. `second.position` places the whole cube in the study. `second.points[6] += Vector3(0, 0, 0.25)` changes one local corner; call `second.show_faces(second.points, second.faces)` afterward to redraw it. Every face using entry six changes. A formerly square side can become two angled planes, making the diagonal matter to the surface itself.

These cubes have visible edges and faces, without colliders. The wider prefab collection in the museum remains available for reflection; it is not another construction dependency.

## Make it your own

Make a third CubeBody and place it somewhere else. Change one corner on that instance and redraw it. Verify that the first two cubes keep their shapes. Then explain the difference between moving a body and editing the data from which it is made.

Keep CubeBody. The next hall asks whether a short rule can generate a position list that we have so far written out.

## Source and scope

The runnable study is a small reconstruction in the existing Endless Museum. The hall contains additional artifacts; this lesson does not reproduce their complete runtime. Camera, light, player and XR Tools are declared museum infrastructure. Local geometry is generated by the printed files.

Godot documents clockwise front faces and ordered vertex submission in [SurfaceTool](https://docs.godotengine.org/en/4.6/classes/class_surfacetool.html).
