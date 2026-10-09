extends Node3D

var rng := RandomNumberGenerator.new()
var seed_value := 42

func _ready() -> void:
	$Display.build(4, false)
	replay()

func replay() -> void:
	rng.seed = seed_value
	for cube in $Display.left:
		var a := rng.randf()
		var b := rng.randf()
		var c := rng.randf()
		var colour := Color(a, b, c)
		var material: StandardMaterial3D = cube.material_override
		material.albedo_color = colour
