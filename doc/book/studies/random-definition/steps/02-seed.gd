extends Node3D

var rng := RandomNumberGenerator.new()
var seed_value := 42

func _ready() -> void:
	$Display.build(1, false)
	replay()

func replay() -> void:
	rng.seed = seed_value
	var cube: MeshInstance3D = $Display.left[0]
	var material: StandardMaterial3D = cube.material_override
	var a := rng.randf()
	var b := rng.randf()
	var c := rng.randf()
	material.albedo_color = Color(a, b, c)
