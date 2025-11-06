# Homing drone that chases the player and can be destroyed by throwable balls
extends CharacterBody3D

signal player_hit(drone: Node3D)
signal drone_destroyed(drone: Node3D, points_awarded: int)

const VISUAL_SCENE := preload("res://commons/primitives/truncatedtetrahedron/truncatedtetrahedron.tscn")

@export_group("Targeting")
@export var player_path: NodePath
@export var fallback_player_names: PackedStringArray = PackedStringArray(["XROrigin3D", "XRPlayer", "Player", "Camera3D", "PlayerBody", "FirstPersonPlayer"])
@export var move_speed: float = 3.2
@export var acceleration: float = 6.0
@export var hover_height: float = 1.6
@export var strafe_amplitude: float = 0.6
@export var strafe_frequency: float = 1.0

@export_group("Combat")
@export var max_health: int = 2
@export var ball_damage: int = 1
@export var stun_duration: float = 0.35
@export var player_hit_radius: float = 0.45
@export var player_hit_cooldown: float = 2.0
@export var knockback_force: float = 5.0
@export var points_value: int = 25
@export var destruction_fade_time: float = 0.6

@export_group("Kamikaze Mode")
@export var enable_kamikaze: bool = true  # Explode and damage player on death
@export var kamikaze_speed_boost: float = 2.0  # Speed multiplier when kamikaze
@export var explosion_radius: float = 0.8  # Distance to trigger explosion
@export var min_damage_percent: float = 20.0  # Min damage to player (% of max health)
@export var max_damage_percent: float = 40.0  # Max damage to player (% of max health)
@export var kamikaze_duration: float = 3.0  # Max time in kamikaze mode before auto-explode

@export_group("Visuals")
@export var base_color: Color = Color(1.0, 0.45, 0.1, 1.0)
@export var spin_speed_deg: float = 65.0
@export var bob_amplitude: float = 0.15
@export var bob_frequency: float = 1.4

var current_health: int = 0
var stun_timer: float = 0.0
var player_hit_timer: float = 0.0
var bob_timer: float = 0.0
var player_node: Node3D
var visual_root: Node3D
var visual_mesh: MeshInstance3D
var base_material: Material
var is_destroyed: bool = false
var rng := RandomNumberGenerator.new()

# Kamikaze state
var is_kamikaze: bool = false
var kamikaze_timer: float = 0.0
var has_exploded: bool = false

@onready var ball_detector: Area3D = $BallDetector
@onready var physics_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	rng.randomize()
	bob_timer = rng.randf() * TAU
	current_health = max_health
	_configure_body()
	_configure_detector()
	_ensure_visual()
	_acquire_player()

func _process(delta: float) -> void:
	if visual_root:
		# Spin faster in kamikaze mode
		var spin_multiplier = 3.0 if is_kamikaze else 1.0
		visual_root.rotate_y(deg_to_rad(spin_speed_deg * spin_multiplier) * delta)

		if not is_kamikaze:
			bob_timer += delta * bob_frequency
			visual_root.position = Vector3(0.0, sin(bob_timer) * bob_amplitude, 0.0)
		else:
			# Violent shake in kamikaze mode
			visual_root.position = Vector3(
				rng.randf_range(-0.05, 0.05),
				rng.randf_range(-0.05, 0.05),
				rng.randf_range(-0.05, 0.05)
			)

func _physics_process(delta: float) -> void:
	if is_destroyed or has_exploded:
		return

	# Kamikaze mode behavior
	if is_kamikaze:
		_kamikaze_physics(delta)
		return

	stun_timer = max(stun_timer - delta, 0.0)
	player_hit_timer = max(player_hit_timer - delta, 0.0)

	if not player_node or not is_instance_valid(player_node):
		_acquire_player()
		if not player_node:
			velocity = velocity.lerp(Vector3.ZERO, delta * 3.0)
			move_and_slide()
			return

	var target_position = player_node.global_position + Vector3(0, hover_height, 0)
	var to_target = target_position - global_position
	var desired_velocity = Vector3.ZERO

	if to_target.length() > 0.1:
		desired_velocity = to_target.normalized() * move_speed
		desired_velocity += _strafe_offset()
	if stun_timer > 0.0:
		desired_velocity *= 0.4

	velocity = velocity.lerp(desired_velocity, clamp(acceleration * delta, 0.0, 1.0))
	move_and_slide()
	_face_target(target_position)

	if to_target.length() <= player_hit_radius and player_hit_timer <= 0.0:
		player_hit_timer = player_hit_cooldown
		_handle_player_hit()

