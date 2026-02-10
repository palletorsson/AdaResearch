# gravity_gun.gd
# VR Gravity Gun - Ray-based targeting with manual capture
# Objects must be grabbed and placed into the capture zone
extends Node3D

@export_group("Targeting Settings")
@export var ray_length: float = 15.0  # How far the ray reaches
@export var ray_start_offset: float = 0.6  # Start ray 0.6m from hand
@export var highlight_targeted: bool = true  # Show highlight on targeted object

@export_group("Attraction Settings")
@export var attraction_strength: float = 35.0  # Pull force
@export var pull_stop_distance: float = 0.4  # Stop pulling at this distance (hand grabs from here)
@export var gravity_restore_time: float = 2.0  # Seconds before gravity restores after release

@export_group("Capture Zone Settings (Wrist Bracelet)")
@export var capture_zone_major_radius: float = 0.05  # Distance from wrist center to torus center
@export var capture_zone_minor_radius: float = 0.025  # Thickness of the bracelet
@export var capture_zone_offset: Vector3 = Vector3(0, 0, 0.22)  # Further back on forearm
@export var max_captured_objects: int = 20  # Max objects held
@export var captured_scale: float = 0.35  # Scale of captured objects

@export_group("Launch Settings")
@export var launch_force: float = 20.0  # Force when launching
@export var launch_spread: float = 0.05  # Randomness in launch direction

@export_group("Visual Settings")
@export var show_laser: bool = true
@export var show_capture_zone: bool = true
@export var laser_color_idle: Color = Color(0.2, 0.6, 1.0, 0.4)
@export var laser_color_target: Color = Color(0.2, 1.0, 0.4, 0.6)
@export var laser_color_holding: Color = Color(1.0, 0.6, 0.2, 0.8)
@export var laser_color_pulling: Color = Color(1.0, 1.0, 0.2, 0.7)  # Yellow when actively pulling
@export var capture_zone_color: Color = Color(0.3, 0.8, 1.0, 0.15)
@export var laser_width: float = 0.008

@export_group("VR Controller")
@export var grip_action: String = "grip"  # Button to attract
@export var trigger_action: String = "trigger"  # Button to launch

@export_group("Collision")
@export var collision_mask: int = 7  # Layers 1, 2, 3

@export_group("Debug")
@export var debug: bool = false

# Internal state
var targeted_object: RigidBody3D = null
var captured_objects: Array[RigidBody3D] = []
var original_scales: Dictionary = {}
var is_attracting: bool = false

# Gravity restoration tracking
var gravity_restore_queue: Dictionary = {}  # body -> {original_gravity, time_remaining}

# Visual components
var laser_mesh: MeshInstance3D
var target_indicator: MeshInstance3D
var capture_zone_mesh: MeshInstance3D
var capture_zone_area: Area3D
var count_label: Label3D

# VR Controller
var controller: XRController3D = null
var grip_threshold: float = 0.7
var last_trigger_pressed: bool = false  # Track trigger state for edge detection

# Cooldowns
var recently_launched: Dictionary = {}
var launch_cooldown: float = 0.5

# Raycast
var ray_query: PhysicsRayQueryParameters3D

# Signals
signal object_targeted(object: RigidBody3D)
signal object_captured(object: RigidBody3D)
signal object_launched(object: RigidBody3D, velocity: Vector3)

func _ready() -> void:
	setup_visuals()
	setup_capture_zone()
	setup_raycast()
	setup_vr_controller()

func setup_visuals() -> void:
	# Create count label (positioned near bracelet)
	count_label = Label3D.new()
	count_label.name = "CountLabel"
	count_label.position = Vector3(0, 0.12, 0.12)  # Above bracelet
	count_label.font_size = 48
	count_label.pixel_size = 0.001
	count_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	count_label.modulate = Color(1, 1, 1, 0.9)
	count_label.outline_size = 8
	count_label.visible = false
	add_child(count_label)
	
	if not show_laser:
		return
	
	# Create laser beam
	laser_mesh = MeshInstance3D.new()
	laser_mesh.name = "LaserBeam"
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = laser_width
	cylinder.bottom_radius = laser_width
	cylinder.height = 1.0
	laser_mesh.mesh = cylinder
	laser_mesh.rotation_degrees.x = 90
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = laser_color_idle
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = laser_color_idle
	mat.emission_energy_multiplier = 2.0
	laser_mesh.material_override = mat
	
	add_child(laser_mesh)
	
	# Create target indicator
	target_indicator = MeshInstance3D.new()
	target_indicator.name = "TargetIndicator"
	
	var sphere = SphereMesh.new()
	sphere.radius = 0.03
	sphere.height = 0.06
	target_indicator.mesh = sphere
	target_indicator.visible = false
	
	var indicator_mat = StandardMaterial3D.new()
	indicator_mat.albedo_color = laser_color_target
	indicator_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	indicator_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	indicator_mat.emission_enabled = true
	indicator_mat.emission = laser_color_target
	indicator_mat.emission_energy_multiplier = 3.0
	target_indicator.material_override = indicator_mat
	
	add_child(target_indicator)

