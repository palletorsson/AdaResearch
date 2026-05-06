# throw_ball_sphere.gd
# Extends grab_sphere to add throwing mechanics with velocity tracking
extends "res://commons/primitives/point/grab_sphere.gd"

@export_group("Throwing Physics")
@export var velocity_samples: int = 5  # Number of position samples for velocity calculation
@export var velocity_multiplier: float = 1.2  # Boost throw speed for better feel
@export var max_throw_speed: float = 10.0  # Cap maximum throw velocity
@export var enable_gravity_on_throw: bool = true
@export var ball_mass: float = 0.5

@export_group("Visual Feedback")
@export var ball_color: Color = Color(1.0, 0.5, 0.0, 1.0)  # Orange
@export var show_velocity_vector: bool = true
@export var show_gravity_vector: bool = true
@export var velocity_vector_scale: float = 0.5  # Scale vector arrow length
@export var velocity_color: Color = Color(0.0, 1.0, 1.0, 1.0)  # Cyan
@export var gravity_color: Color = Color(1.0, 0.2, 0.2, 1.0)  # Red

# Velocity tracking
var position_history: Array[Vector3] = []
var time_history: Array[float] = []
var calculated_velocity: Vector3 = Vector3.ZERO
var is_being_held: bool = false

# Vector visualization
var velocity_arrow: Node3D = null
var gravity_arrow: Node3D = null
var vectors_container: Node3D = null

func _ready() -> void:
	super._ready()
	_setup_throwing_physics()
	_setup_vectors()
	_apply_ball_color()

	# Add to throwable group for target detection
	add_to_group("throwable")

	# Reconnect signals to ensure child methods are called
	# Disconnect parent connections first
	if picked_up.is_connected(Callable(self, "_on_picked_up")):
		picked_up.disconnect(Callable(self, "_on_picked_up"))
	if dropped.is_connected(Callable(self, "_on_dropped")):
		dropped.disconnect(Callable(self, "_on_dropped"))

	# Connect to child methods
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)

	# Debug: Print collision layers
	print("[ThrowBall] Collision layer: ", collision_layer, " mask: ", collision_mask)

func _setup_throwing_physics() -> void:
	"""Configure physics for throwing"""
	mass = ball_mass
	gravity_scale = 0.0  # Disable gravity until thrown
	freeze = true  # Start frozen
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 4

	# Add layer 2 for target detection, preserve existing layers (like XRTools layer 21)
	collision_layer |= 2  # Add layer 2 while keeping existing layers
	collision_mask |= 1   # Add collision with layer 1 (ground, walls, etc.)

func _setup_vectors() -> void:
	"""Create container for vector arrows"""
	vectors_container = Node3D.new()
	vectors_container.name = "ThrowVectors"
	add_child(vectors_container)

	if show_velocity_vector:
		velocity_arrow = _create_vector_arrow("VelocityVector", velocity_color)
		vectors_container.add_child(velocity_arrow)

	if show_gravity_vector:
		gravity_arrow = _create_vector_arrow("GravityVector", gravity_color)
		vectors_container.add_child(gravity_arrow)
		# Show constant downward gravity arrow
		_update_gravity_vector()

func _create_vector_arrow(arrow_name: String, color: Color) -> Node3D:
	"""Create a vector arrow visualization"""
	var arrow = Node3D.new()
	arrow.name = arrow_name

	# Create arrow shaft (cylinder)
	var shaft = MeshInstance3D.new()
	shaft.name = "Shaft"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.005
	cylinder.bottom_radius = 0.005
	cylinder.height = 1.0
	shaft.mesh = cylinder

	# Create arrow tip (cone)
	var tip = MeshInstance3D.new()
	tip.name = "Tip"
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.015
	cone.height = 0.05
	tip.mesh = cone
	tip.position = Vector3(0, 0.525, 0)  # Position at end of shaft

	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy = 0.5
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	shaft.material_override = material
	tip.material_override = material

	arrow.add_child(shaft)
	arrow.add_child(tip)
	arrow.visible = false

	return arrow

func _process(delta: float) -> void:
	"""Update velocity tracking and vector display"""
	if is_being_held:
		_track_velocity(delta)
		_update_velocity_vector()

func _track_velocity(_delta: float) -> void:
	"""Track position history for velocity calculation"""
	var current_pos = global_position
	var current_time = Time.get_ticks_msec() / 1000.0

	position_history.append(current_pos)
	time_history.append(current_time)

	# Keep only recent samples
	while position_history.size() > velocity_samples:
		position_history.pop_front()
		time_history.pop_front()

	# Calculate velocity from position history
	if position_history.size() >= 2:
		var oldest_pos = position_history[0]
		var oldest_time = time_history[0]
		var time_diff = current_time - oldest_time

		if time_diff > 0.001:  # Avoid division by zero
			calculated_velocity = (current_pos - oldest_pos) / time_diff

