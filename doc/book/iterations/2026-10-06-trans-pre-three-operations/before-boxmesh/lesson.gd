extends Node3D
const CubeBody = preload("cube_body.gd")

var cube := CubeBody.new()
var start := Vector3(0, 1, 0)
var turn_degrees := 0.0
var size_factor := 1.0
var rise := 0.0
var duration := 2.0
var elapsed := 0.0

func _ready() -> void:
    assert(duration > 0.0 and size_factor > 0.0)
    add_child(cube)
    cube.position = start
    cube.rotation_degrees.y = turn_degrees
    cube.scale = Vector3.ONE * size_factor

func _process(delta: float) -> void:
    elapsed += delta
    var t: float = minf(elapsed / duration, 1.0)
    cube.position = start + Vector3.UP * rise * t