func _kamikaze_physics(delta: float) -> void:
	"""Kamikaze mode - fly straight at player and explode"""
	kamikaze_timer += delta

	if not player_node or not is_instance_valid(player_node):
		_kamikaze_explode()
		return

	# Auto-explode after duration
	if kamikaze_timer >= kamikaze_duration:
		_kamikaze_explode()
		return

	# Fly directly at player at high speed
	var target_position = player_node.global_position
	var to_target = target_position - global_position
	var distance = to_target.length()

	# Check if close enough to explode
	if distance <= explosion_radius:
		_kamikaze_explode()
		return

	# Accelerate towards player
	var desired_velocity = to_target.normalized() * (move_speed * kamikaze_speed_boost)
	velocity = velocity.lerp(desired_velocity, clamp(acceleration * 2.0 * delta, 0.0, 1.0))
	move_and_slide()
	_face_target(target_position)

func _configure_body() -> void:
	collision_layer = 1
	collision_mask = 3
	if physics_shape and physics_shape.shape is SphereShape3D:
		var shape := physics_shape.shape as SphereShape3D
		shape.radius = max(player_hit_radius, shape.radius)

func _configure_detector() -> void:
	if not ball_detector:
		return
	ball_detector.monitoring = true
	ball_detector.monitorable = true
	ball_detector.collision_layer = 0
	ball_detector.collision_mask = 2
	if not ball_detector.body_entered.is_connected(_on_ball_detector_body_entered):
		ball_detector.body_entered.connect(_on_ball_detector_body_entered)

func _ensure_visual() -> void:
	if visual_root and is_instance_valid(visual_root):
		visual_root.queue_free()
	visual_root = Node3D.new()
	visual_root.name = "VisualRoot"
	visual_root.position = Vector3.ZERO
	add_child(visual_root)

	var visual_scene: Node3D = VISUAL_SCENE.instantiate()
	visual_scene.scale = Vector3.ONE * 1.45
	visual_scene.rotation_degrees = Vector3.ZERO
	visual_root.add_child(visual_scene)

	var helper_camera := visual_scene.get_node_or_null("Camera3D")
	if helper_camera:
		helper_camera.queue_free()

	if visual_scene.has_method("set_base_color"):
		visual_scene.set_base_color(base_color)

	visual_mesh = visual_scene.get_node_or_null("TruncatedTetrahedron") as MeshInstance3D
	if visual_mesh and visual_mesh.material_override:
		base_material = visual_mesh.material_override.duplicate(true)
		visual_mesh.material_override = base_material
		_apply_material_color(base_color)

func _acquire_player() -> void:
	if player_node and is_instance_valid(player_node):
		return

	# Try explicit path first
	if player_path != NodePath(""):
		var candidate := get_node_or_null(player_path) as Node3D
		if candidate and candidate is Node3D:
			player_node = candidate
			print("[Drone] Found player via path: ", player_node.name)
			return

	# Try finding by group
	var xr_origin = get_tree().get_first_node_in_group("xr_origin")
	if xr_origin:
		player_node = xr_origin
		player_path = player_node.get_path()
		print("[Drone] Found player via xr_origin group: ", player_node.name)
		return

	# Try finding XROrigin3D directly
	if get_tree().root:
		var found_xr = _find_xr_origin_recursive(get_tree().root)
		if found_xr:
			player_node = found_xr
			player_path = player_node.get_path()
			print("[Drone] Found XROrigin3D: ", player_node.name)
			return

	# Fallback to searching by name
	var search_roots: Array = []
	var parent := get_parent()
	while parent:
		search_roots.append(parent)
		parent = parent.get_parent()
	if get_tree():
		if get_tree().current_scene:
			search_roots.append(get_tree().current_scene)
		search_roots.append(get_tree().root)

	for root in search_roots:
		if not root:
			continue
		for name in fallback_player_names:
			var found := root.find_child(name, true, false) as Node3D
			if found:
				player_node = found
				player_path = player_node.get_path()
				print("[Drone] Found player by name: ", player_node.name)
				return

	print("[Drone] WARNING: Could not find player!")

func _find_xr_origin_recursive(node: Node) -> Node3D:
	"""Recursively search for XROrigin3D"""
	if node is XROrigin3D:
		return node as Node3D

	for child in node.get_children():
		var result = _find_xr_origin_recursive(child)
		if result:
			return result

	return null

func _strafe_offset() -> Vector3:
	var time := float(Time.get_ticks_msec()) / 1000.0
	var offset := Vector3.ZERO
	offset.x = sin(time * strafe_frequency + bob_timer) * strafe_amplitude
	offset.z = cos(time * (strafe_frequency * 0.75) + bob_timer * 0.5) * (strafe_amplitude * 0.6)
	return offset

func _face_target(target_position: Vector3) -> void:
	if target_position == global_position:
		return
	look_at(target_position, Vector3.UP)

func _handle_player_hit() -> void:
	stun_timer = stun_duration
	_flash_material(base_color.lerp(Color(1, 0.2, 0.2), 0.6), 0.1, 0.25)
	emit_signal("player_hit", self)

func _on_ball_detector_body_entered(body: Node) -> void:
	if is_destroyed:
		return
	if not body or not body.is_in_group("throwable"):
		return
	take_damage(ball_damage, body)