func setup_capture_zone() -> void:
	# Create capture zone Area3D - bracelet torus around wrist behind hand
	capture_zone_area = Area3D.new()
	capture_zone_area.name = "CaptureZoneBracelet"
	capture_zone_area.position = capture_zone_offset
	capture_zone_area.collision_layer = 0
	capture_zone_area.collision_mask = collision_mask
	capture_zone_area.monitoring = true
	capture_zone_area.monitorable = false
	
	# Create torus collision using multiple capsules arranged in a ring
	var num_segments = 8
	for i in range(num_segments):
		var angle = (float(i) / float(num_segments)) * TAU
		var next_angle = (float(i + 1) / float(num_segments)) * TAU
		
		# Position on the torus ring
		var pos = Vector3(
			cos(angle) * capture_zone_major_radius,
			sin(angle) * capture_zone_major_radius,
			0
		)
		
		var collision = CollisionShape3D.new()
		var capsule = CapsuleShape3D.new()
		capsule.radius = capture_zone_minor_radius
		capsule.height = capture_zone_minor_radius * 3  # Overlap segments
		collision.shape = capsule
		collision.position = pos
		# Rotate capsule to follow the torus curve
		collision.rotation.z = angle + PI/2
		capture_zone_area.add_child(collision)
	
	add_child(capture_zone_area)
	
	# Connect signals
	capture_zone_area.body_entered.connect(_on_capture_zone_entered)
	
	# Visual for capture zone - torus mesh
	if show_capture_zone:
		capture_zone_mesh = MeshInstance3D.new()
		capture_zone_mesh.name = "CaptureZoneVisual"
		
		# Create torus mesh
		var torus = TorusMesh.new()
		torus.inner_radius = capture_zone_major_radius - capture_zone_minor_radius
		torus.outer_radius = capture_zone_major_radius + capture_zone_minor_radius
		torus.rings = 24
		torus.ring_segments = 12
		capture_zone_mesh.mesh = torus
		
		var zone_mat = StandardMaterial3D.new()
		zone_mat.albedo_color = capture_zone_color
		zone_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		zone_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		zone_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		zone_mat.emission_enabled = true
		zone_mat.emission = Color(capture_zone_color.r, capture_zone_color.g, capture_zone_color.b, 1.0)
		zone_mat.emission_energy_multiplier = 0.5
		capture_zone_mesh.material_override = zone_mat
		
		capture_zone_area.add_child(capture_zone_mesh)

func setup_raycast() -> void:
	ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.collision_mask = collision_mask
	ray_query.collide_with_areas = false
	ray_query.collide_with_bodies = true

func setup_vr_controller() -> void:
	var parent = get_parent()
	var depth = 0
	while parent and depth < 10:
		if parent is XRController3D:
			controller = parent
			if debug:
				print("[GravityGun] Found controller: ", controller.name)
			break
		parent = parent.get_parent()
		depth += 1

func _physics_process(delta: float) -> void:
	_update_cooldowns(delta)
	_update_gravity_restoration(delta)
	_check_input()
	
	if is_attracting and targeted_object:
		_attract_targeted_object(delta)
	else:
		_update_targeting()
	
	_update_captured_objects()
	_update_laser_visual()
	_update_count_label()
	_update_capture_zone_visual()

func _check_input() -> void:
	if not controller or not controller.get_is_active():
		return
	
	var grip_value = controller.get_float(grip_action)
	var trigger_pressed = controller.is_button_pressed(trigger_action)
	
	var was_attracting = is_attracting
	is_attracting = grip_value > grip_threshold
	
	# Released grip - queue gravity restoration for the targeted object
	if not is_attracting and was_attracting and targeted_object:
		_queue_gravity_restore(targeted_object)
		if debug:
			print("[GravityGun] Released - gravity will restore in ", gravity_restore_time, "s")
	
	# Trigger to launch - only on rising edge (press, not hold)
	if trigger_pressed and not last_trigger_pressed:
		if not captured_objects.is_empty():
			launch_one()
			if debug:
				print("[GravityGun] Trigger pressed - launched 1, remaining: ", captured_objects.size())
	
	last_trigger_pressed = trigger_pressed

