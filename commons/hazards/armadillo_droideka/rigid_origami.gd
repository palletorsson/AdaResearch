extends RefCounted
class_name RigidOrigami
## Rigid origami geometry solver.
## Given a crease pattern and a deployment parameter, computes the 3D vertex positions
## such that all faces remain rigid (no stretching/shearing).
##
## Based on the waterbomb/magic-ball mechanism which has 1 DOF.

## A single vertex in the crease pattern
class PatternVertex:
	var id: int
	var flat_pos: Vector2  # Position in the flat (unfolded) pattern
	var pos_3d: Vector3    # Computed 3D position
	var is_boundary: bool = false
	
	func _init(p_id: int, p_pos: Vector2) -> void:
		id = p_id
		flat_pos = p_pos
		pos_3d = Vector3(p_pos.x, 0.0, p_pos.y)


## A crease (edge) in the pattern
class Crease:
	var id: int
	var v0: int  # Vertex indices
	var v1: int
	var fold_sign: float  # +1 = mountain, -1 = valley
	var rest_length: float
	var fold_angle: float = 0.0  # Current fold angle (radians, 0 = flat)
	
	func _init(p_id: int, p_v0: int, p_v1: int, p_sign: float, p_length: float) -> void:
		id = p_id
		v0 = p_v0
		v1 = p_v1
		fold_sign = p_sign
		rest_length = p_length


## A triangular face
class Face:
	var id: int
	var vertices: PackedInt32Array  # 3 vertex indices (CCW order)
	var edges: PackedInt32Array     # 3 crease indices
	var normal: Vector3
	
	func _init(p_id: int, p_verts: PackedInt32Array) -> void:
		id = p_id
		vertices = p_verts


# Pattern data
var vertices: Array[PatternVertex] = []
var creases: Array[Crease] = []
var faces: Array[Face] = []
var _edge_map: Dictionary = {}  # Vector2i -> crease index

# Configuration
var radial_segments: int = 12
var ring_count: int = 2
var base_radius: float = 1.0


func build_waterbomb_ball(n_segments: int, n_rings: int, radius: float) -> void:
	## Generate a waterbomb ball crease pattern.
	## This is a radially symmetric pattern that can inflate/deflate.
	
	radial_segments = max(4, n_segments)
	ring_count = max(1, n_rings)
	base_radius = radius
	
	vertices.clear()
	creases.clear()
	faces.clear()
	_edge_map.clear()
	
	var n: int = radial_segments
	var m: int = ring_count
	var angle_step: float = TAU / float(n)
	
	# === Generate vertices ===
	
	# Top pole
	var top_pole: int = _add_vertex(Vector2.ZERO)
	
	# Rings from pole toward equator
	# Each ring has n primary vertices + n cell-center vertices
	var ring_primary: Array[PackedInt32Array] = []
	var ring_centers: Array[PackedInt32Array] = []
	
	for r in range(m):
		var ring_radius: float = base_radius * float(r + 1) / float(m + 1)
		var center_radius: float = base_radius * (float(r) + 0.5) / float(m + 1)
		
		var primaries: PackedInt32Array = []
		var centers: PackedInt32Array = []
		
		for s in range(n):
			var angle: float = angle_step * float(s)
			var center_angle: float = angle_step * (float(s) + 0.5)
			
			# Primary vertex on ring
			var px: float = cos(angle) * ring_radius
			var py: float = sin(angle) * ring_radius
			primaries.append(_add_vertex(Vector2(px, py)))
			
			# Center vertex (between rings)
			if r > 0:
				var cx: float = cos(center_angle) * center_radius
				var cy: float = sin(center_angle) * center_radius
				centers.append(_add_vertex(Vector2(cx, cy)))
		
		ring_primary.append(primaries)
		if centers.size() > 0:
			ring_centers.append(centers)
	
	# Equator vertices
	var equator: PackedInt32Array = []
	for s in range(n):
		var angle: float = angle_step * float(s)
		var ex: float = cos(angle) * base_radius
		var ey: float = sin(angle) * base_radius
		equator.append(_add_vertex(Vector2(ex, ey)))
	
	# === Generate faces and creases ===
	
	# Top cap: triangles from pole to first ring
	var first_ring: PackedInt32Array = ring_primary[0]
	for s in range(n):
		var next_s: int = (s + 1) % n
		var v0: int = top_pole
		var v1: int = first_ring[s]
		var v2: int = first_ring[next_s]
		
		_add_face([v0, v1, v2])
		_add_crease(v0, v1, 1.0)  # Mountain from pole
		_add_crease(v1, v2, -1.0)  # Valley around ring
	
	# Intermediate rings: waterbomb cells
	for r in range(m - 1):
		var inner: PackedInt32Array = ring_primary[r]
		var outer: PackedInt32Array = ring_primary[r + 1]
		
		for s in range(n):
			var next_s: int = (s + 1) % n
			
			# Quad between inner and outer ring, split into 2 triangles
			var vi0: int = inner[s]
			var vi1: int = inner[next_s]
			var vo0: int = outer[s]
			var vo1: int = outer[next_s]
			
			# Waterbomb pattern: diagonal crease
			_add_face([vi0, vo0, vi1])
			_add_face([vi1, vo0, vo1])
			
			_add_crease(vi0, vo0, 1.0)   # Mountain
			_add_crease(vo0, vi1, -1.0)  # Valley (diagonal)
			_add_crease(vi1, vo1, 1.0)   # Mountain
			_add_crease(vo0, vo1, -1.0)  # Valley around ring
	
	# Connect last ring to equator
	var last_ring: PackedInt32Array = ring_primary[m - 1]
	for s in range(n):
		var next_s: int = (s + 1) % n
		var vi0: int = last_ring[s]
		var vi1: int = last_ring[next_s]
		var ve0: int = equator[s]
		var ve1: int = equator[next_s]
		
		_add_face([vi0, ve0, vi1])
		_add_face([vi1, ve0, ve1])
		
		_add_crease(vi0, ve0, 1.0)
		_add_crease(ve0, vi1, -1.0)
		_add_crease(vi1, ve1, 1.0)
		_add_crease(ve0, ve1, 0.0)  # Equator edge (neutral)
	
	# Bottom hemisphere mirrors top (for a full ball)
	_mirror_hemisphere_z()


