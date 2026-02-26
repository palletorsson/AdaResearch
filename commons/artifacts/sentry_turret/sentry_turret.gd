extends Node3D
class_name SentryTurret

## Half-Life style sentry turret - targets balls or player
## Map syntax: sentry_turret:yaw:y_offset:scale#target:player/balls/all
## Uses raycasting and direct scene queries - simple and reliable

signal target_acquired(target: Node3D)
signal target_lost
signal fired(position: Vector3, direction: Vector3)
signal hit_target(target: Node3D, position: Vector3)

@export_category("Turret")
@export var rotation_speed: float = 5.0
@export var detection_range: float = 15.0
@export var fire_rate: float = 3.0  # shots per second
@export var bullet_speed: float = 20.0
@export var reload_time: float = 2.0  # cooldown between bursts
@export var burst_size: int = 5  # shots before reload
@export var target_player: bool = true
@export var target_balls: bool = true
@export var use_laser_damage: bool = true  # Laser deals damage instead of bullets
@export var laser_damage_per_second: float = 100.0  # Damage when laser is on target

@export_category("Appearance")
@export var turret_color: Color = Color(0.5, 0.5, 0.55)
@export var laser_color: Color = Color(1.0, 0.1, 0.0)

# Components
var base: Node3D
var head: Node3D
var barrel: Node3D
var laser: MeshInstance3D
var muzzle_pos: Node3D
var eye: MeshInstance3D

# State
var current_target: Node3D = null
var fire_cooldown: float = 0.0
var reload_cooldown: float = 0.0
var shots_in_burst: int = 0
var bullets: Array[Dictionary] = []
var is_laser_firing: bool = false

# Shared effect resources (created once, reused for all effects)
var _spark_mesh: SphereMesh
var _spark_mat_template: StandardMaterial3D
var _bullet_mesh: SphereMesh
var _bullet_mat_template: StandardMaterial3D
var _hit_mesh: SphereMesh
var _hit_mat_template: StandardMaterial3D

# Hit-flash MultiMesh pool (replaces per-hit MeshInstance3D creation)
const HIT_POOL_SIZE := 8
var _hit_mm: MultiMesh
var _hit_mmi: MultiMeshInstance3D
var _hit_timers: Array[float] = []  # remaining lifetime per slot
const HIT_FLASH_DURATION := 0.1
var _hit_next_slot: int = 0  # round-robin index
# Hidden transform (move instance far away when inactive)
var _hit_hidden_xf := Transform3D(Basis(), Vector3(0, -1000, 0))

func _ready():
	_init_shared_resources()
	_build_turret()
	# Hit-flash pool lives under scene root so positions are world-space
	get_tree().root.call_deferred("add_child", _hit_mmi)
	# Defer config parsing to allow metadata to be set by map loader
	call_deferred("_parse_config")
	add_to_group("turrets")

func _init_shared_resources():
	# Spark effect mesh + material (shared across all explosion sparks)
	_spark_mesh = SphereMesh.new()
	_spark_mesh.radius = 0.04
	_spark_mat_template = StandardMaterial3D.new()
	_spark_mat_template.emission_enabled = true
	_spark_mat_template.emission_energy_multiplier = 8.0
	_spark_mat_template.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Bullet visual mesh + material
	_bullet_mesh = SphereMesh.new()
	_bullet_mesh.radius = 0.03
	_bullet_mesh.height = 0.06
	_bullet_mat_template = StandardMaterial3D.new()
	_bullet_mat_template.albedo_color = Color(1.0, 0.8, 0.3)
	_bullet_mat_template.emission_enabled = true
	_bullet_mat_template.emission = Color(1.0, 0.6, 0.2)
	_bullet_mat_template.emission_energy_multiplier = 3.0

	# Hit flash mesh + material (used as MultiMesh template)
	_hit_mesh = SphereMesh.new()
	_hit_mesh.radius = 0.08
	_hit_mat_template = StandardMaterial3D.new()
	_hit_mat_template.albedo_color = Color(1.0, 0.5, 0.2)
	_hit_mat_template.emission_enabled = true
	_hit_mat_template.emission = Color(1.0, 0.4, 0.1)
	_hit_mat_template.emission_energy_multiplier = 4.0

	# Hit-flash MultiMesh pool — 1 draw call for all hit effects
	_hit_mm = MultiMesh.new()
	_hit_mm.transform_format = MultiMesh.TRANSFORM_3D
	_hit_mm.mesh = _hit_mesh
	_hit_mm.instance_count = HIT_POOL_SIZE
	for i in HIT_POOL_SIZE:
		_hit_mm.set_instance_transform(i, _hit_hidden_xf)
	_hit_mmi = MultiMeshInstance3D.new()
	_hit_mmi.multimesh = _hit_mm
	_hit_mmi.material_override = _hit_mat_template
	_hit_timers.resize(HIT_POOL_SIZE)
	_hit_timers.fill(0.0)

