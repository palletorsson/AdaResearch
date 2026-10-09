# Arrange what you can already make

## Learning elements

- Composition with known classes
- Independent instances
- Placement versus construction
- Reusing a learned capability

## In the museum

Dürer's objects gather in the museum's Melencolia hall. Our tutorial closes this sequence with a smaller task: make an arrangement from two instances of your cube and the familiar sphere point. The reflective text can ask what geometry promises; the tutorial gives you enough control to make an arrangement of your own.

There is no new mesh recipe here. Keep CubeBody from Cube and PointBody from the earlier point lessons. These are recognizable constructions, not substitutes downloaded for the closing image.

## Make this study

Attach lesson.gd to a unit-scale Node3D named ArrangementStudy in this hall's working copy. Place that study at floor level. The cube's local bottom is y = 0; the sphere's centre is one radius above the floor. PointBody retains pickup and frozen release; the cubes remain visible mesh objects without colliders.

Create the following files together. The complete main program appears once; the remaining listings name every local code dependency. Earlier files return unchanged unless this lesson explicitly identifies a later edition.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const CubeBody = preload("cube_body.gd")
const PointBody = preload("point_body.gd")
var places: Array[Vector3] = [Vector3(-0.8, 0, 0), Vector3(0.5, 0, -0.7)]
var cubes: Array[Node3D] = []
var point := PointBody.new()

func _ready() -> void:
    for place in places:
        var cube := CubeBody.new()
        cube.position = place
        add_child(cube)
        cubes.append(cube)
    point.position = Vector3(0.1, PointBody.RADIUS, 0.6)
    add_child(point)
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

## Read the construction

The loop constructs two independent CubeBody instances and assigns positions from places. Reusing a class does not mean sharing one mutable vertex array. Moving an instance should leave its geometry and its neighbour unchanged.

The point is the same white sphere with the same size and interaction settings. It can be picked up and left somewhere else during a run. That temporary placement is not written back into this script. To keep an arrangement across runs, put your chosen coordinates in the source; persistent composition is a later capability.

The program uses constructors, arrays, a loop and positions you have already met. Scale and rotation stay for Transformation. You can still change the relation between bodies through distance, overlap and placement. The resulting arrangement is your decision, not the inevitable output of the cube rule.

## Make it your own

Make a second arrangement by changing only places and the point's initial position. Keep the classes unchanged. Show how a different interval or overlap changes what you notice. You should be able to reconstruct both arrangements from their saved script values.

## After the chapter: an arrangement without a recipe

Choose a different arrangement in a clear part of your working museum hall. Use the earlier files as references, but write your own small main script. This is an independent challenge; there is no new construction hidden in a supplied answer.

- Generate a list of at least five positions with a rule you can explain. Keep an unchanged source list and modify an independently owned copy.
- Reuse PointBody and FaceBody. Choose three non-collinear entries from the list and connect them as a face.
- Show two spheres of equal radius with different resolutions, using the construction already studied in Godot Primitives.
- Decide their spacing and arrangement. Keep the known collider behaviour; making a new walkable structure is outside this task.

Show the arrangement to someone who has not seen your script. Locate the stored values, the variable referring to each body, and the indices establishing the face. Explain what the generator decided, what resolution changed, what you preserved, and one aesthetic choice that no calculation required.

Run your script and check that changing the copy leaves the source intact, that the selected face has area, and that each sphere keeps its own mesh. Then change one choice and predict the result before running again. Successful execution is evidence about the program; explaining and transferring the choices gives evidence about what you learned.

Carry CubeBody and PointBody into Transformation. A body that you can place is ready to become a body whose position, rotation or scale changes over time.

## Source and scope

The runnable study is a small reconstruction in the existing Endless Museum. The hall contains additional artifacts; this lesson does not reproduce their complete runtime. Camera, light, player and XR Tools are declared museum infrastructure. Local geometry is generated by the printed files.


[Current lesson.gd](../../../doc/book/iterations/2026-10-06-starter-one-course/lessons/Primitives_Melencolia/lesson.gd) · [Complete working project](../../../doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](../../../doc/book/iterations/2026-10-06-starter-one-course/index.html)
