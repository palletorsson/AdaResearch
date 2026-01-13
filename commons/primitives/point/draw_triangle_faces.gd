extends Node3D
## Draw triangle faces by placing points and closing loops

@export var grab_point_path: NodePath = NodePath("GrabPoint")
@export var draw_sphere_path: NodePath = NodePath("GrabPoint/DrawSphere")

# Grid snapping
@export var snap_to_grid: bool = true
@export var grid_size: float = 0.1
@export var point_snap_distance: float = 0.15  # Distance to snap to existing points

# Visual settings
@export var point_indicator_size: float = 0.03
@export var line_color: Color = Color(0.2, 1.0, 0.6, 1.0)
@export var active_line_color: Color = Color(1.0, 0.8, 0.2, 1.0)
@export var point_color: Color = Color(0.3, 0.7, 1.0, 1.0)
@export var snap_indicator_color: Color = Color(1.0, 0.3, 0.3, 1.0)

# Triangle mesh settings
@export var triangle_colors: Array[Color] = [
	Color(1.0, 0.2, 0.5, 0.6),  # Pink
	Color(0.2, 0.5, 1.0, 0.6),  # Blue
	Color(0.5, 1.0, 0.2, 0.6),  # Green
	Color(1.0, 0.8, 0.2, 0.6),  # Yellow
	Color(0.8, 0.2, 1.0, 0.6),  # Purple
]
@export var wireframe_color: Color = Color(0.9, 0.9, 0.9, 0.8)

var _grab_point: Node3D
var _draw_sphere: Node3D
var _is_grabbed: bool = false

# Point tracking
var placed_points: Array[Vector3] = []
var point_indicators: Array[MeshInstance3D] = []
var current_path: Array[int] = []  # Indices into placed_points

# Line visualization
var line_mesh: ImmediateMesh
var line_instance: MeshInstance3D
var active_line_mesh: ImmediateMesh
var active_line_instance: MeshInstance3D

# Triangle tracking
var completed_triangles: Array[Dictionary] = []  # {points: Array[int], mesh: MeshInstance3D}
var triangle_color_index: int = 0

# Snap indicator
var snap_indicator: MeshInstance3D
var snap_target_index: int = -1

func _ready() -> void:
	_grab_point = get_node_or_null(grab_point_path)
	_draw_sphere = get_node_or_null(draw_sphere_path)
	
	if not _grab_point:
		push_warning("DrawTriangleFaces: Missing grab point in scene.")
		set_process(false)
		return
	
	if not _draw_sphere:
		_draw_sphere = _grab_point
	
	_setup_line_visualization()
	_setup_snap_indicator()
	
	# Connect to grab point signals
	if _grab_point.has_signal("dropped"):
		_grab_point.dropped.connect(_on_grab_point_dropped)
	if _grab_point.has_signal("picked_up"):
		_grab_point.picked_up.connect(_on_grab_point_picked_up)
	
	set_process(true)
	print("DrawTriangleFaces: Ready! Pick up the sphere and start drawing.")

func _setup_line_visualization() -> void:
	# Completed lines
	line_mesh = ImmediateMesh.new()
	line_instance = MeshInstance3D.new()
	line_instance.name = "Lines"
	line_instance.mesh = line_mesh
	line_instance.set_as_top_level(true)
	
	var line_material := StandardMaterial3D.new()
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_material.albedo_color = line_color
	line_material.emission_enabled = true
	line_material.emission = line_color
	line_instance.material_override = line_material
	add_child(line_instance)
	
	# Active drawing line
	active_line_mesh = ImmediateMesh.new()
	active_line_instance = MeshInstance3D.new()
	active_line_instance.name = "ActiveLine"
	active_line_instance.mesh = active_line_mesh
	active_line_instance.set_as_top_level(true)
	
	var active_material := StandardMaterial3D.new()
	active_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	active_material.albedo_color = active_line_color
	active_material.emission_enabled = true
	active_material.emission = active_line_color
	active_line_instance.material_override = active_material
	add_child(active_line_instance)

func _setup_snap_indicator() -> void:
	snap_indicator = MeshInstance3D.new()
	snap_indicator.name = "SnapIndicator"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = point_snap_distance * 0.5
	sphere_mesh.height = point_snap_distance
	snap_indicator.mesh = sphere_mesh
	
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = snap_indicator_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = snap_indicator_color
	snap_indicator.material_override = material
	snap_indicator.visible = false
	snap_indicator.set_as_top_level(true)
	add_child(snap_indicator)

