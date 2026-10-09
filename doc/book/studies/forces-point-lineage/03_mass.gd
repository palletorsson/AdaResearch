extends "study.gd"
var points: Array[RigidBody3D] = []
var force := Vector3(0, 0, 1) # newtons in the study frame
var remaining := 0.0
var reading: Label3D

func _ready() -> void:
    for i in range(3):
        var point = Point.new()
        add_child(point)
        point.position = Vector3(i - 1, 1.2, 0)
        point.mass = pow(2.0, i)
        points.append(point)
    reading = caption("")
    button("PUSH 1 s", Vector3(0, 1, -0.8), push)

func push() -> void:
    remaining = 1.0

func _physics_process(delta: float) -> void:
    var interval := minf(remaining, delta)
    for point in points:
        if interval > 0 and not point.is_picked_up():
            point.apply_central_force(global_basis * force * interval / delta)
    remaining = maxf(0, remaining - delta)
    reading.text = "1 / 2 / 4 kg\n%.2f / %.2f / %.2f m/s" % [
        points[0].linear_velocity.length(), points[1].linear_velocity.length(),
        points[2].linear_velocity.length()]

