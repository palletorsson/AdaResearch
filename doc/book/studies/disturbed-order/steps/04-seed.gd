extends Node3D

const Look := preload("res://supplied/look.gd")

var columns := 12    # cubes along the walk, left to right
var rows := 5        # cubes across it
var spacing := 0.6   # metres from one cube's middle to the next: a gap of 0.1 m
var amplitude := 20.0   # degrees: the most a cube may turn
var seed_value := 1968
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = seed_value
	var part: PackedScene = load("res://borrowed/cube_part.tscn")
	var paint := Look.paint(Look.BODY)
	for x in range(columns):
		var amount := float(x) / (columns - 1)          # 0 in the first column, 1 in the last
		var turn := deg_to_rad(amplitude) * amount      # the most a cube of this column may turn
		var slide := 0.25 * amplitude / 90.0 * amount   # and the most it may slide, in metres
		for z in range(rows):
			var cube: MeshInstance3D = part.instantiate()
			cube.material_override = paint
			cube.position = Vector3(x * spacing, 0.25, z * spacing)
			cube.position += Vector3(rng.randf_range(-slide, slide), 0.0, rng.randf_range(-slide, slide))
			cube.rotation = Vector3(rng.randf_range(-turn, turn), rng.randf_range(-turn, turn), rng.randf_range(-turn, turn))
			add_child(cube)
	print("seed ", rng.seed, ", amplitude ", amplitude, ": the last cube turned ", get_child(-1).rotation_degrees.snappedf(0.1))
