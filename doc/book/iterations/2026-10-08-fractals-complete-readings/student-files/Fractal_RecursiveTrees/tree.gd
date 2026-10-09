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
