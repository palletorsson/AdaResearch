extends "study.gd"

var points: Array[RigidBody3D] = []
var masses: Array[float] = [1.0, 2.0]
var durations: Array[float] = [1.0, 2.0]
var remaining: Array[float] = [0.0, 0.0]
var start_positions: Array[Vector3] = []
var force := Vector3(0, 0, 1)
var reading: Label3D
var pulse_started := false
var snapshot_taken := false
var finish_distances: Array[float] = [0.0, 0.0]

func _ready() -> void:
    for i in range(2):
        var point = Point.new()
        add_child(point)
        point.position = Vector3(i * 1.2 - 0.6, 1.2, 0)
        point.mass = masses[i]
        points.append(point)
        start_positions.append(point.position)
    reading = caption("")
    button("START BOTH", Vector3(0, 1, -0.8), push)

func push() -> void:
    for i in range(2):
        remaining[i] = durations[i]
    pulse_started = true
    snapshot_taken = false

func _physics_process(delta: float) -> void:
    for i in range(2):
        var interval := minf(remaining[i], delta)
        var point = points[i]
        if interval > 0 and not point.is_picked_up():
            point.apply_central_force(global_basis * force * interval / delta)
        remaining[i] = maxf(0, remaining[i] - delta)

    var first_distance := (points[0].position - start_positions[0]).length()
    var second_distance := (points[1].position - start_positions[1]).length()
    if pulse_started and not snapshot_taken and remaining[0] == 0.0 and remaining[1] == 0.0:
        finish_distances[0] = first_distance
        finish_distances[1] = second_distance
        snapshot_taken = true

    reading.text = "1 kg / 2 kg; pushes 1 s / 2 s\nSPEED %.3f / %.3f m/s\nDISTANCE %.3f / %.3f m\nPUSH LEFT %.2f / %.2f s" % [
        points[0].linear_velocity.length(), points[1].linear_velocity.length(),
        first_distance, second_distance, remaining[0], remaining[1]]
    if snapshot_taken:
        reading.text += "\nAT BOTH PUSHES END %.3f / %.3f m" % [
            finish_distances[0], finish_distances[1]]
    else:
        reading.text += "\nEND DISTANCES waiting for both pushes"
