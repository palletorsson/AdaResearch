extends RefCounted
const Walker = preload("traversal.gd")
const VERTICES := 7
# New undirected build costs; these are not the earlier event records.
var links: Array = [
	{"a": 0, "b": 1, "cost": 4.0},
	{"a": 0, "b": 2, "cost": 2.0},
	{"a": 1, "b": 3, "cost": 1.0},
	{"a": 1, "b": 4, "cost": 3.0},
	{"a": 2, "b": 5, "cost": 6.0},
	{"a": 2, "b": 6, "cost": 5.0},
	{"a": 4, "b": 5, "cost": 0.5},
	{"a": 1, "b": 5, "cost": 8.0},
]
var order: Array[int] = []
var chosen: Array[int] = []
var refused: Array[int] = []
var cursor := 0
var current := -1

func reset() -> void:
	order.clear()
	for i in range(links.size()):
		order.append(i)
	order.sort_custom(func(a, b):
		if links[a].cost == links[b].cost:
			return a < b
		return links[a].cost < links[b].cost)
	chosen.clear()
	refused.clear()
	cursor = 0
	current = -1

func reachable(kept: Array[int], start: int) -> Array[int]:
	if start < 0 or start >= VERTICES:
		return []
	var walker = Walker.new()
	walker.neighbours.clear()
	for vertex in range(VERTICES):
		walker.neighbours.append([])
	for i in kept:
		var link: Dictionary = links[i]
		walker.neighbours[link.a].append(link.b)
		walker.neighbours[link.b].append(link.a)
	walker.restart(true)
	walker.pending.assign([start])
	while walker.next_visit() != -1:
		pass
	return walker.visited

func step() -> void:
	if complete():
		return
	current = order[cursor]
	cursor += 1
	var link: Dictionary = links[current]
	if link.b in reachable(chosen, link.a):
		refused.append(current)
	else:
		chosen.append(current)

func complete() -> bool:
	return cursor >= order.size()

func spans() -> bool:
	return chosen.size() == VERTICES - 1 and reachable(chosen, 0).size() == VERTICES

func cost(kept: Array[int]) -> float:
	var total := 0.0
	for i in kept:
		total += links[i].cost
	return total
