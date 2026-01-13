extends Node3D
class_name SnapLineSegment

## SnapLineSegment - A line segment with draggable snap points at each endpoint
## The line dynamically updates as endpoints are moved

## Line appearance
@export var line_width: float = 0.01  # 1cm thick line
@export var line_color: Color = Color(1, 1, 1, 0.8)
@export var locked_color: Color = Color(0.2, 1, 0.3, 1)  # Green when locked
@export var snap_tolerance: float = 0.05  # 5cm snap distance to target

## Target positions (set by puzzle controller) - stored as GLOBAL positions
var target_start_global: Vector3 = Vector3.ZERO
var target_end_global: Vector3 = Vector3.ZERO
var has_targets: bool = false

## Target marker nodes (3D cross indicators)
var target_marker_a: Node3D
var target_marker_b: Node3D

## Internal state
var is_locked: bool = false
var endpoint_a: Node3D  # First snap point
var endpoint_b: Node3D  # Second snap point
var line_mesh: MeshInstance3D
var material: StandardMaterial3D

## Signals
signal endpoints_changed(start_pos: Vector3, end_pos: Vector3)
signal snapped_to_target()
signal line_locked()

func _ready() -> void:
	print("SnapLineSegment: Initializing...")
	
	# Find the two snap point children
	var snap_points = []
	for child in get_children():
		if child is XRToolsPickable and child.has_signal("point_moved"):
			snap_points.append(child)
			print("  Found snap point: ", child.name)
	
	if snap_points.size() >= 2:
		endpoint_a = snap_points[0]
		endpoint_b = snap_points[1]
		
		# Increase snap distance on the snap points for easier targeting
		if "snap_distance" in endpoint_a:
			endpoint_a.snap_distance = 0.15  # 15cm snap range
		if "snap_distance" in endpoint_b:
			endpoint_b.snap_distance = 0.15
		
		# Connect to endpoint movement signals
		if endpoint_a.has_signal("point_moved"):
			endpoint_a.point_moved.connect(_on_endpoint_moved)
			print("  Connected point_moved for ", endpoint_a.name)
		if endpoint_b.has_signal("point_moved"):
			endpoint_b.point_moved.connect(_on_endpoint_moved)
			print("  Connected point_moved for ", endpoint_b.name)
		
		# Connect to pickup/drop signals for validation
		if endpoint_a.has_signal("dropped"):
			endpoint_a.dropped.connect(_on_endpoint_dropped.bind(endpoint_a))
			print("  Connected dropped for ", endpoint_a.name)
		if endpoint_b.has_signal("dropped"):
			endpoint_b.dropped.connect(_on_endpoint_dropped.bind(endpoint_b))
			print("  Connected dropped for ", endpoint_b.name)
	else:
		push_error("SnapLineSegment: Need at least 2 snap point children! Found: %d" % snap_points.size())
		return
	
	# Create the line mesh
	_create_line_mesh()
	print("  Line mesh created with material")
	
	# Initial line update
	call_deferred("_update_line_geometry")
	print("SnapLineSegment: Initialization complete")

func _create_line_mesh() -> void:
	"""Create the visual line mesh"""
	line_mesh = MeshInstance3D.new()
	line_mesh.name = "LineMesh"
	add_child(line_mesh)
	
	# Create material
	material = StandardMaterial3D.new()
	material.albedo_color = line_color
	material.emission_enabled = true
	material.emission = line_color
	material.emission_energy_multiplier = 0.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	line_mesh.material_override = material

func _update_line_geometry() -> void:
	"""Update the line mesh to connect the two endpoints"""
	if not endpoint_a or not endpoint_b or not line_mesh:
		return
	
	var start = endpoint_a.global_position
	var end = endpoint_b.global_position
	
	# Calculate line parameters
	var line_vector = end - start
	var line_length = line_vector.length()
	var line_center = (start + end) / 2.0
	
	# Hide if line is too short (prevents degenerate basis)
	if line_length < 0.001:
		line_mesh.visible = false
		return
	
	line_mesh.visible = true
	
	# Create cylinder mesh
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = line_width
	cylinder.bottom_radius = line_width
	cylinder.height = line_length
	cylinder.radial_segments = 8
	cylinder.rings = 1
	
	line_mesh.mesh = cylinder
	
	# Position at center
	line_mesh.global_position = line_center
	
	# Rotate to align with line direction
	var direction = line_vector.normalized()
	var up = Vector3.UP
	
	# Avoid parallel vectors (prevents degenerate basis)
	if abs(direction.dot(up)) > 0.999:
		up = Vector3.FORWARD
	
	# Safely create basis
	var basis = Basis.looking_at(direction, up)
	# Check if basis is valid (non-zero determinant)
	if abs(basis.determinant()) > 0.001:
		line_mesh.global_transform.basis = basis * Basis(Vector3(1, 0, 0), PI/2)
	else:
		# Fallback: use identity basis if degenerate
		line_mesh.global_transform.basis = Basis()

