## VoronoiCS — Irregular Voronoi tessellation coordinate system
## Seed points generate irregular cells via nearest-neighbor partitioning.
## Reuses cell generation approach from voronoi_visualization.gd.
## Natural for organic patterns, stained glass, cracked earth, biological structures.
##
## grid_width = number of seed points
## grid_height = grid resolution for cell boundary computation

extends "res://commons/composition/coordinate_system.gd"

var seeds: Array = []          # Array of Vector2 seed positions
var cell_vertices: Array = []  # Array of Array[Vector2] — polygon vertices per cell
var bounds: Vector2 = Vector2(20.0, 20.0)
var _rng = RandomNumberGenerator.new()

enum SeedStrategy { RANDOM, BLUE_NOISE, GRID_JITTERED, RELAXED }
var seed_strategy: int = SeedStrategy.GRID_JITTERED

# Gap factor for visual separation between cells (0.0 = no gap, 1.0 = full size)
var cell_gap: float = 0.96

func _init(seed_count: int = 30, bound_size: int = 20, cs: float = 1.0) -> void:
	type = Type.VORONOI
	grid_width = seed_count
	grid_height = bound_size
	cell_size = cs
	bounds = Vector2(float(bound_size) * cs, float(bound_size) * cs)
	_rng.seed = seed_count * 7919 + bound_size
	_generate_seeds()
	_compute_cells()

func set_seed_strategy(strategy: int, seed_val: int = 42) -> void:
	seed_strategy = strategy
	_rng.seed = seed_val
	_generate_seeds()
	_compute_cells()

func iterate_cells() -> Array:
	var cells: Array = []
	for i in seeds.size():
		cells.append(i)
	return cells

func cell_to_world(cell_key) -> Vector3:
	var idx: int = int(cell_key)
	if idx < 0 or idx >= seeds.size():
		return Vector3.ZERO
	var pos: Vector2 = seeds[idx]
	return Vector3(pos.x - bounds.x * 0.5, 0.0, pos.y - bounds.y * 0.5)

func create_cell_mesh(cell_key) -> Mesh:
	var idx: int = int(cell_key)
	if idx < 0 or idx >= cell_vertices.size():
		return null
	var verts: Array = cell_vertices[idx]
	if verts.size() < 3:
		return null
	return _build_polygon_mesh(verts, seeds[idx])

func cell_to_normalized(cell_key) -> Vector2:
	var idx: int = int(cell_key)
	if idx < 0 or idx >= seeds.size():
		return Vector2(0.5, 0.5)
	return Vector2(seeds[idx].x / bounds.x, seeds[idx].y / bounds.y)

func get_world_width() -> float:
	return bounds.x

func get_world_height() -> float:
	return bounds.y

# ═══════════════════════════════════════════════════════════════════
# SEED GENERATION
# ═══════════════════════════════════════════════════════════════════

func _generate_seeds() -> void:
	seeds.clear()
	match seed_strategy:
		SeedStrategy.RANDOM:
			for _i in grid_width:
				seeds.append(Vector2(
					_rng.randf_range(0.5, bounds.x - 0.5),
					_rng.randf_range(0.5, bounds.y - 0.5)
				))
		SeedStrategy.GRID_JITTERED:
			_generate_jittered_grid()
		SeedStrategy.BLUE_NOISE:
			_generate_blue_noise()
		SeedStrategy.RELAXED:
			_generate_relaxed()

func _generate_jittered_grid() -> void:
	# Approximate sqrt for grid dimensions
	var cols = ceili(sqrt(float(grid_width)))
	var rows = ceili(float(grid_width) / float(cols))
	var dx = bounds.x / float(cols)
	var dy = bounds.y / float(rows)
	var count = 0
	# Jitter at 0.4 of cell size for good visual variety while keeping regularity
	var jitter_factor: float = 0.4

	for r in rows:
		for c in cols:
			if count >= grid_width:
				break
			var jx = _rng.randf_range(-dx * jitter_factor, dx * jitter_factor)
			var jy = _rng.randf_range(-dy * jitter_factor, dy * jitter_factor)
			var px = (float(c) + 0.5) * dx + jx
			var py = (float(r) + 0.5) * dy + jy
			px = clampf(px, 0.1, bounds.x - 0.1)
			py = clampf(py, 0.1, bounds.y - 0.1)
			seeds.append(Vector2(px, py))
			count += 1

