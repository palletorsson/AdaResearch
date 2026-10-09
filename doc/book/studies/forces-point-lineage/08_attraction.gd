extends "study.gd"
var a = Point.new()
var b = Point.new()
var strength := 4.0 # m³ / (kg s²), an authored model value
var softening := 1.2 # metres

func _ready() -> void:
    add_child(a)
    add_child(b)
    a.position = Vector3(-1.5, 1.2, 0)
    b.position = Vector3(1.5, 1.2, 0)
    a.linear_velocity = global_basis * Vector3(0, 0, 0.6)
    b.linear_velocity = -a.linear_velocity
    for point in [a, b]:
        point.mass = 2.0
        point.collision_layer = 0
        point.collision_mask = 0
    caption("Two sources. Neither is fixed.")

func pair_force(displacement: Vector3) -> Vector3:
    var denominator := pow(displacement.length_squared() + softening * softening, 1.5)
    return displacement * strength * a.mass * b.mass / denominator

func _physics_process(_delta: float) -> void:
    var force := pair_force(b.global_position - a.global_position)
    a.apply_central_force(force)
    b.apply_central_force(-force)

