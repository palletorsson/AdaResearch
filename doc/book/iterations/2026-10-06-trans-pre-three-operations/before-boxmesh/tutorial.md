# Move, turn, change size

**Learning elements**

- Translation: position
- Rotation: orientation and an axis
- Uniform scale: size and proportion
- Node origin: where a change is anchored
- Animation: a transform changing over time

Walk past the four cubes in Trans_Pre. One stays still, one rises, another adds a turn, and the last changes size as well. Follow a corner. Which changes belong to its journey, and which change the body itself?

Bring **CubeBody** from the Cube lesson: the same eight corners, twelve faces and dark edges. In Melencolia, you placed instances of it. Here you will change one instance's position, orientation and size while keeping its construction. Begin with a still pose. A transformation does not need an animation.

## The study beside the encounter

The existing Endless Museum supplies the room, player, camera and lighting. In your working museum scene, add one empty `Node3D` named `TransformStudy` in a clear floor space beside the row. Give that study root zero rotation and unit scale; its origin sits at floor level. Attach `lesson.gd` below. Its positions are local metres relative to that root, as in Coordinates.

Keep `cube_body.gd`, `face_body.gd` and `line_skin.gd` beside it. They are unchanged from [Cube](../Point_Animatedcube/tutorial.md); their complete listings are retained below. The main script creates its own cube. It does not look up or modify an installed exhibit. This study has visible geometry; the hall's pickup and collision behaviour remain supplied.

## One cube, three changes

Save this complete main script as `lesson.gd`.

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const CubeBody = preload("cube_body.gd")

var cube := CubeBody.new()
var start := Vector3(0, 1, 0)
var turn_degrees := 0.0
var size_factor := 1.0
var rise := 0.0
var duration := 2.0
var elapsed := 0.0

func _ready() -> void:
    assert(duration > 0.0 and size_factor > 0.0)
    add_child(cube)
    cube.position = start
    cube.rotation_degrees.y = turn_degrees
    cube.scale = Vector3.ONE * size_factor

func _process(delta: float) -> void:
    elapsed += delta
    var t: float = minf(elapsed / duration, 1.0)
    cube.position = start + Vector3.UP * rise * t
```

Initially the cube stays still. `rise` is zero, so the running clock makes no change to its position. `_ready()` attaches the cube and sets its starting pose; `_process()` will let us animate its position later. The assertion requires a positive duration and size.

Our cube's corners run from −0.5 to 0.5 along X and Z, and from 0 to 1 along Y. Its origin is therefore the **bottom centre**, not the middle of its volume. At the starting pose, its bottom is one metre above the study root and its top is two metres above it.

Change one value and run again. Restore the starting values before each comparison.

| Change this value | Look for this result | What stays the same |
| --- | --- | --- |
| `start = Vector3(1, 1, 0)` | The whole cube is one metre farther along X. This is **translation**. | Every corner receives the same displacement. Facing and edge lengths remain fixed. |
| `turn_degrees = 45.0` | The cube turns around its upright Y axis through its origin. This is **rotation**. | The origin and distances between corners remain fixed. |
| `size_factor = 1.5` | The edges become 1.5 metres long. This is **uniform scaling**. | All dimensions receive the same factor, so proportions remain fixed. |

Edit the values on their existing `var` lines; do not add new declarations. Each assignment changes a property of the cube node. Its surface and edges follow that node. Its stored corner list still describes the original one-metre cube.

During scaling, the bottom centre stays at `start`; the top rises. That follows from our chosen origin. Rotation around Y also passes through the cube's middle, because the bottom centre lies on the same upright axis. We will move the pivot in the Rotation hall.

## Give translation a duration

Restore `start`, `turn_degrees` and `size_factor`, then change `rise` to `1.0`. The cube now travels one metre upward in two seconds and stops.

`elapsed += delta` adds the seconds since the previous frame. Dividing elapsed time by `duration` gives the fraction of the journey completed. `minf(..., 1.0)` keeps that fraction at one after arrival. Half a second gives `t = 0.25`; one second gives `t = 0.5`.

The last line adds an upward displacement to the starting position. At the halfway point it adds half a metre; at the end it adds one metre. This is linear interpolation written as **start + displacement × fraction**. Each frame assigns a position measured from the same start. It does not add that entire position to the previous one.

Set `duration` to `4.0`. The destination stays fixed and the journey takes twice as long. Turning and size have not changed. More rendered frames give more intermediate poses; they do not shorten the journey.

The hall combines rising, turning and pulsing. Our first animation isolates translation. With `rise` still at one, set `turn_degrees` to 45 and `size_factor` to 1.5: the enlarged, turned cube now rises without changing its facing or size during the journey. A fixed turn and a continuously turning body are different choices. The later halls develop those choices separately.

## Make another pose

Return to a still cube. Choose a different angle around Y. Before running it, name one corner that should move and one distance that should stay fixed. Then try the change. A quarter-turn can recover the cube's outline even though a particular corner has moved; an angle such as −30 degrees makes the change easier to see.

Carry the three properties onward: **position, orientation, scale**. The construction can stay the same while its relation to the surrounding room changes. In the next hall, those changes make different kinds of crossing.

## Returning code

These three files return unchanged from Cube. You need them beside `lesson.gd`; their geometry is already part of the student's code corpus. Read the main script for this lesson's new operations.

### cube_body.gd

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

### face_body.gd

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

### line_skin.gd

The face renderer sets each edge's material to dark gray; the helper's earlier pink default is not used by this cube.

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

## Executable check

The [lesson files and review](../../../doc/book/iterations/2026-10-06-trans-pre-three-operations/index.html) include the exact printed program, edited variants and native Godot evidence. Checks compare corner positions, distances, construction data and elapsed time. They do not establish that a reader can yet explain the changes or verify headset comfort.