func _generate_blue_noise() -> void:
	# Simple dart-throwing blue noise
	var min_dist = bounds.x / (sqrt(float(grid_width)) * 1.5)
	var attempts: int = 0
	var max_attempts: int = grid_width * 30

	while seeds.size() < grid_width and attempts < max_attempts:
		var candidate = Vector2(
			_rng.randf_range(0.5, bounds.x - 0.5),
			_rng.randf_range(0.5, bounds.y - 0.5)
		)
		var valid: bool = true
		for existing in seeds:
			if candidate.distance_to(existing) < min_dist:
				valid = false
				break
		if valid:
			seeds.append(candidate)
		attempts += 1

	# Fill remaining with random if dart throwing exhausted attempts
	while seeds.size() < grid_width:
		seeds.append(Vector2(
			_rng.randf_range(0.5, bounds.x - 0.5),
			_rng.randf_range(0.5, bounds.y - 0.5)
		))

func _generate_relaxed() -> void:
	## Lloyd's relaxation: start with jittered grid, then iteratively
	## move each seed toward the centroid of its Voronoi cell.
	## Produces more uniform cell sizes — good for tile floors, mosaics.
	_generate_jittered_grid()
	var iterations: int = 5
	for _iter in iterations:
		_compute_cells()
		# Move each seed toward its cell centroid
		for i in seeds.size():
			var verts: Array = cell_vertices[i]
			if verts.size() < 3:
				continue
			var centroid = _polygon_centroid(verts)
			# Blend 70% toward centroid (full snap can cause instability)
			seeds[i] = seeds[i].lerp(centroid, 0.7)
			# Keep within bounds
			seeds[i].x = clampf(seeds[i].x, 0.1, bounds.x - 0.1)
			seeds[i].y = clampf(seeds[i].y, 0.1, bounds.y - 0.1)

func _polygon_centroid(verts: Array) -> Vector2:
	## Compute the centroid of a polygon using the signed-area formula.
	var cx: float = 0.0
	var cy: float = 0.0
	var signed_area: float = 0.0
	var n: int = verts.size()
	for i in n:
		var v0: Vector2 = verts[i]
		var v1: Vector2 = verts[(i + 1) % n]
		var cross: float = v0.x * v1.y - v1.x * v0.y
		signed_area += cross
		cx += (v0.x + v1.x) * cross
		cy += (v0.y + v1.y) * cross
	signed_area *= 0.5
	if absf(signed_area) < 1e-8:
		# Degenerate polygon — return arithmetic mean
		var mean = Vector2.ZERO
		for v in verts:
			mean += v
		return mean / float(n)
	cx /= (6.0 * signed_area)
	cy /= (6.0 * signed_area)
	return Vector2(cx, cy)

# ═══════════════════════════════════════════════════════════════════
# CELL COMPUTATION — grid-based nearest-neighbor + boundary clipping
# ═══════════════════════════════════════════════════════════════════