func _process(_delta: float) -> void:
	"""Update target markers to show proximity"""
	if not has_targets or is_locked:
		return
	
	# Make target markers pulse faster when endpoints are nearby
	if target_marker_a and endpoint_a:
		var distance = endpoint_a.global_position.distance_to(target_start_global)
		if distance < snap_tolerance:
			# Very close - make it bright and pulse fast
			var intensity = 1.0 - (distance / snap_tolerance)
			target_marker_a.scale = Vector3.ONE * (1.0 + intensity * 0.5)
	
	if target_marker_b and endpoint_b:
		var distance = endpoint_b.global_position.distance_to(target_end_global)
		if distance < snap_tolerance:
			# Very close - make it bright and pulse fast
			var intensity = 1.0 - (distance / snap_tolerance)
			target_marker_b.scale = Vector3.ONE * (1.0 + intensity * 0.5)

func _on_endpoint_moved(_new_position: Vector3) -> void:
	"""Called when either endpoint moves"""
	if is_locked:
		return
	
	_update_line_geometry()
	
	if endpoint_a and endpoint_b:
		endpoints_changed.emit(endpoint_a.global_position, endpoint_b.global_position)

func _on_endpoint_dropped(_pickable: Node3D, endpoint: Node3D) -> void:
	"""Called when an endpoint is dropped - check for snap to target"""
	if is_locked or not has_targets:
		return
	
	var snapped = false
	
	# Check if endpoint_a is near target_start
	if endpoint == endpoint_a:
		var distance_to_start = endpoint.global_position.distance_to(target_start_global)
		print("  Endpoint A dropped:")
		print("    Current position: ", endpoint.global_position)
		print("    Target position:  ", target_start_global)
		print("    Distance: %.3f m (tolerance: %.3f m)" % [distance_to_start, snap_tolerance])
		if distance_to_start <= snap_tolerance:
			endpoint.global_position = target_start_global
			# Freeze this endpoint in place
			if endpoint is RigidBody3D:
				endpoint.freeze = true
			# Trigger haptic feedback if snap point supports it
			if endpoint.has_method("trigger_haptic_pulse"):
				endpoint.trigger_haptic_pulse(0.6, 0.15)
			# Hide the target marker
			if target_marker_a:
				target_marker_a.visible = false
			snapped = true
			print("SnapLineSegment: ✓ Endpoint A snapped and locked to target")
	
	# Check if endpoint_b is near target_end
	elif endpoint == endpoint_b:
		var distance_to_end = endpoint.global_position.distance_to(target_end_global)
		print("  Endpoint B dropped:")
		print("    Current position: ", endpoint.global_position)
		print("    Target position:  ", target_end_global)
		print("    Distance: %.3f m (tolerance: %.3f m)" % [distance_to_end, snap_tolerance])
		if distance_to_end <= snap_tolerance:
			endpoint.global_position = target_end_global
			# Freeze this endpoint in place
			if endpoint is RigidBody3D:
				endpoint.freeze = true
			# Trigger haptic feedback if snap point supports it
			if endpoint.has_method("trigger_haptic_pulse"):
				endpoint.trigger_haptic_pulse(0.6, 0.15)
			# Hide the target marker
			if target_marker_b:
				target_marker_b.visible = false
			snapped = true
			print("SnapLineSegment: ✓ Endpoint B snapped and locked to target")
	
	if snapped:
		# Check if BOTH endpoints are now at target
		var both_at_target = is_at_target()
		print("SnapLineSegment: Checking if both endpoints at target: ", both_at_target)
		
		if both_at_target:
			# Lock both endpoints at EXACT target positions
			if endpoint_a:
				endpoint_a.global_position = target_start_global
			if endpoint_b:
				endpoint_b.global_position = target_end_global
			
			# Update line geometry with exact positions
			_update_line_geometry()
			
			# Turn line green to indicate correct placement
			if material:
				print("  Changing line color to GREEN (locked_color)")
				material.albedo_color = locked_color
				material.emission = locked_color
				print("  ✓ Line turned GREEN! Both endpoints correct!")
			else:
				push_error("  ✗ Material is null, cannot change color!")
			
			# Hide the endpoint spheres
			_hide_endpoint_spheres()
			
			# Mark as locked
			is_locked = true
		else:
			print("  One endpoint snapped, waiting for the other...")
			_update_line_geometry()
		
		snapped_to_target.emit()

