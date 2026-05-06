extends Node3D

# Laser Turret - Targets and destroys colorballs one at a time
# Sharp laser burns through balls making them explode

signal ball_destroyed(ball: Node3D)
signal target_acquired(ball: Node3D)
signal target_lost

@export_category("Turret Settings")
@export var rotation_speed: float = 3.0  # Radians per second
@export var detection_range: float = 15.0
@export var fire_delay: float = 0.3  # Time to lock before firing
@export var burn_time: float = 0.4  # Time laser burns before ball explodes

@export_category("Laser Settings")
@export var laser_color: Color = Color(1.0, 0.1, 0.0, 1.0)  # Hot red
@export var laser_width: float = 0.02
@export var laser_glow_width: float = 0.08
@export var laser_intensity: float = 3.0

@export_category("Targeting")
@export var target_group: String = ""  # Leave empty to target all balls
@export var auto_target: bool = true
@export var prioritize_closest: bool = true

# Internal
var current_target: Node3D = null
var target_rigid_body: RigidBody3D = null
var lock_timer: float = 0.0
var burn_timer: float = 0.0
var is_firing: bool = false
var is_burning: bool = false

# Nodes
var turret_base: Node3D
var turret_head: Node3D
var laser_origin: Node3D
var laser_beam: MeshInstance3D
var laser_glow: MeshInstance3D
var laser_impact: GPUParticles3D
var muzzle_flash: GPUParticles3D

func _ready() -> void:
	_build_turret()
	_build_laser()
	_build_particles()

func _build_turret() -> void:
	# Base (rotating platform)
	turret_base = Node3D.new()
	turret_base.name = "TurretBase"
	add_child(turret_base)
	
	var base_mesh = MeshInstance3D.new()
	base_mesh.name = "BaseMesh"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.3
	cylinder.bottom_radius = 0.35
	cylinder.height = 0.15
	base_mesh.mesh = cylinder
	base_mesh.position.y = 0.075
	
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.2, 0.2, 0.25)
	base_mat.metallic = 0.8
	base_mat.roughness = 0.3
	base_mesh.material_override = base_mat
	turret_base.add_child(base_mesh)
	
	# Head (pivoting gun housing)
	turret_head = Node3D.new()
	turret_head.name = "TurretHead"
	turret_head.position.y = 0.15
	turret_base.add_child(turret_head)
	
	var head_mesh = MeshInstance3D.new()
	head_mesh.name = "HeadMesh"
	var box = BoxMesh.new()
	box.size = Vector3(0.15, 0.12, 0.25)
	head_mesh.mesh = box
	head_mesh.position.z = -0.05
	
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.15, 0.15, 0.2)
	head_mat.metallic = 0.9
	head_mat.roughness = 0.2
	head_mesh.material_override = head_mat
	turret_head.add_child(head_mesh)
	
	# Barrel
	var barrel = MeshInstance3D.new()
	barrel.name = "Barrel"
	var barrel_mesh = CylinderMesh.new()
	barrel_mesh.top_radius = 0.025
	barrel_mesh.bottom_radius = 0.03
	barrel_mesh.height = 0.3
	barrel.mesh = barrel_mesh
	barrel.rotation.x = PI / 2
	barrel.position.z = -0.3
	
	var barrel_mat = StandardMaterial3D.new()
	barrel_mat.albedo_color = Color(0.1, 0.1, 0.12)
	barrel_mat.metallic = 1.0
	barrel_mat.roughness = 0.1
	barrel.material_override = barrel_mat
	turret_head.add_child(barrel)
	
	# Laser origin point
	laser_origin = Node3D.new()
	laser_origin.name = "LaserOrigin"
	laser_origin.position.z = -0.45
	turret_head.add_child(laser_origin)
	
	# Lens glow
	var lens = MeshInstance3D.new()
	lens.name = "Lens"
	var lens_mesh = SphereMesh.new()
	lens_mesh.radius = 0.02
	lens_mesh.height = 0.04
	lens.mesh = lens_mesh
	lens.position.z = -0.45
	
	var lens_mat = StandardMaterial3D.new()
	lens_mat.albedo_color = laser_color
	lens_mat.emission_enabled = true
	lens_mat.emission = laser_color
	lens_mat.emission_energy_multiplier = 0.5
	lens.material_override = lens_mat
	turret_head.add_child(lens)

