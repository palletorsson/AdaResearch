extends Node3D

# Laser Turret - Tracks and destroys balls using vector math
# Never stops - remembers where targets were, resets if idle too long

signal ball_destroyed(ball: Node3D, position: Vector3)
signal target_acquired(ball: Node3D)
signal target_lost

@export_category("Turret Settings")
@export var rotation_speed: float = 8.0
@export var detection_range: float = 30.0
@export var fire_delay: float = 0.1
@export var damage_per_second: float = 80.0

@export_category("Laser Appearance")
@export var laser_color: Color = Color(1.0, 0.05, 0.0)
@export var laser_width: float = 0.012
@export var laser_glow_width: float = 0.05
@export var laser_intensity: float = 5.0

@export_category("Targeting")
@export var auto_target: bool = true
@export var target_closest: bool = true
@export var idle_reset_time: float = 10.0

# State
var current_target: Node3D = null
var target_rb: RigidBody3D = null
var lock_timer: float = 0.0
var is_firing: bool = false

# Smart hunting
var last_target_direction: Vector3 = Vector3.FORWARD
var last_target_position: Vector3 = Vector3.ZERO
var idle_time: float = 0.0
var total_kills: int = 0

# Components
var turret_base: Node3D
var turret_head: Node3D
var barrel: Node3D
var laser_origin: Node3D
var laser_beam: MeshInstance3D
var laser_glow: MeshInstance3D
var impact_particles: GPUParticles3D
var eye_glow: MeshInstance3D

func _ready() -> void:
	_build_turret()
	_build_laser()
	_build_particles()
	_build_lighting()

func _build_turret() -> void:
	turret_base = Node3D.new()
	turret_base.name = "TurretBase"
	add_child(turret_base)
	
	var base_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.28
	cyl.height = 0.08
	base_mesh.mesh = cyl
	base_mesh.position.y = 0.04
	
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.6, 0.62, 0.65)
	base_mat.metallic = 0.7
	base_mat.roughness = 0.4
	base_mesh.material_override = base_mat
	turret_base.add_child(base_mesh)
	
	var column = MeshInstance3D.new()
	var col_mesh = CylinderMesh.new()
	col_mesh.top_radius = 0.05
	col_mesh.bottom_radius = 0.07
	col_mesh.height = 0.2
	column.mesh = col_mesh
	column.position.y = 0.18
	column.material_override = base_mat
	turret_base.add_child(column)
	
	turret_head = Node3D.new()
	turret_head.name = "TurretHead"
	turret_head.position.y = 0.3
	turret_base.add_child(turret_head)
	
	var head_mesh = MeshInstance3D.new()
	var head_box = BoxMesh.new()
	head_box.size = Vector3(0.14, 0.1, 0.18)
	head_mesh.mesh = head_box
	head_mesh.position.z = -0.03
	
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.5, 0.52, 0.55)
	head_mat.metallic = 0.7
	head_mat.roughness = 0.35
	head_mesh.material_override = head_mat
	turret_head.add_child(head_mesh)
	
	barrel = Node3D.new()
	barrel.name = "Barrel"
	turret_head.add_child(barrel)
	
	var barrel_mesh = MeshInstance3D.new()
	var barrel_cyl = CylinderMesh.new()
	barrel_cyl.top_radius = 0.02
	barrel_cyl.bottom_radius = 0.025
	barrel_cyl.height = 0.22
	barrel_mesh.mesh = barrel_cyl
	barrel_mesh.rotation.x = PI / 2
	barrel_mesh.position.z = -0.2
	
	var barrel_mat = StandardMaterial3D.new()
	barrel_mat.albedo_color = Color(0.7, 0.72, 0.75)
	barrel_mat.metallic = 0.8
	barrel_mat.roughness = 0.2
	barrel_mesh.material_override = barrel_mat
	barrel.add_child(barrel_mesh)
	
	laser_origin = Node3D.new()
	laser_origin.name = "LaserOrigin"
	laser_origin.position.z = -0.32
	barrel.add_child(laser_origin)
	
	eye_glow = MeshInstance3D.new()
	eye_glow.name = "EyeGlow"
	var eye_mesh = SphereMesh.new()
	eye_mesh.radius = 0.018
	eye_mesh.height = 0.036
	eye_glow.mesh = eye_mesh
	eye_glow.position = Vector3(0, 0.02, 0.06)
	
	var eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = laser_color
	eye_mat.emission_enabled = true
	eye_mat.emission = laser_color
	eye_mat.emission_energy_multiplier = 2.0
	eye_glow.material_override = eye_mat
	turret_head.add_child(eye_glow)