func take_damage(amount: int, source: Node = null) -> void:
	if is_destroyed:
		return

	current_health -= amount
	stun_timer = stun_duration
	_flash_material(base_color.lerp(Color(1, 1, 1), 0.7), 0.08, 0.2)
	_apply_knockback_from_source(source)

	if current_health <= 0:
		_handle_destroyed()

func _apply_knockback_from_source(source: Node) -> void:
	if not source or not (source is Node3D):
		return
	var source_pos := (source as Node3D).global_position
	var away := (global_position - source_pos).normalized()
	if away == Vector3.ZERO:
		away = Vector3.UP
	velocity += away * knockback_force
	velocity.y += knockback_force * 0.25
	if source is RigidBody3D:
		var rigid := source as RigidBody3D
		rigid.linear_velocity = rigid.linear_velocity - away * knockback_force

func _handle_destroyed() -> void:
	if is_destroyed:
		return

	# Enter kamikaze mode if enabled
	if enable_kamikaze and not is_kamikaze:
		_enter_kamikaze_mode()
		return

	# Otherwise, just destroy normally
	is_destroyed = true
	collision_layer = 0
	collision_mask = 0
	if ball_detector:
		ball_detector.monitoring = false
		ball_detector.collision_mask = 0
	if physics_shape:
		physics_shape.disabled = true
	velocity = Vector3.ZERO
	_flash_material(Color(1, 1, 1), 0.05, destruction_fade_time)
	emit_signal("drone_destroyed", self, points_value)
	var tween := create_tween()
	if visual_root:
		tween.tween_property(visual_root, "scale", Vector3.ZERO, destruction_fade_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func _enter_kamikaze_mode() -> void:
	"""Enter kamikaze mode - last ditch attack"""
	is_kamikaze = true
	kamikaze_timer = 0.0
	current_health = 1  # Prevent re-entering kamikaze

	# Flash red to indicate kamikaze mode
	_flash_material(Color(1.0, 0.2, 0.0), 0.1, 0.1)

	print("[Drone] Entering KAMIKAZE mode!")

func _kamikaze_explode() -> void:
	"""Explode and damage player"""
	if has_exploded:
		return

	has_exploded = true
	is_destroyed = true

	print("[Drone] KAMIKAZE EXPLOSION!")

	# Calculate random damage
	var damage_percent = rng.randf_range(min_damage_percent, max_damage_percent)
	var damage_amount = (damage_percent / 100.0) * GameManager.max_player_health

	# Apply damage to player
	GameManager.apply_health_damage(damage_amount)
	print("[Drone] Dealt %.1f%% damage (%.1f HP) to player" % [damage_percent, damage_amount])

	# Disable collision
	collision_layer = 0
	collision_mask = 0
	if ball_detector:
		ball_detector.monitoring = false
	if physics_shape:
		physics_shape.disabled = true

	# Explosion visual effect
	_explosion_effect()

	# Award points for avoiding/destroying the kamikaze
	emit_signal("drone_destroyed", self, points_value)

	# Remove after explosion
	await get_tree().create_timer(1.5).timeout
	queue_free()

func _explosion_effect() -> void:
	"""Visual explosion effect"""
	if not visual_root:
		return

	# Bright flash
	_apply_material_color(Color(1.5, 1.5, 1.5))

	var tween = create_tween()
	tween.set_parallel(true)

	# Expand then shrink
	tween.tween_property(visual_root, "scale", Vector3.ONE * 2.5, 0.2)
	tween.tween_property(visual_root, "scale", Vector3.ZERO, 0.8).set_delay(0.2)

	# Fade out material
	tween.chain()
	tween.tween_method(_apply_material_color, Color(1.5, 0.5, 0.0), Color(1.0, 0.0, 0.0, 0.0), 0.5)

func _flash_material(target_color: Color, time_up: float, time_down: float) -> void:
	if not base_material:
		return
	var tween := create_tween()
	tween.tween_method(_apply_material_color, base_color, target_color, time_up)
	tween.tween_method(_apply_material_color, target_color, base_color, time_down)

func _apply_material_color(color: Color) -> void:
	if not base_material:
		return
	if base_material is ShaderMaterial:
		var shader_mat := base_material as ShaderMaterial
		shader_mat.set_shader_parameter("base_color", color)
		shader_mat.set_shader_parameter("edge_color", color.lightened(0.3))
		shader_mat.set_shader_parameter("emission_strength", 0.9 + color.v * 0.5)
	else:
		var std := base_material as StandardMaterial3D
		std.albedo_color = color
		std.emission_enabled = true
		std.emission = color

func reset_drone() -> void:
	is_destroyed = false
	current_health = max_health
	stun_timer = 0.0
	player_hit_timer = 0.0
	velocity = Vector3.ZERO
	collision_layer = 1
	collision_mask = 3
	if physics_shape:
		physics_shape.disabled = false
	if ball_detector:
		ball_detector.monitoring = true
		ball_detector.collision_mask = 2
	_apply_material_color(base_color)
	if visual_root:
		visual_root.scale = Vector3.ONE
