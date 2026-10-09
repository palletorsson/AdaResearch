extends "study.gd"
var points: Array[RigidBody3D] = []
var arms: Array[MeshInstance3D] = []
var angles := [0.0, 0.0]
var rates := [TAU / 6.0, TAU / 6.0]
var reading: Label3D

func _ready() -> void:
    for i in range(2):
        var point = Point.new()
        add_child(point)
        point.freeze = true
        point.enabled = false
        point.collision_layer = 0
        point.collision_mask = 0
        points.append(point)
        arms.append(rod())
    reading = caption("")
    button("OFFSET", Vector3(-0.5, 1, -0.8), offset)
    button("DRIFT", Vector3(0.5, 1, -0.8), drift)

func offset() -> void:
    angles[1] += PI / 4.0

func drift() -> void:
    rates[1] = TAU / 6.0 * 1.04

func _process(delta: float) -> void:
    for i in range(2):
        angles[i] = fposmod(angles[i] + rates[i] * delta, TAU)
        var pivot := Vector3(i * 1.6 - 0.8, 1.3, 0)
        points[i].position = pivot + Vector3(sin(angles[i]), cos(angles[i]), 0) * 0.6
        join(arms[i], pivot, points[i].position)
    reading.text = "gap %.1f degrees · prescribed position" % rad_to_deg(
        fposmod(angles[1] - angles[0], TAU))

