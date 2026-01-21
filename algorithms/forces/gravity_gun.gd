# gravity_gun.gd
# VR Gravity Gun - Attracts and launches objects
# Attach to player's hand in VR
extends Node3D

@export_group("Attraction Settings")
@export var attraction_radius: float = 1.5  # Range of force field
@export var attraction_strength: float = 15.0  # Base attraction force (increased to overcome gravity)
@export var capture_radius: float = 0.2  # Distance to capture objects
@export var max_captured_objects: int = 20  # Max objects that can be held
@export var captured_scale: float = 0.3  # Scale of captured objects
@export var disable_gravity_on_attraction: bool = true  # Disable gravity while attracting

@export_group("Launch Settings")
@export var launch_force: float = 15.0  # Force applied when launching (increased for better throw)
@export var launch_spread: float = 0.1  # Randomness in launch direction

@export_group("Visual Settings")
@export var show_force_field: bool = true
@export var force_field_color: Color = Color(0.3, 0.8, 1.0, 0.2)  # Cyan glow
@export var show_gun_model: bool = true
@export var gun_color: Color = Color(0.8, 0.9, 1.0, 1.0)

@export_group("VR Controller")
@export var controller_path: NodePath = NodePath("")  # Path to XRController3D
@export var trigger_button_action: String = "trigger"  # Button action name for launching

@export_group("Debug")
@export var debug: bool = false  # Enable debug console output

# Internal state
var attraction_area: Area3D
var captured_objects: Array[RigidBody3D] = []
var attracted_objects: Dictionary = {}  # RigidBody3D -> distance
var original_gravity_scales: Dictionary = {}  # Store original gravity scales
var original_scales: Dictionary = {}  # Store original object scales

# Visual components
var force_field_mesh: MeshInstance3D
var gun_mesh: MeshInstance3D
var muzzle_point: Node3D

# VR Controller
var controller: XRController3D = null
var last_trigger_state: bool = false  # Track trigger state to detect press events

# Launch cooldown to prevent immediate re-capture
var recently_launched: Dictionary = {}  # RigidBody3D -> time
var launch_cooldown: float = 1.0  # Seconds before object can be recaptured

# Signals
signal object_captured(object: RigidBody3D)
signal object_launched(object: RigidBody3D, velocity: Vector3)
signal objects_launched(count: int)

func _ready() -> void:
	setup_gun_visuals()
	setup_force_field()
	setup_attraction_area()
	setup_vr_controller()

func setup_gun_visuals() -> void:
	"""Create the visual representation of the gun"""
	if not show_gun_model:
		return

	gun_mesh = MeshInstance3D.new()
	gun_mesh.name = "GunModel"

	# Create a simple gun shape (box + cylinder barrel)
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(0.08, 0.12, 0.15)
	gun_mesh.mesh = body_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = gun_color
	mat.metallic = 0.7
	mat.roughness = 0.3
	mat.emission_enabled = true
	mat.emission = gun_color * 0.3
	mat.emission_energy_multiplier = 0.5

	gun_mesh.material_override = mat
	add_child(gun_mesh)

	# Create muzzle point (where objects gather)
	muzzle_point = Node3D.new()
	muzzle_point.name = "MuzzlePoint"
	muzzle_point.position = Vector3(0, 0, -0.15)  # Front of gun
	add_child(muzzle_point)

func setup_force_field() -> void:
	"""Create visual force field sphere"""
	if not show_force_field:
		return

	force_field_mesh = MeshInstance3D.new()
	force_field_mesh.name = "ForceField"

	var sphere = SphereMesh.new()
	sphere.radius = attraction_radius
	sphere.height = attraction_radius * 2
	force_field_mesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = force_field_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = force_field_color.lightened(0.2)
	mat.emission_energy_multiplier = 0.8

	force_field_mesh.material_override = mat
	add_child(force_field_mesh)

	# Animate the force field
	_animate_force_field()

