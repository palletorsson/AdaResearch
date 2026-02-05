extends Node3D

# Laser Turret - Sharp laser burns and explodes balls one at a time
# Standalone unit - no floor needed
# Demonstrates: Vector subtraction (direction), magnitude (range), normalization (aim)

signal ball_destroyed(ball: Node3D, position: Vector3)
signal target_acquired(ball: Node3D)
signal target_lost

@export_category("Turret Settings")
@export var rotation_speed: float = 4.0
@export var detection_range: float = 10.0
@export var fire_delay: float = 0.25  # Lock time before firing
@export var burn_time: float = 0.35   # Burn time before explosion

@export_category("Laser Appearance")
@export var laser_color: Color = Color(1.0, 0.05, 0.0)
@export var laser_width: float = 0.012
@export var laser_glow_width: float = 0.05
@export var laser_intensity: float = 5.0

@export_category("Targeting")
@export var auto_target: bool = true
@export var target_closest: bool = true

# State
var current_target: Node3D = null
var target_rb: RigidBody3D = null
var lock_timer: float = 0.0
var burn_timer: float = 0.0
var is_firing: bool = false

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

func _build_turret() -> void:
	# Base (yaw rotation)
	turret_base = Node3D.new()
	turret_base.name = "TurretBase"
	add_child(turret_base)
	
	# Base mesh - tripod style
	var base_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.28
	cyl.height = 0.08
	base_mesh.mesh = cyl
	base_mesh.position.y = 0.04
	
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.15, 0.15, 0.18)
	base_mat.metallic = 0.7
	base_mat.roughness = 0.3
	base_mesh.material_override = base_mat
	turret_base.add_child(base_mesh)
	
	# Support column
	var column = MeshInstance3D.new()
	var col_mesh = CylinderMesh.new()
	col_mesh.top_radius = 0.05
	col_mesh.bottom_radius = 0.07
	col_mesh.height = 0.2
	column.mesh = col_mesh
	column.position.y = 0.18
	column.material_override = base_mat
	turret_base.add_child(column)
	
	# Head (pitch rotation)
	turret_head = Node3D.new()
	turret_head.name = "TurretHead"
	turret_head.position.y = 0.3
	turret_base.add_child(turret_head)
	
	# Head housing
	var head_mesh = MeshInstance3D.new()
	var head_box = BoxMesh.new()
	head_box.size = Vector3(0.14, 0.1, 0.18)
	head_mesh.mesh = head_box
	head_mesh.position.z = -0.03
	
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.12, 0.12, 0.15)
	head_mat.metallic = 0.8
	head_mat.roughness = 0.25
	head_mesh.material_override = head_mat
	turret_head.add_child(head_mesh)
	
	# Barrel
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
	barrel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	barrel_mat.metallic = 0.9
	barrel_mat.roughness = 0.15
	barrel_mesh.material_override = barrel_mat
	barrel.add_child(barrel_mesh)
	
	# Laser origin
	laser_origin = Node3D.new()
	laser_origin.name = "LaserOrigin"
	laser_origin.position.z = -0.32
	barrel.add_child(laser_origin)
	
	# Eye/sensor glow
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
	# Sharp laser core
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
	
	# Soft glow around laser
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
	# Impact sparks
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

func _process(delta: float) -> void:
	if auto_target and current_target == null:
		_find_target()
	
	if current_target != null:
		if not is_instance_valid(current_target):
			_lose_target()
			return
		
		_track_target(delta)
		_update_targeting(delta)
	else:
		_idle_scan(delta)
	
	_update_laser()

func _find_target() -> void:
	var all_balls = _get_all_balls()
	if all_balls.is_empty():
		return
	
	var best: Node3D = null
	var best_dist: float = INF
	
	for ball in all_balls:
		if not is_instance_valid(ball):
			continue
		
		var dist = global_position.distance_to(ball.global_position)
		if dist > detection_range:
			continue
		
		if target_closest:
			if dist < best_dist:
				best_dist = dist
				best = ball
		else:
			best = ball
			break
	
	if best != null:
		_acquire_target(best)

