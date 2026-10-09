extends Node3D

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	$Display.build(1, false)
	replay()

func replay() -> void:
	var cube: MeshInstance3D = $Display.left[0]
	var material: StandardMaterial3D = cube.material_override
	var a := rng.randf()
	var b := rng.randf()
	var c := rng.randf()
	material.albedo_color = Color(a, b, c)