func _animate_force_field() -> void:
	"""Pulse the force field for visual effect"""
	if not force_field_mesh:
		return

	var tween = create_tween()
	tween.set_loops()
	tween.set_parallel(true)

	# Pulse scale
	tween.tween_property(force_field_mesh, "scale", Vector3.ONE * 1.1, 1.0)
	tween.tween_property(force_field_mesh, "scale", Vector3.ONE * 0.95, 1.0).set_delay(1.0)

	# Pulse emission
	if force_field_mesh.material_override:
		tween.tween_property(force_field_mesh.material_override, "emission_energy_multiplier", 1.2, 1.0)
		tween.tween_property(force_field_mesh.material_override, "emission_energy_multiplier", 0.6, 1.0).set_delay(1.0)

func setup_attraction_area() -> void:
	"""Create Area3D for detecting objects in range"""
	attraction_area = Area3D.new()
	attraction_area.name = "AttractionArea"
	attraction_area.monitoring = true
	attraction_area.monitorable = false

	# Detect all physics objects
	attraction_area.collision_layer = 0
	attraction_area.collision_mask = 1 | 2  # Layer 1 (default) and 2 (throwable)

	add_child(attraction_area)

	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = attraction_radius
	collision_shape.shape = sphere_shape
	attraction_area.add_child(collision_shape)

	# Connect signals
	attraction_area.body_entered.connect(_on_body_entered_range)
	attraction_area.body_exited.connect(_on_body_exited_range)

func setup_vr_controller() -> void:
	"""Setup VR controller input"""
	if debug:
		print("[GravityGun] setup_vr_controller called")
		print("[GravityGun] My parent is: ", get_parent().name if get_parent() else "NULL")
		print("[GravityGun] My parent type: ", get_parent().get_class() if get_parent() else "NULL")

	if controller_path.is_empty():
		# Try to find controller in parent hierarchy (same as XRTools pattern)
		var parent = get_parent()
		var depth = 0
		while parent:
			if debug:
				print("[GravityGun] Checking parent at depth ", depth, ": ", parent.name, " (", parent.get_class(), ")")
			if parent is XRController3D:
				controller = parent
				if debug:
					print("[GravityGun] Found XRController3D at depth ", depth)
				break
			parent = parent.get_parent()
			depth += 1
			if depth > 10:  # Prevent infinite loop
				if debug:
					print("[GravityGun] Stopped searching after depth 10")
				break
	else:
		controller = get_node_or_null(controller_path)
		if debug:
			print("[GravityGun] Using controller_path: ", controller_path)

	if controller:
		if debug:
			print("[GravityGun] ✓ Connected to controller: ", controller.name, " (", controller.get_class(), ")")
			print("[GravityGun] Controller is_active: ", controller.get_is_active())
			print("[GravityGun] Looking for button action: ", trigger_button_action)
	else:
		if debug:
			print("[GravityGun] ✗ ERROR: No controller found!")

func _physics_process(delta: float) -> void:
	"""Apply attraction forces to objects in range"""
	# Check VR controller input (using XR Tools polling pattern)
	_check_trigger_input()

	# Update launch cooldowns
	_update_launch_cooldowns(delta)

	# Update tracked objects
	var objects_to_remove = []
	for body in attracted_objects.keys():
		if not is_instance_valid(body) or body not in attraction_area.get_overlapping_bodies():
			objects_to_remove.append(body)

	for body in objects_to_remove:
		attracted_objects.erase(body)
		# Restore gravity when object leaves
		if body in original_gravity_scales and body is RigidBody3D:
			body.gravity_scale = original_gravity_scales[body]
			original_gravity_scales.erase(body)

	# Apply forces to attracted objects
	for body in attracted_objects.keys():
		if body is RigidBody3D and not body.freeze:
			# Skip if recently launched
			if body in recently_launched:
				continue
			_apply_attraction_force(body)

	# Keep captured objects near muzzle
	_update_captured_objects()

func _update_launch_cooldowns(delta: float) -> void:
	"""Update and remove expired launch cooldowns"""
	var expired = []
	for body in recently_launched.keys():
		recently_launched[body] -= delta
		if recently_launched[body] <= 0:
			expired.append(body)

	for body in expired:
		recently_launched.erase(body)
		if debug:
			print("[GravityGun] Object ", body.name, " can now be recaptured")

