extends Node3D
class_name Grid3DRenderer

## Dual MultiMesh renderer for Grid3D substrate.
## - Node MultiMesh: spheres at 3D positions
## - Edge MultiMesh: thin cylinders connecting node pairs
## Per-instance color + emission via INSTANCE_CUSTOM.

const NODE_RADIUS: float = 0.06
const EDGE_RADIUS: float = 0.012
const LERP_SPEED: float = 6.0
const FLASH_DECAY: float = 3.0

# Node MultiMesh
var _node_mm: MultiMesh
var _node_mmi: MultiMeshInstance3D
var _node_count: int = 0

# Edge MultiMesh
var _edge_mm: MultiMesh
var _edge_mmi: MultiMeshInstance3D
var _edge_count: int = 0

# Current visual state (interpolation targets)
var _current_positions: PackedVector3Array
var _target_positions: PackedVector3Array
var _current_node_colors: PackedColorArray
var _target_node_colors: PackedColorArray
var _node_flash: PackedFloat32Array
var _node_scales: PackedFloat32Array  # per-node radius multiplier

# Edge data
var _edge_pairs: Array = []  # [[from, to], ...]
var _current_edge_colors: PackedColorArray
var _target_edge_colors: PackedColorArray
var _edge_flash: PackedFloat32Array


func setup_nodes(count: int) -> void:
	_node_count = count

	# Init arrays
	_current_positions = PackedVector3Array()
	_current_positions.resize(count)
	_target_positions = PackedVector3Array()
	_target_positions.resize(count)
	_current_node_colors = PackedColorArray()
	_current_node_colors.resize(count)
	_target_node_colors = PackedColorArray()
	_target_node_colors.resize(count)
	_node_flash = PackedFloat32Array()
	_node_flash.resize(count)
	_node_scales = PackedFloat32Array()
	_node_scales.resize(count)

	for i in range(count):
		_current_node_colors[i] = Color(0.3, 0.4, 0.6)
		_target_node_colors[i] = Color(0.3, 0.4, 0.6)
		_node_flash[i] = 0.0
		_node_scales[i] = 1.0

	# Remove old
	if _node_mmi:
		_node_mmi.queue_free()

	# Create node MultiMesh
	_node_mm = MultiMesh.new()
	_node_mm.transform_format = MultiMesh.TRANSFORM_3D
	_node_mm.use_colors = true
	_node_mm.use_custom_data = true
	_node_mm.instance_count = count

	var sphere = SphereMesh.new()
	sphere.radius = NODE_RADIUS
	sphere.height = NODE_RADIUS * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	_node_mm.mesh = sphere

	_node_mmi = MultiMeshInstance3D.new()
	_node_mmi.name = "NodeMultiMesh"
	_node_mmi.multimesh = _node_mm

	var mat = ShaderMaterial.new()
	mat.shader = preload("res://commons/substrates/grid3d/grid3d_node.gdshader")
	_node_mmi.material_override = mat

	add_child(_node_mmi)


func setup_edges(edges: Array) -> void:
	_edge_pairs = edges
	_edge_count = edges.size()

	_current_edge_colors = PackedColorArray()
	_current_edge_colors.resize(_edge_count)
	_target_edge_colors = PackedColorArray()
	_target_edge_colors.resize(_edge_count)
	_edge_flash = PackedFloat32Array()
	_edge_flash.resize(_edge_count)

	for i in range(_edge_count):
		_current_edge_colors[i] = Color(0.3, 0.3, 0.4, 0.4)
		_target_edge_colors[i] = Color(0.3, 0.3, 0.4, 0.4)
		_edge_flash[i] = 0.0

	# Remove old
	if _edge_mmi:
		_edge_mmi.queue_free()

	if _edge_count == 0:
		return

	# Create edge MultiMesh
	_edge_mm = MultiMesh.new()
	_edge_mm.transform_format = MultiMesh.TRANSFORM_3D
	_edge_mm.use_colors = true
	_edge_mm.use_custom_data = true
	_edge_mm.instance_count = _edge_count

	# Unit cylinder (height=1 along Y, radius=EDGE_RADIUS)
	var cyl = CylinderMesh.new()
	cyl.top_radius = EDGE_RADIUS
	cyl.bottom_radius = EDGE_RADIUS
	cyl.height = 1.0
	cyl.radial_segments = 6
	cyl.rings = 1
	_edge_mm.mesh = cyl

	_edge_mmi = MultiMeshInstance3D.new()
	_edge_mmi.name = "EdgeMultiMesh"
	_edge_mmi.multimesh = _edge_mm

	var mat = ShaderMaterial.new()
	mat.shader = preload("res://commons/substrates/grid3d/grid3d_edge.gdshader")
	_edge_mmi.material_override = mat

	add_child(_edge_mmi)


func update_nodes(positions: PackedVector3Array, cartridge: Grid3DCartridge,
		states: PackedInt32Array, step_result: Dictionary = {}) -> void:
	if positions.size() != _node_count:
		return

	for i in range(_node_count):
		_target_positions[i] = positions[i]
		_target_node_colors[i] = cartridge.get_node_color(states[i])
		_node_scales[i] = cartridge.get_node_radius(states[i])

	# Apply per-node highlight overrides
	if step_result.has("highlights"):
		for idx in step_result["highlights"]:
			var i = int(idx)
			if i >= 0 and i < _node_count:
				_target_node_colors[i] = step_result["highlights"][idx]
				_node_flash[i] = 1.0


