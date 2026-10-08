extends RefCounted
## Exact state of the browser's 4 by 4 cells[x][z] study.
var cells: Array = []
var selected := Vector2i(1, 1)

func _init() -> void:
	reset()

func reset() -> void:
	cells.clear()
	for x in 4:
		cells.append([true, true, true, true])
	selected = Vector2i(1, 1)

func select_slot(x: int, z: int) -> bool:
	if x < 0 or x >= 4 or z < 0 or z >= 4:
		return false
	selected = Vector2i(x, z)
	return true

func next_slot() -> void:
	var slot := (selected.y * 4 + selected.x + 1) % 16
	select_slot(slot % 4, slot / 4)

func read_selected() -> bool:
	return cells[selected.x][selected.y]

func write_selected() -> void:
	cells[selected.x][selected.y] = not read_selected()

func checker() -> void:
	for x in 4:
		for z in 4:
			cells[x][z] = (x + z) % 2 == 0

func snapshot() -> Array:
	return cells.duplicate(true)