func _check_trigger_input() -> void:
	"""Check for trigger press using XR Tools polling pattern"""
	if not controller:
		if debug and Engine.get_physics_frames() % 120 == 0:  # Print error less frequently
			print("[GravityGun] ERROR: No controller found!")
		return

	# Skip if the controller isn't active
	if not controller.get_is_active():
		# This is normal when controller is sleeping, don't spam
		return

	# Check if trigger button is pressed (polling, not signals)
	var trigger_pressed = controller.is_button_pressed(trigger_button_action)

	# Debug: Print every 60 frames (once per second at 60fps) to show we're polling
	if debug and Engine.get_physics_frames() % 60 == 0:
		print("[GravityGun] Polling - Controller: ", controller.name,
			  " Active: ", controller.get_is_active(),
			  " Button: '", trigger_button_action, "'",
			  " Pressed: ", trigger_pressed,
			  " LastState: ", last_trigger_state,
			  " Captured: ", captured_objects.size())

	# Detect rising edge (button just pressed)
	if trigger_pressed and not last_trigger_state:
		if debug:
			print("[GravityGun] *** TRIGGER PRESSED! Launching 1 object...")
			print("[GravityGun] Launch direction: ", -global_transform.basis.z)
		launch_one()

	# Debug: Show when trigger is released
	if debug and not trigger_pressed and last_trigger_state:
		print("[GravityGun] Trigger released")

	last_trigger_state = trigger_pressed

func _apply_attraction_force(body: RigidBody3D) -> void:
	"""Calculate and apply attraction force to a body"""
	var target_pos = muzzle_point.global_position if muzzle_point else global_position
	var direction = target_pos - body.global_position
	var distance = direction.length()

	# Disable gravity on attracted objects so they can be lifted
	if disable_gravity_on_attraction and body.gravity_scale != 0.0:
		if body not in original_gravity_scales:
			original_gravity_scales[body] = body.gravity_scale
		body.gravity_scale = 0.0

	# Check if object should be captured
	if distance < capture_radius and captured_objects.size() < max_captured_objects:
		if body not in captured_objects:
			_capture_object(body)
			return

	# Apply attraction force (inverse square law)
	if distance > 0.01:
		direction = direction.normalized()
		var clamped_distance = clamp(distance, 0.1, attraction_radius)
		var force_magnitude = attraction_strength / (clamped_distance * clamped_distance)
		var force = direction * force_magnitude

		body.apply_central_force(force)

		# Store distance for other uses
		attracted_objects[body] = distance

func _capture_object(body: RigidBody3D) -> void:
	"""Capture an object and hold it near the gun"""
	if body in captured_objects:
		return

	captured_objects.append(body)

	# Store original scale
	if body not in original_scales:
		original_scales[body] = body.scale

	# Scale down the object
	body.scale = body.scale * captured_scale

	# Freeze the object
	body.freeze = true
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO

	object_captured.emit(body)
	if debug:
		print("[GravityGun] Captured object: ", body.name, " (scaled to ", captured_scale, ")")

func _update_captured_objects() -> void:
	"""Keep captured objects positioned near the muzzle"""
	if captured_objects.is_empty():
		return

	var target_pos = muzzle_point.global_position if muzzle_point else global_position

	# Arrange objects in a circle around muzzle
	var count = captured_objects.size()
	for i in range(count):
		var obj = captured_objects[i]
		if not is_instance_valid(obj):
			continue

		# Position in circle
		var angle = (float(i) / float(count)) * TAU
		var radius = 0.12
		var offset = Vector3(
			cos(angle) * radius,
			sin(angle) * radius,
			0
		)

		# Transform offset to world space
		var world_offset = global_transform.basis * offset
		obj.global_position = target_pos + world_offset

