extends Node3D
class_name SnapLineSegment

## SnapLineSegment - A line segment with draggable snap points at each endpoint
## The line dynamically updates as endpoints are moved

## Line appearance
@export var line_width: float = 0.01  # 1cm thick line
@export var line_color: Color = Color(1, 1, 1, 0.8)
@export var locked_color: Color = Color(0.2, 1, 0.3, 1)  # Green when locked
@export var snap_tolerance: float = 0.05  # 5cm snap distance to target

## Shared target pool (set by puzzle controller) - all available targets in global positions
var shared_targets: Array[Vector3] = []
var has_targets: bool = false

## Track which targets each endpoint has snapped to
var endpoint_a_snapped_target: Vector3 = Vector3.INF
var endpoint_b_snapped_target: Vector3 = Vector3.INF

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
	"""No per-frame updates needed for shared target system"""
	pass

func _on_endpoint_moved(_new_position: Vector3) -> void:
	"""Called when either endpoint moves"""
	if is_locked:
		return
	
	_update_line_geometry()
	
	if endpoint_a and endpoint_b:
		endpoints_changed.emit(endpoint_a.global_position, endpoint_b.global_position)

func _on_endpoint_dropped(_pickable: Node3D, endpoint: Node3D) -> void:
	"""Called when an endpoint is dropped - snap to nearest available target"""
	if is_locked or not has_targets or shared_targets.is_empty():
		return

	# Find the nearest target within tolerance
	var best_target: Vector3 = Vector3.INF
	var best_distance: float = snap_tolerance + 1.0

	for target in shared_targets:
		var dist = endpoint.global_position.distance_to(target)
		if dist <= snap_tolerance and dist < best_distance:
			best_distance = dist
			best_target = target

	if best_target != Vector3.INF:
		# Snap to target
		endpoint.global_position = best_target

		# Track which target this endpoint snapped to
		if endpoint == endpoint_a:
			endpoint_a_snapped_target = best_target
		elif endpoint == endpoint_b:
			endpoint_b_snapped_target = best_target

		# Freeze this endpoint in place
		if endpoint is RigidBody3D:
			endpoint.freeze = true

		# Trigger haptic feedback
		if endpoint.has_method("trigger_haptic_pulse"):
			endpoint.trigger_haptic_pulse(0.6, 0.15)

		print("SnapLineSegment: ✓ Endpoint snapped to target at ", best_target)
		_update_line_geometry()
		snapped_to_target.emit()

func set_shared_targets(targets: Array[Vector3]) -> void:
	"""Set the shared target pool for this line segment (in global coordinates)"""
	shared_targets = targets
	has_targets = not targets.is_empty()
	print("SnapLineSegment: Received %d shared targets" % targets.size())

func is_at_target() -> bool:
	"""Check if both endpoints are at any target position"""
	if not has_targets or not endpoint_a or not endpoint_b:
		return false

	var a_at_target = _is_at_any_target(endpoint_a.global_position)
	var b_at_target = _is_at_any_target(endpoint_b.global_position)

	return a_at_target and b_at_target

func _is_at_any_target(pos: Vector3) -> bool:
	"""Check if a position is at any target in the shared pool"""
	for target in shared_targets:
		if pos.distance_to(target) <= snap_tolerance:
			return true
	return false

func get_snapped_targets() -> Array[Vector3]:
	"""Return which targets this line's endpoints have snapped to"""
	var result: Array[Vector3] = []
	if endpoint_a_snapped_target != Vector3.INF:
		result.append(endpoint_a_snapped_target)
	if endpoint_b_snapped_target != Vector3.INF:
		result.append(endpoint_b_snapped_target)
	return result

func reset_snapped_targets() -> void:
	"""Reset the tracked snapped targets"""
	endpoint_a_snapped_target = Vector3.INF
	endpoint_b_snapped_target = Vector3.INF

	# Unfreeze endpoints
	if endpoint_a and endpoint_a is RigidBody3D:
		endpoint_a.freeze = false
	if endpoint_b and endpoint_b is RigidBody3D:
		endpoint_b.freeze = false

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
	"""Hide the endpoint spheres when puzzle is solved"""
	if endpoint_a:
		endpoint_a.visible = false
		print("  Hidden endpoint A sphere")
	if endpoint_b:
		endpoint_b.visible = false
		print("  Hidden endpoint B sphere")