func _build_laser() -> void:
	# Main laser beam (thin, sharp)
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
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	laser_beam.material_override = beam_mat
	add_child(laser_beam)
	
	# Glow around laser (wider, softer)
	laser_glow = MeshInstance3D.new()
	laser_glow.name = "LaserGlow"
	laser_glow.visible = false
	
	var glow_mesh = CylinderMesh.new()
	glow_mesh.top_radius = laser_glow_width
	glow_mesh.bottom_radius = laser_glow_width
	glow_mesh.height = 1.0
	laser_glow.mesh = glow_mesh
	
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(laser_color.r, laser_color.g, laser_color.b, 0.3)
	glow_mat.emission_enabled = true
	glow_mat.emission = laser_color
	glow_mat.emission_energy_multiplier = laser_intensity * 0.5
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	laser_glow.material_override = glow_mat
	add_child(laser_glow)

func _build_particles() -> void:
	# Impact sparks
	laser_impact = GPUParticles3D.new()
	laser_impact.name = "ImpactParticles"
	laser_impact.emitting = false
	laser_impact.amount = 32
	laser_impact.lifetime = 0.3
	laser_impact.one_shot = false
	laser_impact.explosiveness = 0.0
	
	var impact_mat = ParticleProcessMaterial.new()
	impact_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	impact_mat.emission_sphere_radius = 0.05
	impact_mat.direction = Vector3(0, 1, 0)
	impact_mat.spread = 180.0
	impact_mat.initial_velocity_min = 1.0
	impact_mat.initial_velocity_max = 3.0
	impact_mat.gravity = Vector3(0, -5, 0)
	impact_mat.scale_min = 0.02
	impact_mat.scale_max = 0.05
	impact_mat.color = laser_color
	laser_impact.process_material = impact_mat
	
	var spark_mesh = SphereMesh.new()
	spark_mesh.radius = 0.02
	spark_mesh.height = 0.04
	laser_impact.draw_pass_1 = spark_mesh
	add_child(laser_impact)
	
	# Muzzle flash
	muzzle_flash = GPUParticles3D.new()
	muzzle_flash.name = "MuzzleFlash"
	muzzle_flash.emitting = false
	muzzle_flash.amount = 8
	muzzle_flash.lifetime = 0.1
	muzzle_flash.one_shot = true
	
	var muzzle_mat = ParticleProcessMaterial.new()
	muzzle_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	muzzle_mat.direction = Vector3(0, 0, -1)
	muzzle_mat.spread = 15.0
	muzzle_mat.initial_velocity_min = 2.0
	muzzle_mat.initial_velocity_max = 4.0
	muzzle_mat.scale_min = 0.03
	muzzle_mat.scale_max = 0.06
	muzzle_mat.color = Color.WHITE
	muzzle_flash.process_material = muzzle_mat
	
	var flash_mesh = SphereMesh.new()
	flash_mesh.radius = 0.03
	flash_mesh.height = 0.06
	muzzle_flash.draw_pass_1 = flash_mesh
	laser_origin.add_child(muzzle_flash)

func _process(delta: float) -> void:
	if auto_target and current_target == null:
		_find_new_target()
	
	if current_target != null:
		if not is_instance_valid(current_target):
			_lose_target()
			return
		
		_track_target(delta)
		_update_targeting_state(delta)
	else:
		_idle_behavior(delta)
	
	_update_laser_visuals()

func _find_new_target() -> Node3D:
	var balls = _get_all_balls()
	if balls.is_empty():
		return null
	
	var best_target: Node3D = null
	var best_distance: float = INF
	
	for ball in balls:
		if not is_instance_valid(ball):
			continue
		
		var distance = global_position.distance_to(ball.global_position)
		if distance > detection_range:
			continue
		
		if prioritize_closest:
			if distance < best_distance:
				best_distance = distance
				best_target = ball
		else:
			# Random selection within range
			if randf() < 0.3 or best_target == null:
				best_target = ball
	
	if best_target != null:
		_acquire_target(best_target)
	
	return best_target

