## MeshData — Core mutable mesh representation for the grammar system.
## Stores vertices, triangular faces, tags, depth, and lazy adjacency.
## Converts to/from ArrayMesh and the project's vertices+faces format.
extends RefCounted
class_name MeshData

# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------
var vertices: PackedVector3Array = PackedVector3Array()
var faces: Array[PackedInt32Array] = []          # Each entry: [v0, v1, v2]

# Per-face metadata
var face_tags: Array[PackedStringArray] = []     # face_idx -> ["tag1", ...]
var face_depth: PackedInt32Array = PackedInt32Array()  # grammar generation depth
var face_metadata: Array[Dictionary] = []        # arbitrary per-face data

# Per-vertex metadata
var vertex_tags: Array[PackedStringArray] = []

# Lazy adjacency (rebuilt on demand)
var _face_neighbors: Array[PackedInt32Array] = []
var _vertex_faces: Array[PackedInt32Array] = []
var _edges: Dictionary = {}  # Vector2i(min_v, max_v) -> {"faces": PackedInt32Array}
var _adjacency_dirty: bool = true

# ---------------------------------------------------------------------------
# Construction — from arrays
# ---------------------------------------------------------------------------
static func from_arrays(verts: Array, face_list: Array) -> MeshData:
	var md := MeshData.new()

	# Accept both Array[Vector3] and PackedVector3Array
	if typeof(verts) == TYPE_PACKED_VECTOR3_ARRAY:
		md.vertices = verts
	else:
		for v in verts:
			md.vertices.append(v)

	# Accept faces as [i0,i1,i2], PackedInt32Array, or {"indices":[...]}
	for face in face_list:
		var indices: PackedInt32Array
		if face is PackedInt32Array:
			indices = face
		elif face is Dictionary:
			var raw: Array = face.get("indices", [])
			indices = PackedInt32Array(raw)
		elif face is Array:
			indices = PackedInt32Array(face)
		else:
			continue

		# Triangulate quads
		if indices.size() == 4:
			md.faces.append(PackedInt32Array([indices[0], indices[1], indices[2]]))
			md.faces.append(PackedInt32Array([indices[0], indices[2], indices[3]]))
		elif indices.size() == 3:
			md.faces.append(indices)
		# Skip degenerate

	md._init_metadata()
	return md

# ---------------------------------------------------------------------------
# Construction — from ArrayMesh
# ---------------------------------------------------------------------------
static func from_array_mesh(mesh_resource: ArrayMesh, surface_idx: int = 0) -> MeshData:
	var md := MeshData.new()
	if mesh_resource == null or mesh_resource.get_surface_count() <= surface_idx:
		return md

	var arrays := mesh_resource.surface_get_arrays(surface_idx)
	var raw_verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var raw_indices = arrays[Mesh.ARRAY_INDEX]

	if raw_indices != null and raw_indices.size() > 0:
		# Indexed mesh — deduplicate vertices
		var vert_map: Dictionary = {}
		var unique_verts: PackedVector3Array = PackedVector3Array()
		var index_remap: PackedInt32Array = PackedInt32Array()
		index_remap.resize(raw_verts.size())

		for i in range(raw_verts.size()):
			var v: Vector3 = raw_verts[i]
			var key := _vert_key(v)
			if not vert_map.has(key):
				vert_map[key] = unique_verts.size()
				unique_verts.append(v)
			index_remap[i] = vert_map[key]

		md.vertices = unique_verts
		for i in range(0, raw_indices.size(), 3):
			if i + 2 >= raw_indices.size():
				break
			var i0: int = index_remap[raw_indices[i]]
			var i1: int = index_remap[raw_indices[i + 1]]
			var i2: int = index_remap[raw_indices[i + 2]]
			if i0 == i1 or i1 == i2 or i2 == i0:
				continue  # Skip degenerate
			md.faces.append(PackedInt32Array([i0, i1, i2]))
	else:
		# Non-indexed — every 3 vertices is a face, deduplicate
		var vert_map: Dictionary = {}
		var unique_verts: PackedVector3Array = PackedVector3Array()

		for i in range(0, raw_verts.size(), 3):
			if i + 2 >= raw_verts.size():
				break
			var tri := PackedInt32Array()
			for j in range(3):
				var v: Vector3 = raw_verts[i + j]
				var key := _vert_key(v)
				if not vert_map.has(key):
					vert_map[key] = unique_verts.size()
					unique_verts.append(v)
				tri.append(vert_map[key])
			if tri[0] == tri[1] or tri[1] == tri[2] or tri[2] == tri[0]:
				continue
			md.faces.append(tri)

		md.vertices = unique_verts

	md._init_metadata()
	return md