func _process(_delta: float) -> void:
	if not _draw_sphere or not _is_grabbed:
		return
	
	var current_pos = _draw_sphere.global_position
	var snapped_pos = snap_position_to_grid(current_pos)
	
	# Check if near an existing point
	snap_target_index = _find_nearby_point(snapped_pos)
	
	# Update snap indicator
	if snap_target_index >= 0 and snap_target_index != _get_last_point_in_path():
		snap_indicator.global_position = placed_points[snap_target_index]
		snap_indicator.visible = true
	else:
		snap_indicator.visible = false
	
	# Update active line preview
	_update_active_line_preview(snapped_pos)

func _update_active_line_preview(current_pos: Vector3) -> void:
	active_line_mesh.clear_surfaces()
	
	if current_path.is_empty():
		return
	
	var last_point_index = current_path[-1]
	var last_point = placed_points[last_point_index]
	
	active_line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	active_line_mesh.surface_add_vertex(last_point)
	
	# If snapping, show line to snap target
	if snap_target_index >= 0 and snap_target_index != last_point_index:
		active_line_mesh.surface_add_vertex(placed_points[snap_target_index])
	else:
		active_line_mesh.surface_add_vertex(current_pos)
	
	active_line_mesh.surface_end()

func _on_grab_point_picked_up(_pickable) -> void:
	_is_grabbed = true
	print("DrawTriangleFaces: Grabbed! Move to place points.")

func _on_grab_point_dropped(_pickable) -> void:
	if not _is_grabbed:
		return
	
	_is_grabbed = false
	var drop_pos = _draw_sphere.global_position
	var snapped_pos = snap_position_to_grid(drop_pos)
	
	# Check if we're snapping to an existing point
	var nearby_index = _find_nearby_point(snapped_pos)
	
	if nearby_index >= 0:
		# Snapping to existing point
		_handle_snap_to_point(nearby_index)
	else:
		# Create new point
		_create_new_point(snapped_pos)
	
	# Rebuild line visualization
	_rebuild_lines()
	
	# Clear active line
	active_line_mesh.clear_surfaces()
	snap_indicator.visible = false

func _handle_snap_to_point(point_index: int) -> void:
	var last_point = _get_last_point_in_path()
	
	# Don't snap to the same point we just placed
	if point_index == last_point:
		print("DrawTriangleFaces: Cannot snap to the last placed point.")
		return
	
	# Add this point to current path
	current_path.append(point_index)
	
	# Check if we've closed a loop with at least 3 points
	if _is_loop_closed():
		var loop_size = current_path.size()
		print("DrawTriangleFaces: Loop closed with %d points!" % loop_size)
		
		# Create triangles from the closed loop
		_create_triangles_from_path()
		
		# Start new path from this point
		current_path.clear()
		current_path.append(point_index)
	
	print("DrawTriangleFaces: Snapped to point %d" % point_index)

func _create_new_point(position: Vector3) -> void:
	var point_index = placed_points.size()
	placed_points.append(position)
	current_path.append(point_index)
	
	# Create visual indicator
	var indicator = MeshInstance3D.new()
	indicator.name = "Point_%d" % point_index
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = point_indicator_size
	sphere_mesh.height = point_indicator_size * 2
	indicator.mesh = sphere_mesh
	
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = point_color
	material.emission_enabled = true
	material.emission = point_color
	indicator.material_override = material
	
	indicator.global_position = position
	indicator.set_as_top_level(true)
	add_child(indicator)
	point_indicators.append(indicator)
	
	print("DrawTriangleFaces: Created point %d at %v" % [point_index, position])

func _find_nearby_point(position: Vector3) -> int:
	for i in range(placed_points.size()):
		var dist = position.distance_to(placed_points[i])
		if dist < point_snap_distance:
			return i
	return -1

func _get_last_point_in_path() -> int:
	if current_path.is_empty():
		return -1
	return current_path[-1]

func _is_loop_closed() -> bool:
	if current_path.size() < 3:
		return false
	
	# Check if the last point equals an earlier point in the path
	var last_point = current_path[-1]
	for i in range(current_path.size() - 1):
		if current_path[i] == last_point:
			return true
	
	return false