func _update_velocity_vector() -> void:
	"""Update velocity vector arrow visualization"""
	if not velocity_arrow or not show_velocity_vector:
		return

	var speed = calculated_velocity.length()
	if speed < 0.01:
		velocity_arrow.visible = false
		return

	velocity_arrow.visible = true

	# Scale arrow length based on velocity
	var arrow_length = speed * velocity_vector_scale
	var shaft = velocity_arrow.get_node("Shaft")
	var tip = velocity_arrow.get_node("Tip")

	# Update shaft scale
	shaft.scale.y = arrow_length

	# Position tip at end of shaft
	tip.position.y = arrow_length / 2.0 + 0.025

	# Orient arrow in velocity direction
	var direction = calculated_velocity.normalized()
	if direction.length() > 0.1:
		velocity_arrow.look_at(global_position + direction, Vector3.UP)
		velocity_arrow.rotate_object_local(Vector3.RIGHT, -PI / 2)

func _update_gravity_vector() -> void:
	"""Update gravity vector arrow (constant downward)"""
	if not gravity_arrow or not show_gravity_vector:
		return

	gravity_arrow.visible = true

	# Fixed downward arrow
	var gravity_magnitude = 9.8
	var arrow_length = gravity_magnitude * 0.05

	var shaft = gravity_arrow.get_node("Shaft")
	var tip = gravity_arrow.get_node("Tip")

	shaft.scale.y = arrow_length
	tip.position.y = arrow_length / 2.0 + 0.025

	# Point downward
	gravity_arrow.rotation = Vector3(0, 0, 0)
	gravity_arrow.rotate_x(PI)

func _on_picked_up(pickable: Variant) -> void:
	"""Override parent to add throwing setup"""
	super._on_picked_up(pickable)

	is_being_held = true
	position_history.clear()
	time_history.clear()
	calculated_velocity = Vector3.ZERO

	# Enable physics tracking but keep frozen
	freeze = true
	gravity_scale = 0.0

	# Show vectors
	if velocity_arrow:
		velocity_arrow.visible = false
	if gravity_arrow and show_gravity_vector:
		gravity_arrow.visible = true

func _on_dropped(pickable: Variant) -> void:
	"""Override parent to apply throw velocity"""
	# Calculate final throw velocity before calling super
	var throw_velocity = calculated_velocity * velocity_multiplier

	# Cap maximum speed
	if throw_velocity.length() > max_throw_speed:
		throw_velocity = throw_velocity.normalized() * max_throw_speed

	# Call parent drop logic
	super._on_dropped(pickable)

	is_being_held = false

	# Apply physics - now unfreeze and add velocity
	freeze = false
	linear_velocity = throw_velocity

	if enable_gravity_on_throw:
		gravity_scale = 1.0

	# Ensure collision layer is still correct after drop
	collision_layer |= 2

	print("[ThrowBall] Dropped - velocity: ", throw_velocity.length(), " freeze: ", freeze, " layer: ", collision_layer)

	# Keep velocity vector visible briefly
	if velocity_arrow:
		velocity_arrow.visible = true
		_fade_out_vector(velocity_arrow)

	# Reset for next throw
	position_history.clear()
	time_history.clear()
	calculated_velocity = Vector3.ZERO

func _fade_out_vector(arrow: Node3D) -> void:
	"""Fade out vector arrow after throw"""
	if not arrow:
		return

	# Get the shaft and tip meshes
	var shaft = arrow.get_node_or_null("Shaft")
	var tip = arrow.get_node_or_null("Tip")

	if not shaft or not tip:
		arrow.visible = false
		return

	# Fade out by tweening material transparency
	var tween = create_tween()
	tween.set_parallel(true)

	# Get materials
	var shaft_mat = shaft.material_override
	var tip_mat = tip.material_override

	if shaft_mat and tip_mat:
		# Enable transparency
		if shaft_mat is StandardMaterial3D:
			shaft_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		if tip_mat is StandardMaterial3D:
			tip_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

		# Fade out alpha
		tween.tween_property(shaft_mat, "albedo_color:a", 0.0, 1.0)
		tween.tween_property(tip_mat, "albedo_color:a", 0.0, 1.0)

		# Hide and reset after fade
		tween.chain()
		tween.tween_callback(func():
			arrow.visible = false
			if shaft_mat is StandardMaterial3D:
				shaft_mat.albedo_color.a = 1.0
			if tip_mat is StandardMaterial3D:
				tip_mat.albedo_color.a = 1.0
		)
	else:
		# Fallback: just hide after delay
		await get_tree().create_timer(1.0).timeout
		arrow.visible = false

func get_current_velocity() -> Vector3:
	"""Get the currently calculated velocity"""
	return calculated_velocity

func get_throw_speed() -> float:
	"""Get the magnitude of throw velocity"""
	return calculated_velocity.length()

func _apply_ball_color() -> void:
	"""Apply the ball color to the mesh and parent materials"""
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		return

	# Update the original material that parent cached
	if _original_material and _original_material is StandardMaterial3D:
		var mat = _original_material as StandardMaterial3D
		mat.albedo_color = ball_color
		mat.emission_enabled = true
		mat.emission = ball_color
		mat.emission_energy_multiplier = 0.3

	# Rebuild glow material with new color
	_glow_material = _build_glow_material(_original_material)

	# Apply to mesh if not currently glowing
	if not _is_glowing and mesh_instance.mesh and mesh_instance.mesh.get_surface_count() > 0:
		mesh_instance.set_surface_override_material(0, _original_material)

func set_ball_color(color: Color) -> void:
	"""Set the ball color (can be called externally)"""
	ball_color = color
	_apply_ball_color()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