func _get_all_balls() -> Array:
	var balls: Array = []
	
	# Check ball droppers
	for dropper in get_tree().get_nodes_in_group("ball_dropper"):
		if "balls" in dropper:
			for ball in dropper.balls:
				if is_instance_valid(ball):
					balls.append(ball)
	
	# Check colorballs spawners
	for spawner in get_tree().get_nodes_in_group("colorballs"):
		if "balls" in spawner:
			for ball in spawner.balls:
				if is_instance_valid(ball):
					balls.append(ball)
	
	# Scan for balls by name pattern
	if balls.is_empty():
		_scan_for_balls(get_tree().root, balls)
	
	return balls

func _scan_for_balls(node: Node, results: Array) -> void:
	var node_name = node.name.to_lower()
	if "ball" in node_name and "dropper" not in node_name and "turret" not in node_name:
		var rb = node.get_node_or_null("RigidBody3D")
		if rb != null:
			results.append(node)
	
	for child in node.get_children():
		_scan_for_balls(child, results)

func _acquire_target(ball: Node3D) -> void:
	current_target = ball
	target_rb = ball.get_node_or_null("RigidBody3D")
	lock_timer = 0.0
	burn_timer = 0.0
	is_firing = false
	emit_signal("target_acquired", ball)

func _lose_target() -> void:
	current_target = null
	target_rb = null
	lock_timer = 0.0
	burn_timer = 0.0
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
	
	# Yaw (base rotation)
	var target_yaw = atan2(to_target.x, to_target.z)
	turret_base.rotation.y = lerp_angle(turret_base.rotation.y, target_yaw + PI, rotation_speed * delta)
	
	# Pitch (head rotation)
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
	
	if aim_quality > 0.97:  # Good lock
		if not is_firing:
			lock_timer += delta
			if lock_timer >= fire_delay:
				is_firing = true
				burn_timer = 0.0
		else:
			burn_timer += delta
			_apply_burn_effect()
			
			if burn_timer >= burn_time:
				_destroy_ball()
	else:
		# Lost lock
		if is_firing:
			is_firing = false
			laser_beam.visible = false
			laser_glow.visible = false
			impact_particles.emitting = false
		lock_timer = max(0, lock_timer - delta * 2)

func _apply_burn_effect() -> void:
	if target_rb == null:
		return
	
	var mesh = target_rb.get_node_or_null("MeshInstance3D")
	if mesh and mesh.material_override:
		var mat = mesh.material_override as StandardMaterial3D
		if mat:
			var progress = burn_timer / burn_time
			mat.emission_energy_multiplier = 0.8 + progress * 6.0
			var burn_color = mat.albedo_color.lerp(Color.WHITE, progress * 0.6)
			mat.emission = burn_color

func _destroy_ball() -> void:
	if current_target == null:
		return
	
	var pos = _get_target_position()
	var ball_color = current_target.get_meta("ball_color", Color(1, 0.5, 0.2))
	
	# Explosion effect
	_spawn_explosion(pos, ball_color)
	
	emit_signal("ball_destroyed", current_target, pos)
	
	# Remove from dropper tracking
	for dropper in get_tree().get_nodes_in_group("ball_dropper"):
		if dropper.has_method("remove_ball"):
			dropper.remove_ball(current_target)
	
	# Destroy
	current_target.queue_free()
	_lose_target()

func _spawn_explosion(pos: Vector3, color: Color) -> void:
	var explosion = GPUParticles3D.new()
	explosion.name = "Explosion"
	explosion.emitting = true
	explosion.amount = 48
	explosion.lifetime = 0.4
	explosion.one_shot = true
	explosion.explosiveness = 1.0
	explosion.global_position = pos
	
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
	
	# Color gradient
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
	
	# Cleanup
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
	
	# Position beams
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
	
	# Impact point
	impact_particles.global_position = target_pos
	impact_particles.emitting = true
	
	# Flicker
	var flicker = 0.85 + randf() * 0.3
	laser_beam.material_override.emission_energy_multiplier = laser_intensity * 2 * flicker
	laser_glow.material_override.emission_energy_multiplier = laser_intensity * 0.3 * flicker

func _idle_scan(delta: float) -> void:
	# Slow scanning rotation when idle
	turret_base.rotation.y += delta * 0.5
	turret_head.rotation.x = lerp_angle(turret_head.rotation.x, 0.0, delta * 2)

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
