extends "study.gd"
const Landscape = preload("landscape.gd")
var rng := RandomNumberGenerator.new()
var current := Vector2(2, 0)
var best := current
var temperature := 0.5
var cooling := 0.98
var attempts := 0
var status := "READY"
var point: Node3D
var best_point: Node3D
var readout: Label3D

func _ready() -> void:
    landscape_surface(true)
    point = make_point(Vector3.ZERO, false)
    best_point = make_point(Vector3.ZERO, false)
    point.scale = Vector3.ONE * 0.45
    best_point.scale = Vector3.ONE * 0.3
    readout = caption("", Vector3(0, 2.1, 0))
    button("PROPOSE", Vector3(-0.3, 1, -1.65), step_once)
    button("RESET", Vector3(0.3, 1, -1.65), restart)
    restart()

func restart() -> void:
    rng.seed = 7
    current = Vector2(2, 0)
    best = current
    temperature = 0.5
    attempts = 0
    status = "READY"
    refresh()

func accepts(change: float, draw: float) -> bool:
    return change <= 0 or (temperature > 0 and draw < exp(-change / temperature))

func step_once() -> void:
    if temperature < 0.01 or attempts >= 240:
        status = "STOPPED"
        refresh()
        return
    var candidate := current + Vector2(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5))
    var draw := rng.randf()
    status = "OUTSIDE"
    if absf(candidate.x) <= 3 and absf(candidate.y) <= 3:
        var change := Landscape.cost(candidate, true) - Landscape.cost(current, true)
        status = "REJECTED"
        if accepts(change, draw):
            current = candidate
            status = "ACCEPTED"
            if Landscape.cost(current, true) < Landscape.cost(best, true):
                best = current
    attempts += 1
    temperature *= cooling
    refresh()

func refresh() -> void:
    point.position = Landscape.plot(current, true)
    best_point.position = Landscape.plot(best, true) + Vector3.UP * 0.12
    readout.text = "%s | attempt %d | T %.3f\nCurrent %.3f / best %.3f\nSmall raised point keeps the best address" % [status, attempts,
        temperature, Landscape.cost(current, true), Landscape.cost(best, true)]
