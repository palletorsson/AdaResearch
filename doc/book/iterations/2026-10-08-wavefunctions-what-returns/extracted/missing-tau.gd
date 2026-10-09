extends Node3D

@export var amplitude := 0.4
@export var frequency := 0.5
@export var phase := 0.0
var centre := Vector3(0, 1.3, 0)
var elapsed := 0.0
var cube := MeshInstance3D.new()
var label := Label3D.new()

func _ready() -> void:
    assert(amplitude >= 0.0 and frequency >= 0.0)
    cube.mesh = BoxMesh.new()
    cube.scale = Vector3.ONE * 0.4
    add_child(cube)
    label.position = centre + Vector3(0, 0.8, 0)
    label.font_size = 36
    label.pixel_size = 0.0025
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(label)
    draw_state()

func _process(delta: float) -> void:
    elapsed += delta
    draw_state()

func height_at(seconds: float) -> float:
    return centre.y + amplitude * sin(frequency * seconds + phase)

func draw_state() -> void:
    cube.position = Vector3(centre.x, height_at(elapsed), centre.z)
    label.text = "time %.2f s   height %.2f m\nA %.2f m   f %.2f Hz   phase %.2f rad" % [
        elapsed, cube.position.y, amplitude, frequency, phase]