func _parse_config():
	# Check config_target meta (set by map loader via #target:mode syntax)
	if has_meta("config_target"):
		var mode = get_meta("config_target")
		print("[SentryTurret] Found config_target meta: %s" % mode)
		_apply_target_mode(str(mode))
		return
	
	# Check direct target meta
	if has_meta("target"):
		var mode = get_meta("target")
		print("[SentryTurret] Found target meta: %s" % mode)
		_apply_target_mode(str(mode))
		return
	
	print("[SentryTurret] No target config found, using defaults: player=%s, balls=%s" % [target_player, target_balls])

func _apply_target_mode(mode: String):
	mode = mode.to_lower().strip_edges()
	match mode:
		"player":
			target_player = true
			target_balls = false
		"balls":
			target_player = false
			target_balls = true
		"all":
			target_player = true
			target_balls = true
	print("[SentryTurret] Target mode set: %s (player=%s, balls=%s)" % [mode, target_player, target_balls])

func _build_turret():
	# Base
	base = Node3D.new()
	base.name = "Base"
	add_child(base)
	
	var base_mesh = MeshInstance3D.new()
	var base_cyl = CylinderMesh.new()
	base_cyl.top_radius = 0.2
	base_cyl.bottom_radius = 0.25
	base_cyl.height = 0.1
	base_mesh.mesh = base_cyl
	base_mesh.position.y = 0.05
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = turret_color
	base_mat.metallic = 0.6
	base_mat.roughness = 0.4
	base_mesh.material_override = base_mat
	base.add_child(base_mesh)
	
	# Column
	var column = MeshInstance3D.new()
	var col_cyl = CylinderMesh.new()
	col_cyl.top_radius = 0.06
	col_cyl.bottom_radius = 0.08
	col_cyl.height = 0.3
	column.mesh = col_cyl
	column.position.y = 0.25
	column.material_override = base_mat
	base.add_child(column)
	
	# Head (rotates yaw)
	head = Node3D.new()
	head.name = "Head"
	head.position.y = 0.45
	base.add_child(head)
	
	var head_mesh = MeshInstance3D.new()
	var head_box = BoxMesh.new()
	head_box.size = Vector3(0.18, 0.12, 0.2)
	head_mesh.mesh = head_box
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = turret_color.darkened(0.1)
	head_mat.metallic = 0.5
	head_mesh.material_override = head_mat
	head.add_child(head_mesh)
	
	# Eye
	eye = MeshInstance3D.new()
	var eye_mesh = SphereMesh.new()
	eye_mesh.radius = 0.025
	eye_mesh.height = 0.05
	eye.mesh = eye_mesh
	eye.position = Vector3(0, 0.02, 0.1)
	var eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = laser_color
	eye_mat.emission_enabled = true
	eye_mat.emission = laser_color
	eye_mat.emission_energy_multiplier = 2.0
	eye.material_override = eye_mat
	head.add_child(eye)
	
	# Barrel (rotates pitch)
	barrel = Node3D.new()
	barrel.name = "Barrel"
	barrel.position = Vector3(0, 0, 0.1)
	head.add_child(barrel)
	
	var barrel_mesh = MeshInstance3D.new()
	var barrel_cyl = CylinderMesh.new()
	barrel_cyl.top_radius = 0.02
	barrel_cyl.bottom_radius = 0.025
	barrel_cyl.height = 0.25
	barrel_mesh.mesh = barrel_cyl
	barrel_mesh.rotation.x = PI/2
	barrel_mesh.position.z = 0.125
	var barrel_mat = StandardMaterial3D.new()
	barrel_mat.albedo_color = turret_color.darkened(0.2)
	barrel_mat.metallic = 0.7
	barrel_mesh.material_override = barrel_mat
	barrel.add_child(barrel_mesh)
	
	# Muzzle position
	muzzle_pos = Node3D.new()
	muzzle_pos.name = "Muzzle"
	muzzle_pos.position.z = 0.28
	barrel.add_child(muzzle_pos)
	
	# Laser sight
	laser = MeshInstance3D.new()
	laser.name = "Laser"
	laser.visible = false
	var laser_mesh = CylinderMesh.new()
	laser_mesh.top_radius = 0.003
	laser_mesh.bottom_radius = 0.003
	laser_mesh.height = 1.0
	laser.mesh = laser_mesh
	var laser_mat = StandardMaterial3D.new()
	laser_mat.albedo_color = laser_color
	laser_mat.emission_enabled = true
	laser_mat.emission = laser_color
	laser_mat.emission_energy_multiplier = 3.0
	laser_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	laser.material_override = laser_mat
	add_child(laser)