func _build_laser() -> void:
	laser_beam = MeshInstance3D.new()
	laser_beam.name = "LaserBeam"
	laser_beam.visible = false
	
	var beam_mesh = CylinderMesh.new()
	beam_mesh.top_radius = laser_width
	beam_mesh.bottom_radius = laser_width
	beam_mesh.height = 1.0
	laser_beam.mesh = beam_mesh
	
	var beam_mat = StandardMaterial3D.new()
	beam_mat.albedo_color = Color.WHITE
	beam_mat.emission_enabled = true
	beam_mat.emission = laser_color
	beam_mat.emission_energy_multiplier = laser_intensity * 2
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	laser_beam.material_override = beam_mat
	add_child(laser_beam)
	
	laser_glow = MeshInstance3D.new()
	laser_glow.name = "LaserGlow"
	laser_glow.visible = false
	
	var glow_mesh = CylinderMesh.new()
	glow_mesh.top_radius = laser_glow_width
	glow_mesh.bottom_radius = laser_glow_width
	glow_mesh.height = 1.0
	laser_glow.mesh = glow_mesh
	
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(laser_color.r, laser_color.g, laser_color.b, 0.25)
	glow_mat.emission_enabled = true
	glow_mat.emission = laser_color
	glow_mat.emission_energy_multiplier = laser_intensity * 0.3
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	laser_glow.material_override = glow_mat
	add_child(laser_glow)

func _build_particles() -> void:
	impact_particles = GPUParticles3D.new()
	impact_particles.name = "ImpactSparks"
	impact_particles.emitting = false
	impact_particles.amount = 24
	impact_particles.lifetime = 0.25
	impact_particles.one_shot = false
	impact_particles.explosiveness = 0.0
	
	var part_mat = ParticleProcessMaterial.new()
	part_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	part_mat.emission_sphere_radius = 0.03
	part_mat.direction = Vector3(0, 1, 0)
	part_mat.spread = 180.0
	part_mat.initial_velocity_min = 1.5
	part_mat.initial_velocity_max = 4.0
	part_mat.gravity = Vector3(0, -8, 0)
	part_mat.scale_min = 0.015
	part_mat.scale_max = 0.03
	part_mat.color = laser_color
	impact_particles.process_material = part_mat
	
	var spark_mesh = SphereMesh.new()
	spark_mesh.radius = 0.015
	spark_mesh.height = 0.03
	impact_particles.draw_pass_1 = spark_mesh
	add_child(impact_particles)

func _build_lighting() -> void:
	var spotlight = SpotLight3D.new()
	spotlight.name = "TurretSpotlight"
	spotlight.light_color = Color(0.95, 0.95, 1.0)
	spotlight.light_energy = 2.0
	spotlight.spot_range = 5.0
	spotlight.spot_angle = 35.0
	spotlight.spot_angle_attenuation = 0.8
	spotlight.position = Vector3(0, 2.5, 0.5)
	spotlight.rotation_degrees = Vector3(-70, 0, 0)
	spotlight.shadow_enabled = true
	add_child(spotlight)
	
	var fill_light = OmniLight3D.new()
	fill_light.name = "FillLight"
	fill_light.light_color = Color(0.7, 0.8, 1.0)
	fill_light.light_energy = 0.4
	fill_light.omni_range = 3.0
	fill_light.omni_attenuation = 1.5
	fill_light.position = Vector3(0, 1.0, 2.0)
	add_child(fill_light)

func _process(delta: float) -> void:
	if auto_target and current_target == null:
		idle_time += delta
		
		# Reset if idle too long
		if idle_time > idle_reset_time:
			_reset_hunt()
		
		_find_target()
	
	if current_target != null:
		idle_time = 0.0  # Reset idle counter
		
		if not is_instance_valid(current_target):
			_lose_target()
			return
		
		if current_target.has_meta("health") and current_target.get_meta("health") <= 0:
			_destroy_ball()
			return
		
		_track_target(delta)
		_update_targeting(delta)
	else:
		_smart_scan(delta)
	
	_update_laser()

func _reset_hunt() -> void:
	"""Reset turret state after being idle too long"""
	idle_time = 0.0
	lock_timer = 0.0
	is_firing = false
	# Look towards last known position or reset to forward
	if last_target_position != Vector3.ZERO:
		var dir = (last_target_position - global_position).normalized()
		last_target_direction = dir

func _find_target() -> void:
	var all_balls = _get_all_balls()
	if all_balls.is_empty():
		return
	
	var best: Node3D = null
	var best_score: float = -INF
	
	for ball in all_balls:
		if not is_instance_valid(ball):
			continue
		if not ball.visible:
			continue
		
		var ball_pos = ball.global_position
		var to_ball = ball_pos - global_position
		var dist = to_ball.length()
		
		if dist > detection_range:
			continue
		
		# Score: prefer closer balls, and balls in last target direction
		var dist_score = 1.0 - (dist / detection_range)
		var dir_score = 0.0
		if last_target_direction != Vector3.ZERO:
			dir_score = to_ball.normalized().dot(last_target_direction) * 0.3
		
		var score = dist_score + dir_score
		
		if score > best_score:
			best_score = score
			best = ball
	
	if best != null:
		_acquire_target(best)