func set_targets(start_global: Vector3, end_global: Vector3) -> void:
	"""Set the target positions for this line segment (in global coordinates)"""
	target_start_global = start_global
	target_end_global = end_global
	has_targets = true
	
	# Debug: Check endpoint positions vs targets
	if endpoint_a and endpoint_b:
		print("SnapLineSegment: Target setup:")
		print("  Endpoint A current: ", endpoint_a.global_position)
		print("  Endpoint B current: ", endpoint_b.global_position)
		print("  Target A: ", target_start_global)
		print("  Target B: ", target_end_global)
		print("  Distance A: %.3f m" % endpoint_a.global_position.distance_to(target_start_global))
		print("  Distance B: %.3f m" % endpoint_b.global_position.distance_to(target_end_global))
	
	# Create visual target markers
	call_deferred("_create_target_markers")

func is_at_target() -> bool:
	"""Check if both endpoints are at their target positions"""
	if not has_targets or not endpoint_a or not endpoint_b:
		return false
	
	var a_distance = endpoint_a.global_position.distance_to(target_start_global)
	var b_distance = endpoint_b.global_position.distance_to(target_end_global)
	
	var result = a_distance <= snap_tolerance and b_distance <= snap_tolerance
	
	# Only print detailed debug on state changes or when very close
	if result or (a_distance < snap_tolerance * 2 or b_distance < snap_tolerance * 2):
		print("    Distance check - A: %.3f m, B: %.3f m (tolerance: %.3f m)" % [a_distance, b_distance, snap_tolerance])
		
		if result:
			print("    ✓ Both endpoints within tolerance!")
		else:
			if a_distance > snap_tolerance:
				print("    ✗ Endpoint A: %.3f m away" % a_distance)
			else:
				print("    ✓ Endpoint A: at target!")
			if b_distance > snap_tolerance:
				print("    ✗ Endpoint B: %.3f m away" % b_distance)
			else:
				print("    ✓ Endpoint B: at target!")
	
	return result

func _create_target_markers() -> void:
	"""Create visual cross markers at target positions"""
	# Get line index from name (SnapLine1, SnapLine2, etc.)
	var line_index = 0
	if name.begins_with("SnapLine"):
		line_index = int(name.substr(8)) - 1  # Extract number from "SnapLine1"
	
	# Determine labels based on line index
	var label_start = "a" if line_index == 0 else "c"
	var label_end = "b" if line_index == 0 else "d"
	var line_label = "%s->%s" % [label_start, label_end]
	
	# Create marker for endpoint A target
	target_marker_a = _create_cross_marker(Color(1, 1, 0, 0.8))  # Yellow
	target_marker_a.name = "TargetMarker" + label_start.to_upper()
	add_child(target_marker_a)
	target_marker_a.global_position = target_start_global
	
	# Update label with position
	var label_a = target_marker_a.get_node("TargetLabel")
	if label_a:
		label_a.text = label_start
	
	# Create marker for endpoint B target
	target_marker_b = _create_cross_marker(Color(1, 0.5, 0, 0.8))  # Orange
	target_marker_b.name = "TargetMarker" + label_end.to_upper()
	add_child(target_marker_b)
	target_marker_b.global_position = target_end_global
	
	# Update label with position
	var label_b = target_marker_b.get_node("TargetLabel")
	if label_b:
		label_b.text = label_end
	
	print("SnapLineSegment: Created target markers for line '%s' at %s and %s" % [line_label, target_start_global, target_end_global])

