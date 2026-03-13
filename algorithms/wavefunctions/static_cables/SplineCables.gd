extends Node3D

@export var points_per_cable: int = 80
@export var cable_radius: float = 0.12
@export var ring_segments: int = 12
@export var color_start: Color = Color(0.9, 0.5, 0.6)
@export var color_end: Color = Color(0.5, 0.7, 1.0)
@export var auto_generate_on_ready: bool = true

# Sine wave parameters for position-based cables
@export_group("Sine Wave Settings")
@export var use_position_markers: bool = true
@export var sine_amplitude: float = 0.5
@export var sine_frequency: float = 2.0
@export var sine_vertical: bool = true  # Apply sine vertically (Y) vs horizontally
@export var auto_switch_oscillation: bool = true  # Automatically switch between XZ (floor) and Y (up)
@export var floor_height_threshold: float = 0.5  # Below this Y, use XZ oscillation

var cables: Array[MeshInstance3D] = []

func _ready() -> void:
	_create_environment()
	if auto_generate_on_ready:
		if use_position_markers:
			_generate_cables_from_positions()
		else:
			_generate_cables_from_paths()

func _create_environment() -> void:
	var env_node := WorldEnvironment.new()
	add_child(env_node)
	var env := Environment.new()
	env_node.environment = env
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.06, 0.08)
	env.ambient_light_color = Color(0.1, 0.1, 0.2)
	env.glow_enabled = true
	env.glow_intensity = 0.6

func _generate_cables_from_paths() -> void:
	# Clear existing cables
	for cable in cables:
		cable.queue_free()
	cables.clear()

	# Find all Path3D children
	var path_nodes: Array[Path3D] = []
	for child in get_children():
		if child is Path3D:
			path_nodes.append(child)

	if path_nodes.is_empty():
		push_warning("SplineCables: No Path3D children found. Add Path3D nodes to define cable paths.")
		return

	# Generate a cable for each path
	for i in range(path_nodes.size()):
		var path_node := path_nodes[i]
		var curve := path_node.curve

		if curve == null or curve.point_count < 2:
			push_warning("SplineCables: Path3D '%s' has no valid curve." % path_node.name)
			continue

		# Sample points along the curve
		var path_points := _sample_curve(curve, points_per_cable)

		# Create tube mesh
		var cable := MeshInstance3D.new()
		cable.mesh = _create_tube_mesh(path_points)
		cable.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

		# Material with color gradient
		var material := StandardMaterial3D.new()
		material.metallic = 0.6
		material.roughness = 0.25
		var tcol = float(i) / max(1, path_nodes.size() - 1)
		material.albedo_color = color_start.lerp(color_end, tcol)
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.3
		cable.material_override = material

		add_child(cable)
		cables.append(cable)

func _sample_curve(curve: Curve3D, num_points: int) -> PackedVector3Array:
	var points := PackedVector3Array()
	var curve_length := curve.get_baked_length()

	for i in range(num_points):
		var t: float = float(i) / float(num_points - 1)
		var offset := t * curve_length
		var point := curve.sample_baked(offset)
		points.append(point)

	return points

