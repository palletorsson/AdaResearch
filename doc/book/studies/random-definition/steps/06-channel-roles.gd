extends Node3D

var rng := RandomNumberGenerator.new()
var seed_value := 42

func _ready() -> void:
	$Display.build(4, true)
	replay()

func replay() -> void:
	colour_grid($Display.left, false)
	colour_grid($Display.right, true)

func colour_grid(cubes: Array[MeshInstance3D], swap_channels: bool) -> void:
	rng.seed = seed_value
	for cube in cubes:
		var a := rng.randf()
		var b := rng.randf()
		var c := rng.randf()
		var colour := Color(a, b, c)
		if swap_channels:
			colour = Color(c, b, a)
		var material: StandardMaterial3D = cube.material_override
		material.albedo_color = colour
