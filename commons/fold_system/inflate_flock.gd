# @identity
# essence: vertices flock like boids to inflate/deflate a mesh — pressure pushes out, cohesion holds shape
# desire: a living membrane that breathes — inflating with organic wobble, deflating into a tight seed
# critical_parameter: fold_amount — 0 is deflated (all vertices at centroid), 1 is fully inflated
# triggers: each vertex feels pressure (outward), separation (don't overlap), cohesion (stay grouped)
# emerges: the mesh breathes because vertices negotiate position instead of following a script
# truth: inflation is democracy. every vertex votes on where the surface should be.

class_name InflateFlock
extends Node3D
## A mesh that inflates/deflates using vertex flocking.
## At fold_amount=0, vertices are packed at the center.
## At fold_amount=1, vertices reach their target positions.
## Flocking rules (separation, cohesion, alignment) create organic motion.
## Shows 5 stages side by side.

const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")

const STAGE_COUNT := 5
const STAGE_FOLDS: PackedFloat64Array = [0.0, 0.25, 0.5, 0.75, 1.0]
const SPACING := 0.45

@export var subdivisions: int = 2       ## Icosphere subdivision level (0=20f, 1=80f, 2=320f)
@export var target_radius: float = 0.1  ## Full inflated radius
@export var separation_radius: float = 0.02  ## Min distance between vertices
@export var separation_strength: float = 0.3
@export var cohesion_strength: float = 0.1
@export var pressure_strength: float = 1.0   ## Outward inflation force

var _verts_target: Array[Vector3] = []   ## Inflated positions (icosphere surface)
var _verts_center: Array[Vector3] = []   ## Deflated positions (all at center)
var _faces: Array = []
var _neighbors: Array = []               ## Per-vertex neighbor lists for flocking


func _ready() -> void:
	_generate_icosphere()
	_compute_neighbors()
	_build_stages()


