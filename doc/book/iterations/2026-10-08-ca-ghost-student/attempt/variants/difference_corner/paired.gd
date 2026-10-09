extends RefCounted
const N := 11
const COUNT := N * N * N
const LIMIT := 100
var site := Vector3i(0, 0, 0)
var a := PackedFloat64Array()
var b := PackedFloat64Array()
var neighbours: Array[PackedInt32Array] = []
var tick := 0
var pull := 0.25
var drive := 0.0
var integer_storage := true
var scattered := false
var changed := true

func _init() -> void:
	for z in N:
		for y in N:
			for x in N:
				var ns := PackedInt32Array()
				for dz in range(-1, 2):
					for dy in range(-1, 2):
						for dx in range(-1, 2):
							if dx == 0 and dy == 0 and dz == 0:
								continue
							var p := Vector3i(x + dx, y + dy, z + dz)
							if p.x >= 0 and p.x < N and p.y >= 0 and p.y < N and p.z >= 0 and p.z < N:
								ns.append(index(p))
				neighbours.append(ns)
	reset()

func index(p: Vector3i) -> int:
	return p.x + N * p.y + N * N * p.z

func reset() -> void:
	tick = 0
	a.resize(COUNT)
	for i in COUNT:
		a[i] = float((i * 73 + i * i * 19 + 17) % 10) if scattered else 4.0
	b = a.duplicate()
	if changed:
		b[index(site)] += 1.0

func sample(i: int, generation: int) -> float:
	var h: int = ((i + 1) * 73856093 + (generation + 1) * 19349663 + 83492791) % 2147483647
	h = (h * 48271) % 2147483647
	return float(h % 2001) / 1000.0 - 1.0

func step() -> void:
	if tick >= LIMIT:
		return
	var na := PackedFloat64Array()
	var nb := PackedFloat64Array()
	na.resize(COUNT)
	nb.resize(COUNT)
	for i in COUNT:
		var sa := 0.0
		var sb := 0.0
		for j in neighbours[i]:
			sa += a[j]
			sb += b[j]
		var forcing := drive * sample(i, tick)
		var va := clampf(a[i] * (1.0 - pull) + sa / neighbours[i].size() * pull + forcing, 0.0, 9.0)
		var vb := clampf(b[i] * (1.0 - pull) + sb / neighbours[i].size() * pull + forcing, 0.0, 9.0)
		na[i] = float(int(va)) if integer_storage else va
		nb[i] = float(int(vb)) if integer_storage else vb
	a = na
	b = nb
	tick += 1

func report() -> Dictionary:
	var count := 0
	var maximum := 0.0
	var total := 0.0
	for i in COUNT:
		var difference := absf(a[i] - b[i])
		maximum = maxf(maximum, difference)
		total += difference
		if difference > 0.000001:
			count += 1
	return {"count": count, "maximum": maximum, "mean": total / COUNT}
