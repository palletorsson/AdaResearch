# Homing drone that chases the player and can be destroyed by throwable balls
#
# @identity
# essence: desired = (target - position).normalized() * speed. Chase, prepare, shoot, cooldown. A state machine driven by vector subtraction.
# desire: To hunt. To orbit at ideal_distance, charge projectiles, fire in bursts, and kamikaze when dying — an adversary that teaches vectors by trying to kill you.
# critical_parameter: ideal_distance (4.0 units) — the range the drone wants to maintain. Too close = backs up. Too far = approaches. In range = switches to attack states.
# triggers: Player position → chase/orbit, prepare timer → spawn held projectiles, shoot timer → fire burst, health reaches 0 → kamikaze mode (speed boost, explosion, damage)
# emerges: The drone's strafing pattern from sinusoidal offsets. Leading shots via look_at. Kamikaze desperation creating final-moment tension.
# needs: State machine AI [has], burst-fire system [has], kamikaze mode [has], VR player tracking [has]. Missing: difficulty scaling, formation flying with multiple drones.
# relationships: Enemy counterpart to hl_turret_vectors (player-controlled targeting vs AI targeting). Sub-component of VectorThrowing. Uses subtraction and normalization as core AI.
# truth: The drone is a mirror of the turret. Same math, opposite role. Subtraction works for both hunter and hunted.
extends CharacterBody3D

signal player_hit(drone: Node3D)
signal drone_destroyed(drone: Node3D, points_awarded: int)



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

@export_group("Shooter AI")
@export var projectile_scene: PackedScene = preload("res://algorithms/vectors/08_vector_throwing/drone_projectile.tscn")
@export var ideal_distance: float = 4.0
@export var shoot_interval: float = 0.5
@export var prepare_time: float = 1.0
@export var cooldown_time: float = 2.0
@export var burst_count: int = 3

enum State { CHASE, PREPARE, SHOOT, COOLDOWN }
var current_state: State = State.CHASE
var state_timer: float = 0.0
var shots_fired: int = 0
var held_projectiles: Array[Node3D] = []


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

	# Update timers
	stun_timer = max(stun_timer - delta, 0.0)
	state_timer = max(state_timer - delta, 0.0)
	player_hit_timer = max(player_hit_timer - delta, 0.0)

	if not player_node or not is_instance_valid(player_node):
		_acquire_player()
		if not player_node:
			velocity = velocity.lerp(Vector3.ZERO, delta * 3.0)
			move_and_slide()
			return
			
	var ideal_height = ideal_distance * tan(deg_to_rad(35.0)) # 35 degrees elevation
	var target_pos = player_node.global_position + Vector3(0, ideal_height, 0)
	_face_target(player_node.global_position + Vector3(0, 1.0, 0)) # Look at player, not the spot above them

	match current_state:
		State.CHASE:
			_process_chase(target_pos, delta)

		State.PREPARE:
			_process_prepare(delta)
		State.SHOOT:
			_process_shoot(delta)
		State.COOLDOWN:
			_process_cooldown(target_pos, delta)

	move_and_slide()
	
	# Check for collisions with player
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider == player_node or collider.is_in_group("player") or collider.is_in_group("player_body"):
			_handle_player_hit()


# AI States
func _process_chase(target_pos: Vector3, delta: float) -> void:
	var to_target = target_pos - global_position
	var dist = to_target.length()
	var desired_velocity = Vector3.ZERO

	if dist > ideal_distance + 0.5:
		# Too far, approach
		desired_velocity = to_target.normalized() * move_speed
	elif dist < ideal_distance - 0.5:
		# Too close, back up
		desired_velocity = -to_target.normalized() * move_speed
	else:
		# In range, maybe strafe a bit?
		desired_velocity = _strafe_offset() * 2.0
		# If stable in range, switch state
		if stun_timer <= 0.0:
			_switch_state(State.PREPARE)
	
	velocity = velocity.lerp(desired_velocity, delta * acceleration)

func _process_prepare(_delta: float) -> void:
	velocity = velocity.lerp(Vector3.ZERO, _delta * 2.0)
	if state_timer <= 0.0:
		_switch_state(State.SHOOT)