func _update_targeting() -> void:
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return
	
	var ray_origin = global_position + (-global_transform.basis.z * ray_start_offset)
	var ray_end = global_position + (-global_transform.basis.z * ray_length)
	
	ray_query.from = ray_origin
	ray_query.to = ray_end
	
	var result = space_state.intersect_ray(ray_query)
	
	var new_target: RigidBody3D = null
	
	if result and result.collider is RigidBody3D:
		var body = result.collider as RigidBody3D
		if _is_valid_target(body):
			new_target = body
			if target_indicator:
				target_indicator.global_position = result.position
				target_indicator.visible = true
	else:
		if target_indicator:
			target_indicator.visible = false
	
	if new_target != targeted_object:
		if targeted_object and highlight_targeted:
			_set_highlight(targeted_object, false)
		
		targeted_object = new_target
		
		if targeted_object and highlight_targeted:
			_set_highlight(targeted_object, true)
			object_targeted.emit(targeted_object)

func _is_valid_target(body: RigidBody3D) -> bool:
	if body.freeze and not body.has_method("pick_up"):
		return false
	if body.is_in_group("no_gravity_gun"):
		return false
	if body in recently_launched:
		return false
	if body in captured_objects:
		return false
	return true

func _attract_targeted_object(_delta: float) -> void:
	if not targeted_object or not is_instance_valid(targeted_object):
		targeted_object = null
		return
	
	# Pull toward a point in front of hand (not into capture zone - user must place it there)
	var pull_target = global_position + (-global_transform.basis.z * pull_stop_distance)
	var obj_pos = targeted_object.global_position
	var direction = pull_target - obj_pos
	var distance = direction.length()
	
	# Disable gravity while attracting
	if targeted_object not in gravity_restore_queue:
		# Store original gravity if not already tracked
		var original_grav = targeted_object.gravity_scale
		gravity_restore_queue[targeted_object] = {
			"original_gravity": original_grav,
			"time_remaining": -1.0  # -1 means actively being held
		}
	else:
		# Reset timer while still attracting
		gravity_restore_queue[targeted_object]["time_remaining"] = -1.0
	
	targeted_object.gravity_scale = 0.0
	
	# Unfreeze if frozen
	if targeted_object.freeze:
		targeted_object.freeze = false
	
	# Stop pulling when close enough (user grabs from here)
	if distance < 0.1:
		# Object is close - dampen velocity, wait for user to grab
		targeted_object.linear_velocity *= 0.8
		targeted_object.angular_velocity *= 0.8
		return
	
	# Apply attraction force
	if distance > 0.01:
		direction = direction.normalized()
		var force_multiplier = clamp(distance, 0.5, 3.0)
		var force = direction * attraction_strength * force_multiplier
		
		targeted_object.linear_velocity *= 0.92
		targeted_object.apply_central_force(force)

func _queue_gravity_restore(body: RigidBody3D) -> void:
	if body in gravity_restore_queue:
		# Start the countdown
		gravity_restore_queue[body]["time_remaining"] = gravity_restore_time
	else:
		# Wasn't tracked, restore immediately
		pass

func _update_gravity_restoration(delta: float) -> void:
	var to_restore = []
	
	for body in gravity_restore_queue.keys():
		if not is_instance_valid(body):
			to_restore.append(body)
			continue
		
		var data = gravity_restore_queue[body]
		
		# Skip if actively being held (time_remaining == -1)
		if data["time_remaining"] < 0:
			continue
		
		# Count down
		data["time_remaining"] -= delta
		
		if data["time_remaining"] <= 0:
			# Restore gravity
			body.gravity_scale = data["original_gravity"]
			to_restore.append(body)
			if debug:
				print("[GravityGun] Restored gravity for: ", body.name)
	
	for body in to_restore:
		gravity_restore_queue.erase(body)

