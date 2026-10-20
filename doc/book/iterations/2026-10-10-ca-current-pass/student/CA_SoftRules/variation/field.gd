extends RefCounted
const N := 32
const FEED := 0.037
const KILL := 0.060
var u := PackedFloat32Array()
var v := PackedFloat32Array()
var exchange := true
var ticks := 0

func _init() -> void:
	u.resize(N * N)
	v.resize(N * N)
	reset()

func index(x: int, y: int) -> int:
	return posmod(y, N) * N + posmod(x, N)

func reset() -> void:
	u.fill(1.0)
	v.fill(0.0)
	ticks = 0
	for y in range(13, 19):
		for x in range(13, 19):
			u[index(x, y)] = 0.5
			v[index(x, y)] = 0.25

func seed_at(site: Vector2i) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			u[index(site.x + dx, site.y + dy)] = 0.7
			v[index(site.x + dx, site.y + dy)] = 0.1

func laplacian(values: PackedFloat32Array, x: int, y: int) -> float:
	return values[index(x - 1, y)] + values[index(x + 1, y)] + values[index(x, y - 1)] + values[index(x, y + 1)] - 4.0 * values[index(x, y)]

func next_pair(a: float, b: float, lap_u: float, lap_v: float) -> Vector2:
	# Supplied Grayâ€“Scott model. One numerical step has dt = 1.
	var coupling := 1.0 if exchange else 0.0
	var uvv := a * b * b
	return Vector2(
		clampf(a + coupling * 0.16 * lap_u - uvv + FEED * (1.0 - a), 0.0, 1.0),
		clampf(b + coupling * 0.08 * lap_v + uvv - (KILL + FEED) * b, 0.0, 1.0)
	)

func step() -> void:
	var next_u := PackedFloat32Array()
	var next_v := PackedFloat32Array()
	next_u.resize(N * N)
	next_v.resize(N * N)
	for y in N:
		for x in N:
			var i := index(x, y)
			var answer := next_pair(u[i], v[i], laplacian(u, x, y), laplacian(v, x, y))
			next_u[i] = answer.x
			next_v[i] = answer.y
	u = next_u
	v = next_v
	ticks += 1
