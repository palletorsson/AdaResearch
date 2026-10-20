extends RefCounted
const Route = preload("route.gd")
# People 0,1; tools 2,3. All IDs are consecutive from zero.
var people: Array[int] = [0, 1]
var tools: Array[int] = [2, 3]
var links: Array = [[0, 2], [0, 3], [1, 2]]
var mate: Array[int] = []
var path: Array[int] = []
var removed: Array = []
var done := false

func reset() -> void:
	mate.resize(people.size() + tools.size())
	mate.fill(-1)
	path.clear()
	removed.clear()
	done = false

func pair(a: int, b: int) -> void:
	mate[a] = b
	mate[b] = a

func greedy(reverse_order: bool = false) -> void:
	reset()
	var scan := links.duplicate()
	if reverse_order:
		scan.reverse()
	for edge in scan:
		var a: int = edge[0]
		var b: int = edge[1]
		if mate[a] == -1 and mate[b] == -1:
			pair(a, b)

func alternating_path() -> Array[int]:
	var route = Route.new()
	var neighbours: Array = []
	for i in range(mate.size()):
		neighbours.append([])
	for edge in links:
		var a: int = edge[0]
		var b: int = edge[1]
		if mate[a] == b:
			neighbours[b].append(a)
		else:
			neighbours[a].append(b)
	route.neighbours = neighbours
	for person in people:
		if mate[person] != -1:
			continue
		for tool in tools:
			if mate[tool] == -1:
				var found: Array[int] = route.find_path(person, tool, [])
				if not found.is_empty():
					return found
	return []

func augment() -> bool:
	path = alternating_path()
	removed.clear()
	if path.is_empty():
		done = true
		return false
	# Remove old pairs first; then select the other edges of the path.
	for i in range(1, path.size() - 1, 2):
		var a: int = path[i]
		var b: int = path[i + 1]
		removed.append([a, b])
		mate[a] = -1
		mate[b] = -1
	for i in range(0, path.size() - 1, 2):
		pair(path[i], path[i + 1])
	done = false
	return true

func size() -> int:
	var count := 0
	for person in people:
		if mate[person] != -1:
			count += 1
	return count
