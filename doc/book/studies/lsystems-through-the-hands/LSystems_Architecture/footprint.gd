extends RefCounted
const PITCH := 0.1
const DIRECTIONS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

func add_rectangle(target: Dictionary, low: Vector2, high: Vector2) -> void:
	for z in range(floori((low.y + 0.0001) / PITCH), ceili((high.y - 0.0001) / PITCH)):
		for x in range(floori((low.x + 0.0001) / PITCH), ceili((high.x - 0.0001) / PITCH)):
			target[Vector2i(x, z)] = true

func make(records: Dictionary, width: float, rooms_on: bool) -> Dictionary:
	var occupied := {}
	var room_cells := {}
	var addresses := {}
	for at in records.rooms: addresses[at] = true
	for ends in records.segments:
		var a: Vector2 = ends[0]
		var b: Vector2 = ends[1]
		add_rectangle(occupied, a.min(b) - Vector2.ONE * width / 2, a.max(b) + Vector2.ONE * width / 2)
	if rooms_on:
		for at in addresses:
			add_rectangle(room_cells, at - Vector2.ONE * 1.4, at + Vector2.ONE * 1.4)
		occupied.merge(room_cells)
	return {"occupied": occupied, "rooms": room_cells, "addresses": addresses,
		"floors": rectangles(occupied), "walls": boundaries(occupied, width)}

func boundaries(occupied: Dictionary, width: float) -> Array:
	var edges := {}
	for cell: Vector2i in occupied:
		for direction in DIRECTIONS:
			if occupied.has(cell + direction): continue
			var center := (Vector2(cell) + Vector2.ONE * 0.5 + Vector2(direction) * 0.5) * PITCH
			# Only the two main ends are doors; branch ends stay closed.
			if direction.x == 0 and absf(center.x) < width / 2 and (center.y >= width / 2 - 0.001 or center.y <= -8.0 - width / 2 + 0.001): continue
			var constant: int = cell.x + (1 if direction.x > 0 else 0) if direction.x != 0 else cell.y + (1 if direction.y > 0 else 0)
			var key := Vector3i(direction.x, direction.y, constant)
			if not edges.has(key): edges[key] = []
			edges[key].append(cell.y if direction.x != 0 else cell.x)
	var walls: Array = []
	for key: Vector3i in edges:
		var values: Array = edges[key]
		values.sort()
		var start: int = values[0]
		var previous := start
		for i in range(1, values.size() + 1):
			if i < values.size() and values[i] == previous + 1:
				previous = values[i]
				continue
			var length := (previous + 1 - start) * PITCH
			var middle := (start + previous + 1) * PITCH * 0.5
			var center := Vector3(key.z * PITCH + key.x * 0.05, 0.93, middle) if key.x != 0 else Vector3(middle, 0.93, key.z * PITCH + key.y * 0.05)
			var size := Vector3(0.1, 1.7, length) if key.x != 0 else Vector3(length, 1.7, 0.1)
			walls.append({"center": center, "size": size})
			if i < values.size(): start = values[i]; previous = start
	return walls

func rectangles(cells: Dictionary) -> Array[Rect2i]:
	var remaining := cells.duplicate(); var result: Array[Rect2i] = []
	while not remaining.is_empty():
		var origin: Vector2i = remaining.keys()[0]
		for key: Vector2i in remaining:
			if key.y < origin.y or (key.y == origin.y and key.x < origin.x): origin = key
		var width := 1
		while remaining.has(origin + Vector2i(width, 0)): width += 1
		var height := 1
		while true:
			var full := true
			for x in width:
				if not remaining.has(origin + Vector2i(x, height)): full = false; break
			if not full: break
			height += 1
		for z in height:
			for x in width: remaining.erase(origin + Vector2i(x,z))
		result.append(Rect2i(origin, Vector2i(width,height)))
	return result

