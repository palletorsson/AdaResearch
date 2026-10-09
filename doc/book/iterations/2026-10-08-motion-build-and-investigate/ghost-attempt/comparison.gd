extends "study.gd"

var points: Array[RigidBody3D] = []
var start_positions: Array[Vector3] = []
var masses: Array[float] = [1.0, 2.0]
var durations: Array[float] = [1.0, 2.0]
var remaining: Array[float] = [0.0, 0.0]
var distances: Array[float] = [0.0, 0.0]
var started := false
var snapshot_taken := false
var force := Vector3(0, 0, 1)
var reading: Label3D

func _ready() -> void:
    for i in range(2):
        var point = Point.new()
        point.position = Vector3(i * 2 - 1, 1.2, 0)
        point.mass = masses[i]
        add_child(point)
        points.append(point)
        start_positions.append(point.position)
    reading = caption("")
    button("PUSH 1 s / 2 s", Vector3(0, 1, -0.8), push)

func push() -> void:
    started = true
    snapshot_taken = false
    for i in range(2):
        remaining[i] = durations[i]

func _physics_process(delta: float) -> void:
    for i in range(2):
        var point = points[i]
        var interval := minf(remaining[i], delta)
        if interval > 0 and not point.is_picked_up():
            point.apply_central_force(global_basis * force * interval / delta)
        remaining[i] = maxf(0, remaining[i] - delta)
    if not snapshot_taken:
        for i in range(2):
            distances[i] = (points[i].position - start_positions[i]).length()
        if started and remaining[0] == 0.0 and remaining[1] == 0.0:
            snapshot_taken = true
    var distance_heading := "DISTANCE FROM START (LIVE)"
    if snapshot_taken:
        distance_heading = "DISTANCE WHEN BOTH PUSHES ENDED"
    reading.text = distance_heading + "\n1 kg / 1 s: %.2f m/s, %.2f m\n2 kg / 2 s: %.2f m/s, %.2f m" % [
        points[0].linear_velocity.length(),
        distances[0],
        points[1].linear_velocity.length(),
        distances[1]]