func _get_all_balls() -> Array:
	var balls: Array = []
	
	for dropper in get_tree().get_nodes_in_group("ball_dropper"):
		if dropper.has_method("get_active_balls"):
			balls.append_array(dropper.get_active_balls())
		elif "balls" in dropper:
			for ball in dropper.balls:
				if is_instance_valid(ball):
					balls.append(ball)
		elif "active_balls" in dropper:
			for ball in dropper.active_balls:
				if is_instance_valid(ball):
					balls.append(ball)
	
	for spawner in get_tree().get_nodes_in_group("colorballs"):
		if "balls" in spawner:
			for ball in spawner.balls:
				if is_instance_valid(ball):
					balls.append(ball)
	
	if balls.is_empty():
		_scan_for_balls(get_tree().root, balls)
	
	return balls

func _scan_for_balls(node: Node, results: Array) -> void:
	var node_name = node.name.to_lower()
	if "ball" in node_name and "dropper" not in node_name and "turret" not in node_name:
		if node is Node3D and node.visible:
			results.append(node)
	
	for child in node.get_children():
		_scan_for_balls(child, results)

func _acquire_target(ball: Node3D) -> void:
	current_target = ball
	target_rb = ball.get_node_or_null("RigidBody3D")
	lock_timer = 0.0
	is_firing = false
	idle_time = 0.0
	
	# Remember this direction for future hunting
	var to_target = ball.global_position - global_position
	if to_target.length() > 0.1:
		last_target_direction = to_target.normalized()
		last_target_position = ball.global_position
	
	emit_signal("target_acquired", ball)

func _lose_target() -> void:
	current_target = null
	target_rb = null
	lock_timer = 0.0
	is_firing = false
	laser_beam.visible = false
	laser_glow.visible = false
	impact_particles.emitting = false
	emit_signal("target_lost")

func _track_target(delta: float) -> void:
	if current_target == null:
		return
	
	var target_pos = _get_target_position()
	var to_target = target_pos - turret_base.global_position
	
	# Update last known direction
	if to_target.length() > 0.1:
		last_target_direction = to_target.normalized()
		last_target_position = target_pos
	
	var target_yaw = atan2(to_target.x, to_target.z)
	turret_base.rotation.y = lerp_angle(turret_base.rotation.y, target_yaw + PI, rotation_speed * delta)
	
	var local_target = turret_head.global_transform.affine_inverse() * target_pos
	var target_pitch = atan2(-local_target.y, -local_target.z)
	target_pitch = clamp(target_pitch, -PI/3, PI/4)
	turret_head.rotation.x = lerp_angle(turret_head.rotation.x, target_pitch, rotation_speed * delta)

func _get_target_position() -> Vector3:
	if target_rb:
		return target_rb.global_position
	return current_target.global_position

func _update_targeting(delta: float) -> void:
	if current_target == null:
		return
	
	var target_pos = _get_target_position()
	var aim_dir = -laser_origin.global_transform.basis.z
	var to_target = (target_pos - laser_origin.global_position).normalized()
	var aim_quality = aim_dir.dot(to_target)
	
	if aim_quality > 0.97:
		if not is_firing:
			lock_timer += delta
			if lock_timer >= fire_delay:
				is_firing = true
		else:
			_apply_damage(delta)
			_apply_burn_effect()
	else:
		if is_firing:
			is_firing = false
			laser_beam.visible = false
			laser_glow.visible = false
			impact_particles.emitting = false
		lock_timer = max(0, lock_timer - delta * 2)

func _apply_damage(delta: float) -> void:
	if current_target == null:
		return
	
	if not current_target.has_meta("health"):
		current_target.set_meta("health", 100.0)
		current_target.set_meta("max_health", 100.0)
	
	var health = current_target.get_meta("health")
	health -= damage_per_second * delta
	current_target.set_meta("health", health)

func _apply_burn_effect() -> void:
	if current_target == null:
		return
	
	var max_health = current_target.get_meta("max_health") if current_target.has_meta("max_health") else 100.0
	var health = current_target.get_meta("health") if current_target.has_meta("health") else max_health
	var progress = 1.0 - (health / max_health)
	
	if target_rb == null:
		return
	
	var mesh = target_rb.get_node_or_null("MeshInstance3D")
	if mesh and mesh.material_override:
		var mat = mesh.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 0.8 + progress * 6.0
			var burn_color = mat.albedo_color.lerp(Color.WHITE, progress * 0.6)
			mat.emission = burn_color

