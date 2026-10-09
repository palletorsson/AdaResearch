extends "study.gd"
var point = Point.new()
var reading: Label3D

func _ready() -> void:
    add_child(point)
    point.position = Vector3(2, 1.2, 0)
    point.linear_velocity = global_basis * Vector3(0, 0, 1.8)
    reading = caption("")

func sample(p: Vector3) -> Vector3:
    var flat := Vector3(p.x, 0, p.z)
    if flat.length() < 0.05:
        return Vector3.ZERO
    var tangent := Vector3(-flat.z, 0, flat.x).normalized()
    return -flat * 0.65 + tangent * 2.8 # m/s²

func _physics_process(_delta: float) -> void:
    var acceleration := global_basis * sample(point.position)
    if not point.is_picked_up():
        point.apply_central_force(point.mass * acceleration)
    reading.text = "at %s m\nacceleration %s m/s²" % [point.position, acceleration]

