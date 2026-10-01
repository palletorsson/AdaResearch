extends Node3D

const Look := preload("res://supplied/look.gd")

var columns := 12    # cubes along the walk, left to right
var rows := 5        # cubes across it
var spacing := 0.6   # metres from one cube's middle to the next: a gap of 0.1 m

func _ready() -> void:
	var part: PackedScene = load("res://borrowed/cube_part.tscn")
	var paint := Look.paint(Look.BODY)
	for x in range(columns):
		for z in range(rows):
			var cube: MeshInstance3D = part.instantiate()
			cube.material_override = paint
			cube.position = Vector3(x * spacing, 0.25, z * spacing)
			add_child(cube)
	print(get_child_count(), " cubes in order")