func _create_cross_marker(color: Color) -> Node3D:
	"""Create a 3D cross marker (position set after adding to tree)"""
	var marker = Node3D.new()
	
	# Create a larger, more visible sphere marker
	var sphere_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.02  # 2cm radius sphere - smaller, less distracting
	sphere.height = 0.04
	sphere.radial_segments = 12
	sphere.rings = 6
	
	sphere_mesh.mesh = sphere
	
	# Create bright emissive material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0  # Slightly dimmer
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	sphere_mesh.material_override = mat
	marker.add_child(sphere_mesh)
	
	# Create three perpendicular lines forming a 3D cross
	var axes = [
		[Vector3(-0.03, 0, 0), Vector3(0.03, 0, 0)],  # X axis (6cm wide - smaller)
		[Vector3(0, -0.03, 0), Vector3(0, 0.03, 0)],  # Y axis
		[Vector3(0, 0, -0.03), Vector3(0, 0, 0.03)]   # Z axis
	]
	
	for axis in axes:
		var line_mesh = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		cylinder.top_radius = 0.003  # 3mm thick - thinner
		cylinder.bottom_radius = 0.003
		cylinder.height = 0.06  # 6cm long - shorter
		cylinder.radial_segments = 4
		
		line_mesh.mesh = cylinder
		
		# Create emissive material
		var mat2 = StandardMaterial3D.new()
		mat2.albedo_color = color
		mat2.emission_enabled = true
		mat2.emission = color
		mat2.emission_energy_multiplier = 2.5
		mat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		
		line_mesh.material_override = mat2
		
		# Position and rotate
		var direction = (axis[1] - axis[0]).normalized()
		var center = (axis[0] + axis[1]) / 2.0
		line_mesh.position = center
		
		if direction.dot(Vector3.UP) < 0.999:
			line_mesh.transform.basis = Basis.looking_at(direction, Vector3.UP) * Basis(Vector3(1, 0, 0), PI/2)
		
		marker.add_child(line_mesh)
	
	# Add debug label (position will be set after adding to tree)
	var label = Label3D.new()
	label.name = "TargetLabel"
	label.text = "TARGET"
	label.font_size = 12
	label.outline_size = 3
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	label.position = Vector3(0, 0.08, 0)  # 8cm above marker
	marker.add_child(label)
	
	# Note: Tween will be created after adding to tree
	
	return marker

func lock_line() -> void:
	"""Lock the line in place (freeze endpoints, change color)"""
	if is_locked:
		return
	
	is_locked = true
	
	# Freeze both endpoints
	if endpoint_a and endpoint_a is RigidBody3D:
		endpoint_a.freeze = true
	if endpoint_b and endpoint_b is RigidBody3D:
		endpoint_b.freeze = true
	
	# Change line color to locked color
	if material:
		material.albedo_color = locked_color
		material.emission = locked_color
	
	line_locked.emit()
	print("SnapLineSegment: Line locked at target")

func unlock_line() -> void:
	"""Unlock the line (unfreeze endpoints, restore color)"""
	is_locked = false
	
	# Unfreeze both endpoints (including individually snapped ones)
	if endpoint_a and endpoint_a is RigidBody3D:
		endpoint_a.freeze = false
	if endpoint_b and endpoint_b is RigidBody3D:
		endpoint_b.freeze = false
	
	# Restore original color
	if material:
		material.albedo_color = line_color
		material.emission = line_color
	
	print("SnapLineSegment: Line unlocked")

func get_start_position() -> Vector3:
	"""Get the current position of endpoint A"""
	return endpoint_a.global_position if endpoint_a else Vector3.ZERO

func get_end_position() -> Vector3:
	"""Get the current position of endpoint B"""
	return endpoint_b.global_position if endpoint_b else Vector3.ZERO

func set_line_color(color: Color) -> void:
	"""Change the line color"""
	line_color = color
	if material and not is_locked:
		material.albedo_color = color
		material.emission = color

func _hide_endpoint_spheres() -> void:
	"""Hide the endpoint spheres and target markers when puzzle is solved"""
	if endpoint_a:
		endpoint_a.visible = false
		print("  Hidden endpoint A sphere")
	if endpoint_b:
		endpoint_b.visible = false
		print("  Hidden endpoint B sphere")
	
	# Also hide target markers
	if target_marker_a:
		target_marker_a.visible = false
		print("  Hidden target marker A")
	if target_marker_b:
		target_marker_b.visible = false
		print("  Hidden target marker B")
