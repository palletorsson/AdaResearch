extends Node3D

const Look := preload("res://supplied/look.gd")

@export var seed_value := 1982   # the year of the Commodore 64

var columns := 6
var rows := 4
var cell := 1.1              # metres: one cell of the grid
var leans: Array[int] = []   # for each cell, in the order it was made: 1 or -1
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = seed_value
	var slab := BoxMesh.new()
	slab.size = Vector3(cell * sqrt(2.0), 2.0, 0.06)   # as long as the cell's diagonal
	slab.material = Look.paint(Look.BODY)
	for z in range(rows):
		for x in range(columns):
			var lean := rng.randi_range(0, 1) * 2 - 1   # 0 or 1, made into -1 or 1
			var wall := MeshInstance3D.new()
			wall.mesh = slab
			wall.position = Vector3((x + 0.5) * cell, 1.0, (z + 0.5) * cell)
			wall.rotation_degrees.y = 45.0 * lean
			add_child(wall)
			wall.create_trimesh_collision()
			leans.append(lean)
	print("seed ", rng.seed, ": ", leans.count(1), " walls lean one way, ", leans.count(-1), " the other")
