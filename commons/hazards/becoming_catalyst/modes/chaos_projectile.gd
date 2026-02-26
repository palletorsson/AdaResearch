# ChaosProjectile.gd
# Irregular shape, flickering colors, random impulses.
# You cannot predict where this goes — and that's the point.
extends CatalystProjectile

var _impulse_timer: float = 0.0
const IMPULSE_INTERVAL := 0.3
const IMPULSE_STRENGTH := 3.0

func _build_visual() -> void:
	_mesh_instance = MeshInstance3D.new()
	# Deformed sphere — use low-poly for irregular feel
	var sphere := SphereMesh.new()
	sphere.radius = 0.08 * projectile_scale
	sphere.height = 0.16 * projectile_scale
	sphere.radial_segments = 5
	sphere.rings = 3
	_mesh_instance.mesh = sphere
	_mesh_instance.material_override = _make_material(color_primary, emission_energy)
	# Random initial rotation for unique shape
	_mesh_instance.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
	add_child(_mesh_instance)

	# Flickering particles
	_particles = GPUParticles3D.new()
	_particles.amount = 10
	_particles.lifetime = 0.3
	_particles.emitting = true
	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pmat.emission_sphere_radius = 0.05
	pmat.gravity = Vector3.ZERO
	pmat.initial_velocity_min = 1.0
	pmat.initial_velocity_max = 3.0
	pmat.direction = Vector3(0, 0, 0)
	pmat.spread = 180.0
	pmat.scale_min = 0.005
	pmat.scale_max = 0.02
	var grad := Gradient.new()
	grad.add_point(0.0, Color(1, 0.3, 0.6, 0.9))
	grad.add_point(0.5, Color(0.8, 0.1, 0.9, 0.5))
	grad.add_point(1.0, Color(0.5, 0.0, 0.5, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	pmat.color_ramp = tex
	_particles.process_material = pmat
	_particles.draw_pass_1 = QuadMesh.new()
	add_child(_particles)

func _update_trajectory(delta: float) -> void:
	if has_hit:
		return
	_impulse_timer += delta
	if _impulse_timer >= IMPULSE_INTERVAL:
		_impulse_timer = 0.0
		# Random impulse
		var impulse := Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-0.5, 0.5),
			randf_range(-1.0, 1.0)
		).normalized() * IMPULSE_STRENGTH
		apply_central_impulse(impulse)

	# Flicker color
	if _mesh_instance and _mesh_instance.material_override:
		var mat: StandardMaterial3D = _mesh_instance.material_override
		mat.emission = Color.from_hsv(randf(), 0.8, 1.0)

	# Chaotic rotation
	if _mesh_instance:
		_mesh_instance.rotate_x(delta * randf_range(-5, 5))
		_mesh_instance.rotate_y(delta * randf_range(-5, 5))

func _on_hit(body: Node3D) -> void:
	projectile_hit.emit(body, global_position)
	# Random effect
	var roll := randi() % 4
	match roll:
		0:  # Shrink
			if body is Node3D:
				var tw := body.create_tween()
				tw.tween_property(body, "scale", body.scale * 0.6, 0.4)
				tw.tween_property(body, "scale", body.scale, 1.5)
		1:  # Push
			if body is RigidBody3D:
				body.apply_central_impulse(direction.normalized() * 5.0)
		2:  # Color shift
			_tint(body)
		3:  # Spin
			if body is RigidBody3D:
				body.apply_torque_impulse(Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3)))

func _tint(body: Node3D) -> void:
	for child in body.get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = child.material_override
			var original := mat.emission
			mat.emission = Color.from_hsv(randf(), 0.9, 1.0)
			var tw := child.create_tween()
			tw.tween_property(mat, "emission", original, 2.0)
			break
