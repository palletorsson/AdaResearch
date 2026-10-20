extends RefCounted
const Route = preload("route.gd")
const COUNT := 7
const SOURCE := 0
const SINK := 6
# One planning interval. Each integer is a number of crate slots.
var links: Array = [
	{"a": 0, "b": 1, "cap": 1}, {"a": 0, "b": 2, "cap": 1},
	{"a": 1, "b": 3, "cap": 1}, {"a": 1, "b": 4, "cap": 1},
	{"a": 2, "b": 3, "cap": 1}, {"a": 3, "b": 5, "cap": 1},
	{"a": 4, "b": 5, "cap": 1}, {"a": 5, "b": 6, "cap": 1},
]
var capacity: Array = []
var flow: Array = []
var path: Array[int] = []
var changes: Array = []
var total := 0
var done := false

func reset() -> void:
	capacity.clear()
	flow.clear()
	for i in range(COUNT):
		var row: Array[int] = []
		row.resize(COUNT)
		row.fill(0)
		capacity.append(row.duplicate())
		flow.append(row.duplicate())
	for link in links:
		capacity[link.a][link.b] += link.cap
	path.clear()
	changes.clear()
	total = 0
	done = false

func residual(a: int, b: int) -> int:
	return capacity[a][b] - flow[a][b]

func search() -> Array[int]:
	var walker = Route.new()
	walker.neighbours.clear()
	for a in range(COUNT):
		var row: Array[int] = []
		for b in range(COUNT):
			if residual(a, b) > 0:
				row.append(b)
		walker.neighbours.append(row)
	return walker.find_path(SOURCE, SINK, [])

func step() -> void:
	if done:
		return
	path = search()
	changes.clear()
	if path.is_empty():
		done = true
		return
	var amount: int = residual(path[0], path[1])
	for i in range(path.size() - 1):
		amount = mini(amount, residual(path[i], path[i + 1]))
	for i in range(path.size() - 1):
		var a: int = path[i]
		var b: int = path[i + 1]
		changes.append({"a": a, "b": b, "amount": amount, "undo": flow[a][b] < 0})
		flow[a][b] += amount
		flow[b][a] -= amount
	total += amount