func _compute_cells() -> void:
	cell_vertices.clear()
	if seeds.is_empty():
		return

	# Adaptive resolution: scale with sqrt of seed count, clamped for sanity.
	# For 30 seeds in a 20x20 area, ~80 is sufficient. For 200+ seeds, go higher.
	var base_res = ceili(sqrt(float(grid_width)) * 14.0)
	var resolution: int = clampi(base_res, 40, 300)

	# Build spatial hash for fast nearest-seed lookup.
	# Bucket size chosen so each bucket contains ~1-4 seeds on average.
	var bucket_size: float = bounds.x / maxf(sqrt(float(grid_width)), 1.0)
	var bucket_cols: int = maxi(ceili(bounds.x / bucket_size), 1)
	var bucket_rows: int = maxi(ceili(bounds.y / bucket_size), 1)
	# Actual bucket dimensions
	var bw: float = bounds.x / float(bucket_cols)
	var bh: float = bounds.y / float(bucket_rows)

	# Populate buckets with seed indices
	var buckets: Dictionary = {}  # Vector2i -> Array[int]
	for i in seeds.size():
		var bc: int = clampi(int(seeds[i].x / bw), 0, bucket_cols - 1)
		var br: int = clampi(int(seeds[i].y / bh), 0, bucket_rows - 1)
		var key = Vector2i(bc, br)
		if not buckets.has(key):
			buckets[key] = []
		buckets[key].append(i)

	# Map grid sample points to nearest seed using spatial hash
	var cell_points: Dictionary = {}  # int -> Array[Vector2]
	for i in seeds.size():
		cell_points[i] = []

	var inv_res: float = 1.0 / float(resolution)
	for gx in resolution:
		var wx: float = (float(gx) + 0.5) * inv_res * bounds.x
		for gy in resolution:
			var wy: float = (float(gy) + 0.5) * inv_res * bounds.y
			var pos = Vector2(wx, wy)

			# Find nearest seed via spatial hash: check the bucket this point
			# falls in plus all 8 neighbors (handles seeds near bucket edges).
			var center_bc: int = clampi(int(wx / bw), 0, bucket_cols - 1)
			var center_br: int = clampi(int(wy / bh), 0, bucket_rows - 1)

			var closest_idx: int = -1
			var closest_dist: float = INF
			for dbr in range(-1, 2):
				var br_check: int = center_br + dbr
				if br_check < 0 or br_check >= bucket_rows:
					continue
				for dbc in range(-1, 2):
					var bc_check: int = center_bc + dbc
					if bc_check < 0 or bc_check >= bucket_cols:
						continue
					var bkey = Vector2i(bc_check, br_check)
					if not buckets.has(bkey):
						continue
					var bucket_seeds: Array = buckets[bkey]
					for si in bucket_seeds:
						var d: float = pos.distance_squared_to(seeds[si])
						if d < closest_dist:
							closest_dist = d
							closest_idx = si

			# Fallback: brute force if spatial hash missed (shouldn't happen often)
			if closest_idx == -1:
				closest_dist = pos.distance_squared_to(seeds[0])
				closest_idx = 0
				for i in range(1, seeds.size()):
					var d: float = pos.distance_squared_to(seeds[i])
					if d < closest_dist:
						closest_dist = d
						closest_idx = i

			cell_points[closest_idx].append(pos)

	# Build clipped convex hull for each cell
	var clip_rect = Rect2(Vector2.ZERO, bounds)
	for i in seeds.size():
		var points: Array = cell_points.get(i, [])
		if points.size() < 3:
			# Degenerate cell (seed near boundary or crowded out).
			# Create a small fallback polygon around the seed, clipped to bounds.
			var fallback = _make_fallback_cell(seeds[i], clip_rect)
			cell_vertices.append(fallback)
			continue
		var hull: Array = _convex_hull(points)
		# Clip hull to bounding box so boundary cells have clean edges
		hull = _clip_polygon_to_rect(hull, clip_rect)
		if hull.size() < 3:
			hull = _make_fallback_cell(seeds[i], clip_rect)
		cell_vertices.append(hull)

func _make_fallback_cell(seed_pos: Vector2, clip_rect: Rect2) -> Array:
	## Create a small square cell around a seed, clipped to bounds.
	## Used for degenerate cells that have < 3 sample points.
	var half = bounds.x / (sqrt(float(grid_width)) * 2.0)
	half = maxf(half, 0.3)
	var raw: Array = [
		Vector2(seed_pos.x - half, seed_pos.y - half),
		Vector2(seed_pos.x + half, seed_pos.y - half),
		Vector2(seed_pos.x + half, seed_pos.y + half),
		Vector2(seed_pos.x - half, seed_pos.y + half),
	]
	return _clip_polygon_to_rect(raw, clip_rect)

func _convex_hull(points: Array) -> Array:
	if points.size() < 3:
		return points.duplicate()

	# Find bottom-most point (lowest y, then leftmost x)
	var start = points[0]
	for p in points:
		if p.y < start.y or (p.y == start.y and p.x < start.x):
			start = p

	# Sort by polar angle relative to start
	var sorted_points = points.duplicate()
	sorted_points.sort_custom(func(a, b) -> bool:
		var angle_a = atan2(a.y - start.y, a.x - start.x)
		var angle_b = atan2(b.y - start.y, b.x - start.x)
		if absf(angle_a - angle_b) < 1e-9:
			# Same angle: keep closer point first
			return a.distance_squared_to(start) < b.distance_squared_to(start)
		return angle_a < angle_b
	)

	# Graham scan
	var hull: Array = []
	for point in sorted_points:
		while hull.size() > 1:
			var o: Vector2 = hull[hull.size() - 2]
			var a: Vector2 = hull[hull.size() - 1]
			var cross: float = (a.x - o.x) * (point.y - o.y) - (a.y - o.y) * (point.x - o.x)
			if cross <= 0.0:
				hull.pop_back()
			else:
				break
		hull.append(point)
	return hull

# ═══════════════════════════════════════════════════════════════════
# SUTHERLAND-HODGMAN POLYGON CLIPPING — clips polygon to axis-aligned rect
# ═══════════════════════════════════════════════════════════════════

