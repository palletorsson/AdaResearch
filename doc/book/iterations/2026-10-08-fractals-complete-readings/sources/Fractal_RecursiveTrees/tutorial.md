# Recursive Trees — turn one fork

**Learning elements**

- Two recursive calls from one branch
- Parent and child transforms
- Inherited direction and length
- A local edit that preserves the other subtree

Press GROW beside the small tree. Hold one of its two points and turn the first branch. Its descendants follow. The other side stays. Look up: the large canopy receives the same edit. Release the point, then add another generation. Its new branches begin at the tips you moved.

The sphere still acts as a point you can hold. The line still gives two positions a visible span. We now arrange those spans in a hierarchy, so you can change a family of branches without dragging every endpoint.

## What continues

Keep the museum workspace, XR hands and the `LineSkin` from the previous lesson. Save `tree.gd`, `point_body.gd` and `line_skin.gd` together. On your empty `PointStudy` node, replace `frames.gd` with `tree.gd`; keep the frame script as your previous working version. Use unit scale and place the station with clear space in front of you. The script creates a small tree and two grips inside the existing museum environment.

This is the minimal reconstruction of the fork interaction. The museum artifact additionally supplies the growth buttons, readout, large solid canopy and alternative branching settings. Our study uses two children and a fixed 35-degree turn. Its `generations` Inspector value sets the whole tree before running. Re-run to rebuild; the study does not add another set of museum controls.

## tree.gd

<!-- student-code:tree.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
@export_range(1, 4) var generations := 3
@export_range(0.4, 0.8) var ratio := 0.7
const TURN := PI * 35.0 / 180.0
var tree: Node3D
var first_forks: Array[Node3D] = []
var points: Array = []
var segment_count := 0

func _ready() -> void:
    tree = branch(0.7, clampi(generations, 1, 4))
    tree.position = Vector3(0, 0.60, 0)
    add_child(tree)
    for child in tree.get_children():
        if child.has_meta("length"):
            first_forks.append(child)
    for i in range(2):
        var point = PointBody.new()
        point.tint = Color("e99db8") if i == 0 else Color("25212a")
        add_child(point)
        points.append(point)
        park_point(i)

func branch(length: float, remaining: int) -> Node3D:
    var joint := Node3D.new()
    joint.set_meta("length", length)
    var line := LineSkin.new()
    joint.add_child(line)
    line.show_segment(Vector3.ZERO, Vector3.UP * length, length)
    segment_count += 1
    if remaining <= 0:
        return joint
    for sign_value in [-1.0, 1.0]:
        var child := branch(length * clampf(ratio, 0.4, 0.8), remaining - 1)
        child.position = Vector3.UP * length
        child.rotation.z = TURN * sign_value
        joint.add_child(child)
    return joint

func _process(_delta: float) -> void:
    for i in range(2):
        if points[i].held():
            var fork := first_forks[i]
            var parent: Node3D = fork.get_parent()
            var displacement := parent.to_local(points[i].global_position) - fork.position
            turn_fork(i, displacement)
        else:
            park_point(i)

func turn_fork(index: int, displacement: Vector3) -> void:
    if not displacement.is_finite() or displacement.length() < 0.001:
        return
    var horizontal := Vector3(displacement.x, 0, displacement.z)
    if horizontal.length() < 0.001:
        return
    var angle := clampf(atan2(horizontal.length(), displacement.y), deg_to_rad(12), deg_to_rad(65))
    var direction := Vector3.UP * cos(angle) + horizontal.normalized() * sin(angle)
    first_forks[index].basis = Basis(Quaternion(Vector3.UP, direction))

func park_point(index: int) -> void:
    var fork := first_forks[index]
    var tip := Vector3.UP * float(fork.get_meta("length"))
    points[index].global_position = fork.to_global(tip)
```

`branch()` makes a joint and draws one line upwards from it. It returns that joint, including anything attached below it. When `remaining` is zero, the visible branch is the last one: it gets no children. Here `generations` counts the generations **after the trunk**. Three gives 1 + 2 + 4 + 8 = 15 segments; four gives 31.

The two loop values give opposite turns. Each loop iteration calls `branch()` again with a shorter length and one fewer generation. The returned child is placed at the parent's tip, turned, then attached to that parent. Its children have already been made by the same rule. This is a depth-first construction: finish one subtree, then make its sibling.

Earlier, local and world coordinates described a point relative to a room. Here every child has a local position relative to its parent branch. `child.position = Vector3.UP * length` puts its origin at that parent's end. Moving or turning the parent carries the children through their existing attachments. The scene tree performs that inheritance; we do not recalculate every descendant in `_process()`.

The two grips control only the first fork. While one is held, we convert its world position into its branch parent's coordinates, subtract the attachment position and obtain a direction. `turn_fork()` aligns the branch's local Y axis to that direction. The quaternion line is a supplied alignment operation: it turns one axis towards another. Length is unchanged. The 12–65-degree limit keeps this particular hand study within a manageable arc; it is an interface choice, not a law of recursion. Pulling farther does not lengthen a branch.

On release, `park_point()` places the grip back at the represented endpoint. Its handle is an editing tool; it is not a free endpoint that stretches the branch. The other first fork has a different parented subtree, so turning one does not turn both.

## The familiar point — point_body.gd

This keeps the sphere, matching collider and frozen XRTools pickup construction from Point Lines. The radius is reduced to 8.5 cm for this small model. A material distinguishes the two grips. The small `held()` adapter also recognises the museum's existing desktop pickup and drop hooks. XR Tools still supplies the actual hand attachment; the tutorial does not rebuild the player.

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

## The same line skin — line_skin.gd

Keep this supplied renderer unchanged. The new work is the relationship between branches.

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

## Test a different tree

Set `generations` to 4. Predict 31 segments, then run. Turn the rose point out of the original plane. Follow one of its terminal twigs and compare it with a twig on the black side. The first must move; the second must stay. Release the point and check that no branch has gained length or lost its attachment.

Change `ratio` from 0.7 to 0.5 and run again. Predict which property changes and which stays: the tree reaches less far but still has 31 segments. This is the independent test of the lesson: distinguish a change in geometry from a change in the number of branches.

## Back at the large canopy

The museum source evaluates its branching rule through a queue of unfinished tips. GROW advances a complete generation; it does not use the depth-first call order of our small study. It also stores branch positions in one shared local frame. Its hand editor explicitly turns the selected branch records, their descendants and their pending tips. Our nested nodes make the same inheritance visible with less machinery. These are two implementations of the relation, not identical scripts or an exact geometric copy.

The small museum model and large canopy, however, really do share the source's branch records. Their scale differs; their branching decisions do not. ANGLE and LENGTH on the original desk change the whole rule and rebuild the specimen. The point grips make a local edit. Release both before using those controls or RESET.

Carry the bounded self-call onward. In Cantor Set, the next decision will be which part of an interval is retained, removed and passed to another call.