# ---------------------------------------------------------------------------
# Conversion — to arrays (compatible with PrimitiveMeshBuilder)
# ---------------------------------------------------------------------------
func to_arrays() -> Dictionary:
	var v_arr: Array[Vector3] = []
	for v in vertices:
		v_arr.append(v)
	var f_arr: Array = []
	for f in faces:
		f_arr.append(Array(f))
	return {"vertices": v_arr, "faces": f_arr}

# ---------------------------------------------------------------------------
# Conversion — to ArrayMesh
# ---------------------------------------------------------------------------
func to_array_mesh(options: Dictionary = {}) -> ArrayMesh:
	var double_sided: bool = options.get("double_sided", false)
	# When face_colors is true, read per-face Color from face_metadata[i]["color"]
	# (set by PaintByTagOp) and bake it as SurfaceTool vertex colour. Material
	# must use vertex_color_use_as_albedo to display.
	var face_colors: bool = options.get("face_colors", false)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for fi in range(faces.size()):
		var face: PackedInt32Array = faces[fi]
		if face.size() != 3:
			continue
		var v0: Vector3 = vertices[face[0]]
		var v1: Vector3 = vertices[face[1]]
		var v2: Vector3 = vertices[face[2]]
		var normal := (v1 - v0).cross(v2 - v0)
		if normal.length_squared() < 1e-10:
			continue
		normal = normal.normalized()

		var face_color: Color = Color.WHITE
		if face_colors and fi < face_metadata.size():
			var md: Dictionary = face_metadata[fi]
			if md.has("color"):
				face_color = md["color"]

		st.set_normal(normal)
		if face_colors: st.set_color(face_color)
		st.add_vertex(v0)
		st.set_normal(normal)
		if face_colors: st.set_color(face_color)
		st.add_vertex(v1)
		st.set_normal(normal)
		if face_colors: st.set_color(face_color)
		st.add_vertex(v2)

		if double_sided:
			var back := -normal
			st.set_normal(back)
			if face_colors: st.set_color(face_color)
			st.add_vertex(v0)
			st.set_normal(back)
			if face_colors: st.set_color(face_color)
			st.add_vertex(v2)
			st.set_normal(back)
			if face_colors: st.set_color(face_color)
			st.add_vertex(v1)

	if options.get("generate_normals", false):
		st.generate_normals()
	if options.get("generate_tangents", false):
		st.generate_tangents()
	return st.commit()


## Convert to ArrayMesh with multiple surfaces, one per unique tag prefix.
## tag_prefix: e.g. "zone_" — groups faces by their zone_* tag.
## Returns: { "mesh": ArrayMesh, "surface_names": Array[String] }
func to_multi_surface_mesh(tag_prefix: String = "zone_", options: Dictionary = {}) -> Dictionary:
	var double_sided: bool = options.get("double_sided", true)
	
	# Group faces by their first matching tag
	var groups: Dictionary = {}  # tag_value -> Array[int] (face indices)
	for fi in range(faces.size()):
		var group_name := "default"
		if fi < face_tags.size():
			for t in face_tags[fi]:
				if t.begins_with(tag_prefix):
					group_name = t
					break
		if not groups.has(group_name):
			groups[group_name] = []
		groups[group_name].append(fi)
	
	var array_mesh := ArrayMesh.new()
	var surface_names: Array[String] = []
	
	for group_name in groups.keys():
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var has_geometry := false
		
		for fi in groups[group_name]:
			var face: PackedInt32Array = faces[fi]
			if face.size() != 3:
				continue
			var v0: Vector3 = vertices[face[0]]
			var v1: Vector3 = vertices[face[1]]
			var v2: Vector3 = vertices[face[2]]
			var normal := (v1 - v0).cross(v2 - v0)
			if normal.length_squared() < 1e-10:
				continue
			normal = normal.normalized()
			has_geometry = true

			st.set_normal(normal)
			st.add_vertex(v0)
			st.set_normal(normal)
			st.add_vertex(v1)
			st.set_normal(normal)
			st.add_vertex(v2)

			if double_sided:
				var back := -normal
				st.set_normal(back)
				st.add_vertex(v0)
				st.set_normal(back)
				st.add_vertex(v2)
				st.set_normal(back)
				st.add_vertex(v1)
		
		if has_geometry:
			st.generate_normals()
			st.commit(array_mesh)
			surface_names.append(group_name)
	
	return { "mesh": array_mesh, "surface_names": surface_names }


