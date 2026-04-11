# sculpture_editor.gd — SDF-based sculpture editor
# Composes signed distance fields (spheres, boxes, tori) into organic/crystal/biological
# forms using MorphoPrimitive's SDF meshing pipeline.
extends BaseGeometryEditor


func _get_editor_name() -> String:
	return "Sculpture"


func _get_parameter_groups() -> Array:
	return [
		{"name": "Sculpture", "params": [
			{"id": "type", "label": "Type (0-9)", "min": 0.0, "max": 9.0, "step": 1.0, "default": 0.0},
			{"id": "resolution", "label": "Resolution", "min": 16.0, "max": 48.0, "step": 2.0, "default": 24.0},
		]},
		{"name": "Character", "params": [
			{"id": "hollow", "label": "Hollow", "min": 0.0, "max": 1.0, "step": 0.05, "default": 0.7},
			{"id": "complexity", "label": "Complexity", "min": 0.0, "max": 1.0, "step": 0.05, "default": 0.8},
			{"id": "organic_flow", "label": "Organic Flow", "min": 0.0, "max": 1.0, "step": 0.05, "default": 0.9},
			{"id": "seed_val", "label": "Seed", "min": 0.0, "max": 999.0, "step": 1.0, "default": 42.0},
		]},
	]


func _rebuild() -> void:
	_clear_content()

	var sculpture_type: int = clampi(int(p("type", 0)), 0, 9)
	var res: int = clampi(int(p("resolution", 24)), 16, 48)
	var hollow_val: float = p("hollow", 0.7)
	var complexity_val: float = p("complexity", 0.8)
	var flow_val: float = p("organic_flow", 0.9)
	var seed_int: int = int(p("seed_val", 42))

	# Use a seeded RNG for reproducible variation
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_int

	# Build density field on a 3D grid and extract surface with SurfaceTool
	var field_size: int = res
	var scale: float = 2.0
	var cell: float = scale / float(field_size)
	var half: float = scale * 0.5

	# Evaluate density at each grid point
	var field: Array = []
	field.resize(field_size)
	for x in field_size:
		field[x] = []
		field[x].resize(field_size)
		for y in field_size:
			field[x][y] = PackedFloat32Array()
			field[x][y].resize(field_size)
			for z in field_size:
				var pos := Vector3(
					float(x) * cell - half,
					float(y) * cell - half,
					float(z) * cell - half
				)
				field[x][y][z] = _evaluate(pos, sculpture_type, hollow_val, complexity_val, flow_val, rng)

	# March the field and build mesh
	var mesh: ArrayMesh = _march_field(field, field_size, cell, half)
	if not mesh:
		return

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.82, 0.72)
	mat.roughness = 0.35
	mat.metallic = 0.05
	mat.cull_mode = StandardMaterial3D.CULL_DISABLED
	mi.material_override = mat
	content_root.add_child(mi)

	var type_names: Array[String] = [
		"Organic", "Crystal", "Biological", "Mineral", "Fluid",
		"Spiral", "Fractal", "Cluster", "Cave", "Cellular",
	]
	if info_label:
		info_label.text = "Sculpture: %s | Grid: %d^3" % [type_names[sculpture_type], field_size]


# ── Density evaluation ───────────────────────────────────────

func _evaluate(pos: Vector3, stype: int, hollow: float, complexity: float, flow: float, rng: RandomNumberGenerator) -> float:
	var d: float = 0.0
	match stype:
		0: d = _sdf_organic(pos, hollow, complexity, flow)
		1: d = _sdf_crystal(pos, complexity, flow)
		2: d = _sdf_biological(pos, hollow, complexity)
		3: d = _sdf_mineral(pos, complexity)
		4: d = _sdf_fluid(pos, complexity, flow)
		5: d = _sdf_spiral(pos, flow, complexity)
		6: d = _sdf_fractal(pos, complexity)
		7: d = _sdf_cluster(pos, complexity, rng)
		8: d = _sdf_cave(pos, hollow, complexity)
		9: d = _sdf_cellular(pos, hollow, complexity)
	return d


func _noise3(pos: Vector3) -> float:
	return sin(pos.x * 2.3 + pos.y * 1.7) * cos(pos.z * 1.9 + pos.x * 2.1) * sin(pos.y * 2.5 + pos.z * 1.8)


func _sdf_sphere(pos: Vector3, center: Vector3, radius: float) -> float:
	return (pos - center).length() - radius


func _sdf_box(pos: Vector3, center: Vector3, half_size: Vector3) -> float:
	var q: Vector3 = (pos - center).abs() - half_size
	return Vector3(maxf(q.x, 0), maxf(q.y, 0), maxf(q.z, 0)).length() + minf(maxf(q.x, maxf(q.y, q.z)), 0.0)


func _sdf_torus_xz(pos: Vector3, center: Vector3, major: float, minor: float) -> float:
	var p2 := pos - center
	var q := Vector2(Vector2(p2.x, p2.z).length() - major, p2.y)
	return q.length() - minor