# === Tube mesh generation (from StaticCables.gd) ===
func _create_tube_mesh(path: PackedVector3Array) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if path.size() < 2:
		return mesh

	var segments: int = max(3, ring_segments)
	var radius: float = cable_radius

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for i in range(path.size()):
		var p := path[i]
		var dir := Vector3.ZERO
		if i == 0:
			dir = (path[i + 1] - p).normalized()
		elif i == path.size() - 1:
			dir = (p - path[i - 1]).normalized()
		else:
			dir = (path[i + 1] - path[i - 1]).normalized()
		if dir.length_squared() == 0.0:
			dir = Vector3.FORWARD
		var up := Vector3.UP
		if abs(dir.dot(up)) > 0.9:
			up = Vector3.RIGHT
		var right := dir.cross(up).normalized()
		var real_up := right.cross(dir).normalized()

		for j in range(segments):
			var a := float(j) / float(segments) * TAU
			var offset := (right * cos(a) + real_up * sin(a)) * radius
			vertices.append(p + offset)
			normals.append(offset.normalized())
			uvs.append(Vector2(float(i) / (path.size() - 1), float(j) / float(segments)))

	for i in range(path.size() - 1):
		var ringA := i * segments
		var ringB := (i + 1) * segments
		for j in range(segments):
			var nj := (j + 1) % segments
			indices.append(ringA + j)
			indices.append(ringB + j)
			indices.append(ringA + nj)
			indices.append(ringA + nj)
			indices.append(ringB + j)
			indices.append(ringB + nj)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _generate_cables_from_positions() -> void:
	# Clear existing cables
	for cable in cables:
		cable.queue_free()
	cables.clear()

	# Find all position markers (nodes named p_1, p_2, etc.)
	var position_nodes: Array[Node3D] = []
	for child in get_children():
		if child is Node3D and child.name.begins_with("p_"):
			position_nodes.append(child)

	if position_nodes.is_empty():
		push_warning("SplineCables: No position marker nodes found (looking for nodes named p_1, p_2, etc.)")
		return

	# Sort by name to ensure correct order (p_1, p_2, p_3, ...)
	position_nodes.sort_custom(func(a, b): return a.name < b.name)

	# Create sine wave path through the positions
	var path_points := _create_sine_wave_path(position_nodes)

	# Create cable mesh
	var cable := MeshInstance3D.new()
	cable.mesh = _create_tube_mesh(path_points)
	cable.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	# Material
	var material := StandardMaterial3D.new()
	material.metallic = 0.4
	material.roughness = 0.4
	material.albedo_color = color_start
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.1
	cable.material_override = material

	add_child(cable)
	cables.append(cable)

func _create_sine_wave_path(positions: Array[Node3D]) -> PackedVector3Array:
	var points := PackedVector3Array()

	if positions.is_empty():
		return points

	# Calculate total path length
	var segment_lengths: Array[float] = []
	var total_length := 0.0
	for i in range(positions.size() - 1):
		var seg_length := positions[i].global_position.distance_to(positions[i + 1].global_position)
		segment_lengths.append(seg_length)
		total_length += seg_length

	# Generate points along the path with sine wave
	for i in range(points_per_cable):
		var t := float(i) / float(points_per_cable - 1)
		var target_distance := t * total_length

		# Find which segment we're in
		var accumulated_dist := 0.0
		var segment_idx := 0
		var local_t := 0.0

		for j in range(segment_lengths.size()):
			if accumulated_dist + segment_lengths[j] >= target_distance:
				segment_idx = j
				local_t = (target_distance - accumulated_dist) / segment_lengths[j]
				break
			accumulated_dist += segment_lengths[j]

		# Get base position (lerp between segment start and end)
		var start_pos := positions[segment_idx].global_position
		var end_pos := positions[segment_idx + 1].global_position
		var base_pos := start_pos.lerp(end_pos, local_t)

		# Apply sine wave
		var sine_phase := t * sine_frequency * TAU
		var sine_offset := sin(sine_phase) * sine_amplitude

		# Calculate perpendicular direction for sine displacement
		var forward := (end_pos - start_pos).normalized()
		var offset_vec := Vector3.ZERO

		# Determine oscillation direction based on height
		var use_vertical := sine_vertical
		if auto_switch_oscillation:
			# Below floor threshold: oscillate in Z (floor level)
			# Above threshold: oscillate vertically (Y)
			use_vertical = base_pos.y >= floor_height_threshold

		if use_vertical:
			# Apply sine wave vertically (Y axis) - for rising sections
			offset_vec = Vector3.UP * sine_offset
		else:
			# Apply sine wave in Z direction - for floor sections
			offset_vec = Vector3(0, 0, sine_offset)

		# Debug first few points
		if i < 3:
			print("Point %d: base_pos.y=%.2f, use_vertical=%s, offset=%s" % [i, base_pos.y, use_vertical, offset_vec])

		points.append(base_pos + offset_vec)

	return points

# Call this to regenerate cables after editing paths in the editor
func regenerate_cables() -> void:
	if use_position_markers:
		_generate_cables_from_positions()
	else:
		_generate_cables_from_paths()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