func _clip_polygon_to_rect(polygon: Array, rect: Rect2) -> Array:
	## Clip a convex polygon to an axis-aligned rectangle.
	## Uses Sutherland-Hodgman algorithm — clips against each edge in turn.
	if polygon.size() < 3:
		return polygon
	var output: Array = polygon.duplicate()
	# Clip edges: left, right, bottom, top
	# Left edge (x >= rect.position.x)
	output = _clip_edge(output, 0, rect.position.x, true)
	if output.size() < 3:
		return output
	# Right edge (x <= rect.end.x)
	output = _clip_edge(output, 0, rect.end.x, false)
	if output.size() < 3:
		return output
	# Bottom edge (y >= rect.position.y)
	output = _clip_edge(output, 1, rect.position.y, true)
	if output.size() < 3:
		return output
	# Top edge (y <= rect.end.y)
	output = _clip_edge(output, 1, rect.end.y, false)
	return output

func _clip_edge(polygon: Array, axis: int, threshold: float, keep_greater: bool) -> Array:
	## Clip polygon against a single axis-aligned edge.
	## axis: 0 = x, 1 = y
	## keep_greater: true = keep points >= threshold, false = keep points <= threshold
	var result: Array = []
	var n: int = polygon.size()
	if n == 0:
		return result

	for i in n:
		var current: Vector2 = polygon[i]
		var next_pt: Vector2 = polygon[(i + 1) % n]
		var c_val: float = current[axis]
		var n_val: float = next_pt[axis]
		var c_inside: bool = (c_val >= threshold) if keep_greater else (c_val <= threshold)
		var n_inside: bool = (n_val >= threshold) if keep_greater else (n_val <= threshold)

		if c_inside:
			result.append(current)
			if not n_inside:
				# Exiting: add intersection
				result.append(_intersect_edge(current, next_pt, axis, threshold))
		elif n_inside:
			# Entering: add intersection
			result.append(_intersect_edge(current, next_pt, axis, threshold))
	return result

func _intersect_edge(p0: Vector2, p1: Vector2, axis: int, threshold: float) -> Vector2:
	## Find intersection of segment p0->p1 with an axis-aligned line.
	var d: float = p1[axis] - p0[axis]
	if absf(d) < 1e-12:
		return p0  # Parallel — shouldn't normally happen
	var t: float = (threshold - p0[axis]) / d
	return p0.lerp(p1, t)

# ═══════════════════════════════════════════════════════════════════
# POLYGON MESH — builds ArrayMesh from cell vertices
# ═══════════════════════════════════════════════════════════════════

func _build_polygon_mesh(verts: Array, center: Vector2) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()

	# Sort vertices around center for correct winding order
	var sorted: Array = verts.duplicate()
	sorted.sort_custom(func(a, b) -> bool:
		var angle_a = atan2(a.y - center.y, a.x - center.x)
		var angle_b = atan2(b.y - center.y, b.x - center.x)
		return angle_a < angle_b
	)

	# Compute cell-local AABB for proper 0..1 UV mapping
	var aabb_min = Vector2(sorted[0].x, sorted[0].y)
	var aabb_max = aabb_min
	for v in sorted:
		aabb_min.x = minf(aabb_min.x, v.x)
		aabb_min.y = minf(aabb_min.y, v.y)
		aabb_max.x = maxf(aabb_max.x, v.x)
		aabb_max.y = maxf(aabb_max.y, v.y)
	var aabb_size = aabb_max - aabb_min
	# Prevent division by zero for flat cells
	aabb_size.x = maxf(aabb_size.x, 0.001)
	aabb_size.y = maxf(aabb_size.y, 0.001)

	# Center vertex (index 0)
	vertices.append(Vector3.ZERO)
	normals.append(Vector3.UP)
	# UV for center: map center position into the cell's AABB
	var center_uv = Vector2(
		(center.x - aabb_min.x) / aabb_size.x,
		(center.y - aabb_min.y) / aabb_size.y
	)
	uvs.append(center_uv.clamp(Vector2.ZERO, Vector2.ONE))

	# Ring vertices — shrink slightly for gap between cells
	for v in sorted:
		var local = v - center
		local *= cell_gap
		vertices.append(Vector3(local.x, 0.0, local.y))
		normals.append(Vector3.UP)
		# UV: map original (pre-gap) position into cell's AABB for 0..1 range
		var uv = Vector2(
			(v.x - aabb_min.x) / aabb_size.x,
			(v.y - aabb_min.y) / aabb_size.y
		)
		uvs.append(uv.clamp(Vector2.ZERO, Vector2.ONE))

	# Fan triangulation from center
	var n: int = sorted.size()
	for i in n:
		indices.append(0)
		indices.append(i + 1)
		indices.append((i + 1) % n + 1)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
