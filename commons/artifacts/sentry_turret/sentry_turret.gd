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

func _ready():
	_build_turret()
	# Defer config parsing to allow metadata to be set by map loader
	call_deferred("_parse_config")
	add_to_group("turrets")

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

func _find_target():
	var best_target: Node3D = null
	var best_dist: float = INF
	
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
		for ball in balls:
			if not is_instance_valid(ball):
				continue
			var dist = global_position.distance_to(ball.global_position)
			if dist < detection_range and dist < best_dist:
				best_dist = dist
				best_target = ball
	
	if best_target != current_target:
		if best_target:
			current_target = best_target
			emit_signal("target_acquired", current_target)
		elif current_target:
			current_target = null
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
	for dropper in get_tree().get_nodes_in_group("ball_dropper"):
		if "active_balls" in dropper:
			balls.append_array(dropper.active_balls)
		elif "balls" in dropper:
			for b in dropper.balls:
				if is_instance_valid(b):
					balls.append(b)
	
	# Check colorballs
	for spawner in get_tree().get_nodes_in_group("colorballs"):
		if "balls" in spawner:
			balls.append_array(spawner.balls)
	
	# Scan for ball nodes
	if balls.is_empty():
		for node in get_tree().get_nodes_in_group("balls"):
			balls.append(node)
	
	return balls

func _track_target(delta: float):
	if not current_target or not is_instance_valid(current_target):
		# Idle scan
		head.rotation.y += delta * 0.8
		barrel.rotation.x = lerp_angle(barrel.rotation.x, 0.0, delta * 2)
		return
	
	var target_pos = current_target.global_position
	var head_pos = head.global_position
	var to_target = target_pos - head_pos
	
	# Yaw
	var target_yaw = atan2(to_target.x, to_target.z)
	head.rotation.y = lerp_angle(head.rotation.y, target_yaw, rotation_speed * delta)
	
	# Pitch
	var horiz_dist = Vector2(to_target.x, to_target.z).length()
	var target_pitch = -atan2(to_target.y, horiz_dist)
	target_pitch = clamp(target_pitch, -PI/4, PI/4)
	barrel.rotation.x = lerp_angle(barrel.rotation.x, target_pitch, rotation_speed * delta)

func _update_shooting(delta: float):
	fire_cooldown -= delta
	reload_cooldown -= delta
	
	if not current_target or not is_instance_valid(current_target):
		return
	
	# Check if reloading
	if reload_cooldown > 0:
		return
	
	# Check aim
	var muzzle_world = muzzle_pos.global_position
	var aim_dir = -barrel.global_transform.basis.z
	var to_target = (current_target.global_position - muzzle_world).normalized()
	var aim_quality = aim_dir.dot(to_target)
	
	if aim_quality > 0.95 and fire_cooldown <= 0:
		_fire()
		fire_cooldown = 1.0 / fire_rate
		shots_in_burst += 1
		
		# Check if need to reload
		if shots_in_burst >= burst_size:
			reload_cooldown = reload_time
			shots_in_burst = 0

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
	var sphere = SphereMesh.new()
	sphere.radius = 0.03
	sphere.height = 0.06
	mesh.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.8, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.2)
	mat.emission_energy_multiplier = 3.0
	mesh.material_override = mat
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
					var dist = b["pos"].distance_to(ball.global_position)
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
	
	# Hit effect
	var flash = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.08
	flash.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.5, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.1)
	mat.emission_energy_multiplier = 4.0
	flash.material_override = mat
	flash.position = pos
	get_tree().root.add_child(flash)
	
	get_tree().create_timer(0.1).timeout.connect(func():
		if is_instance_valid(flash):
			flash.queue_free()
	)

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
	
	# Brighter/different color when targeting player
	if is_targeting_player:
		eye.material_override.emission_energy_multiplier = 5.0
		laser.material_override.emission_energy_multiplier = 5.0
	else:
		eye.material_override.emission_energy_multiplier = 3.0
		laser.material_override.emission_energy_multiplier = 3.0
	
	var muzzle_world = muzzle_pos.global_position
	var target_pos = current_target.global_position
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