func _destroy_ball() -> void:
	if current_target == null:
		return
	
	var pos = _get_target_position()
	var ball_color = current_target.get_meta("ball_color", Color(1, 0.5, 0.2))
	
	_spawn_explosion(pos, ball_color)
	
	emit_signal("ball_destroyed", current_target, pos)
	total_kills += 1
	
	for dropper in get_tree().get_nodes_in_group("ball_dropper"):
		if dropper.has_method("remove_ball"):
			dropper.remove_ball(current_target)
	
	if is_instance_valid(current_target):
		current_target.queue_free()
	
	current_target = null
	target_rb = null
	lock_timer = 0.0
	is_firing = false
	laser_beam.visible = false
	laser_glow.visible = false
	impact_particles.emitting = false

func _spawn_explosion(pos: Vector3, color: Color) -> void:
	var explosion = GPUParticles3D.new()
	explosion.name = "Explosion"
	explosion.amount = 48
	explosion.lifetime = 0.4
	explosion.one_shot = true
	explosion.explosiveness = 1.0
	
	var exp_mat = ParticleProcessMaterial.new()
	exp_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	exp_mat.emission_sphere_radius = 0.08
	exp_mat.direction = Vector3(0, 0, 0)
	exp_mat.spread = 180.0
	exp_mat.initial_velocity_min = 2.5
	exp_mat.initial_velocity_max = 6.0
	exp_mat.gravity = Vector3(0, -4, 0)
	exp_mat.scale_min = 0.02
	exp_mat.scale_max = 0.06
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 0.9, 0.5))
	gradient.set_color(1, Color(color.r, color.g * 0.5, color.b * 0.2, 0.0))
	var texture = GradientTexture1D.new()
	texture.gradient = gradient
	exp_mat.color_ramp = texture
	
	explosion.process_material = exp_mat
	
	var spark_mesh = SphereMesh.new()
	spark_mesh.radius = 0.03
	spark_mesh.height = 0.06
	explosion.draw_pass_1 = spark_mesh
	
	get_tree().root.add_child(explosion)
	explosion.global_position = pos
	explosion.emitting = true
	
	get_tree().create_timer(1.0).timeout.connect(func(): 
		if is_instance_valid(explosion):
			explosion.queue_free()
	)

func _update_laser() -> void:
	if not is_firing or current_target == null:
		laser_beam.visible = false
		laser_glow.visible = false
		impact_particles.emitting = false
		return
	
	var target_pos = _get_target_position()
	var origin_pos = laser_origin.global_position
	var distance = origin_pos.distance_to(target_pos)
	var direction = (target_pos - origin_pos).normalized()
	var midpoint = origin_pos + direction * (distance / 2)
	
	laser_beam.global_position = midpoint
	laser_beam.scale.y = distance
	laser_beam.look_at(target_pos, Vector3.UP)
	laser_beam.rotate_object_local(Vector3.RIGHT, PI / 2)
	laser_beam.visible = true
	
	laser_glow.global_position = midpoint
	laser_glow.scale.y = distance
	laser_glow.look_at(target_pos, Vector3.UP)
	laser_glow.rotate_object_local(Vector3.RIGHT, PI / 2)
	laser_glow.visible = true
	
	impact_particles.global_position = target_pos
	impact_particles.emitting = true
	
	var flicker = 0.85 + randf() * 0.3
	laser_beam.material_override.emission_energy_multiplier = laser_intensity * 2 * flicker
	laser_glow.material_override.emission_energy_multiplier = laser_intensity * 0.3 * flicker

func _smart_scan(delta: float) -> void:
	"""Scan towards last known target direction"""
	var target_yaw: float
	
	if last_target_direction != Vector3.ZERO:
		# Look towards last target direction with some sweep
		var sweep = sin(Time.get_ticks_msec() * 0.002) * 0.5
		target_yaw = atan2(last_target_direction.x, last_target_direction.z) + sweep
	else:
		# Default sweep
		target_yaw = turret_base.rotation.y + delta * 2.0
	
	turret_base.rotation.y = lerp_angle(turret_base.rotation.y, target_yaw, rotation_speed * 0.5 * delta)
	turret_head.rotation.x = lerp_angle(turret_head.rotation.x, 0.1, delta * 2)

# Public API
func set_target(ball: Node3D) -> void:
	if ball:
		_acquire_target(ball)
	else:
		_lose_target()

func is_targeting() -> bool:
	return current_target != null

func is_actively_firing() -> bool:
	return is_firing

func get_current_target() -> Node3D:
	return current_target

func get_kill_count() -> int:
	return total_kills

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

