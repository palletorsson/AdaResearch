extends Node3D
const BoxBody = preload("box_body.gd")

var cube := BoxBody.new()
var start := Vector3(0, 1.3, 0)
var rise := 0.35
var turn_speed := 45.0
var pulse := 0.2
var period := 4.0
var elapsed := 0.0

func _ready() -> void:
    assert(period > 0.0 and pulse >= 0.0 and pulse < 1.0)
    add_child(cube)
    cube.position = start

func _process(delta: float) -> void:
    elapsed += delta
    var t := pingpong(2.0 * elapsed / period + 0.5, 1.0)
    cube.position = start + Vector3.UP * lerpf(-rise, rise, t)
    cube.rotation_degrees.y = turn_speed * elapsed
    cube.scale = Vector3.ONE * lerpf(1.0 - pulse, 1.0 + pulse, t)
