extends RefCounted
const SIZE := 6
const OFFSETS := [Vector3i(1,0,0), Vector3i(-1,0,0),
	Vector3i(0,1,0), Vector3i(0,-1,0), Vector3i(0,0,1), Vector3i(0,0,-1), Vector3i(1,1,1), Vector3i(-1,-1,-1)]
var occupied: Dictionary = {}
var sources: Dictionary = {}
var reached: Dictionary = {}
var generation := 0

func contact(corner: bool) -> void:
	var a := Vector3i(2,1,2)
	var b := Vector3i(3,2,3) if corner else Vector3i(3,1,2)
	occupied = {a:true, b:true}
	sources = {a:true}
	restart()

func lattice(cutoff: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	occupied = {}; sources = {}
	for x in SIZE:
		for y in SIZE:
			for z in SIZE:
				if rng.randf() < cutoff: occupied[Vector3i(x,y,z)] = true
	for x in SIZE:
		for y in SIZE:
			var cell := Vector3i(x,y,SIZE-1)
			occupied[cell] = true
			sources[cell] = true
	restart()

func restart() -> void:
	reached = sources.duplicate()
	generation = 0

func step() -> int:
	if generation >= 64: return 0
	var next := reached.duplicate()
	for cell: Vector3i in occupied:
		if reached.has(cell): continue
		for offset: Vector3i in OFFSETS:
			if reached.has(cell + offset):
				next[cell] = true
				break
	var added := next.size() - reached.size()
	reached = next
	generation += 1
	return added

func far_count() -> int:
	var count := 0
	for cell: Vector3i in reached:
		if cell.z == 0: count += 1
	return count
