extends "traversal.gd"

var predecessor: Dictionary = {}

func _init() -> void:
	# Keep the previous tree; add one reciprocal connection for a detour.
	pass

func find_path(start: int, goal: int, blocked: Array[int]) -> Array[int]:
	restart(true)
	pending.clear()
	predecessor.clear()
	if start < 0 or start >= neighbours.size() or goal < 0 or goal >= neighbours.size():
		return []
	if start in blocked or goal in blocked:
		return []
	pending.append(start)
	predecessor[start] = -1
	while not pending.is_empty():
		var vertex: int = pending.pop_front()
		visited.append(vertex)
		if vertex == goal:
			break
		for other: int in neighbours[vertex]:
			if other not in blocked and not predecessor.has(other):
				predecessor[other] = vertex
				pending.append(other)
	if not predecessor.has(goal):
		return []
	var path: Array[int] = []
	var vertex := goal
	while vertex != -1:
		path.push_front(vertex)
		vertex = predecessor[vertex]
	return path