func _smooth_union(a: float, b: float, k: float) -> float:
	var h: float = clampf(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
	return lerpf(b, a, h) - k * h * (1.0 - h)


func _sdf_organic(pos: Vector3, hollow: float, complexity: float, flow: float) -> float:
	var d: float = _sdf_sphere(pos, Vector3.ZERO, 0.6)
	d = _smooth_union(d, _sdf_sphere(pos, Vector3(0.3, 0.2, 0), 0.35), 0.3 * flow)
	d = _smooth_union(d, _sdf_sphere(pos, Vector3(-0.2, -0.15, 0.25), 0.3), 0.25 * flow)
	d += _noise3(pos * 4.0 * complexity) * 0.1 * complexity
	if hollow > 0.1:
		var inner: float = _sdf_sphere(pos, Vector3.ZERO, 0.6 * (1.0 - hollow))
		d = maxf(d, -inner)
	return -d  # Invert so positive = inside


func _sdf_crystal(pos: Vector3, complexity: float, flow: float) -> float:
	var d: float = _sdf_box(pos, Vector3.ZERO, Vector3(0.3, 0.5, 0.3))
	d = minf(d, _sdf_box(pos, Vector3(0.2, 0.1, 0.2), Vector3(0.2, 0.4, 0.15)))
	d = minf(d, _sdf_box(pos, Vector3(-0.15, -0.1, -0.1), Vector3(0.15, 0.35, 0.2)))
	d = minf(d, _sdf_box(pos, Vector3(0, 0.3, -0.2), Vector3(0.1, 0.25, 0.1)))
	d += abs(_noise3(pos * 3.0)) * 0.05 * complexity
	return -d


func _sdf_biological(pos: Vector3, hollow: float, complexity: float) -> float:
	var d: float = _smooth_union(
		_sdf_sphere(pos, Vector3.ZERO, 0.5),
		_sdf_torus_xz(pos, Vector3(0, 0.1, 0), 0.4, 0.15),
		0.3
	)
	d += _noise3(pos * 5.0 * complexity) * 0.08
	if hollow > 0.3:
		d = maxf(d, -_sdf_sphere(pos, Vector3(0, 0.1, 0), 0.35 * hollow))
	return -d


func _sdf_mineral(pos: Vector3, complexity: float) -> float:
	var d: float = _sdf_sphere(pos, Vector3.ZERO, 0.55)
	var cut: float = _sdf_box(pos, Vector3(0.15, 0.15, 0.15), Vector3(0.35, 0.35, 0.35))
	d = maxf(d, -cut)
	d += sin(pos.y * 10.0 + _noise3(pos * 2.0) * 3.0) * 0.03 * complexity
	return -d


func _sdf_fluid(pos: Vector3, complexity: float, flow: float) -> float:
	var d: float = _sdf_sphere(pos, Vector3.ZERO, 0.4)
	d = _smooth_union(d, _sdf_sphere(pos, Vector3(0.25, 0.15, 0.1), 0.3), 0.4 * flow)
	d = _smooth_union(d, _sdf_sphere(pos, Vector3(-0.2, -0.1, 0.2), 0.25), 0.4 * flow)
	d = _smooth_union(d, _sdf_sphere(pos, Vector3(0.1, -0.2, -0.15), 0.2), 0.35 * flow)
	d = _smooth_union(d, _sdf_sphere(pos, Vector3(-0.1, 0.25, -0.1), 0.22), 0.35 * flow)
	d += _noise3(pos * 3.0) * 0.06 * complexity
	return -d


func _sdf_spiral(pos: Vector3, flow: float, complexity: float) -> float:
	var d: float = _sdf_torus_xz(pos, Vector3.ZERO, 0.45, 0.12)
	# Add a second torus rotated
	var rotated := Vector3(pos.y, pos.x, pos.z)
	d = _smooth_union(d, _sdf_torus_xz(rotated, Vector3.ZERO, 0.35, 0.1), 0.2 * flow)
	d += _noise3(pos * 4.0) * 0.05 * complexity
	return -d


func _sdf_fractal(pos: Vector3, complexity: float) -> float:
	# Tree-like: vertical trunk + branching spheres
	var trunk: float = _sdf_box(pos, Vector3(0, -0.1, 0), Vector3(0.08, 0.5, 0.08))
	var branch1: float = _sdf_sphere(pos, Vector3(0.2, 0.25, 0), 0.18)
	var branch2: float = _sdf_sphere(pos, Vector3(-0.15, 0.35, 0.1), 0.15)
	var branch3: float = _sdf_sphere(pos, Vector3(0.05, 0.45, -0.12), 0.12)
	var d: float = _smooth_union(trunk, branch1, 0.15)
	d = _smooth_union(d, branch2, 0.12)
	d = _smooth_union(d, branch3, 0.1)
	d += _noise3(pos * 5.0) * 0.04 * complexity
	return -d


func _sdf_cluster(pos: Vector3, complexity: float, rng: RandomNumberGenerator) -> float:
	# Seeded sphere cluster
	rng.seed = rng.seed  # Reset to initial seed for consistency
	var d: float = 1e10
	for i in 6:
		var center := Vector3(
			rng.randf_range(-0.3, 0.3),
			rng.randf_range(-0.3, 0.3),
			rng.randf_range(-0.3, 0.3)
		)
		var radius: float = rng.randf_range(0.12, 0.28)
		d = _smooth_union(d, _sdf_sphere(pos, center, radius), 0.2)
	d += _noise3(pos * 3.0) * 0.04 * complexity
	return -d


func _sdf_cave(pos: Vector3, hollow: float, complexity: float) -> float:
	var outer: float = _sdf_sphere(pos, Vector3.ZERO, 0.7)
	var inner: float = _sdf_sphere(pos, Vector3.ZERO, 0.7 * hollow)
	var shell: float = maxf(outer, -inner)
	# Punch holes with noise
	var holes: float = _noise3(pos * 4.0 * complexity)
	if holes > 0.3:
		shell = maxf(shell, -(0.1 - abs(holes - 0.5) * 0.3))
	return -shell


func _sdf_cellular(pos: Vector3, hollow: float, complexity: float) -> float:
	var outer: float = _sdf_sphere(pos, Vector3.ZERO, 0.65)
	# Voronoi-like cells via repeating subtractions
	var cell_d: float = 1e10
	var cs: float = 0.3
	var cell_pos := Vector3(
		floorf(pos.x / cs) * cs,
		floorf(pos.y / cs) * cs,
		floorf(pos.z / cs) * cs
	)
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				var nb := cell_pos + Vector3(dx, dy, dz) * cs
				var center := nb + Vector3(
					_noise3(nb * 0.5) * cs * 0.3,
					_noise3(nb * 0.5 + Vector3(10, 0, 0)) * cs * 0.3,
					_noise3(nb * 0.5 + Vector3(0, 10, 0)) * cs * 0.3
				)
				cell_d = minf(cell_d, (pos - center).length())
	var wall: float = cs * 0.12 * (1.0 - hollow * 0.5) - cell_d
	var d: float = maxf(-outer, wall)
	return -d


# ── Marching cubes surface extraction ────────────────────────

func _march_field(field: Array, size: int, cell: float, half: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var has_tris: bool = false

	for x in size - 1:
		for y in size - 1:
			for z in size - 1:
				var vals: Array[float] = [
					field[x][y][z],
					field[x + 1][y][z],
					field[x + 1][y][z + 1],
					field[x][y][z + 1],
					field[x][y + 1][z],
					field[x + 1][y + 1][z],
					field[x + 1][y + 1][z + 1],
					field[x][y + 1][z + 1],
				]

				# Check surface crossing
				var pos_count: int = 0
				for v in vals:
					if v > 0.0:
						pos_count += 1
				if pos_count == 0 or pos_count == 8:
					continue

				# For each edge that crosses zero, interpolate vertex
				var corners: Array[Vector3] = [
					Vector3(x, y, z), Vector3(x + 1, y, z),
					Vector3(x + 1, y, z + 1), Vector3(x, y, z + 1),
					Vector3(x, y + 1, z), Vector3(x + 1, y + 1, z),
					Vector3(x + 1, y + 1, z + 1), Vector3(x, y + 1, z + 1),
				]

				# Edges: pairs of corner indices
				var edges: Array = [
					[0,1],[1,2],[2,3],[3,0],
					[4,5],[5,6],[6,7],[7,4],
					[0,4],[1,5],[2,6],[3,7],
				]

				var edge_verts: Array[Vector3] = []
				for edge in edges:
					var a_idx: int = edge[0]
					var b_idx: int = edge[1]
					var va: float = vals[a_idx]
					var vb: float = vals[b_idx]
					if (va > 0.0) != (vb > 0.0):
						var t: float = va / (va - vb)
						var world_a: Vector3 = corners[a_idx] * cell - Vector3(half, half, half)
						var world_b: Vector3 = corners[b_idx] * cell - Vector3(half, half, half)
						edge_verts.append(world_a.lerp(world_b, t))

				# Fan triangulate the edge vertices around their centroid
				if edge_verts.size() >= 3:
					var centroid := Vector3.ZERO
					for ev in edge_verts:
						centroid += ev
					centroid /= float(edge_verts.size())

					# Sort around centroid normal
					var normal := Vector3.ZERO
					for i in edge_verts.size():
						var a2: Vector3 = edge_verts[i] - centroid
						var b2: Vector3 = edge_verts[(i + 1) % edge_verts.size()] - centroid
						normal += a2.cross(b2)
					normal = normal.normalized()

					# Build fan
					for i in edge_verts.size() - 2:
						st.add_vertex(edge_verts[0])
						st.add_vertex(edge_verts[i + 1])
						st.add_vertex(edge_verts[i + 2])
						has_tris = true

	if not has_tris:
		return null

	st.generate_normals()
	return st.commit()