# ---------------------------------------------------------------------------
# Topology queries (lazy-rebuild adjacency)
# ---------------------------------------------------------------------------
func get_face_normal(face_idx: int) -> Vector3:
	var f := faces[face_idx]
	var v0: Vector3 = vertices[f[0]]
	var v1: Vector3 = vertices[f[1]]
	var v2: Vector3 = vertices[f[2]]
	var n := (v1 - v0).cross(v2 - v0)
	if n.length_squared() < 1e-10:
		return Vector3.UP
	return n.normalized()

func get_face_centroid(face_idx: int) -> Vector3:
	var f := faces[face_idx]
	return (vertices[f[0]] + vertices[f[1]] + vertices[f[2]]) / 3.0

func get_face_area(face_idx: int) -> float:
	var f := faces[face_idx]
	var v0: Vector3 = vertices[f[0]]
	var v1: Vector3 = vertices[f[1]]
	var v2: Vector3 = vertices[f[2]]
	return (v1 - v0).cross(v2 - v0).length() * 0.5

func get_face_neighbors(face_idx: int) -> PackedInt32Array:
	_ensure_adjacency()
	if face_idx >= 0 and face_idx < _face_neighbors.size():
		return _face_neighbors[face_idx]
	return PackedInt32Array()

func get_vertex_faces(vert_idx: int) -> PackedInt32Array:
	_ensure_adjacency()
	if vert_idx >= 0 and vert_idx < _vertex_faces.size():
		return _vertex_faces[vert_idx]
	return PackedInt32Array()

func get_face_edges(face_idx: int) -> Array[Vector2i]:
	var f := faces[face_idx]
	return [
		_edge_key(f[0], f[1]),
		_edge_key(f[1], f[2]),
		_edge_key(f[2], f[0])
	]

func get_edge_faces(edge: Vector2i) -> PackedInt32Array:
	_ensure_adjacency()
	if _edges.has(edge):
		return _edges[edge]["faces"]
	return PackedInt32Array()

func get_boundary_edges() -> Array[Vector2i]:
	_ensure_adjacency()
	var result: Array[Vector2i] = []
	for edge_key in _edges:
		if _edges[edge_key]["faces"].size() == 1:
			result.append(edge_key)
	return result

## Get N-ring face neighborhood around a face.
func get_face_ring(face_idx: int, depth: int = 1) -> PackedInt32Array:
	_ensure_adjacency()
	var visited: Dictionary = {face_idx: true}
	var frontier: PackedInt32Array = PackedInt32Array([face_idx])
	var result: PackedInt32Array = PackedInt32Array([face_idx])

	for _d in range(depth):
		var next_frontier: PackedInt32Array = PackedInt32Array()
		for fi in frontier:
			for neighbor in get_face_neighbors(fi):
				if not visited.has(neighbor):
					visited[neighbor] = true
					next_frontier.append(neighbor)
					result.append(neighbor)
		frontier = next_frontier
		if frontier.is_empty():
			break
	return result

# ---------------------------------------------------------------------------
# Mutation
# ---------------------------------------------------------------------------
func add_vertex(pos: Vector3, tags: PackedStringArray = PackedStringArray()) -> int:
	var idx := vertices.size()
	vertices.append(pos)
	vertex_tags.append(tags)
	_adjacency_dirty = true
	return idx

func add_face(indices: PackedInt32Array, tags: PackedStringArray = PackedStringArray(), depth: int = 0) -> int:
	var idx := faces.size()
	faces.append(indices)
	face_tags.append(tags)
	face_depth.append(depth)
	face_metadata.append({})
	_adjacency_dirty = true
	return idx