func launch_one() -> void:
	"""Launch one captured object (first in array)"""
	if captured_objects.is_empty():
		if debug:
			print("[GravityGun] ⚠ No objects to launch!")
		return

	# Get the first captured object
	var obj = captured_objects[0]
	if not is_instance_valid(obj):
		# Clean up scale tracking for invalid object
		if obj in original_scales:
			original_scales.erase(obj)
		captured_objects.remove_at(0)
		return

	if debug:
		print("[GravityGun] 🚀 Launching 1 object (", captured_objects.size() - 1, " remaining)")

	var launch_direction = -global_transform.basis.z  # Forward direction
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	# Add some spread
	var spread = Vector3(
		rng.randf_range(-launch_spread, launch_spread),
		rng.randf_range(-launch_spread, launch_spread),
		rng.randf_range(-launch_spread, launch_spread)
	)

	var launch_velocity = (launch_direction + spread).normalized() * launch_force

	# Restore original scale
	if obj in original_scales:
		obj.scale = original_scales[obj]
		original_scales.erase(obj)

	# Unfreeze and launch
	obj.freeze = false
	obj.linear_velocity = launch_velocity
	obj.gravity_scale = 1.0  # Enable gravity

	# Add to recently launched to prevent immediate recapture
	recently_launched[obj] = launch_cooldown

	if debug:
		print("[GravityGun]   → Launched ", obj.name, " at velocity ", launch_velocity.length())

	object_launched.emit(obj, launch_velocity)

	# Remove from captured array
	captured_objects.remove_at(0)

func launch_all() -> void:
	"""Launch all captured objects at once"""
	if captured_objects.is_empty():
		if debug:
			print("[GravityGun] ⚠ launch_all called but no objects captured!")
		return

	if debug:
		print("[GravityGun] 🚀 LAUNCHING ", captured_objects.size(), " OBJECTS!")

	var launch_direction = -global_transform.basis.z  # Forward direction
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for obj in captured_objects:
		if not is_instance_valid(obj):
			continue

		# Add some spread
		var spread = Vector3(
			rng.randf_range(-launch_spread, launch_spread),
			rng.randf_range(-launch_spread, launch_spread),
			rng.randf_range(-launch_spread, launch_spread)
		)

		var launch_velocity = (launch_direction + spread).normalized() * launch_force

		# Restore original scale
		if obj in original_scales:
			obj.scale = original_scales[obj]
			original_scales.erase(obj)

		# Unfreeze and launch
		obj.freeze = false
		obj.linear_velocity = launch_velocity
		obj.gravity_scale = 1.0  # Enable gravity

		# Add to recently launched to prevent immediate recapture
		recently_launched[obj] = launch_cooldown

		if debug:
			print("[GravityGun]   → Launched ", obj.name, " at velocity ", launch_velocity.length())

		object_launched.emit(obj, launch_velocity)

	var count = captured_objects.size()
	objects_launched.emit(count)
	if debug:
		print("[GravityGun] ✓ Successfully launched ", count, " objects")

	captured_objects.clear()

func _on_body_entered_range(body: Node3D) -> void:
	"""Track objects entering attraction range"""
	if body is RigidBody3D and body != self:
		# Skip if object is in a group we should ignore
		if body.is_in_group("no_gravity_gun"):
			return

		# Skip if recently launched (cooldown period)
		if body in recently_launched:
			if debug:
				print("[GravityGun] Object ", body.name, " entered range but on cooldown")
			return

		attracted_objects[body] = 0.0
		if debug:
			print("[GravityGun] Object entered range: ", body.name)

func _on_body_exited_range(body: Node3D) -> void:
	"""Stop tracking objects leaving attraction range"""
	if body in attracted_objects:
		attracted_objects.erase(body)

		# Restore original gravity when leaving range
		if body in original_gravity_scales and body is RigidBody3D:
			body.gravity_scale = original_gravity_scales[body]
			original_gravity_scales.erase(body)

		if debug:
			print("[GravityGun] Object exited range: ", body.name)

# Public API
func set_attraction_strength(strength: float) -> void:
	attraction_strength = strength

func set_attraction_radius(radius: float) -> void:
	attraction_radius = radius
	if attraction_area and attraction_area.has_node("CollisionShape3D"):
		var shape = attraction_area.get_node("CollisionShape3D").shape
		if shape is SphereShape3D:
			shape.radius = radius
	if force_field_mesh:
		force_field_mesh.mesh.radius = radius
		force_field_mesh.mesh.height = radius * 2

func get_captured_count() -> int:
	return captured_objects.size()

func release_all() -> void:
	"""Release all captured objects without launching"""
	for obj in captured_objects:
		if is_instance_valid(obj):
			# Restore original scale
			if obj in original_scales:
				obj.scale = original_scales[obj]
				original_scales.erase(obj)
			obj.freeze = false
			obj.gravity_scale = 1.0
	captured_objects.clear()