func _process(delta):
	_find_target()
	_track_target(delta)
	_update_shooting(delta)
	_update_bullets(delta)
	_update_laser()
	_update_hit_pool(delta)

func _update_hit_pool(delta: float):
	for i in HIT_POOL_SIZE:
		if _hit_timers[i] > 0.0:
			_hit_timers[i] -= delta
			if _hit_timers[i] <= 0.0:
				_hit_mm.set_instance_transform(i, _hit_hidden_xf)

func _get_target_position(target: Node3D) -> Vector3:
	"""Get actual position of target - handles ball structure with RigidBody child"""
	if not is_instance_valid(target):
		return Vector3.ZERO
	
	# Check if target has a RigidBody3D child (ball structure)
	var rb = target.get_node_or_null("RigidBody3D")
	if rb:
		return rb.global_position
	
	# Check if target IS a RigidBody3D
	if target is RigidBody3D:
		return target.global_position
	
	# Fallback to node's own position
	return target.global_position

var _debug_timer: float = 0.0

func _find_target():
	var best_target: Node3D = null
	var best_dist: float = INF
	
	# Debug every 2 seconds
	_debug_timer += get_process_delta_time()
	var do_debug = _debug_timer > 2.0
	if do_debug:
		_debug_timer = 0.0
	
	# Find player
	if target_player:
		var player = _find_player()
		if player:
			var dist = global_position.distance_to(player.global_position)
			if dist < detection_range and dist < best_dist:
				best_dist = dist
				best_target = player
	
	# Find balls
	if target_balls:
		var balls = _find_balls()
		if do_debug:
			print("[Turret] Found %d balls, target_balls=%s" % [balls.size(), target_balls])
		for ball in balls:
			if not is_instance_valid(ball):
				continue
			var ball_pos = _get_target_position(ball)
			var dist = global_position.distance_to(ball_pos)
			if do_debug:
				print("[Turret]   Ball at %s, dist=%.1f (range=%.1f)" % [ball_pos, dist, detection_range])
			if dist < detection_range and dist < best_dist:
				best_dist = dist
				best_target = ball
	
	if best_target != current_target:
		if best_target:
			current_target = best_target
			print("[Turret] TARGET ACQUIRED: %s at dist %.1f" % [best_target.name, best_dist])
			emit_signal("target_acquired", current_target)
		elif current_target:
			current_target = null
			print("[Turret] TARGET LOST")
			emit_signal("target_lost")

func _find_player() -> Node3D:
	# Try XR camera first
	var xr_origin = get_tree().get_first_node_in_group("xr_origin")
	if xr_origin:
		var camera = xr_origin.get_node_or_null("XRCamera3D")
		if camera:
			return camera
	
	# Try regular camera
	var cameras = get_tree().get_nodes_in_group("player")
	if cameras.size() > 0:
		return cameras[0]
	
	# Fallback to any Camera3D
	var viewport = get_viewport()
	if viewport:
		var cam = viewport.get_camera_3d()
		if cam:
			return cam
	
	return null

