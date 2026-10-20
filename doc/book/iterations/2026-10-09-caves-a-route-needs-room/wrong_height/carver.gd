extends RefCounted
const SIZE := Vector3i(7, 4, 7)
const RADIUS := 1
const HEADROOM := 2
var solid := PackedByteArray()
var history: Array[Vector3i] = []

func reset() -> void:
	solid.resize(SIZE.x * SIZE.y * SIZE.z)
	solid.fill(1)
	history.clear()

func inside(p: Vector3i) -> bool:
	return p.x >= 0 and p.x < SIZE.x and p.y >= 0 and p.y < SIZE.y and p.z >= 0 and p.z < SIZE.z

func index(p: Vector3i) -> int:
	return (p.y * SIZE.z + p.z) * SIZE.x + p.x

func carve(center: Vector3i) -> void:
	history.append(center)
	for dy in HEADROOM + 1:
		for dz in range(-RADIUS, RADIUS + 1):
			for dx in range(-RADIUS, RADIUS + 1):
				var p := center + Vector3i(dx, dy, dz)
				if inside(p) and Vector2i(dx, dz).length() <= RADIUS:
					solid[index(p)] = 0

func air_count() -> int:
	return solid.count(0)
