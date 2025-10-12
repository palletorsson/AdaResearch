# ZigzagProfile.gd - Creates a standing zigzag profile with 7 segments and interactive points
extends Node3D

var vertex_color: Color = Color(0.2, 0.8, 0.3, 0.7)  # Transparent green marble
@export var sphere_size_multiplier: float = 0.3  # Smaller spheres for profile
@export var sphere_y_offset: float = 0.0
@export var segment_width: float = 0.5
@export var segment_height: float = 0.8
@export var segment_count: int = 5
@export var double_sided: bool = true

## Freeze behavior options
@export var alter_freeze : bool = false  # Keep profile fixed; points move freely

# Profile mesh instance
var profile_mesh: MeshInstance3D
var drag_points: DragPointSet

# Zigzag profile vertices - alternating peaks and valleys
var vertex_positions: Array[Vector3] = []
# Base vertices for editing the bottom edge
var base_vertex_positions: Array[Vector3] = []

func _ready():
	drag_points = DragPointSet.new()
	drag_points.name = "DragPoints"
	add_child(drag_points)

	drag_points.point_picked_up.connect(_on_point_picked_up)
	drag_points.point_dropped.connect(_on_point_dropped)
	drag_points.point_moved.connect(_on_point_moved)

	create_profile_mesh()
	create_zigzag_vertices()
	_setup_drag_points()
	update_profile_mesh()
	print_help()

func create_profile_mesh():
	# Create profile mesh
	profile_mesh = MeshInstance3D.new()
	profile_mesh.name = "ZigzagProfileMesh"
	apply_profile_material(profile_mesh, Color.DEEP_PINK)
	add_child(profile_mesh)

func create_zigzag_vertices():
	# Create zigzag vertices with alternating peaks and valleys (70% folded)
	vertex_positions.clear()
	base_vertex_positions.clear()

	for i in range(segment_count + 1):
		var x = float(i) * segment_width
		var y_val = sphere_y_offset

		# Create base vertices (editable bottom edge)
		base_vertex_positions.append(Vector3(x, sphere_y_offset, 0.0))

		# Alternate between peak and valley with 70% fold height
		if i % 2 == 0:
			y_val += segment_height * 0.7  # Peak (70% folded)
		else:
			y_val += segment_height * 0.3  # Valley (30% folded)

		vertex_positions.append(Vector3(x, y_val, 0.0))

func _setup_drag_points():
	var point_configs: Array = []
	for i in range(vertex_positions.size()):
		point_configs.append({
			"id": i,
			"name": "GrabSphere_Top_%d" % i,
			"position": vertex_positions[i],
			"meta": {"vertex_index": i, "is_base": false}
		})

	for i in range(base_vertex_positions.size()):
		point_configs.append({
			"id": vertex_positions.size() + i,
			"name": "GrabSphere_Base_%d" % i,
			"position": base_vertex_positions[i],
			"meta": {
				"vertex_index": vertex_positions.size() + i,
				"is_base": true,
				"base_index": i
			},
			"scale": sphere_size_multiplier * 0.8,
			"color": Color(0.3, 0.6, 0.9, 0.7)
		})

	drag_points.setup(point_configs, {
		"freeze_on_drop": true,
		"unfreeze_on_pickup": true,
		"default_scale": sphere_size_multiplier,
		"default_color": vertex_color,
		"alter_freeze": alter_freeze
	})

func _collect_point_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	positions.append_array(vertex_positions)
	positions.append_array(base_vertex_positions)
	return positions

func update_profile_mesh() -> void:
	# Update the profile mesh from current vertices
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Create triangles from the zigzag profile using both top and base vertices
	for i in range(vertex_positions.size() - 1):
		var v0 = vertex_positions[i]  # Top vertex
		var v1 = vertex_positions[i + 1]  # Next top vertex
		var v2 = base_vertex_positions[i]  # Base vertex
		var v3 = base_vertex_positions[i + 1]  # Next base vertex

		# Create two triangles for each segment
		add_triangle_with_normal(st, [v2, v1, v0])  # First triangle
		add_triangle_with_normal(st, [v2, v3, v1])  # Second triangle

	# Commit the mesh
	profile_mesh.mesh = st.commit()

func add_triangle_with_normal(st: SurfaceTool, vertices: Array):
	var v0 = vertices[0]
	var v1 = vertices[1]
	var v2 = vertices[2]

	# Calculate face normal
	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var normal = edge1.cross(edge2).normalized()

	# Add vertices with normal and UV coordinates (front face)
	st.set_normal(normal)
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(v0)

	st.set_normal(normal)
	st.set_uv(Vector2(1.0, 0.0))
	st.add_vertex(v1)

	st.set_normal(normal)
	st.set_uv(Vector2(0.5, 1.0))
	st.add_vertex(v2)

	if double_sided:
		# Add the back face for double-sided rendering
		st.set_normal(-normal)
		st.set_uv(Vector2(0.0, 0.0))
		st.add_vertex(v0)

		st.set_normal(-normal)
		st.set_uv(Vector2(0.5, 1.0))
		st.add_vertex(v2)

		st.set_normal(-normal)
		st.set_uv(Vector2(1.0, 0.0))
		st.add_vertex(v1)