func _find_balls() -> Array:
	var balls: Array = []
	
	# Check droppers
	var droppers = get_tree().get_nodes_in_group("ball_dropper")
	for dropper in droppers:
		if "active_balls" in dropper:
			for ball in dropper.active_balls:
				if is_instance_valid(ball) and ball.visible:
					balls.append(ball)
		elif "balls" in dropper:
			for b in dropper.balls:
				if is_instance_valid(b) and b.visible:
					balls.append(b)
	
	# Check colorballs
	for spawner in get_tree().get_nodes_in_group("colorballs"):
		if "balls" in spawner:
			for b in spawner.balls:
				if is_instance_valid(b) and b.visible:
					balls.append(b)
	
	# Scan for ball nodes in group
	if balls.is_empty():
		for node in get_tree().get_nodes_in_group("balls"):
			if is_instance_valid(node) and node.visible:
				balls.append(node)
	
	return balls

func _track_target(delta: float):
	if not current_target or not is_instance_valid(current_target):
		# Idle scan
		head.rotation.y += delta * 0.8
		barrel.rotation.x = lerp_angle(barrel.rotation.x, 0.0, delta * 2)
		return
	
	var target_pos = _get_target_position(current_target)
	var head_pos = head.global_position
	
	# Guard: skip if positions are too close (causes singular matrix)
	var to_target_world = target_pos - head_pos
	if to_target_world.length_squared() < 0.0001:
		return
	
	# Guard: skip if basis is degenerate (zero scale during animation)
	var det = global_transform.basis.determinant()
	if abs(det) < 0.0001:
		return
	
	# Transform target direction into turret's local space for proper yaw/pitch
	var to_target_local = global_transform.basis.inverse() * to_target_world
	
	# Yaw (in local space)
	var target_yaw = atan2(to_target_local.x, to_target_local.z)
	head.rotation.y = lerp_angle(head.rotation.y, target_yaw, rotation_speed * delta)
	
	# Pitch (using local space direction)
	var horiz_dist = Vector2(to_target_local.x, to_target_local.z).length()
	var target_pitch = -atan2(to_target_local.y, horiz_dist)
	target_pitch = clamp(target_pitch, -PI/4, PI/4)
	barrel.rotation.x = lerp_angle(barrel.rotation.x, target_pitch, rotation_speed * delta)

func _update_shooting(delta: float):
	fire_cooldown -= delta
	reload_cooldown -= delta
	
	if not current_target or not is_instance_valid(current_target):
		is_laser_firing = false
		return
	
	# Check distance to target
	var muzzle_world = muzzle_pos.global_position
	var target_pos = _get_target_position(current_target)
	var dist_to_target = muzzle_world.distance_to(target_pos)
	var is_close_enough = dist_to_target < detection_range
	
	# Laser damage mode - just fire if target is in range (laser visual already hits)
	if use_laser_damage:
		if is_close_enough:
			if not is_laser_firing:
				print("[Turret] *** LASER FIRING *** dist: %.1f" % dist_to_target)
			is_laser_firing = true
			_apply_laser_damage(delta)
		else:
			if is_laser_firing:
				print("[Turret] Target out of range - dist: %.1f" % dist_to_target)
			is_laser_firing = false
		return
	
	# Bullet mode
	is_laser_firing = false
	
	# Check if reloading
	if reload_cooldown > 0:
		return
	
	if is_close_enough and fire_cooldown <= 0:
		_fire()
		fire_cooldown = 1.0 / fire_rate
		shots_in_burst += 1
		
		# Check if need to reload
		if shots_in_burst >= burst_size:
			reload_cooldown = reload_time
			shots_in_burst = 0

var _damage_debug_timer: float = 0.0

# Signal for external listeners
signal laser_hit(target: Node3D, damage: float, position: Vector3)