func _on_capture_zone_entered(body: Node3D) -> void:
	if not body is RigidBody3D:
		return

	var rb = body as RigidBody3D

	# Check if it's a valid object to capture
	if rb in captured_objects:
		return
	if rb.is_in_group("no_gravity_gun"):
		return
	if rb in recently_launched:
		return

	# Check if the object is currently being held by a hand (XRToolsPickable)
	# We only capture objects that are NOT currently picked up
	# This allows the user to grab with hand first, then place into zone
	if rb.has_method("is_picked_up") and rb.is_picked_up():
		# Object is held by hand - don't capture yet
		# It will be captured when dropped into the zone
		return

	# Only capture objects that:
	# 1. Are being actively attracted by the gravity gun (targeted_object)
	# 2. Were recently dropped (in gravity restore queue = was being manipulated)
	# This prevents the torus from grabbing random objects it bumps into
	var is_being_attracted = (rb == targeted_object and is_attracting)
	var was_recently_manipulated = rb in gravity_restore_queue

	if not is_being_attracted and not was_recently_manipulated:
		return

	# Object entered zone and was being manipulated - capture it!
	_capture_object(rb)

func _capture_object(body: RigidBody3D) -> void:
	if body in captured_objects:
		return

	if captured_objects.size() >= max_captured_objects:
		if debug:
			print("[GravityGun] Max captured objects reached")
		return

	captured_objects.append(body)

	# Store and modify scale
	if body not in original_scales:
		original_scales[body] = body.scale
	body.scale = body.scale * captured_scale

	# Remove from gravity restore queue (captured objects stay zero-g)
	if body in gravity_restore_queue:
		gravity_restore_queue.erase(body)

	# Freeze the object
	body.freeze = true
	body.gravity_scale = 0.0
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO

	if highlight_targeted:
		_set_highlight(body, false)

	# Clear as targeted if it was
	if targeted_object == body:
		targeted_object = null

	# Connect to picked_up signal so we can release when another hand grabs it
	if body.has_signal("picked_up") and not body.is_connected("picked_up", _on_captured_object_picked_up):
		body.picked_up.connect(_on_captured_object_picked_up)

	object_captured.emit(body)
	if debug:
		print("[GravityGun] Captured: ", body.name, " (total: ", captured_objects.size(), ")")

## Called when a captured object is picked up by a hand - release it from capture
func _on_captured_object_picked_up(pickable) -> void:
	if pickable not in captured_objects:
		return

	# Restore original scale
	if pickable in original_scales:
		pickable.scale = original_scales[pickable]
		original_scales.erase(pickable)

	# Remove from captured list
	captured_objects.erase(pickable)

	# Disconnect signal
	if pickable.has_signal("picked_up") and pickable.is_connected("picked_up", _on_captured_object_picked_up):
		pickable.picked_up.disconnect(_on_captured_object_picked_up)

	if debug:
		print("[GravityGun] Released to hand: ", pickable.name, " (remaining: ", captured_objects.size(), ")")

func _update_captured_objects() -> void:
	if captured_objects.is_empty():
		return

	var bracelet_pos = capture_zone_area.global_position

	# Clean up invalid objects
	var to_remove = []
	for obj in captured_objects:
		if not is_instance_valid(obj):
			to_remove.append(obj)
	for obj in to_remove:
		captured_objects.erase(obj)
		if obj in original_scales:
			original_scales.erase(obj)
		# Disconnect signal if still connected (for valid objects being removed)
		if is_instance_valid(obj) and obj.has_signal("picked_up") and obj.is_connected("picked_up", _on_captured_object_picked_up):
			obj.picked_up.disconnect(_on_captured_object_picked_up)
	
	var count = captured_objects.size()
	if count == 0:
		return
	
	var time = Time.get_ticks_msec() / 1000.0
	
	# Objects orbit around the bracelet (around the arm axis)
	for i in range(count):
		var obj = captured_objects[i]
		
		# Multiple rings along the arm if many objects
		var ring = i / 6  # 6 objects per ring around arm
		var index_in_ring = i % 6
		var objects_in_this_ring = mini(6, count - ring * 6)
		
		# Angle around the arm (Y-X plane relative to hand)
		var angle = (float(index_in_ring) / float(objects_in_this_ring)) * TAU
		angle += time * 0.4  # Slow orbit
		
		# Orbit radius increases slightly for outer rings
		var orbit_radius = capture_zone_major_radius + 0.06 + ring * 0.04
		
		# Stack rings along the arm (positive Z = further up arm)
		var z_along_arm = ring * 0.06
		
		var offset = Vector3(
			cos(angle) * orbit_radius,
			sin(angle) * orbit_radius,
			z_along_arm
		)
		
		var world_offset = global_transform.basis * offset
		obj.global_position = bracelet_pos + world_offset
		obj.rotation.y += 0.015

