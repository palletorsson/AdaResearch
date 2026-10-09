# Keep the board's material; change one light's colour or aim.
extends Node3D

var beam_colour := Color(1, 0, 0)
var first_target := Vector3(0, 2, 0)
var board: MeshInstance3D
var surface: StandardMaterial3D
var first_light: SpotLight3D
var second_light: SpotLight3D

func _ready() -> void:
    board = MeshInstance3D.new()
    var shape := BoxMesh.new()
    shape.size = Vector3(4.4, 2.4, 0.12)
    board.mesh = shape
    board.position = Vector3(0, 1.5, 0)
    surface = StandardMaterial3D.new()
    surface.albedo_color = Color(0.9, 0.9, 0.9)
    surface.roughness = 1.0
    board.material_override = surface
    add_child(board)

    first_light = make_light(beam_colour, Vector3(-1, 1.5, 2.5), first_target)
    second_light = make_light(Color(0, 1, 0), Vector3(1, 1.5, 2.5), Vector3(1, 1.5, 0))

func make_light(colour: Color, at: Vector3, target: Vector3) -> SpotLight3D:
    var lamp := SpotLight3D.new()
    lamp.light_color = colour
    lamp.light_energy = 2.5
    lamp.spot_range = 6.0
    lamp.spot_angle = 18.0
    lamp.shadow_enabled = true
    lamp.position = at
    add_child(lamp)
    lamp.look_at(to_global(target))
    return lamp