func _create_triangles_from_path() -> void:
	if current_path.size() < 3:
		return
	
	# Find where the loop closes
	var last_point = current_path[-1]
	var loop_start_index = -1
	
	for i in range(current_path.size() - 1):
		if current_path[i] == last_point:
			loop_start_index = i
			break
	
	if loop_start_index < 0:
		return
	
	# Extract the loop (from loop_start_index to end)
	var loop_points: Array[int] = []
	for i in range(loop_start_index, current_path.size()):
		loop_points.append(current_path[i])
	
	# Remove duplicate at the end
	if loop_points.size() > 1 and loop_points[0] == loop_points[-1]:
		loop_points.pop_back()
	
	if loop_points.size() < 3:
		return
	
	print("DrawTriangleFaces: Creating triangles from %d-point loop" % loop_points.size())
	
	# Create mesh instance for this triangle group
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Triangle_%d" % completed_triangles.size()
	mesh_instance.set_as_top_level(true)
	add_child(mesh_instance)
	
	# Build the mesh using fan triangulation
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Get triangle color
	var tri_color = triangle_colors[triangle_color_index % triangle_colors.size()]
	triangle_color_index += 1
	
	# Fan triangulation from first point
	var first_point = placed_points[loop_points[0]]
	
	for i in range(1, loop_points.size() - 1):
		var v0 = first_point
		var v1 = placed_points[loop_points[i]]
		var v2 = placed_points[loop_points[i + 1]]
		
		# Calculate normal
		var edge1 = v1 - v0
		var edge2 = v2 - v0
		var normal = edge1.cross(edge2).normalized()
		
		# Front face
		st.set_normal(normal)
		st.set_color(tri_color)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(v0)
		
		st.set_normal(normal)
		st.set_color(tri_color)
		st.set_uv(Vector2(1, 0))
		st.add_vertex(v1)
		
		st.set_normal(normal)
		st.set_color(tri_color)
		st.set_uv(Vector2(0.5, 1))
		st.add_vertex(v2)
		
		# Back face (double-sided)
		st.set_normal(-normal)
		st.set_color(tri_color)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(v0)
		
		st.set_normal(-normal)
		st.set_color(tri_color)
		st.set_uv(Vector2(0.5, 1))
		st.add_vertex(v2)
		
		st.set_normal(-normal)
		st.set_color(tri_color)
		st.set_uv(Vector2(1, 0))
		st.add_vertex(v1)
	
	mesh_instance.mesh = st.commit()
	
	# Apply material
	var material = StandardMaterial3D.new()
	material.albedo_color = tri_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = tri_color * 0.5
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = material
	
	# Store completed triangle
	completed_triangles.append({
		"points": loop_points.duplicate(),
		"mesh": mesh_instance
	})
	
	print("DrawTriangleFaces: Created %d triangles from loop" % (loop_points.size() - 2))

func _rebuild_lines() -> void:
	line_mesh.clear_surfaces()
	
	if current_path.size() < 2:
		return
	
	line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for i in range(current_path.size() - 1):
		var p0 = placed_points[current_path[i]]
		var p1 = placed_points[current_path[i + 1]]
		line_mesh.surface_add_vertex(p0)
		line_mesh.surface_add_vertex(p1)
	
	line_mesh.surface_end()

func snap_position_to_grid(pos: Vector3) -> Vector3:
	if not snap_to_grid:
		return pos
	return Vector3(
		round(pos.x / grid_size) * grid_size,
		round(pos.y / grid_size) * grid_size,
		round(pos.z / grid_size) * grid_size
	)

func clear_all() -> void:
	# Clear points
	for indicator in point_indicators:
		indicator.queue_free()
	point_indicators.clear()
	placed_points.clear()
	current_path.clear()
	
	# Clear triangles
	for tri_data in completed_triangles:
		tri_data.mesh.queue_free()
	completed_triangles.clear()
	triangle_color_index = 0
	
	# Clear lines
	line_mesh.clear_surfaces()
	active_line_mesh.clear_surfaces()
	
	print("DrawTriangleFaces: All cleared!")

func undo_last_point() -> void:
	if placed_points.is_empty():
		return
	
	# Remove last point indicator
	var last_indicator = point_indicators.pop_back()
	last_indicator.queue_free()
	
	# Remove from placed points
	placed_points.pop_back()
	
	# Remove from current path if it's there
	if not current_path.is_empty() and current_path[-1] == placed_points.size():
		current_path.pop_back()
	
	_rebuild_lines()
	print("DrawTriangleFaces: Undid last point")

