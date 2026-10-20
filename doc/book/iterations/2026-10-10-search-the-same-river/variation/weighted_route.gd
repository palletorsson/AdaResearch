extends "route.gd"
## Continue the same adjacency, predecessor record and route reconstruction.
var costs: Dictionary = {}

func find_weighted_path(start: int, goal: int, blocked: Array[int], places: Array[Vector3], use_estimate: bool) -> Array[int]:
	restart(true)
	pending.clear()
	predecessor.clear()
	costs.clear()
	if places.size() != neighbours.size():
		return []
	if start < 0 or start >= neighbours.size() or goal < 0 or goal >= neighbours.size():
		return []
	if start in blocked or goal in blocked:
		return []
	pending.append(start)
	predecessor[start] = -1
	costs[start] = 0.0
	while not pending.is_empty():
		var best := 0
		for i in range(1, pending.size()):
			if priority(pending[i], goal, places, use_estimate) < priority(pending[best], goal, places, use_estimate):
				best = i
		var vertex: int = pending.pop_at(best)
		visited.append(vertex)
		if vertex == goal:
			break
		for other: int in neighbours[vertex]:
			if other in blocked:
				continue
			var candidate: float = costs[vertex] + places[vertex].distance_to(places[other])
			if not costs.has(other) or candidate < costs[other]:
				costs[other] = candidate
				predecessor[other] = vertex
				if other not in pending:
					pending.append(other)
	var path: Array[int] = []
	if not predecessor.has(goal):
		return path
	var vertex := goal
	while vertex != -1:
		path.push_front(vertex)
		vertex = predecessor[vertex]
	return path

func priority(vertex: int, goal: int, places: Array[Vector3], use_estimate: bool) -> float:
	var remaining := places[vertex].distance_to(places[goal]) if use_estimate else 0.0
	return float(costs[vertex]) + remaining
