extends RefCounted
const SIDE := 20
const SUPPLY := 0.6
const ROOTS := [Vector2i(9, 10), Vector2i(14, 10)]
const RADIUS := 2
const FRACTION := 0.15
var cells: Array = []

func reset() -> void:
	cells.clear()
	for z in SIDE:
		var row: Array[float] = []
		row.resize(SIDE)
		row.fill(SUPPLY)
		cells.append(row)

func patch(root: Vector2i) -> Array[Vector2i]:
	var addresses: Array[Vector2i] = []
	for dz in range(-RADIUS, RADIUS + 1):
		for dx in range(-RADIUS, RADIUS + 1):
			var cell := root + Vector2i(dx, dz)
			if cell.x >= 0 and cell.x < SIDE and cell.y >= 0 and cell.y < SIDE:
				addresses.append(cell)
	return addresses

func consume(root: Vector2i) -> float:
	var uptake := 0.0
	for cell in patch(root):
		var available: float = cells[cell.y][cell.x]
		var take := minf(available * FRACTION, available)
		cells[cell.y][cell.x] -= take
		uptake += take
	return uptake
