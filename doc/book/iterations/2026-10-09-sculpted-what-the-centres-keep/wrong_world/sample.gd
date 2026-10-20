extends RefCounted
const BODY_EDGE := 1.0
const EXTENT_FACTOR := 1.0
const DIRECTIONS := [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.UP,
	Vector3i.DOWN, Vector3i(0,0,1), Vector3i(0,0,-1)]
var centres: Array[Vector3] = []
var cells: Dictionary = {}
var origin := Vector3.ZERO
var cell_size := 0.5

func capture(frame: Node3D, bodies: Array) -> void:
	var positions: Array[Vector3] = []
	for body in bodies: positions.append(body.global_position)
	sample(positions, cell_size)

func sample(positions: Array, spacing: float) -> void:
	assert(spacing > 0.0)
	cell_size = spacing
	centres = []
	for p in positions: centres.append(p)
	cells.clear()
	origin = Vector3.ZERO
	if centres.is_empty(): return
	origin = centres[0]
	for p in centres: origin = origin.min(p)
	origin -= Vector3.ONE * BODY_EDGE
	var extent := ceili(BODY_EDGE * EXTENT_FACTOR / cell_size)
	for p in centres:
		var address := Vector3i(((p - origin) / cell_size).floor())
		for x in range(-extent, extent + 1):
			for y in range(-extent, extent + 1):
				for z in range(-extent, extent + 1):
					cells[address + Vector3i(x,y,z)] = true

func faces() -> Array:
	var result: Array = []
	for cell: Vector3i in cells:
		for direction: Vector3i in DIRECTIONS:
			if not cells.has(cell + direction):
				result.append([cell, direction])
	return result
