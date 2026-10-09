extends "study.gd"
const COUNT := 7
const REST := 0.45
const DT := 1.0 / 60.0
var passes := 4
var positions: Array[Vector3] = []
var previous: Array[Vector3] = []
var points: Array[Node3D] = []
var links: Array[MeshInstance3D] = []
var readout: Label3D
var steps := 0

func _ready() -> void:
    for i in COUNT:
        points.append(make_point(Vector3.ZERO, i == 0 or i == COUNT - 1))
        if i > 0:
            links.append(rod())
    readout = caption("", Vector3(0, 2.3, 0))
    button("STEP", Vector3(-0.55, 1, -0.8), step_once)
    button("PASSES", Vector3(0, 1, -0.8), change_passes)
    button("RESET", Vector3(0.55, 1, -0.8), restart)
    restart()

func restart() -> void:
    positions.clear()
    for i in COUNT:
        positions.append(Vector3(-1.0 + 2.0 * i / (COUNT - 1), 1.7, 0))
        points[i].position = positions[i]
    previous = positions.duplicate()
    steps = 0
    redraw()

func change_passes() -> void:
    passes = 12 if passes == 1 else 1
    restart()

func step_once() -> void:
    for i in [0, COUNT - 1]:
        positions[i] = to_local(points[i].global_position)
        previous[i] = positions[i]
    for i in range(1, COUNT - 1):
        var here := positions[i]
        positions[i] += (here - previous[i]) * 0.99 + Vector3.DOWN * 3.0 * DT * DT
        previous[i] = here
    for pass_index in passes:
        for i in COUNT - 1:
            correct_pair(i, i + 1)
    steps += 1
    redraw()

func correct_pair(a: int, b: int) -> void:
    var d := positions[b] - positions[a]
    if d.length() < 0.00001:
        return
    var correction := d * (d.length() - REST) / d.length()
    var wa := 0.0 if a == 0 else 1.0
    var wb := 0.0 if b == COUNT - 1 else 1.0
    positions[a] += correction * wa / (wa + wb)
    positions[b] -= correction * wb / (wa + wb)

func worst_error() -> float:
    var worst := 0.0
    for i in COUNT - 1:
        worst = maxf(worst, absf(positions[i].distance_to(positions[i + 1]) / REST - 1))
    return worst

func redraw() -> void:
    for i in range(1, COUNT - 1):
        points[i].position = positions[i]
    for i in links.size():
        join(links[i], positions[i], positions[i + 1])
    readout.text = "%d passes | step %d\nWorst length error %.2f%%" % [passes, steps, worst_error() * 100]
