# MeshFix.gd
extends Node
class_name MeshFix

# input: arrays for a single surface (positions, normals, indices)
func fill_open_boundaries(verts: PackedVector3Array, norms: PackedVector3Array, indices: PackedInt32Array) -> void:
	var edge_count := {}   # key: "a_b" with a<b, value: [a,b] + incident count
	for i in range(0, indices.size(), 3):
		var a = indices[i]
		var b = indices[i+1]
		var c = indices[i+2]
		_add_edge(edge_count, a, b)
		_add_edge(edge_count, b, c)
		_add_edge(edge_count, c, a)

	# collect boundary edges (appear once)
	var boundary := []
	for k in edge_count.keys():
		var rec = edge_count[k]
		if rec.count == 1:
			boundary.append(Vector2i(rec.a, rec.b))

	# chain edges into loops
	var loops := _edge_loops(boundary)
	for loop in loops:
		_triangulate_loop(loop, verts, norms, indices)

func _add_edge(dict, a:int, b:int) -> void:
	var a2 = min(a,b)
	var b2 = max(a,b)
	var key = str(a2,"_",b2)
	if not dict.has(key):
		dict[key] = { "a": a2, "b": b2, "count": 0 }
	dict[key].count += 1

func _edge_loops(boundary: Array) -> Array:
	# boundary: Array[Vector2i(a,b)]
	var adj := {}
	for e in boundary:
		if not adj.has(e.x): adj[e.x] = []
		if not adj.has(e.y): adj[e.y] = []
		adj[e.x].append(e.y)
		adj[e.y].append(e.x)
	var visited := {}
	var loops := []
	for start in adj.keys():
		if visited.has(start): continue
		var cur = start
		var prev = -1
		var loop := PackedInt32Array()
		while true:
			visited[cur] = true
			loop.push_back(cur)
			# pick neighbor not equal prev
			var nbrs: Array = adj[cur]
			var next = -1
			for n in nbrs:
				if n != prev:
					next = n
					break
			if next == -1: break
			prev = cur
			cur = next
			if cur == start: 
				loops.append(loop)
				break
	return loops

func _triangulate_loop(loop: PackedInt32Array, verts: PackedVector3Array, norms: PackedVector3Array, indices: PackedInt32Array) -> void:
	if loop.size() < 3: return

	# fit plane (PCA on loop points)
	var pts := PackedVector3Array()
	for i in loop: pts.push_back(verts[i])
	var center := Vector3.ZERO
	for p in pts: center += p
	center /= float(pts.size())
	var cov := Basis() # use as 3x3 accumulator
	for p in pts:
		var d = p - center
		cov.x += Vector3(d.x*d.x, d.x*d.y, d.x*d.z)
		cov.y += Vector3(d.y*d.x, d.y*d.y, d.y*d.z)
		cov.z += Vector3(d.z*d.x, d.z*d.y, d.z*d.z)
	# normal = eigenvector of smallest eigenvalue; cheap fallback: average cross
	var n := Vector3.ZERO
	for i in range(loop.size()):
		var p0 = verts[loop[i]] - center
		var p1 = verts[loop[(i+1)%loop.size()]] - center
		n += p0.cross(p1)
	n = n.normalized()

	# simple fan from centroid (works well for small convex-ish holes)
	var centroid_idx = verts.size()
	verts.push_back(center)
	norms.push_back(n)
	for i in range(1, loop.size()-0):
		var i0 = loop[i-1]
		var i1 = loop[i % loop.size()]
		# only create triangles if not degenerate
		if i0 == i1: continue
		indices.push_back(i0)
		indices.push_back(i1)
		indices.push_back(centroid_idx)