func _add_vertex(pos: Vector2) -> int:
	var idx: int = vertices.size()
	var v: PatternVertex = PatternVertex.new(idx, pos)
	vertices.append(v)
	return idx


func _add_crease(v0: int, v1: int, fold_sign: float) -> int:
	var edge_key: Vector2i = Vector2i(min(v0, v1), max(v0, v1))
	if _edge_map.has(edge_key):
		return _edge_map[edge_key]
	
	var length: float = vertices[v0].flat_pos.distance_to(vertices[v1].flat_pos)
	var idx: int = creases.size()
	var c: Crease = Crease.new(idx, v0, v1, fold_sign, length)
	creases.append(c)
	_edge_map[edge_key] = idx
	return idx


func _add_face(vert_indices: Array) -> int:
	var idx: int = faces.size()
	var verts: PackedInt32Array = []
	for v in vert_indices:
		verts.append(v)
	var f: Face = Face.new(idx, verts)
	faces.append(f)
	return idx


func _mirror_hemisphere_z() -> void:
	## Mirror vertices and faces to create bottom hemisphere.
	## Skip equator vertices (don't duplicate them).
	
	var original_vert_count: int = vertices.size()
	var original_face_count: int = faces.size()
	var vertex_mirror_map: Dictionary = {}  # old_idx -> new_idx
	
	# Find equator vertices (at max radius)
	var max_dist: float = 0.0
	for v in vertices:
		max_dist = max(max_dist, v.flat_pos.length())
	var equator_threshold: float = max_dist * 0.99
	
	# Mirror non-equator vertices
	for i in range(original_vert_count):
		var v: PatternVertex = vertices[i]
		if v.flat_pos.length() >= equator_threshold:
			vertex_mirror_map[i] = i  # Equator maps to itself
		else:
			# Mirror by negating z in flat pattern (conceptually)
			# In practice, we create a new vertex with same flat_pos
			# but it will get mirrored 3D position
			var new_idx: int = vertices.size()
			var new_v: PatternVertex = PatternVertex.new(new_idx, v.flat_pos)
			vertices.append(new_v)
			vertex_mirror_map[i] = new_idx
	
	# Mirror faces (reverse winding)
	for i in range(original_face_count):
		var f: Face = faces[i]
		var new_verts: PackedInt32Array = []
		# Reverse order for correct winding
		for j in range(f.vertices.size() - 1, -1, -1):
			var old_v: int = f.vertices[j]
			new_verts.append(vertex_mirror_map[old_v])
		_add_face(new_verts)
	
	# Mirror creases
	var original_crease_count: int = creases.size()
	for i in range(original_crease_count):
		var c: Crease = creases[i]
		var new_v0: int = vertex_mirror_map[c.v0]
		var new_v1: int = vertex_mirror_map[c.v1]
		if new_v0 != c.v0 or new_v1 != c.v1:
			_add_crease(new_v0, new_v1, -c.fold_sign)  # Flip sign for mirror


