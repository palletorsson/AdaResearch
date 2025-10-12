# FoldedPaper.gd - Creates a simple folded paper structure with 7 segments and interactive points
extends Node3D

var vertex_color: Color = Color(0.2, 0.8, 0.3, 0.7)  # Transparent green marble
@export var sphere_size_multiplier: float = 0.3  # Smaller spheres for profile
@export var sphere_y_offset: float = 0.0
@export var segment_width: float = 0.4
@export var fold_height: float = 0.6
@export var segment_count: int = 5
@export var double_sided: bool = true

## Freeze behavior options
@export var alter_freeze : bool = false  # Keep paper fixed; points move freely

# Paper mesh instance
var paper_mesh: MeshInstance3D
var drag_points: DragPointSet

# Folded paper vertices - alternating fold directions
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

	create_paper_mesh()
	create_folded_vertices()
	_setup_drag_points()
	update_paper_mesh()
	print_help()

func create_paper_mesh():
	# Create paper mesh
	paper_mesh = MeshInstance3D.new()
	paper_mesh.name = "FoldedPaperMesh"
	apply_paper_material(paper_mesh, Color(0.9, 0.9, 0.8))  # Light paper color
	add_child(paper_mesh)

func create_folded_vertices():
	# Create folded paper vertices with alternating fold directions (70% folded)
	vertex_positions.clear()
	base_vertex_positions.clear()

	for i in range(segment_count + 1):
		var x = float(i) * segment_width
		var y_val = sphere_y_offset

		# Create base vertices (editable bottom edge)
		base_vertex_positions.append(Vector3(x, sphere_y_offset, 0.0))

		# Create accordion fold pattern - every pair alternates between up and down
		var pair_index = i / 2  # Which pair of points this is
		var is_second_in_pair = (i % 2) == 1

		if pair_index % 2 == 0:  # Even pairs fold up
			if is_second_in_pair:
				y_val += fold_height * 0.7  # Second point in pair goes up
			else:
				y_val += fold_height * 0.1  # First point in pair stays low
		else:  # Odd pairs fold down
			if is_second_in_pair:
				y_val += fold_height * 0.1  # Second point in pair stays low
			else:
				y_val += fold_height * 0.7  # First point in pair goes up

		vertex_positions.append(Vector3(x, y_val, 0.0))

func _setup_drag_points():
	var point_configs: Array = []
	for i in range(vertex_positions.size()):
		point_configs.append({
			"id": i,
			"name": "GrabSphere_Top_%d" % i,
			"position": vertex_positions[i],
			"meta": {"vertex_index": i, "is_base": false},
			"scale": sphere_size_multiplier,
			"color": vertex_color
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
		"alter_freeze": alter_freeze
	})

func update_paper_mesh():
	# Update the paper mesh from current vertices
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Create triangles from the folded paper using both top and base vertices
	for i in range(vertex_positions.size() - 1):
		var v0 = vertex_positions[i]  # Top vertex
		var v1 = vertex_positions[i + 1]  # Next top vertex
		var v2 = base_vertex_positions[i]  # Base vertex
		var v3 = base_vertex_positions[i + 1]  # Next base vertex

		# Create two triangles for each segment
		add_triangle_with_normal(st, [v2, v1, v0])  # First triangle
		add_triangle_with_normal(st, [v2, v3, v1])  # Second triangle

	# Commit the mesh
	paper_mesh.mesh = st.commit()

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
	print("folded paper sphere dropped ")
	var folded_context := {
		"vertex": index,
		"paper_length": "%.2f" % get_paper_length(),
		"max_fold_height": "%.2f" % get_max_fold_height()
	}

	var handled := false
	if typeof(TextManager) != TYPE_NIL and TextManager.has_method("trigger_event"):
		handled = TextManager.trigger_event("foldedpaper_drop", folded_context)

	if handled and typeof(GameManager) != TYPE_NIL and GameManager.has_method("add_console_message"):
		var status := "Folded paper vertex %d dropped. Length %s, max fold height %s" % [
			folded_context["vertex"],
			folded_context["paper_length"],
			folded_context["max_fold_height"]
		]
		GameManager.add_console_message(status, "info", "folded_paper")
	elif not handled:
		push_warning("FoldedPaper: Missing foldedpaper_drop text entry for current map")