func _apply_laser_damage(delta: float):
	"""Apply continuous laser damage to current target"""
	if not current_target or not is_instance_valid(current_target):
		print("[Turret] _apply_laser_damage: No valid target!")
		return
	
	var damage = laser_damage_per_second * delta
	var target_pos = _get_target_position(current_target)
	
	# Emit signal for any listeners
	emit_signal("laser_hit", current_target, damage, target_pos)
	
	# Try to call take_damage() on the target if it has that method
	if current_target.has_method("take_damage"):
		current_target.take_damage(damage)
	else:
		# Also check RigidBody child
		var rb = current_target.get_node_or_null("RigidBody3D")
		if rb and rb.has_method("take_damage"):
			rb.take_damage(damage)
	
	# Also manage health via metadata (fallback)
	if not current_target.has_meta("health"):
		print("[Turret] Setting initial health on %s" % current_target.name)
		current_target.set_meta("health", 80.0)
		current_target.set_meta("max_health", 80.0)
	
	var health: float = current_target.get_meta("health")
	var max_health: float = current_target.get_meta("max_health")
	health -= damage
	current_target.set_meta("health", health)
	
	# Debug every 0.3 seconds
	_damage_debug_timer += delta
	if _damage_debug_timer > 0.3:
		_damage_debug_timer = 0.0
		print("[Turret] BURNING %s - damage/frame: %.2f, Health: %.1f/%.1f" % [current_target.name, damage, health, max_health])
	
	# Visual burn effect on ball
	_apply_burn_effect(current_target)
	
	# Check if destroyed
	if health <= 0:
		print("[Turret] *** BALL DESTROYED! *** Health: %.1f" % health)
		_destroy_target(current_target)

func _apply_burn_effect(target: Node3D):
	"""Visual feedback when laser is burning a ball"""
	if not is_instance_valid(target):
		return
	
	var max_health = target.get_meta("max_health") if target.has_meta("max_health") else 100.0
	var health = target.get_meta("health") if target.has_meta("health") else max_health
	var burn_progress = 1.0 - clamp(health / max_health, 0.0, 1.0)
	
	# Find the mesh to apply burn effect
	var rb = target.get_node_or_null("RigidBody3D")
	if rb:
		var mesh = rb.get_node_or_null("MeshInstance3D")
		if mesh and mesh.material_override:
			var mat = mesh.material_override as StandardMaterial3D
			if mat:
				# Increase emission as ball burns
				mat.emission_energy_multiplier = 0.8 + burn_progress * 5.0
				# Shift color towards white/yellow
				var original_color = target.get_meta("ball_color") if target.has_meta("ball_color") else mat.albedo_color
				mat.emission = original_color.lerp(Color(1.0, 0.9, 0.5), burn_progress * 0.7)

func _destroy_target(target: Node3D):
	"""Destroy a ball target"""
	if not is_instance_valid(target):
		return
	
	var pos = _get_target_position(target)
	var color = target.get_meta("ball_color") if target.has_meta("ball_color") else Color(1.0, 0.5, 0.2)
	
	print("[Turret] Destroying ball at %s" % pos)
	
	# Clear current target FIRST to prevent re-processing
	var was_current = (current_target == target)
	if was_current:
		current_target = null
		is_laser_firing = false
	
	# Spawn explosion effect
	_spawn_explosion(pos, color)
	
	# Notify dropper to recycle the ball
	var removed = false
	for dropper in get_tree().get_nodes_in_group("ball_dropper"):
		if dropper.has_method("remove_ball"):
			dropper.remove_ball(target)
			removed = true
			print("[Turret] Ball recycled via dropper")
			break
	
	# If no dropper handled it, just hide/free it
	if not removed:
		target.visible = false
		target.queue_free()
		print("[Turret] Ball freed directly")
	
	if was_current:
		emit_signal("target_lost")
	
	emit_signal("hit_target", target, pos)