## Remove faces by indices. Handles index shifting.
func remove_faces(face_indices: PackedInt32Array) -> void:
	if face_indices.is_empty():
		return
	# Sort descending to remove from end first
	var sorted_indices: Array = Array(face_indices)
	sorted_indices.sort()
	sorted_indices.reverse()

	for fi in sorted_indices:
		if fi >= 0 and fi < faces.size():
			faces.remove_at(fi)
			face_tags.remove_at(fi)
			if fi < face_depth.size():
				face_depth.remove_at(fi)
			if fi < face_metadata.size():
				face_metadata.remove_at(fi)
	_adjacency_dirty = true

## Replace a face with multiple new faces. Returns indices of new faces.
func replace_face(face_idx: int, new_faces_data: Array[PackedInt32Array],
		new_tags: Array[PackedStringArray] = []) -> PackedInt32Array:
	var old_depth: int = 0
	if face_idx < face_depth.size():
		old_depth = face_depth[face_idx]

	# Remove old face
	remove_faces(PackedInt32Array([face_idx]))

	# Add new faces
	var new_indices := PackedInt32Array()
	for i in range(new_faces_data.size()):
		var tags: PackedStringArray
		if i < new_tags.size():
			tags = new_tags[i]
		else:
			tags = PackedStringArray()
		var idx := add_face(new_faces_data[i], tags, old_depth + 1)
		new_indices.append(idx)
	return new_indices

func remove_orphan_vertices() -> void:
	# Find which vertices are used
	var used: Dictionary = {}
	for f in faces:
		for vi in f:
			used[vi] = true

	if used.size() == vertices.size():
		return  # All used

	# Build remap
	var remap: PackedInt32Array = PackedInt32Array()
	remap.resize(vertices.size())
	var new_verts := PackedVector3Array()
	var new_vtags: Array[PackedStringArray] = []
	var new_idx: int = 0

	for i in range(vertices.size()):
		if used.has(i):
			remap[i] = new_idx
			new_verts.append(vertices[i])
			if i < vertex_tags.size():
				new_vtags.append(vertex_tags[i])
			else:
				new_vtags.append(PackedStringArray())
			new_idx += 1
		else:
			remap[i] = -1

	# Remap face indices
	for fi in range(faces.size()):
		var f := faces[fi]
		faces[fi] = PackedInt32Array([remap[f[0]], remap[f[1]], remap[f[2]]])

	vertices = new_verts
	vertex_tags = new_vtags
	_adjacency_dirty = true

# ---------------------------------------------------------------------------
# Tagging
# ---------------------------------------------------------------------------
func tag_face(face_idx: int, tag: String) -> void:
	if face_idx >= 0 and face_idx < face_tags.size():
		var tags := face_tags[face_idx]
		if not tags.has(tag):
			tags.append(tag)
			face_tags[face_idx] = tags

func untag_face(face_idx: int, tag: String) -> void:
	if face_idx >= 0 and face_idx < face_tags.size():
		var tags := face_tags[face_idx]
		var pos := tags.find(tag)
		if pos >= 0:
			tags.remove_at(pos)
			face_tags[face_idx] = tags

func tag_faces(face_indices: PackedInt32Array, tag: String) -> void:
	for fi in face_indices:
		tag_face(fi, tag)

func face_has_tag(face_idx: int, tag: String) -> bool:
	if face_idx >= 0 and face_idx < face_tags.size():
		return face_tags[face_idx].has(tag)
	return false

func get_faces_with_tag(tag: String) -> PackedInt32Array:
	var result := PackedInt32Array()
	for i in range(face_tags.size()):
		if face_tags[i].has(tag):
			result.append(i)
	return result

# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------
func duplicate_mesh() -> MeshData:
	var md := MeshData.new()
	md.vertices = vertices.duplicate()
	md.faces = faces.duplicate(true)
	md.face_tags = face_tags.duplicate(true)
	md.face_depth = face_depth.duplicate()
	md.face_metadata = face_metadata.duplicate(true)
	md.vertex_tags = vertex_tags.duplicate(true)
	md._adjacency_dirty = true
	return md

func merge(other: MeshData) -> void:
	var offset: int = vertices.size()
	vertices.append_array(other.vertices)
	vertex_tags.append_array(other.vertex_tags)

	for f in other.faces:
		var shifted := PackedInt32Array([f[0] + offset, f[1] + offset, f[2] + offset])
		faces.append(shifted)

	face_tags.append_array(other.face_tags)
	face_depth.append_array(other.face_depth)
	face_metadata.append_array(other.face_metadata)
	_adjacency_dirty = true

