extends "study.gd"
const ANCHOR := Vector3(0, 2.8, 0)
var point = Point.new()
var rest_length := 1.0
var stiffness := 20.0 # N/m
var damping := 0.5 # kg/s
var tether: MeshInstance3D

func _ready() -> void:
    add_child(point)
    point.position = Vector3(0.5, 1.8, 0)
    point.gravity_scale = 1.0
    tether = rod()
    caption("Pull the point. Release it. The spring keeps its anchor.")

func spring_force(offset: Vector3, velocity: Vector3) -> Vector3:
    var length := offset.length()
    if length < 0.0001:
        return -damping * velocity
    return (offset / length * (length - rest_length) * stiffness
        - damping * velocity).limit_length(150.0)

func _physics_process(_delta: float) -> void:
    var offset: Vector3 = to_global(ANCHOR) - point.global_position
    if not point.is_picked_up():
        point.apply_central_force(spring_force(offset, point.linear_velocity))
    join(tether, point.position, ANCHOR)