func _update_laser_visual() -> void:
	if not laser_mesh:
		return
	
	var color: Color
	if is_attracting and targeted_object:
		color = laser_color_pulling
	elif not captured_objects.is_empty():
		color = laser_color_holding
	elif targeted_object:
		color = laser_color_target
	else:
		color = laser_color_idle
	
	var mat = laser_mesh.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = color
		mat.emission = color
	
	var laser_length_actual = ray_length - ray_start_offset
	
	if targeted_object and is_attracting:
		laser_length_actual = (targeted_object.global_position - global_position).length() - ray_start_offset
	elif target_indicator and target_indicator.visible:
		laser_length_actual = (target_indicator.global_position - global_position).length() - ray_start_offset
	
	laser_length_actual = max(laser_length_actual, 0.1)
	
	laser_mesh.scale.y = laser_length_actual
	laser_mesh.position.z = -(ray_start_offset + laser_length_actual / 2.0)

func _update_count_label() -> void:
	if not count_label:
		return
	
	var count = captured_objects.size()
	if count > 0:
		count_label.text = str(count)
		count_label.visible = true
		var fullness = float(count) / float(max_captured_objects)
		count_label.modulate = Color(1, 1 - fullness * 0.5, 1 - fullness * 0.7, 0.9)
	else:
		count_label.visible = false

func _update_capture_zone_visual() -> void:
	if not capture_zone_mesh:
		return
	
	# Pulse the capture zone when objects are nearby or being attracted
	var mat = capture_zone_mesh.material_override as StandardMaterial3D
	if not mat:
		return
	
	var base_alpha = capture_zone_color.a
	var pulse = sin(Time.get_ticks_msec() / 200.0) * 0.1
	
	if is_attracting and targeted_object:
		# Brighter when actively pulling
		mat.albedo_color = Color(0.5, 1.0, 0.5, base_alpha + 0.2 + pulse)
	elif not captured_objects.is_empty():
		# Orange tint when holding objects
		mat.albedo_color = Color(1.0, 0.7, 0.3, base_alpha + pulse)
	else:
		mat.albedo_color = Color(capture_zone_color.r, capture_zone_color.g, capture_zone_color.b, base_alpha + pulse)

func _update_cooldowns(delta: float) -> void:
	var expired = []
	for body in recently_launched.keys():
		recently_launched[body] -= delta
		if recently_launched[body] <= 0:
			expired.append(body)
	for body in expired:
		recently_launched.erase(body)

func launch_one() -> void:
	if captured_objects.is_empty():
		return

	var obj = captured_objects.pop_front()
	if not is_instance_valid(obj):
		return

	# Restore scale
	if obj in original_scales:
		obj.scale = original_scales[obj]
		original_scales.erase(obj)

	# Disconnect picked_up signal
	if obj.has_signal("picked_up") and obj.is_connected("picked_up", _on_captured_object_picked_up):
		obj.picked_up.disconnect(_on_captured_object_picked_up)

	# Unfreeze and launch
	obj.freeze = false
	obj.gravity_scale = 1.0  # Restore normal gravity on launch

	var launch_dir = -global_transform.basis.z
	var spread = Vector3(
		randf_range(-launch_spread, launch_spread),
		randf_range(-launch_spread, launch_spread),
		randf_range(-launch_spread, launch_spread)
	)

	obj.linear_velocity = (launch_dir + spread).normalized() * launch_force

	recently_launched[obj] = launch_cooldown

	object_launched.emit(obj, obj.linear_velocity)
	if debug:
		print("[GravityGun] Launched: ", obj.name)

func launch_all() -> void:
	while not captured_objects.is_empty():
		launch_one()

func _set_highlight(body: RigidBody3D, enable: bool) -> void:
	if body.has_method("request_highlight"):
		body.request_highlight(self, enable)

# Public API
func get_captured_count() -> int:
	return captured_objects.size()

func get_targeted_object() -> RigidBody3D:
	return targeted_object

func release_all() -> void:
	for obj in captured_objects:
		if is_instance_valid(obj):
			if obj in original_scales:
				obj.scale = original_scales[obj]
				original_scales.erase(obj)
			# Disconnect picked_up signal
			if obj.has_signal("picked_up") and obj.is_connected("picked_up", _on_captured_object_picked_up):
				obj.picked_up.disconnect(_on_captured_object_picked_up)
			obj.freeze = false
			obj.gravity_scale = 1.0
	captured_objects.clear()

func is_holding_objects() -> bool:
	return not captured_objects.is_empty()
