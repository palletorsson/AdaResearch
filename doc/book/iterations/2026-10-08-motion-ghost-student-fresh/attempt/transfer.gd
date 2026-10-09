extends "study.gd"

var point = Point.new()
var force := Vector3(0, 0, 1)
var duration := 3.0
var remaining := 0.0
var start_position := Vector3(0, 1.2, 0)
var reading: Label3D

func _ready() -> void:
    add_child(point)
    point.position = start_position
    point.mass = 3.0
    reading = caption("")
    button("PUSH 3 s", Vector3(0, 1, -0.8), push)

func push() -> void:
    remaining = duration

func _physics_process(delta: float) -> void:
    var interval := minf(remaining, delta)
    if interval > 0 and not point.is_picked_up():
        point.apply_central_force(global_basis * force * interval / delta)
    remaining = maxf(0, remaining - delta)
    reading.text = "3 kg; 1 N for 3 s\nSPEED %.3f m/s\nDISTANCE %.3f m\nPUSH LEFT %.2f s" % [
        point.linear_velocity.length(), (point.position - start_position).length(), remaining]