func solve_deployment(t: float) -> void:
	## Given deployment parameter t in [0, 1], compute 3D vertex positions.
	## t = 0: fully collapsed (compact ball)
	## t = 1: fully deployed (open flower)
	##
	## Uses an iterative constraint solver to maintain edge lengths.
	
	t = clamp(t, 0.0, 1.0)
	
	# First, compute target fold angles from deployment
	_compute_fold_angles(t)
	
	# Initialize 3D positions from spherical mapping
	_initialize_positions(t)
	
	# Iteratively project to satisfy edge length constraints
	for _iter in range(10):
		_project_edge_constraints()


func _compute_fold_angles(t: float) -> void:
	## Compute fold angles for each crease based on deployment.
	## For waterbomb: mountains fold inward when collapsed, outward when deployed.
	
	# Fold angle range:
	# t=0 (collapsed): mountains at +fold_max, valleys at -fold_max
	# t=1 (deployed): all folds near 0 (flat)
	
	var fold_max: float = PI * 0.6  # Max fold angle
	
	for c in creases:
		if abs(c.fold_sign) < 0.01:
			c.fold_angle = 0.0
		else:
			# Interpolate from max fold to flat
			c.fold_angle = c.fold_sign * fold_max * (1.0 - t)


func _initialize_positions(t: float) -> void:
	## Initialize 3D positions using spherical/conical mapping.
	## This provides a good starting point for the constraint solver.
	
	var max_flat_radius: float = 0.0
	for v in vertices:
		max_flat_radius = max(max_flat_radius, v.flat_pos.length())
	if max_flat_radius < 0.001:
		max_flat_radius = 1.0
	
	# Sphere parameters based on deployment
	var sphere_radius: float = base_radius * lerp(0.35, 1.0, t)
	var opening_angle: float = lerp(PI * 0.3, PI * 0.8, t)  # How "open" the flower is
	
	var vert_count: int = vertices.size()
	var half_count: int = (vert_count + 1) / 2  # Rough split for hemispheres
	
	for i in range(vertices.size()):
		var v: PatternVertex = vertices[i]
		var flat_r: float = v.flat_pos.length()
		var flat_theta: float = atan2(v.flat_pos.y, v.flat_pos.x)
		
		# Normalize radius
		var r_norm: float = flat_r / max_flat_radius
		
		# Map to spherical coordinates
		# phi = elevation from pole (0 at pole, PI/2 at equator)
		var phi: float = r_norm * opening_angle
		
		# Determine hemisphere (using vertex index as proxy)
		var is_bottom: bool = i >= half_count and flat_r < max_flat_radius * 0.99
		if is_bottom:
			phi = PI - phi  # Mirror to bottom
		
		# 3D position on sphere
		v.pos_3d = Vector3(
			sin(phi) * cos(flat_theta) * sphere_radius,
			cos(phi) * sphere_radius,
			sin(phi) * sin(flat_theta) * sphere_radius
		)


func _project_edge_constraints() -> void:
	## Project vertices to satisfy edge length constraints.
	## Uses position-based dynamics style constraint projection.
	
	var correction_strength: float = 0.4
	
	for c in creases:
		var v0: PatternVertex = vertices[c.v0]
		var v1: PatternVertex = vertices[c.v1]
		
		var current_length: float = v0.pos_3d.distance_to(v1.pos_3d)
		if current_length < 0.0001:
			continue
		
		var error: float = current_length - c.rest_length
		var direction: Vector3 = (v1.pos_3d - v0.pos_3d).normalized()
		var correction: Vector3 = direction * error * correction_strength * 0.5
		
		v0.pos_3d += correction
		v1.pos_3d -= correction


## Getters for mesh building

func get_vertex_positions() -> PackedVector3Array:
	var positions: PackedVector3Array = []
	for v in vertices:
		positions.append(v.pos_3d)
	return positions


func get_face_indices() -> Array[PackedInt32Array]:
	var indices: Array[PackedInt32Array] = []
	for f in faces:
		indices.append(f.vertices)
	return indices


func get_crease_pairs() -> Array[Vector2i]:
	var pairs: Array[Vector2i] = []
	for c in creases:
		pairs.append(Vector2i(c.v0, c.v1))
	return pairs


func get_crease_signs() -> PackedFloat32Array:
	var signs: PackedFloat32Array = []
	for c in creases:
		signs.append(c.fold_sign)
	return signs