func _on_point_moved(index: int, position: Vector3, meta: Dictionary) -> void:
	var is_base: bool = bool(meta.get("is_base", false))
	if is_base:
		var base_index: int = int(meta.get("base_index", index - vertex_positions.size()))
		if base_index >= 0 and base_index < base_vertex_positions.size():
			if base_vertex_positions[base_index] != position:
				base_vertex_positions[base_index] = position
				update_paper_mesh()
	else:
		if index >= 0 and index < vertex_positions.size():
			if vertex_positions[index] != position:
				vertex_positions[index] = position
				update_paper_mesh()

func apply_paper_material(mesh_instance: MeshInstance3D, color: Color):
	var material = ShaderMaterial.new()
	var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		material.set_shader_parameter("wireframe_color", Color.DARK_GRAY)
		material.set_shader_parameter("fill_color", color)
		mesh_instance.material_override = material
	else:
		# Fallback to standard material if shader fails to load
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = color
		standard_material.emission_enabled = true
		standard_material.emission = color * 0.2  # Subtle paper glow
		standard_material.roughness = 0.8  # Paper-like roughness
		standard_material.metallic = 0.0   # Non-metallic
		standard_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh_instance.material_override = standard_material

func reset_to_accordion():
	# Reset to accordion fold pattern (70% compressed)
	create_folded_vertices()
	update_sphere_positions()
	print("Reset to accordion fold pattern (70% compressed)")

func reset_to_zigzag_fold():
	# Reset to zigzag fold pattern
	vertex_positions.clear()
	for i in range(segment_count + 1):
		var x = float(i) * segment_width
		var y_val = sphere_y_offset + (i % 2) * fold_height
		vertex_positions.append(Vector3(x, y_val, 0.0))
	update_sphere_positions()
	print("Reset to zigzag fold pattern")

func reset_to_wave_fold():
	# Reset to wave fold pattern
	vertex_positions.clear()
	for i in range(segment_count + 1):
		var x = float(i) * segment_width
		var y_val = sphere_y_offset + sin(i * PI / segment_count) * fold_height * 0.5 + fold_height * 0.5
		vertex_positions.append(Vector3(x, y_val, 0.0))
	update_sphere_positions()
	print("Reset to wave fold pattern")

func reset_to_flat():
	# Reset to flat paper
	vertex_positions.clear()
	for i in range(segment_count + 1):
		var x = float(i) * segment_width
		var y_val = sphere_y_offset
		vertex_positions.append(Vector3(x, y_val, 0.0))
	update_sphere_positions()
	print("Reset to flat paper")

func update_sphere_positions():
	if drag_points:
		for i in range(vertex_positions.size()):
			drag_points.set_point_position(i, vertex_positions[i])
		for i in range(base_vertex_positions.size()):
			var sphere_index = vertex_positions.size() + i
			drag_points.set_point_position(sphere_index, base_vertex_positions[i])
	update_paper_mesh()

func set_vertex_color(color: Color):
	vertex_color = color
	if not drag_points:
		return
	for i in range(vertex_positions.size()):
		var sphere = drag_points.get_sphere(i)
		if sphere:
			var mesh_instance = sphere.get_node("MeshInstance3D")
			if mesh_instance:
				var material = mesh_instance.material_override as StandardMaterial3D
				if material:
					material.albedo_color = vertex_color
					material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					material.emission = Color(0.1, 0.4, 0.2) * 0.3
					material.roughness = 0.1
					material.metallic = 0.0
					material.refraction = 0.05

func print_help():
	print("=== Folded Paper Controls ===")
	print("Mouse: Drag the spheres to reshape the folded paper")
	print("Green spheres: Top profile points")
	print("Blue spheres: Base edge points")
	print("A: Reset to accordion fold pattern (70% compressed)")
	print("Z: Reset to zigzag fold pattern")
	print("W: Reset to wave fold pattern")
	print("F: Reset to flat paper")
	print("Paper has %d segments with %d control points (top + base)" % [segment_count, (segment_count + 1) * 2])
	print("============================")

func get_paper_info() -> Dictionary:
	return {
		"vertices": vertex_positions,
		"paper_length": get_paper_length(),
		"max_fold_height": get_max_fold_height(),
		"segment_count": segment_count
	}

func get_paper_length() -> float:
	var total_length = 0.0
	for i in range(vertex_positions.size() - 1):
		total_length += vertex_positions[i].distance_to(vertex_positions[i + 1])
	return total_length

func get_max_fold_height() -> float:
	var max_height = -INF
	for vertex in vertex_positions:
		max_height = max(max_height, vertex.y - sphere_y_offset)
	return max_height
