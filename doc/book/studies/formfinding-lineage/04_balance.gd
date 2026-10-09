extends "study.gd"
var masses := Vector2(1, 2)
var span := 2.0
var distances := Vector2.ZERO
var points: Array[Node3D] = []
var arm: MeshInstance3D
var wire: MeshInstance3D
var readout: Label3D

func _ready() -> void:
    points = [make_point(Vector3.ZERO, false), make_point(Vector3.ZERO, false)]
    arm = rod()
    wire = rod()
    readout = caption("", Vector3(0, 2.4, 0))
    button("LEFT MASS", Vector3(0, 1, -0.8), change_mass)
    rebuild()

func change_mass() -> void:
    masses.x = 4.0 if masses.x == 1 else 1.0
    rebuild()

func rebuild() -> void:
    assert(masses.x > 0 and masses.y > 0 and span > 0)
    distances = Vector2(span * masses.y, span * masses.x) / (masses.x + masses.y)
    points[0].position = Vector3(-distances.x, 1.5, 0)
    points[1].position = Vector3(distances.y, 1.5, 0)
    join(arm, points[0].position, points[1].position)
    join(wire, Vector3(0, 1.5, 0), Vector3(0, 2.15, 0))
    readout.text = "%.1f kg / %.1f kg | arms %.3f / %.3f m\nmass x arm: %.3f / %.3f kg m\nCalculated pose; massless arm" % [
        masses.x, masses.y, distances.x, distances.y,
        masses.x * distances.x, masses.y * distances.y]