func _spawn_explosion(pos: Vector3, color: Color):
	"""Spawn particle explosion at position"""
	# Central flash
	var flash = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.2
	flash.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 15.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.material_override = mat
	flash.position = pos
	get_tree().root.add_child(flash)
	
	# Expanding ring
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.15
	torus.outer_radius = 0.2
	ring.mesh = torus
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = color
	ring_mat.emission_enabled = true
	ring_mat.emission = color
	ring_mat.emission_energy_multiplier = 10.0
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = ring_mat
	ring.position = pos
	get_tree().root.add_child(ring)
	
	# Sparks/fragments — MultiMesh for GPU instancing (8 sparks, 1 draw call)
	var spark_color = color.lerp(Color.YELLOW, 0.5)
	var spark_count := 8
	var spark_mm := MultiMesh.new()
	spark_mm.transform_format = MultiMesh.TRANSFORM_3D
	spark_mm.instance_count = spark_count
	spark_mm.mesh = _spark_mesh
	var spark_mmi := MultiMeshInstance3D.new()
	spark_mmi.multimesh = spark_mm
	var spark_mat = _spark_mat_template.duplicate() as StandardMaterial3D
	spark_mat.albedo_color = spark_color
	spark_mat.emission = spark_color
	spark_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spark_mmi.material_override = spark_mat
	get_tree().root.add_child(spark_mmi)

	# Pre-compute random directions and end positions for each spark
	var spark_starts: Array[Vector3] = []
	var spark_ends: Array[Vector3] = []
	for i in range(spark_count):
		spark_starts.append(pos)
		var dir = Vector3(randf_range(-1, 1), randf_range(0.2, 1), randf_range(-1, 1)).normalized()
		spark_ends.append(pos + dir * randf_range(0.3, 0.6))
		spark_mm.set_instance_transform(i, Transform3D(Basis(), pos))

	# Animate all sparks via a single tween with method callback
	var spark_tween = get_tree().create_tween()
	spark_tween.tween_method(func(t: float):
		for i in range(spark_count):
			var ease_t = 1.0 - pow(1.0 - t, 2.0)  # ease-out quad
			var p = spark_starts[i].lerp(spark_ends[i], ease_t)
			spark_mm.set_instance_transform(i, Transform3D(Basis(), p))
		spark_mat.albedo_color.a = 1.0 - t
	, 0.0, 1.0, 0.3)
	spark_tween.tween_callback(spark_mmi.queue_free)
	
	# Animate flash
	var tween = get_tree().create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.2)
	tween.parallel().tween_property(flash, "scale", Vector3.ONE * 3.0, 0.2)
	tween.tween_callback(flash.queue_free)
	
	# Animate ring
	var ring_tween = get_tree().create_tween()
	ring_tween.tween_property(ring, "scale", Vector3.ONE * 4.0, 0.4).set_ease(Tween.EASE_OUT)
	ring_tween.parallel().tween_property(ring_mat, "albedo_color:a", 0.0, 0.4)
	ring_tween.tween_callback(ring.queue_free)
	
	# Add light flash
	var light = OmniLight3D.new()
	light.light_color = color.lerp(Color.WHITE, 0.5)
	light.light_energy = 5.0
	light.omni_range = 2.0
	light.position = pos
	get_tree().root.add_child(light)
	
	var light_tween = get_tree().create_tween()
	light_tween.tween_property(light, "light_energy", 0.0, 0.3)
	light_tween.tween_callback(light.queue_free)

func _fire():
	var muzzle_world = muzzle_pos.global_position
	var direction = -barrel.global_transform.basis.z
	
	emit_signal("fired", muzzle_world, direction)
	
	# Create bullet
	var bullet = {
		"pos": muzzle_world,
		"vel": direction * bullet_speed,
		"age": 0.0,
		"node": _create_bullet_visual(muzzle_world)
	}
	bullets.append(bullet)
	
	# Muzzle flash
	_muzzle_flash()

func _create_bullet_visual(pos: Vector3) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	mesh.mesh = _bullet_mesh
	mesh.material_override = _bullet_mat_template
	mesh.position = pos
	get_tree().root.add_child(mesh)
	return mesh

func _muzzle_flash():
	var flash = OmniLight3D.new()
	flash.light_color = Color(1.0, 0.7, 0.3)
	flash.light_energy = 3.0
	flash.omni_range = 1.0
	flash.position = muzzle_pos.global_position
	get_tree().root.add_child(flash)
	
	get_tree().create_timer(0.05).timeout.connect(func():
		if is_instance_valid(flash):
			flash.queue_free()
	)

