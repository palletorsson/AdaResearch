extends Node3D


# Spine-corridor contract — see doc/SPINE_HINTS_CONTRACT.md.
# grid_lines reads as "a lattice floating in void" — the cells around it
# should STAY void to preserve that design intent. That signal now lives
# in the registry as `spatial_needs.platform = "sunken"` (step 2a: one
# source of truth). No tag needed here.
func spine_hints() -> Dictionary:
	return {
		"role":         "primary",
		"footprint":    Vector2i(5, 5),     # 5x5 lattice from grid_size default
		"approach":     "any",
		"reading_dist": 1.0,
		"budget_ms":    0.6,
		"tags":         ["visual", "static", "isolated"],
	}


# @identity
# essence: grid = {x=i*step, z=j*step : i,j ∈ ℤ} — the XZ plane made legible as a lattice of lines
# desire: learner experiences space as structured and measurable, not infinite and featureless
# critical_parameter: grid_size — how many cells appear; determines resolution of spatial reference
# triggers: TraceData global signal — saved player traces appear as scaled rotating meshes on grid intersections
# emerges: the grid as a display medium, not just reference — traces replay as spatial memory
# needs: [has Label3D [has], missing VR controls — purely informational]
# relationships: subscribes to player_trace data; uses line as its primitive unit
# truth: a coordinate grid does not exist in space — it is a social agreement we project onto space

# Script to create a grid of lines on the XZ plane (horizontal ground plane)

@export var grid_size: int = 5  # Number of grid cells (will have grid_size+1 lines in each direction)
@export var cell_spacing: float = 1.0  # Distance between grid lines in meters
@export var trace_scale: float = 5.0 # Scale factor for saved traces
@export var shadow_snap_subdivisions: int = 4 # How many snap points per cell for the shadow trace (higher = smoother)

@export var trace_height: float = 0.5 # Elevation above grid
@export var rotation_speed: float = 10.0 # Degrees per second

# Data Table Display
@export_group("Data Table")
@export var show_data_table: bool = true
@export var data_table_position: Vector3 = Vector3(0, 2.5, 0)  # Above the trace
@export var data_table_color: Color = Color(0.9, 0.95, 1.0, 1.0)
@export var data_table_font_size: int = 20
@export var data_table_page_duration: float = 2.0  # Seconds per page

func apply_grid_config(config: Dictionary) -> void:
	## Map-token dress for the lattice (2026-08-24, Palle: "the grid should
	## not rotate, only the trace, but slower"): the lattice itself never
	## turns — _process spins only the saved-trace instances — and the map
	## slows that turn per placement (#rotation_speed:2, degrees per second).
	if config.has("rotation_speed") and str(config["rotation_speed"]).is_valid_float():
		rotation_speed = clampf(float(str(config["rotation_speed"])), 0.0, 90.0)
	if config.has("trace_height") and str(config["trace_height"]).is_valid_float():
		trace_height = clampf(float(str(config["trace_height"])), 0.0, 3.0)


var _rotating_instances: Array[Node3D] = []
var _data_table_label: Label3D
var _trace_data_list: Array[Dictionary] = []  # Store info about each trace
var _data_table_page: int = 0  # Current page of points to display
var _data_table_timer: float = 0.0  # Timer for page cycling

func _process(delta: float) -> void:
	for i in range(_rotating_instances.size() - 1, -1, -1):
		var instance: Node3D = _rotating_instances[i]
		if is_instance_valid(instance):
			instance.rotate_y(deg_to_rad(rotation_speed * delta))
		else:
			_rotating_instances.remove_at(i)

	# Cycle through data table pages
	if _data_table_label and _data_table_label.visible:
		_data_table_timer += delta
		if _data_table_timer >= data_table_page_duration:
			_data_table_timer = 0.0
			_data_table_page += 1
			_update_data_table()

