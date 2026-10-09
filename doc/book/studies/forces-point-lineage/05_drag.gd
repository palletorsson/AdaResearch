extends "study.gd"
var point = Point.new()
var coefficient := 0.6 # kg/m, chosen for this quadratic model
var released := false

func _ready() -> void:
    point.position = Vector3(0, 3, 0)
    add_child(point)
    point.freeze = true
    point.gravity_scale = 1.0
    caption("DROP · one point, one resistance coefficient")
    button("DROP", Vector3(0, 1, -0.8), drop)

func drop() -> void:
    point.freeze = false
    point.sleeping = false
    released = true

func resistance(velocity: Vector3, mass_kg: float, delta: float) -> Vector3:
    var force := -coefficient * velocity.length() * velocity
    return force.limit_length(mass_kg * velocity.length() / delta)

func _physics_process(delta: float) -> void:
    if not released or point.is_picked_up():
        return
    if point.position.y >= 0 and point.position.y <= 2.0:
        point.apply_central_force(resistance(point.linear_velocity, point.mass, delta))