func _generate_icosphere() -> void:
	# Start with icosahedron
	var phi: float = (1.0 + sqrt(5.0)) / 2.0
	var a: float = 1.0 / sqrt(1.0 + phi * phi)
	var b: float = phi * a

	var verts: Array[Vector3] = [
		Vector3(-a, b, 0), Vector3(a, b, 0), Vector3(-a, -b, 0), Vector3(a, -b, 0),
		Vector3(0, -a, b), Vector3(0, a, b), Vector3(0, -a, -b), Vector3(0, a, -b),
		Vector3(b, 0, -a), Vector3(b, 0, a), Vector3(-b, 0, -a), Vector3(-b, 0, a),
	]
	var faces: Array = [
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
		[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
		[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
	]

	# Subdivide
	for _sub in subdivisions:
		var new_faces: Array = []
		var edge_midpoints: Dictionary = {}

		for face in faces:
			var v0: int = face[0]
			var v1: int = face[1]
			var v2: int = face[2]

			var m01: int = _get_midpoint(v0, v1, verts, edge_midpoints)
			var m12: int = _get_midpoint(v1, v2, verts, edge_midpoints)
			var m20: int = _get_midpoint(v2, v0, verts, edge_midpoints)

			new_faces.append([v0, m01, m20])
			new_faces.append([v1, m12, m01])
			new_faces.append([v2, m20, m12])
			new_faces.append([m01, m12, m20])

		faces = new_faces

	# Normalize to sphere and scale
	# Deflated = tightly crumpled ball at 15% of target radius (not a point)
	# Same vertices, visible at every stage
	var deflated_radius: float = target_radius * 0.3
	_verts_target.clear()
	_verts_center.clear()
	for v in verts:
		var dir: Vector3 = v.normalized()
		_verts_target.append(dir * target_radius)
		# Crumpled: same direction but compressed, with noise for wrinkle texture
		var noise_offset: float = sin(dir.x * 13.0 + dir.y * 7.0 + dir.z * 11.0) * deflated_radius * 0.4
		_verts_center.append(dir * (deflated_radius + noise_offset))

	_faces = faces


func _get_midpoint(v0: int, v1: int, verts: Array[Vector3], cache: Dictionary) -> int:
	var key: int = mini(v0, v1) * 10000 + maxi(v0, v1)
	if cache.has(key):
		return cache[key]
	var mid: Vector3 = (verts[v0] + verts[v1]) * 0.5
	verts.append(mid)
	var idx: int = verts.size() - 1
	cache[key] = idx
	return idx


func _compute_neighbors() -> void:
	# Build adjacency: for each vertex, which other vertices share a face
	_neighbors.resize(_verts_target.size())
	for i in _verts_target.size():
		_neighbors[i] = []

	for face in _faces:
		for i in 3:
			var vi: int = face[i]
			for j in 3:
				if i == j:
					continue
				var vj: int = face[j]
				if not (vj in _neighbors[vi]):
					_neighbors[vi].append(vj)


func _build_stages() -> void:
	var total_w: float = (STAGE_COUNT - 1) * SPACING
	var start_x: float = -total_w * 0.5

	for stage in STAGE_COUNT:
		var fold_t: float = STAGE_FOLDS[stage]
		var x_off: float = start_x + stage * SPACING

		# Compute vertex positions with flocking
		var verts: Array = _compute_flocked_positions(fold_t)

		# Color: blue (deflated) → white → warm (inflated)
		var color: Color
		if fold_t < 0.5:
			color = Color(0.4 + fold_t * 0.6, 0.5 + fold_t * 0.5, 0.8 - fold_t * 0.2)
		else:
			var ft: float = (fold_t - 0.5) * 2.0
			color = Color(0.7 + ft * 0.25, 0.75 - ft * 0.15, 0.5 - ft * 0.2)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.6
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.emission_enabled = true
		mat.emission = color * 0.2
		mat.emission_energy_multiplier = 0.5

		var mesh: ArrayMesh = PrimitiveMeshBuilder.build_mesh(verts, _faces, {"double_sided": true})
		if not mesh:
			continue

		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		mi.position = Vector3(x_off, target_radius, 0)
		add_child(mi)

		var label := Label3D.new()
		label.text = "%.0f%%\n%dv %df" % [fold_t * 100.0, verts.size(), _faces.size()]
		label.font_size = 42
		label.pixel_size = 0.002
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color(color.r, color.g, color.b, 0.9)
		label.position = Vector3(x_off, -0.04, 0)
		add_child(label)


func _compute_flocked_positions(fold_t: float) -> Array:
	## Compute positions by simulating a few steps of flocking from the lerped base.
	## Base position = lerp(center, target, fold_t)
	## Then apply separation + cohesion + pressure for organic wobble.

	# Start with simple lerp
	var positions: Array[Vector3] = []
	for i in _verts_target.size():
		positions.append(_verts_center[i].lerp(_verts_target[i], fold_t))

	# Skip flocking for 0% (all at center, no neighbors to flock with)
	if fold_t < 0.01:
		var result: Array = []
		for v in positions:
			result.append(v)
		return result

	# Run a few flocking iterations to distribute vertices organically
	var iterations: int = 8
	for _iter in iterations:
		var forces: Array[Vector3] = []
		forces.resize(positions.size())
		for i in positions.size():
			forces[i] = Vector3.ZERO

		for i in positions.size():
			var pos: Vector3 = positions[i]
			var target: Vector3 = _verts_target[i] * fold_t
			var neighbor_list: Array = _neighbors[i]

			# Pressure: push toward inflated target position
			var pressure: Vector3 = (target - pos) * pressure_strength

			# Separation: push away from too-close neighbors
			var sep := Vector3.ZERO
			for ni in neighbor_list:
				var diff: Vector3 = pos - positions[ni]
				var dist: float = diff.length()
				if dist < separation_radius and dist > 0.0001:
					sep += diff.normalized() * (separation_radius - dist) / separation_radius

			sep *= separation_strength

			# Cohesion: pull toward average neighbor position
			var avg := Vector3.ZERO
			for ni in neighbor_list:
				avg += positions[ni]
			if neighbor_list.size() > 0:
				avg /= float(neighbor_list.size())
			var coh: Vector3 = (avg - pos) * cohesion_strength

			forces[i] = pressure + sep + coh

		# Apply forces with small step
		var step: float = 0.15
		for i in positions.size():
			positions[i] += forces[i] * step

	var result: Array = []
	for v in positions:
		result.append(v)
	return result


func apply_grid_config(_config: Dictionary) -> void:
	pass
