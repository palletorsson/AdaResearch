extends "study.gd"
const Landscape = preload("landscape.gd")
var address := Vector2(-2.8, -2)
var rate := 0.7
var tolerance := 0.08
var valleys := false
var steps := 0
var status := "READY"
var point: Node3D
var readout: Label3D
var terrain: MeshInstance3D

func _ready() -> void:
    terrain = landscape_surface(valleys)
    point = make_point(Vector3.ZERO, false)
    point.scale = Vector3.ONE * 0.45
    readout = caption("", Vector3(0, 2.0, 0))
    button("STEP", Vector3(-0.55, 1, -1.65), step_once)
    button("RESET", Vector3(0, 1, -1.65), restart)
    button("SURFACE", Vector3(0.55, 1, -1.65), change_surface)
    refresh()

func step_once() -> void:
    if status not in ["READY", "STEPPING"]:
        return
    var slope := Landscape.gradient(address, valleys)
    if steps >= 160:
        status = "STEP LIMIT"
    elif slope.length() < tolerance:
        status = "SMALL SLOPE"
    else:
        var proposed := address - rate * slope
        if absf(proposed.x) > 3 or absf(proposed.y) > 3:
            status = "LEFT FRAME"
        else:
            address = proposed
            steps += 1
            status = "STEPPING"
    refresh()

func restart() -> void:
    address = Vector2(-2.8, -2)
    steps = 0
    status = "READY"
    refresh()

func change_surface() -> void:
    valleys = not valleys
    terrain.queue_free()
    terrain = landscape_surface(valleys)
    restart()

func refresh() -> void:
    point.position = Landscape.plot(address, valleys)
    readout.text = "%s | step %d\nx %.2f  z %.2f | cost %.3f" % [status, steps,
        address.x, address.y, Landscape.cost(address, valleys)]
