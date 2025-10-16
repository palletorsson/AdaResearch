class_name Cell
extends RefCounted

enum CellType { EMPTY, STRUCTURE, FRONT_LEFT, FRONT_RIGHT, BACK_LEFT, BACK_RIGHT }

var position: Vector3i
var cell_type: CellType = CellType.EMPTY
var memory_type: CellType = CellType.EMPTY
var gradient: float = 0.0
var is_occupied: bool = false
var generation_born: int = 0

func _init(pos: Vector3i):
	position = pos

func set_occupied(type: CellType, gen: int):
	is_occupied = true
	cell_type = type
	memory_type = type
	generation_born = gen

func clear():
	is_occupied = false
	cell_type = CellType.EMPTY