func _ready():
	print("GridLines: _ready called")
	setup_grid()
	_setup_data_table()

	# Setup trace visualization
	var trace_data = get_node_or_null("/root/TraceData")
	print("GridLines: TraceData status: " + str(trace_data))

	if trace_data:
		trace_data.trace_added.connect(_on_trace_added)
		for trace in trace_data.get_all_traces():
			_create_trace_mesh(trace)
			_add_trace_to_data(trace)
		_update_data_table()

func _on_trace_added(points: Array) -> void:
	_create_trace_mesh(points)
	_add_trace_to_data(points)
	_update_data_table()

func _create_trace_mesh(points: Array) -> void:
	if points.is_empty():
		return
		
	# Calculate Center & Size
	var min_p = points[0]
	var max_p = points[0]
	for p in points:
		min_p = min_p.min(p)
		max_p = max_p.max(p)
	var center = (min_p + max_p) / 2.0
	var size = max_p - min_p
	var max_dim = max(size.x, max(size.y, size.z))
	
	# Calculate scale with clamping
	var final_scale = trace_scale
	if max_dim * trace_scale > 5.0:
		if max_dim > 0.001:
			final_scale = 5.0 / max_dim
			
	print("GridLines: Creating trace mesh with %d points. Centered at: %s. Size: %s. Final Scale: %.2f" % [points.size(), center, size, final_scale])
	
	_create_shadow_trace(points, center, final_scale)
	
	var mesh = ImmediateMesh.new()
	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	instance.name = "SavedTrace"
	instance.position.y = trace_height
	add_child(instance)
	_rotating_instances.append(instance)
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 0.4, 0.9, 1) # Same as default trail
	mat.emission_enabled = true
	mat.emission = Color(1, 0.4, 0.9, 1)
	instance.material_override = mat
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in points:
		# Use local coordinates centered on the grid and scaled
		mesh.surface_add_vertex((p - center) * final_scale)
	mesh.surface_end()
	
	# Bubble Animation
	instance.scale = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(instance, "scale", Vector3.ONE, 1.0).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _create_shadow_trace(points: Array, center: Vector3, scale_factor: float) -> void:
	var shadow_points = []
	var last_snapped = Vector3.INF
	
	for p in points:
		var scaled = (p - center) * scale_factor
		# Snap to grid (with subdivisions)
		var snap_step = cell_spacing / float(max(1, shadow_snap_subdivisions))
		var snapped = scaled.snapped(Vector3.ONE * snap_step)
		
		# Filter duplicates
		if snapped.distance_squared_to(last_snapped) > 0.001:
			shadow_points.append(snapped)
			last_snapped = snapped
			
	if shadow_points.size() < 2:
		return

	var mesh = ImmediateMesh.new()
	var instance = MeshInstance3D.new()
	instance.name = "ShadowTrace"
	instance.mesh = mesh
	instance.position.y = trace_height
	add_child(instance)
	_rotating_instances.append(instance)
	
	# Green Emissive Material (matching GrabSpherePointSnap)
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.2, 1.0, 0.6, 0.8) 
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1.0, 0.6, 1.0)
	mat.emission_energy_multiplier = 1.5
	instance.material_override = mat
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in shadow_points:
		# Lift slightly to avoid z-fighting (relative to instance position)
		# Since instance is already at trace_height, we just add a tiny bit more or 0
		mesh.surface_add_vertex(p) 
	mesh.surface_end()
	
	instance.scale = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(instance, "scale", Vector3.ONE, 1.0).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func setup_grid():
	var half_size = (grid_size * cell_spacing) / 2.0
	var line_index = 1

	# Create lines parallel to X axis (going along X, at different Z positions)
	for i in range(grid_size + 1):
		var z_pos = -half_size + (i * cell_spacing)
		var line_node = get_node_or_null("LineX" + str(i + 1) + "/lineContainer")
		if line_node:
			line_node.set_positions(
				Vector3(-half_size, 0, z_pos),
				Vector3(half_size, 0, z_pos)
			)
			# Highlight center lines
			if i == grid_size / 2:
				line_node.set_line_properties(0.01, Color(1.0, 0.3, 0.3, 1.0))  # Red for X axis
			else:
				line_node.set_line_properties(0.006, Color(0.6, 0.6, 0.6, 0.8))

	# Create lines parallel to Z axis (going along Z, at different X positions)
	for i in range(grid_size + 1):
		var x_pos = -half_size + (i * cell_spacing)
		var line_node = get_node_or_null("LineZ" + str(i + 1) + "/lineContainer")
		if line_node:
			line_node.set_positions(
				Vector3(x_pos, 0, -half_size),
				Vector3(x_pos, 0, half_size)
			)
			# Highlight center lines
			if i == grid_size / 2:
				line_node.set_line_properties(0.01, Color(0.3, 0.3, 1.0, 1.0))  # Blue for Z axis
			else:
				line_node.set_line_properties(0.006, Color(0.6, 0.6, 0.6, 0.8))