func _get_all_balls() -> Array:
	var balls: Array = []
	
	# Find ColorBalls spawner nodes
	var colorballs_nodes = get_tree().get_nodes_in_group("colorballs")
	for cb_node in colorballs_nodes:
		if cb_node.has_method("get") and "balls" in cb_node:
			balls.append_array(cb_node.balls)
	
	# Also check for balls by structure (Node3D with RigidBody3D child)
	if balls.is_empty():
		for node in get_tree().get_nodes_in_group("targetable_ball"):
			balls.append(node)
	
	# Fallback: scan scene for ball-like objects
	if balls.is_empty():
		_scan_for_balls(get_tree().root, balls)
	
	return balls

func _scan_for_balls(node: Node, results: Array) -> void:
	if node.name.begins_with("Ball_") or node.name.begins_with("ColorBall"):
		var rb = node.get_node_or_null("RigidBody3D")
		if rb != null:
			results.append(node)
	
	for child in node.get_children():
		_scan_for_balls(child, results)

func _acquire_target(ball: Node3D) -> void:
	current_target = ball
	target_rigid_body = ball.get_node_or_null("RigidBody3D")
	lock_timer = 0.0
	burn_timer = 0.0
	is_firing = false
	is_burning = false
	emit_signal("target_acquired", ball)
	print("[Turret] Target acquired: %s" % ball.name)

func _lose_target() -> void:
	current_target = null
	target_rigid_body = null
	lock_timer = 0.0
	burn_timer = 0.0
	is_firing = false
	is_burning = false
	laser_beam.visible = false
	laser_glow.visible = false
	laser_impact.emitting = false
	emit_signal("target_lost")

func _track_target(delta: float) -> void:
	if current_target == null:
		return
	
	var target_pos = current_target.global_position
	if target_rigid_body:
		target_pos = target_rigid_body.global_position
	
	# Rotate base (yaw)
	var to_target = target_pos - turret_base.global_position
	var target_yaw = atan2(to_target.x, to_target.z)
	var current_yaw = turret_base.rotation.y
	turret_base.rotation.y = lerp_angle(current_yaw, target_yaw + PI, rotation_speed * delta)
	
	# Rotate head (pitch)
	var local_target = turret_head.global_transform.affine_inverse() * target_pos
	var target_pitch = atan2(-local_target.y, -local_target.z)
	target_pitch = clamp(target_pitch, -PI/3, PI/4)
	turret_head.rotation.x = lerp_angle(turret_head.rotation.x, target_pitch, rotation_speed * delta)

func _update_targeting_state(delta: float) -> void:
	if current_target == null:
		return
	
	var target_pos = current_target.global_position
	if target_rigid_body:
		target_pos = target_rigid_body.global_position
	
	# Check if we're aimed at target
	var aim_direction = -laser_origin.global_transform.basis.z
	var to_target = (target_pos - laser_origin.global_position).normalized()
	var aim_dot = aim_direction.dot(to_target)
	
	if aim_dot > 0.98:  # Good aim
		if not is_firing:
			lock_timer += delta
			if lock_timer >= fire_delay:
				_start_firing()
		else:
			burn_timer += delta
			is_burning = true
			
			# Heat up the ball
			_apply_burn_effect()
			
			if burn_timer >= burn_time:
				_destroy_target()
	else:
		# Lost aim, reset timers
		if is_firing:
			is_firing = false
			is_burning = false
			laser_beam.visible = false
			laser_glow.visible = false
			laser_impact.emitting = false
		lock_timer = max(0, lock_timer - delta * 2)

func _start_firing() -> void:
	is_firing = true
	burn_timer = 0.0
	muzzle_flash.emitting = true
	print("[Turret] Firing at %s" % current_target.name)

func _apply_burn_effect() -> void:
	if target_rigid_body == null:
		return
	
	var mesh = target_rigid_body.get_node_or_null("MeshInstance3D")
	if mesh and mesh.material_override:
		var mat = mesh.material_override as StandardMaterial3D
		if mat:
			# Intensify emission as it burns
			var burn_progress = burn_timer / burn_time
			mat.emission_energy_multiplier = 1.0 + burn_progress * 5.0
			
			# Shift color towards white/yellow
			var burn_color = mat.albedo_color.lerp(Color.WHITE, burn_progress * 0.5)
			mat.emission = burn_color