func _process_shoot(_delta: float) -> void:
	velocity = velocity.lerp(Vector3.ZERO, _delta * 5.0) # Stop to shoot
	if state_timer <= 0.0:
		if shots_fired < burst_count:
			_fire_projectile()
			shots_fired += 1
			state_timer = shoot_interval
		else:
			_switch_state(State.COOLDOWN)

func _process_cooldown(target_pos: Vector3, delta: float) -> void:
	# Strafe while cooling down
	var to_target = target_pos - global_position
	var strafe = to_target.cross(Vector3.UP).normalized() * (move_speed * 0.5)
	if sin(Time.get_ticks_msec() * 0.001) < 0:
		strafe = -strafe
	
	velocity = velocity.lerp(strafe, delta * acceleration)
	
	if state_timer <= 0.0:
		_switch_state(State.CHASE)

func _switch_state(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.CHASE:
			pass
		State.PREPARE:
			state_timer = prepare_time
			_spawn_held_projectiles()
		State.SHOOT:
			shots_fired = 0
			state_timer = 0.0 # Start shooting immediately
		State.COOLDOWN:
			state_timer = cooldown_time
			_clear_held_projectiles()

func _spawn_held_projectiles() -> void:
	_clear_held_projectiles()
	for i in range(burst_count):
		if not projectile_scene: break
		var proj = projectile_scene.instantiate() as RigidBody3D
		if not proj: continue
		
		proj.freeze = true
		proj.scale = Vector3.ONE * 0.5 # Start small?
		add_child(proj)
		
		# Position in a triangle or arc in front
		var angle = (i - (burst_count-1)/2.0) * 0.5
		proj.position = Vector3(sin(angle)*0.8, 0.5, cos(angle)*0.8)
		held_projectiles.append(proj)

func _fire_projectile() -> void:
	if held_projectiles.is_empty():
		return
	
	var proj = held_projectiles.pop_front() as RigidBody3D
	if not is_instance_valid(proj): 
		return
		
	# Detach and fire
	var global_pos = proj.global_position
	remove_child(proj)
	get_parent().add_child(proj)
	proj.global_position = global_pos
	proj.scale = Vector3.ONE
	proj.freeze = false
	
	if player_node:
		var target = player_node.global_position + Vector3(0, 1.0, 0) # Head approx
		# Predict? Naah, just shoot directly + slight lead
		var dir = (target - global_pos).normalized()
		proj.linear_velocity = dir * 12.0 # Fast shot
		proj.look_at(global_pos + dir, Vector3.UP)
	
	# Small recoil/sound effect could go here

func _clear_held_projectiles() -> void:
	for p in held_projectiles:
		if is_instance_valid(p):
			p.queue_free()
	held_projectiles.clear()


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
	if not visual_root:
		visual_root = get_node_or_null("VisualRoot")
	
	if not visual_root:
		push_warning("[VectorDrone] VisualRoot not found in scene!")
		return

	var visual_scene = visual_root.get_node_or_null("Truncatedtetrahedron")
	if not visual_scene:
		push_warning("[VectorDrone] Truncatedtetrahedron visual not found in VisualRoot!")
		return

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

	# Method 1: Ask GameManager (The "Real" Way)
	var gm_player = GameManager.get_player()
	if gm_player and is_instance_valid(gm_player):
		player_node = gm_player
		player_path = player_node.get_path()
		print("[Drone] Found player via GameManager: ", player_node.name)
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
	if player_hit_timer > 0.0:
		return

	player_hit_timer = player_hit_cooldown
	stun_timer = stun_duration
	_flash_material(base_color.lerp(Color(1, 0.2, 0.2), 0.6), 0.1, 0.25)
	
	# Deal 5 damage
	# Note: VectorThrowing.gd will handle "3 hits logic" via signals if needed,
	# but GameManager handles global health.
	GameManager.apply_health_damage(5.0)
	
	emit_signal("player_hit", self)
	
	# Bounce back from player
	if player_node:
		var dir = (global_position - player_node.global_position).normalized()
		velocity += dir * 8.0

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

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
