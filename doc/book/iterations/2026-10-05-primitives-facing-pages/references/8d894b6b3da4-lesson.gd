extends Node3D
const ResolutionPoint = preload("resolution_point.gd")
var point := ResolutionPoint.new()
var comparison := ResolutionPoint.new()
var message := Label3D.new()

func _ready() -> void:
    point.position = Vector3(-0.3, 1.12, 0)
    comparison.position = Vector3(0.3, 1.12, 0)
    add_child(point)
    add_child(comparison)
    add_child(message)
    message.position = Vector3(0, 1.65, 0)
    message.pixel_size = 0.002

func _process(delta: float) -> void:
    point.advance(delta)
    comparison.advance(delta)
    if Input.is_action_just_pressed("ui_accept"):
        point.reset_resolution()
        comparison.reset_resolution()
    message.text = "RINGS %d   SEGMENTS %d" % [point.sphere.rings, point.sphere.radial_segments]
