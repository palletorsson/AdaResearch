extends Node3D

var rng := RandomNumberGenerator.new()
var seed_value := 42

func _ready() -> void:
	$Display.build(4, true)
	replay()

func replay() -> void:
	colour_grid($Display.left, false)
	colour_grid($Display.right, true)

func colour_grid(cubes: Array[MeshInstance3D], skip_first: bool) -> void:
	rng.seed = seed_value
	if skip_first:
		rng.randf()
	for cube in cubes:
		var a := rng.randf()
		var b := rng.randf()
		var c := rng.randf()
		var colour := Color(a, b, c)
		var material: StandardMaterial3D = cube.material_override
		material.albedo_color = colour