func _destroy_target() -> void:
	if current_target == null:
		return
	
	var target_pos = current_target.global_position
	if target_rigid_body:
		target_pos = target_rigid_body.global_position
	
	print("[Turret] Ball destroyed: %s" % current_target.name)
	
	# Create explosion
	_spawn_explosion(target_pos)
	
	# Emit signal before destroying
	emit_signal("ball_destroyed", current_target)
	
	# Remove from parent's ball array if possible
	var parent = current_target.get_parent()
	if parent and "balls" in parent:
		var idx = parent.balls.find(current_target)
		if idx >= 0:
			parent.balls.remove_at(idx)
	
	# Destroy the ball
	current_target.queue_free()
	
	# Reset targeting
	_lose_target()

func _spawn_explosion(pos: Vector3) -> void:
	var explosion = GPUParticles3D.new()
	explosion.name = "Explosion"
	explosion.emitting = true
	explosion.amount = 64
	explosion.lifetime = 0.5
	explosion.one_shot = true
	explosion.explosiveness = 1.0
	explosion.global_position = pos
	
	var exp_mat = ParticleProcessMaterial.new()
	exp_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	exp_mat.emission_sphere_radius = 0.1
	exp_mat.direction = Vector3(0, 0, 0)
	exp_mat.spread = 180.0
	exp_mat.initial_velocity_min = 3.0
	exp_mat.initial_velocity_max = 8.0
	exp_mat.gravity = Vector3(0, -3, 0)
	exp_mat.scale_min = 0.03
	exp_mat.scale_max = 0.08
	exp_mat.color = Color(1.0, 0.6, 0.1)
	
	# Color gradient: orange -> red -> dark
	var color_ramp = Gradient.new()
	color_ramp.set_color(0, Color(1.0, 0.8, 0.2))
	color_ramp.set_color(1, Color(0.8, 0.2, 0.0, 0.0))
	var color_texture = GradientTexture1D.new()
	color_texture.gradient = color_ramp
	exp_mat.color_ramp = color_texture
	
	explosion.process_material = exp_mat
	
	var spark_mesh = SphereMesh.new()
	spark_mesh.radius = 0.04
	spark_mesh.height = 0.08
	explosion.draw_pass_1 = spark_mesh
	
	get_tree().root.add_child(explosion)
	
	# Auto-cleanup
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(func(): explosion.queue_free())

func _update_laser_visuals() -> void:
	if not is_firing or current_target == null:
		laser_beam.visible = false
		laser_glow.visible = false
		laser_impact.emitting = false
		return
	
	var target_pos = current_target.global_position
	if target_rigid_body:
		target_pos = target_rigid_body.global_position
	
	var origin_pos = laser_origin.global_position
	var distance = origin_pos.distance_to(target_pos)
	var direction = (target_pos - origin_pos).normalized()
	var midpoint = origin_pos + direction * (distance / 2)
	
	# Position and scale laser
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
	
	# Position impact particles
	laser_impact.global_position = target_pos
	laser_impact.emitting = true
	
	# Flicker effect
	var flicker = 0.9 + randf() * 0.2
	laser_beam.material_override.emission_energy_multiplier = laser_intensity * 2 * flicker
	laser_glow.material_override.emission_energy_multiplier = laser_intensity * 0.5 * flicker

func _idle_behavior(delta: float) -> void:
	# Slow idle rotation when no target
	turret_base.rotation.y += delta * 0.3
	turret_head.rotation.x = lerp_angle(turret_head.rotation.x, 0.0, delta)

# Public API
func set_target(ball: Node3D) -> void:
	if ball != null:
		_acquire_target(ball)
	else:
		_lose_target()

func force_fire() -> void:
	if current_target != null and not is_firing:
		_start_firing()

func get_current_target() -> Node3D:
	return current_target

func is_targeting() -> bool:
	return current_target != null

func is_actively_firing() -> bool:
	return is_firing

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