func _on_point_picked_up(index: int, _pickable, _meta: Dictionary) -> void:
	print("DEBUG PICKUP")

func _on_point_dropped(index: int, _pickable, meta: Dictionary) -> void:
	print("zigzag sphere dropped ")
	var zigzag_context := {
		"vertex": index,
		"profile_length": "%.2f" % get_profile_length(),
		"max_height": "%.2f" % get_max_height()
	}

	var handled := false
	if typeof(TextManager) != TYPE_NIL and TextManager.has_method("trigger_event"):
		handled = TextManager.trigger_event("zigzag_drop", zigzag_context)

	if handled and typeof(GameManager) != TYPE_NIL and GameManager.has_method("add_console_message"):
		var status := "Zigzag vertex %d dropped. Profile length %s, max height %s" % [
			zigzag_context["vertex"],
			zigzag_context["profile_length"],
			zigzag_context["max_height"]
		]
		GameManager.add_console_message(status, "info", "zigzag_profile")
	elif not handled:
		push_warning("ZigzagProfile: Missing zigzag_drop text entry for current map")

func _on_point_moved(index: int, position: Vector3, meta: Dictionary) -> void:
	var is_base: bool = bool(meta.get("is_base", false))
	if is_base:
		var base_index: int = int(meta.get("base_index", index - vertex_positions.size()))
		if base_index >= 0 and base_index < base_vertex_positions.size():
			if base_vertex_positions[base_index] != position:
				base_vertex_positions[base_index] = position
				update_profile_mesh()
	else:
		if index >= 0 and index < vertex_positions.size():
			if vertex_positions[index] != position:
				vertex_positions[index] = position
				update_profile_mesh()

func apply_profile_material(mesh_instance: MeshInstance3D, color: Color):
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		material.set_shader_parameter("wireframe_color", Color.DARK_VIOLET)
		material.set_shader_parameter("fill_color", color)
		mesh_instance.material_override = material
	else:
		# Fallback to standard material if shader fails to load
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = color
		standard_material.emission_enabled = true
		standard_material.emission = color * 0.3
		standard_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh_instance.material_override = standard_material

func reset_to_zigzag():
	# Reset to perfect zigzag pattern (70% folded)
	create_zigzag_vertices()
	update_sphere_positions()
	print("Reset to zigzag pattern (70% folded)")

func reset_to_sine_wave():
	# Reset to sine wave pattern
	vertex_positions.clear()
	for i in range(segment_count + 1):
		var x = float(i) * segment_width
		var y_val = sphere_y_offset + sin(i * PI / segment_count) * segment_height * 0.5
		vertex_positions.append(Vector3(x, y_val, 0.0))
	update_sphere_positions()
	print("Reset to sine wave pattern")

func reset_to_sawtooth():
	# Reset to sawtooth pattern
	vertex_positions.clear()
	for i in range(segment_count + 1):
		var x = float(i) * segment_width
		var y_val = sphere_y_offset + (i % 2) * segment_height
		vertex_positions.append(Vector3(x, y_val, 0.0))
	update_sphere_positions()
	print("Reset to sawtooth pattern")

func update_sphere_positions() -> void:
	if drag_points:
		drag_points.set_points_positions(_collect_point_positions())
	update_profile_mesh()

func set_vertex_color(color: Color) -> void:
	vertex_color = color
	if not drag_points:
		return
	drag_points.for_each_sphere(func(sphere: Node3D) -> void:
		var id_value = sphere.get_meta("drag_point_id")
		var point_id := -1
		if typeof(id_value) == TYPE_INT or typeof(id_value) == TYPE_FLOAT:
			point_id = int(id_value)
		if point_id < 0 or point_id >= vertex_positions.size():
			return
		var mesh_instance: MeshInstance3D = sphere.get_node_or_null("MeshInstance3D") as MeshInstance3D
		if not mesh_instance:
			return
		var material := mesh_instance.material_override as StandardMaterial3D
		if not material:
			return
		material.albedo_color = vertex_color
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.emission = Color(0.1, 0.4, 0.2) * 0.3
		material.roughness = 0.1
		material.metallic = 0.0
		material.refraction = 0.05
	)

func print_help():
	print("=== Zigzag Profile Controls ===")
	print("Mouse: Drag the spheres to reshape the zigzag profile")
	print("Green spheres: Top profile points")
	print("Blue spheres: Base edge points")
	print("Z: Reset to zigzag pattern (70% folded)")
	print("S: Reset to sine wave pattern")
	print("W: Reset to sawtooth pattern")
	print("Profile has %d segments with %d control points (top + base)" % [segment_count, (segment_count + 1) * 2])
	print("============================")

func get_profile_info() -> Dictionary:
	return {
		"vertices": vertex_positions,
		"profile_length": get_profile_length(),
		"max_height": get_max_height(),
		"segment_count": segment_count
	}

func get_profile_length() -> float:
	var total_length = 0.0
	for i in range(vertex_positions.size() - 1):
		total_length += vertex_positions[i].distance_to(vertex_positions[i + 1])
	return total_length

func get_max_height() -> float:
	var max_height = -INF
	for vertex in vertex_positions:
		max_height = max(max_height, vertex.y - sphere_y_offset)
	return max_height
