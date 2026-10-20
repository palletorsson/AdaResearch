extends Node3D
## Six copies of the hall's original prism, paired into three diamond modules.
## Fixed sculptural joints, not a claim that point contacts balance under gravity.
const Prism = preload("res://commons/primitives/prismes/prism_block.tscn")
const Kit = preload("geometry.gd")
const UNIT: float = 0.65
var pieces: Array[Node3D] = []

func _ready() -> void:
	for level in 3:
		for side in [-1, 1]:
			var piece: Node3D = Prism.instantiate()
			piece.name = "Wedge_%d_%d" % [level, side]
			piece.set_meta("sculpture_piece", true)
			piece.scale = Vector3.ONE * UNIT
			piece.rotation.z = -side * PI / 2.0
			# The source origin is on its base: rotating around it puts the
			# two original bases together at x=0, their apexes pointing out.
			piece.position = Vector3(0, (level + 0.5) * UNIT, 0)
			add_child(piece)
			pieces.append(piece)
	var plaque := Kit.label(self, "SAME WEDGE / ANOTHER ARRANGEMENT", Vector3(0, 0.012, -0.46), 19)
	plaque.rotation = Vector3(-PI / 2.0, 0, PI)

func get_museum_occupied_cells() -> Array:
	return [Vector2i.ZERO]
