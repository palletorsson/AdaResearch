extends RefCounted
## Given part of this kit: it counts what a skin of triangles is made of.
## Use it by path:
##   const Pieces := preload("res://pieces.gd")
## `points` is a list with three points for every triangle, as field_body.gd
## makes it. Two triangles belong to one piece when they share a corner: the
## same place, to the last digit. Contract:
##   count(points)        how many separate pieces the skin has
##   sizes(points)        the triangles of each piece, the largest first
##   open_edges(points, above)   how many edges are used by an odd number of
##                        triangles: the rim of a hole. A closed skin has none.
##                        A triangle with two corners in one place has no area and
##                        is left out. With `above`, only edges that reach higher
##                        than that count: 0.0001 leaves out a rim on the ground
##   flat(points)         how many triangles have two corners in one place
##   outward(points, field)   of all triangles, the share (0 to 1) whose front
##                        looks toward where `field` is lower. `field` is a
##                        Callable that takes a place and returns a number
## It touches no node, so it may run on any thread.

static func count(points: PackedVector3Array) -> int:
	return sizes(points).size()

static func sizes(points: PackedVector3Array) -> Array:
	var number := {}                  # a place -> the number of its corner
	var parent := PackedInt32Array()  # for each corner, a corner of the same piece; a root names itself
	var corner_of := PackedInt32Array()
	corner_of.resize(points.size())
	for i in points.size():
		var p := points[i]
		if not number.has(p):
			number[p] = parent.size()
			parent.append(parent.size())
		corner_of[i] = number[p]
	for i in range(0, points.size(), 3):
		var a := _root(parent, corner_of[i])
		for k in [1, 2]:
			var b := _root(parent, corner_of[i + k])
			if b != a:
				parent[b] = a
	var triangles := {}               # a root -> how many triangles hang on it
	for i in range(0, points.size(), 3):
		var r := _root(parent, corner_of[i])
		triangles[r] = triangles.get(r, 0) + 1
	var out := triangles.values()
	out.sort()
	out.reverse()
	return out

static func open_edges(points: PackedVector3Array, above := -INF) -> int:
	var seen := {}                    # an edge, as its two places in order -> how many triangles use it
	for i in range(0, points.size(), 3):
		if points[i] == points[i + 1] or points[i + 1] == points[i + 2] or points[i] == points[i + 2]:
			continue
		for k in 3:
			var a := points[i + k]
			var b := points[i + (k + 1) % 3]
			var key := [a, b] if a < b else [b, a]
			seen[key] = seen.get(key, 0) + 1
	var open := 0
	for key: Array in seen:
		if seen[key] % 2 == 1 and (key[0].y > above or key[1].y > above):
			open += 1
	return open

static func flat(points: PackedVector3Array) -> int:
	var found := 0
	for i in range(0, points.size(), 3):
		if points[i] == points[i + 1] or points[i + 1] == points[i + 2] or points[i] == points[i + 2]:
			found += 1
	return found

static func outward(points: PackedVector3Array, field: Callable) -> float:
	var good := 0
	var all := 0
	for i in range(0, points.size(), 3):
		var a := points[i]
		var b := points[i + 1]
		var c := points[i + 2]
		var front := (a - c).cross(a - b)   # the side Godot draws: corners clockwise
		if front.length() < 1e-9:
			continue                        # no area, no side
		front = front.normalized()
		all += 1
		var middle := (a + b + c) / 3.0
		if field.call(middle + front * 0.02) < field.call(middle - front * 0.02):
			good += 1
	return good / maxf(all, 1.0)

static func _root(parent: PackedInt32Array, i: int) -> int:
	while parent[i] != i:
		parent[i] = parent[parent[i]]
		i = parent[i]
	return i
