extends "study.gd"
var sag := 0.5
var ends: Array[Node3D] = []
var segments: Array[MeshInstance3D] = []
var curve := Curve3D.new()
var readout: Label3D

func _ready() -> void:
    ends = [make_point(Vector3(-1, 1.6, 0)), make_point(Vector3(1, 1.6, 0))]
    for i in 24:
        segments.append(rod())
    readout = caption("", Vector3(0, 2.15, 0))
    button("SAG", Vector3(0, 1, -0.8), change_sag)
    rebuild()

func change_sag() -> void:
    sag = 0.8 if sag < 0.8 else 0.0
    rebuild()

func _process(_delta: float) -> void:
    rebuild()

func rebuild() -> void:
    var a := to_local(ends[0].global_position)
    var b := to_local(ends[1].global_position)
    var span := a.distance_to(b)
    var drop := Vector3.DOWN * sag * span * 0.5
    curve.clear_points()
    curve.add_point(a, Vector3.ZERO, (b - a) * 0.3 + drop)
    curve.add_point(b, (a - b) * 0.3 + drop, Vector3.ZERO)
    for i in segments.size():
        var t := float(i) / segments.size()
        var next_t := float(i + 1) / segments.size()
        join(segments[i], curve.sample(0, t), curve.sample(0, next_t))
    readout.text = "DRAWN SAG %.2f | span %.2f m\nMove either point" % [sag, span]
