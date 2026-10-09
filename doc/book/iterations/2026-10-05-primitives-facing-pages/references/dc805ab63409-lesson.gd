extends Node3D
const Sweep = preload("profile_sweep.gd")
const FONT = preload("JetBrainsMono-Medium.ttf")
const WIDTH := 1.4
const DEPTH := 1.6
const OFFSET := 0.5
var section: Dictionary
var frames: Array[Transform3D] = []
var body := MeshInstance3D.new()

func _ready() -> void:
    section = Sweep.profile(FONT, "O")
    for i in range(5):
        var fraction := i / 4.0
        var at := Vector3(OFFSET * fraction, 1.1, DEPTH * fraction)
        var frame := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * WIDTH), at)
        frames.append(frame)
    body.mesh = Sweep.make(section, frames)
    var finish := StandardMaterial3D.new()
    finish.albedo_color = Color(0.78, 0.62, 0.72)
    finish.roughness = 0.4
    body.material_override = finish
    add_child(body)
