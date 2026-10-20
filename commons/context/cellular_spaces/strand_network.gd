extends RefCounted
## Join actual 3D centreline contacts. A crossing in a camera projection does
## not count. Return the same geometry split into edges sharing junction IDs.

const WELD: float = 0.0001

static func join_contacts(points: PackedVector3Array, groups: Array) -> Dictionary:
	var result_points := points.duplicate()
	var aliases := PackedInt32Array()
	for i in range(points.size()):
		aliases.append(i)
	var segments: Array[Vector2i] = []
	var group_ids: Array[int] = []
	var cuts: Array = []
	var boxes: Array[AABB] = []
	for group_index in range(groups.size()):
		for edge: Vector2i in groups[group_index]:
			segments.append(edge)
			group_ids.append(group_index)
			cuts.append([Vector2(0, edge.x), Vector2(1, edge.y)])
			boxes.append(AABB(points[edge.x].min(points[edge.y]), (points[edge.x] - points[edge.y]).abs()).grow(WELD))
	for i in range(segments.size()):
		var e := segments[i]
		for j in range(i + 1, segments.size()):
			var f := segments[j]
			if e.x == f.x or e.x == f.y or e.y == f.x or e.y == f.y or not boxes[i].intersects(boxes[j]):
				continue
			var closest := Geometry3D.get_closest_points_between_segments(points[e.x], points[e.y], points[f.x], points[f.y])
			if closest[0].distance_to(closest[1]) > WELD:
				continue
			var contact := (closest[0] + closest[1]) * 0.5
			var vertex := -1
			for k in range(result_points.size()):
				if result_points[k].distance_to(contact) <= WELD:
					vertex = k
					break
			if vertex < 0:
				vertex = result_points.size()
				result_points.append(contact)
				aliases.append(vertex)
			vertex = _representative(aliases, vertex)
			for entry in [Vector2i(i, 0), Vector2i(j, 1)]:
				var edge := segments[entry.x]
				var delta := points[edge.y] - points[edge.x]
				var t := clampf((contact - points[edge.x]).dot(delta) / delta.length_squared(), 0, 1)
				# A contact at an endpoint replaces that endpoint, so touching
				# strands cannot retain distinct identities at the same point.
				if contact.distance_to(points[edge.x]) <= WELD:
					aliases[_representative(aliases, edge.x)] = vertex
					cuts[entry.x][0] = Vector2(0, vertex)
				elif contact.distance_to(points[edge.y]) <= WELD:
					aliases[_representative(aliases, edge.y)] = vertex
					cuts[entry.x][1] = Vector2(1, vertex)
				else:
					cuts[entry.x].append(Vector2(t, vertex))
	var result_groups: Array = []
	for group in groups:
		var output: Array[Vector2i] = []
		result_groups.append(output)
	var unique: Dictionary = {}
	for i in range(segments.size()):
		cuts[i].sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
		for j in range(1, cuts[i].size()):
			var a := _representative(aliases, int(cuts[i][j - 1].y))
			var b := _representative(aliases, int(cuts[i][j].y))
			var key := Vector2i(mini(a, b), maxi(a, b))
			if a == b or unique.has(key):
				continue
			unique[key] = true
			result_groups[group_ids[i]].append(key)
	for i in range(aliases.size()):
		aliases[i] = _representative(aliases, i)
	return {"vertices": result_points, "groups": result_groups, "aliases": aliases}

static func _representative(aliases: PackedInt32Array, id: int) -> int:
	while aliases[id] != id:
		id = aliases[id]
	return id

## Vertex IDs belonging to the largest connected component of these edges.
static func largest_component(count: int, edges: Array[Vector2i]) -> Dictionary:
	var adjacency: Array = []
	adjacency.resize(count)
	for i in range(count):
		adjacency[i] = []
	for edge in edges:
		adjacency[edge.x].append(edge.y)
		adjacency[edge.y].append(edge.x)
	var visited: Dictionary = {}
	var largest: Dictionary = {}
	for start in range(count):
		if visited.has(start) or adjacency[start].is_empty():
			continue
		var component: Dictionary = {start: true}
		var pending: Array[int] = [start]
		visited[start] = true
		while not pending.is_empty():
			var vertex: int = pending.pop_back()
			for neighbour: int in adjacency[vertex]:
				if not visited.has(neighbour):
					visited[neighbour] = true
					component[neighbour] = true
					pending.append(neighbour)
		if component.size() > largest.size():
			largest = component
	return largest
