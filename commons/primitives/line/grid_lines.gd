extends Node3D

# Script to create a grid of lines on the XZ plane (horizontal ground plane)

@export var grid_size: int = 5  # Number of grid cells (will have grid_size+1 lines in each direction)
@export var cell_spacing: float = 1.0  # Distance between grid lines in meters
@export var trace_scale: float = 5.0 # Scale factor for saved traces
@export var shadow_snap_subdivisions: int = 4 # How many snap points per cell for the shadow trace (higher = smoother)

@export var trace_height: float = 0.5 # Elevation above grid
@export var rotation_speed: float = 10.0 # Degrees per second

var _rotating_instances: Array[Node3D] = []

func _process(delta: float) -> void:
	for instance in _rotating_instances:
		if is_instance_valid(instance):
			instance.rotate_y(deg_to_rad(rotation_speed * delta))
		else:
			_rotating_instances.erase(instance)

func _ready():
	print("GridLines: _ready called")
	setup_grid()
	
	# Setup trace visualization
	var trace_data = get_node_or_null("/root/TraceData")
	print("GridLines: TraceData status: " + str(trace_data))
	
	if trace_data:
		trace_data.trace_added.connect(_on_trace_added)
		for trace in trace_data.get_all_traces():
			_create_trace_mesh(trace)

func _on_trace_added(points: Array) -> void:
	_create_trace_mesh(points)

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