func get_bounding_box() -> AABB:
	if vertices.is_empty():
		return AABB()
	var bb := AABB(vertices[0], Vector3.ZERO)
	for i in range(1, vertices.size()):
		bb = bb.expand(vertices[i])
	return bb

func center_to_origin() -> void:
	var bb := get_bounding_box()
	var center := bb.get_center()
	for i in range(vertices.size()):
		vertices[i] -= center

func face_count() -> int:
	return faces.size()

func vertex_count() -> int:
	return vertices.size()

## Count edges in the mesh.
func edge_count() -> int:
	_ensure_adjacency()
	return _edges.size()

## Euler characteristic: V - E + F. For a closed genus-0 surface (sphere), this is 2.
## For a torus it's 0. For a surface with B boundary loops, it's 2 - 2G - B.
func euler_characteristic() -> int:
	return vertex_count() - edge_count() + face_count()

## True if no edge has exactly 1 adjacent face (no boundary/holes).
func is_closed() -> bool:
	return get_boundary_edges().is_empty()

## True if every edge has exactly 2 adjacent faces (manifold).
## Non-manifold = an edge shared by 3+ faces.
func is_manifold() -> bool:
	_ensure_adjacency()
	for edge_key in _edges:
		var face_count_for_edge: int = (_edges[edge_key]["faces"] as PackedInt32Array).size()
		if face_count_for_edge > 2:
			return false
	return true

## Count boundary loops (connected components of boundary edges).
func count_boundary_loops() -> int:
	var boundary: Array[Vector2i] = get_boundary_edges()
	if boundary.is_empty():
		return 0
	# Build adjacency for boundary edges via shared vertices
	var visited: Dictionary = {}
	var loops: int = 0
	for edge in boundary:
		var key: int = edge.x * 100000 + edge.y
		if visited.has(key):
			continue
		loops += 1
		# BFS along boundary edges sharing vertices
		var frontier: Array[Vector2i] = [edge]
		while not frontier.is_empty():
			var current: Vector2i = frontier.pop_back()
			var ckey: int = current.x * 100000 + current.y
			if visited.has(ckey):
				continue
			visited[ckey] = true
			for other in boundary:
				var okey: int = other.x * 100000 + other.y
				if visited.has(okey):
					continue
				if other.x == current.x or other.x == current.y or other.y == current.x or other.y == current.y:
					frontier.append(other)
	return loops

## Count connected components (how many separate mesh islands).
func count_components() -> int:
	if faces.is_empty():
		return 0
	_ensure_adjacency()
	var visited: Dictionary = {}
	var components: int = 0
	for fi in faces.size():
		if visited.has(fi):
			continue
		components += 1
		var frontier: Array[int] = [fi]
		while not frontier.is_empty():
			var current: int = frontier.pop_back()
			if visited.has(current):
				continue
			visited[current] = true
			for neighbor in get_face_neighbors(current):
				if not visited.has(neighbor):
					frontier.append(neighbor)
	return components

## Full topology report as a dictionary.
func topology_report() -> Dictionary:
	return {
		"vertices": vertex_count(),
		"edges": edge_count(),
		"faces": face_count(),
		"euler": euler_characteristic(),
		"is_closed": is_closed(),
		"is_manifold": is_manifold(),
		"boundary_edges": get_boundary_edges().size(),
		"boundary_loops": count_boundary_loops(),
		"components": count_components(),
	}

# ---------------------------------------------------------------------------
# Seed factory helpers
# ---------------------------------------------------------------------------
static func create_cube(size: float = 1.0) -> MeshData:
	var s := size
	return MeshData.from_arrays(
		[Vector3(-s,-s,s), Vector3(s,-s,s), Vector3(s,s,s), Vector3(-s,s,s),
		 Vector3(-s,-s,-s), Vector3(s,-s,-s), Vector3(s,s,-s), Vector3(-s,s,-s)],
		[[0,1,2],[0,2,3], [5,4,7],[5,7,6], [4,0,3],[4,3,7],
		 [1,5,6],[1,6,2], [3,2,6],[3,6,7], [4,5,1],[4,1,0]])