func update_edges(cartridge: Grid3DCartridge, edge_states: PackedInt32Array,
		step_result: Dictionary = {}) -> void:
	if edge_states.size() != _edge_count:
		return

	for i in range(_edge_count):
		_target_edge_colors[i] = cartridge.get_edge_color(edge_states[i])

	# Apply per-edge highlight overrides
	if step_result.has("edge_highlights"):
		for idx in step_result["edge_highlights"]:
			var i = int(idx)
			if i >= 0 and i < _edge_count:
				_target_edge_colors[i] = step_result["edge_highlights"][idx]
				_edge_flash[i] = 1.0


func interpolate(delta: float) -> void:
	var node_changed = false
	for i in range(_node_count):
		# Lerp position
		var p = _current_positions[i].lerp(_target_positions[i], LERP_SPEED * delta)
		if p.distance_squared_to(_current_positions[i]) > 0.000001:
			_current_positions[i] = p
			node_changed = true

		# Lerp color
		_current_node_colors[i] = _current_node_colors[i].lerp(_target_node_colors[i], LERP_SPEED * delta)

		# Decay flash
		if _node_flash[i] > 0.0:
			_node_flash[i] = maxf(0.0, _node_flash[i] - FLASH_DECAY * delta)
			node_changed = true

	_apply_node_transforms()

	# Edges — only update if node positions changed or edge colors changed
	var edge_changed = node_changed
	for i in range(_edge_count):
		_current_edge_colors[i] = _current_edge_colors[i].lerp(_target_edge_colors[i], LERP_SPEED * delta)
		if _edge_flash[i] > 0.0:
			_edge_flash[i] = maxf(0.0, _edge_flash[i] - FLASH_DECAY * delta)
			edge_changed = true

	if edge_changed:
		_apply_edge_transforms()


func _apply_node_transforms() -> void:
	if not _node_mm:
		return

	for i in range(_node_count):
		var s = _node_scales[i]
		var t = Transform3D()
		t = t.scaled(Vector3(s, s, s))
		t.origin = _current_positions[i]
		_node_mm.set_instance_transform(i, t)

		_node_mm.set_instance_color(i, _current_node_colors[i])

		var base_em = 0.3 + _node_flash[i]
		_node_mm.set_instance_custom_data(i, Color(base_em, 0.0, 0.0, 0.0))


func _apply_edge_transforms() -> void:
	if not _edge_mm or _edge_count == 0:
		return

	for i in range(_edge_count):
		var pair = _edge_pairs[i]
		var from_pos = _current_positions[pair[0]]
		var to_pos = _current_positions[pair[1]]

		# Cylinder transform: position at midpoint, oriented along edge, scaled to length
		var midpoint = (from_pos + to_pos) * 0.5
		var direction = to_pos - from_pos
		var length = direction.length()

		if length < 0.001:
			# Degenerate edge — hide it
			var t = Transform3D()
			t = t.scaled(Vector3.ZERO)
			_edge_mm.set_instance_transform(i, t)
			continue

		# Build transform: cylinder default is Y-up, height=1
		# We need to orient Y along the edge direction and scale Y to length
		var t = _cylinder_transform(midpoint, direction.normalized(), length)
		_edge_mm.set_instance_transform(i, t)

		_edge_mm.set_instance_color(i, _current_edge_colors[i])

		var base_em = 0.1 + _edge_flash[i] * 0.8
		_edge_mm.set_instance_custom_data(i, Color(base_em, 0.0, 0.0, 0.0))


func _cylinder_transform(origin: Vector3, direction: Vector3, length: float) -> Transform3D:
	## Build a transform that places a unit cylinder (Y-up, height=1)
	## at `origin`, oriented along `direction`, scaled to `length`.
	var up = Vector3.UP
	if abs(direction.dot(up)) > 0.99:
		up = Vector3.FORWARD

	# Build basis where Y = direction
	var y_axis = direction
	var x_axis = up.cross(y_axis).normalized()
	var z_axis = y_axis.cross(x_axis).normalized()

	var basis = Basis(x_axis, y_axis * length, z_axis)
	return Transform3D(basis, origin)


func get_bounds() -> AABB:
	if _node_count == 0:
		return AABB(Vector3.ZERO, Vector3.ONE)
	var aabb = AABB(_current_positions[0], Vector3.ZERO)
	for i in range(1, _node_count):
		aabb = aabb.expand(_current_positions[i])
	return aabb


func world_to_nearest_node(local_pos: Vector3) -> int:
	var best_idx = -1
	var best_dist = INF
	for i in range(_node_count):
		var d = local_pos.distance_squared_to(_current_positions[i])
		if d < best_dist:
			best_dist = d
			best_idx = i
	if best_dist < 0.5 * 0.5:  # within 0.5m
		return best_idx
	return -1
