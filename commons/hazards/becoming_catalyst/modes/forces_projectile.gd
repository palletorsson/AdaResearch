# ForcesProjectile.gd
# Warm amber mortar with gentle parabolic arc.
# On hit: creates a calming field that slows, tames, focuses.
# Force as care — not destruction but harnessing.
extends CatalystProjectile

const CALM_RADIUS := 2.0
const CALM_DURATION := 3.0
const CALM_DAMP_ADD := 3.0

func _build_visual() -> void:
	_mesh_instance = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12 * projectile_scale
	sphere.height = 0.24 * projectile_scale
	_mesh_instance.mesh = sphere

	var mat := _make_material(color_primary, emission_energy)
	mat.roughness = 0.6
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)

	# Warm trail
	_particles = GPUParticles3D.new()
	_particles.amount = 12
	_particles.lifetime = 0.8
	_particles.emitting = true

	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, -0.5, 0)
	pmat.initial_velocity_min = 0.3
	pmat.initial_velocity_max = 0.8
	pmat.gravity = Vector3(0, -1.0, 0)
	pmat.scale_min = 0.02
	pmat.scale_max = 0.05

	var grad := Gradient.new()
	grad.add_point(0.0, Color(1, 0.8, 0.4, 0.7))
	grad.add_point(1.0, Color(0.9, 0.5, 0.1, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	pmat.color_ramp = tex

	_particles.process_material = pmat
	_particles.draw_pass_1 = QuadMesh.new()
	add_child(_particles)

func _apply_initial_velocity() -> void:
	# Gentle parabolic arc
	gravity_scale = 0.6
	linear_velocity = direction.normalized() * speed

func _update_trajectory(_delta: float) -> void:
	# Gentle pulsing glow
	if _mesh_instance and not has_hit:
		var pulse := 0.8 + sin(time_alive * 4.0) * 0.2
		_mesh_instance.scale = Vector3.ONE * pulse

func _on_hit(body: Node3D) -> void:
	projectile_hit.emit(body, global_position)
	_create_calming_field()

func _create_calming_field() -> void:
	# Visual: expanding ring of warm light
	var ring_particles := GPUParticles3D.new()
	ring_particles.amount = 40
	ring_particles.lifetime = 1.5
	ring_particles.one_shot = true
	ring_particles.emitting = true

	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pmat.emission_ring_radius = 0.1
	pmat.emission_ring_inner_radius = 0.0
	pmat.emission_ring_height = 0.05
	pmat.emission_ring_axis = Vector3(0, 1, 0)
	pmat.direction = Vector3(1, 0, 0)
	pmat.spread = 0.0
	pmat.initial_velocity_min = 1.5
	pmat.initial_velocity_max = 2.5
	pmat.gravity = Vector3(0, -0.5, 0)
	pmat.scale_min = 0.02
	pmat.scale_max = 0.06
	pmat.damping_min = 2.0
	pmat.damping_max = 4.0

	var grad := Gradient.new()
	grad.add_point(0.0, Color(1, 0.85, 0.5, 0.9))
	grad.add_point(0.5, Color(1, 0.7, 0.3, 0.5))
	grad.add_point(1.0, Color(0.9, 0.5, 0.15, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	pmat.color_ramp = tex

	ring_particles.process_material = pmat
	ring_particles.draw_pass_1 = QuadMesh.new()

	# Attach to scene, not to projectile (which will be freed)
	var scene_root := get_tree().current_scene
	scene_root.add_child(ring_particles)
	ring_particles.global_position = global_position

	# Apply calming to nearby RigidBody3D objects
	var space := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = CALM_RADIUS
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = 1 | 2 | 16

	var results := space.intersect_shape(query)
	for result in results:
		var collider = result["collider"]
		if collider is RigidBody3D and collider != self:
			_apply_calming(collider)

	# Cleanup ring particles
	var timer := Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(ring_particles.queue_free)
	ring_particles.add_child(timer)
	timer.start()

func _apply_calming(body: RigidBody3D) -> void:
	# Slow it down — increase damping temporarily
	var original_linear_damp: float = body.linear_damp
	var original_angular_damp: float = body.angular_damp

	body.linear_damp += CALM_DAMP_ADD
	body.angular_damp += CALM_DAMP_ADD * 0.7

	# Also reduce current velocity
	body.linear_velocity *= 0.3
	body.angular_velocity *= 0.2

	# Restore after duration
	var tween := body.create_tween()
	tween.tween_interval(CALM_DURATION)
	tween.tween_property(body, "linear_damp", original_linear_damp, 1.0)
	tween.tween_property(body, "angular_damp", original_angular_damp, 1.0)