func _update_bullets(delta: float):
	var to_remove: Array[int] = []
	
	for i in range(bullets.size()):
		var b = bullets[i]
		b["age"] += delta
		b["pos"] += b["vel"] * delta
		
		if b["node"] and is_instance_valid(b["node"]):
			b["node"].position = b["pos"]
		
		# Check hits on balls only (not player)
		if target_balls:
			for ball in _find_balls():
				if is_instance_valid(ball):
					var ball_pos = _get_target_position(ball)
					var dist = b["pos"].distance_to(ball_pos)
					if dist < 0.2:
						_on_hit(ball, b["pos"])
						to_remove.append(i)
						break
		
		# Lifetime / range
		if b["age"] > 2.0 or b["pos"].length() > detection_range * 2:
			to_remove.append(i)
	
	# Remove in reverse
	for i in range(to_remove.size() - 1, -1, -1):
		var idx = to_remove[i]
		if idx < bullets.size():
			var b = bullets[idx]
			if b["node"] and is_instance_valid(b["node"]):
				b["node"].queue_free()
			bullets.remove_at(idx)

func _on_hit(target: Node3D, pos: Vector3):
	emit_signal("hit_target", target, pos)
	
	# Apply damage if target has health
	if target.has_meta("health"):
		var health = target.get_meta("health")
		health -= 20.0
		target.set_meta("health", health)
	
	# Apply impulse if RigidBody
	var rb = target.get_node_or_null("RigidBody3D")
	if rb == null and target is RigidBody3D:
		rb = target
	if rb:
		var dir = (pos - muzzle_pos.global_position).normalized()
		rb.apply_impulse(dir * 0.3)
	
	# Hit effect — MultiMesh pool (no node creation per hit)
	_hit_mm.set_instance_transform(_hit_next_slot, Transform3D(Basis(), pos))
	_hit_timers[_hit_next_slot] = HIT_FLASH_DURATION
	_hit_next_slot = (_hit_next_slot + 1) % HIT_POOL_SIZE

func _update_laser():
	# Always show laser when targeting player
	var show_laser = false
	var is_targeting_player = false
	
	if current_target and is_instance_valid(current_target):
		# Check if current target is the player (camera)
		var player = _find_player()
		if player and current_target == player:
			is_targeting_player = true
			show_laser = true
		elif target_balls:
			show_laser = true
	
	if not show_laser:
		laser.visible = false
		eye.material_override.emission_energy_multiplier = 1.0
		return
	
	laser.visible = true
	
	# Brighter when actively firing laser
	if is_laser_firing:
		eye.material_override.emission_energy_multiplier = 8.0
		laser.material_override.emission_energy_multiplier = 8.0
		# Thicker laser when firing
		var laser_mesh = laser.mesh as CylinderMesh
		if laser_mesh:
			laser_mesh.top_radius = 0.008
			laser_mesh.bottom_radius = 0.008
	elif is_targeting_player:
		eye.material_override.emission_energy_multiplier = 5.0
		laser.material_override.emission_energy_multiplier = 5.0
	else:
		eye.material_override.emission_energy_multiplier = 3.0
		laser.material_override.emission_energy_multiplier = 3.0
		# Normal thin laser
		var laser_mesh = laser.mesh as CylinderMesh
		if laser_mesh:
			laser_mesh.top_radius = 0.003
			laser_mesh.bottom_radius = 0.003
	
	var muzzle_world = muzzle_pos.global_position
	var target_pos = _get_target_position(current_target)
	var dist = muzzle_world.distance_to(target_pos)
	var dir = (target_pos - muzzle_world).normalized()
	var mid = muzzle_world + dir * (dist / 2)
	
	# Use global_position since laser is child of turret but we calculated world coords
	laser.global_position = mid
	laser.scale.y = dist
	laser.look_at(target_pos, Vector3.UP)
	laser.rotate_object_local(Vector3.RIGHT, PI/2)

# Public API for map loader to set targeting mode
func set_target_mode(mode: String):
	_apply_target_mode(mode)

# Called by map loader when using #config syntax
func configure(config_data: Dictionary):
	print("[SentryTurret] configure() called with: %s" % config_data)
	if config_data.has("target"):
		_apply_target_mode(str(config_data["target"]))