func _setup_data_table() -> void:
	if not show_data_table:
		return

	_data_table_label = Label3D.new()
	_data_table_label.name = "TraceDataTable"
	_data_table_label.font_size = data_table_font_size
	_data_table_label.pixel_size = 0.001  # Sharper text
	_data_table_label.modulate = data_table_color
	_data_table_label.outline_size = 2
	_data_table_label.outline_modulate = Color(0.1, 0.1, 0.2, 0.9)

	# Billboard Y only - rotate to face camera but stay upright
	_data_table_label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_data_table_label.fixed_size = false

	# Horizontal alignment
	_data_table_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Scale bigger
	_data_table_label.scale = Vector3(2.0, 2.0, 2.0)

	_data_table_label.position = data_table_position
	_data_table_label.visible = false

	add_child(_data_table_label)

func _add_trace_to_data(points: Array) -> void:
	if points.is_empty():
		return

	# Calculate trace metrics
	var total_length: float = 0.0
	for i in range(1, points.size()):
		total_length += points[i].distance_to(points[i - 1])

	# Calculate bounding box
	var min_p = points[0]
	var max_p = points[0]
	for p in points:
		min_p = min_p.min(p)
		max_p = max_p.max(p)
	var size = max_p - min_p

	var trace_info = {
		"points": points.size(),
		"length": total_length,
		"size": size,
		"raw_points": points.duplicate()
	}
	_trace_data_list.append(trace_info)

	# Keep only last 10 traces in data list
	while _trace_data_list.size() > 10:
		_trace_data_list.pop_front()

func _update_data_table() -> void:
	if not _data_table_label or _trace_data_list.is_empty():
		return

	var total_points = 0
	var total_length = 0.0
	for trace in _trace_data_list:
		total_points += trace.points
		total_length += trace.length

	# Get raw points from the most recent trace
	var latest_trace = _trace_data_list[_trace_data_list.size() - 1]
	var raw_pts = latest_trace.raw_points
	var pts_per_page = 10
	var total_pages = max(1, ceili(float(raw_pts.size()) / pts_per_page))

	# Wrap page if needed
	if _data_table_page >= total_pages:
		_data_table_page = 0

	# Build full table with raw data points
	var table_text = "GRID TRACE ARCHIVE\n"
	table_text += "─────────────────────────────────\n"
	table_text += "Traces: %d  Points: %d  Length: %.2f m\n" % [_trace_data_list.size(), total_points, total_length]
	table_text += "─────────────────────────────────\n"
	table_text += "RAW DATA POINTS (Page %d/%d)\n" % [_data_table_page + 1, total_pages]
	table_text += "─────────────────────────────────\n"

	# Show 10 points for current page
	var start_idx = _data_table_page * pts_per_page
	var end_idx = min(start_idx + pts_per_page, raw_pts.size())
	for i in range(start_idx, end_idx):
		var pt = raw_pts[i]
		table_text += "%3d: (%.2f, %.2f, %.2f)\n" % [i + 1, pt.x, pt.y, pt.z]

	_data_table_label.text = table_text
	_data_table_label.visible = true