static func create_icosahedron(size: float = 1.0) -> MeshData:
	var verts: Array[Vector3] = [
		Vector3(0.8507, 0.5257, 0) * size, Vector3(-0.8507, 0.5257, 0) * size,
		Vector3(0.8507, -0.5257, 0) * size, Vector3(-0.8507, -0.5257, 0) * size,
		Vector3(0.5257, 0, 0.8507) * size, Vector3(0.5257, 0, -0.8507) * size,
		Vector3(-0.5257, 0, 0.8507) * size, Vector3(-0.5257, 0, -0.8507) * size,
		Vector3(0, 0.8507, 0.5257) * size, Vector3(0, -0.8507, 0.5257) * size,
		Vector3(0, 0.8507, -0.5257) * size, Vector3(0, -0.8507, -0.5257) * size]
	var face_list: Array = [
		[0,8,4],[0,5,10],[2,4,9],[2,11,5],[1,6,8],[1,10,7],
		[3,9,6],[3,7,11],[0,10,8],[1,8,10],[2,9,11],[3,11,9],
		[4,2,0],[5,0,2],[6,1,3],[7,3,1],[8,6,4],[9,4,6],
		[10,5,7],[11,7,5]]
	return MeshData.from_arrays(verts, face_list)

static func create_sphere(radius: float = 1.0, rings: int = 12, segments: int = 16) -> MeshData:
	var md := MeshData.new()
	# Generate sphere vertices
	for i in range(rings + 1):
		var phi: float = PI * float(i) / float(rings)
		for j in range(segments + 1):
			var theta: float = TAU * float(j) / float(segments)
			var x := radius * sin(phi) * cos(theta)
			var y := radius * cos(phi)
			var z := radius * sin(phi) * sin(theta)
			md.vertices.append(Vector3(x, y, z))

	# Generate faces
	for i in range(rings):
		for j in range(segments):
			var cols := segments + 1
			var curr := i * cols + j
			var next_row := curr + cols
			# Skip degenerate triangles at poles
			if i > 0:
				md.faces.append(PackedInt32Array([curr, next_row, curr + 1]))
			if i < rings - 1:
				md.faces.append(PackedInt32Array([curr + 1, next_row, next_row + 1]))

	md._init_metadata()
	return md

# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------
func _init_metadata() -> void:
	face_tags.resize(faces.size())
	face_depth.resize(faces.size())
	face_metadata.resize(faces.size())
	vertex_tags.resize(vertices.size())
	for i in range(faces.size()):
		face_tags[i] = PackedStringArray()
		face_depth[i] = 0
		face_metadata[i] = {}
	for i in range(vertices.size()):
		vertex_tags[i] = PackedStringArray()
	_adjacency_dirty = true

func _ensure_adjacency() -> void:
	if not _adjacency_dirty:
		return
	_rebuild_adjacency()

func _rebuild_adjacency() -> void:
	_face_neighbors.clear()
	_face_neighbors.resize(faces.size())
	_vertex_faces.clear()
	_vertex_faces.resize(vertices.size())
	_edges.clear()

	for i in range(faces.size()):
		_face_neighbors[i] = PackedInt32Array()
	for i in range(vertices.size()):
		_vertex_faces[i] = PackedInt32Array()

	# Build vertex→face and edge→face maps
	for fi in range(faces.size()):
		var f := faces[fi]
		for vi in f:
			if vi >= 0 and vi < _vertex_faces.size():
				_vertex_faces[vi].append(fi)

		# Edges
		for ei in range(3):
			var e := _edge_key(f[ei], f[(ei + 1) % 3])
			if not _edges.has(e):
				_edges[e] = {"faces": PackedInt32Array()}
			_edges[e]["faces"].append(fi)

	# Build face neighbors from shared edges
	for edge_key in _edges:
		var edge_faces: PackedInt32Array = _edges[edge_key]["faces"]
		if edge_faces.size() == 2:
			var f0: int = edge_faces[0]
			var f1: int = edge_faces[1]
			if not _face_neighbors[f0].has(f1):
				_face_neighbors[f0].append(f1)
			if not _face_neighbors[f1].has(f0):
				_face_neighbors[f1].append(f0)

	_adjacency_dirty = false

static func _edge_key(v0: int, v1: int) -> Vector2i:
	return Vector2i(mini(v0, v1), maxi(v0, v1))

static func _vert_key(v: Vector3) -> String:
	return "%s_%s_%s" % [snapped(v.x, 0.0001), snapped(v.y, 0.0001), snapped(v.z, 0.0001)]
