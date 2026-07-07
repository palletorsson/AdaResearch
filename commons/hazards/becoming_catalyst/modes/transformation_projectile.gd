# TransformationProjectile.gd
# verb: shrink
# Purple sphere that shrinks targets on hit.
# Metamorphosis, not destruction — what you touch becomes different.
extends CatalystProjectile

func _build_visual() -> void:
	_mesh_instance = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.09 * projectile_scale
	sphere.height = 0.18 * projectile_scale
	_mesh_instance.mesh = sphere

	var mat := _make_material(color_primary, emission_energy)
	mat.rim_enabled = true
	mat.rim = 0.5
	mat.rim_tint = 0.2
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)

	# Shimmer particles
	_particles = GPUParticles3D.new()
	_particles.amount = 8
	_particles.lifetime = 0.5
	_particles.emitting = true
	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pmat.emission_sphere_radius = 0.06
	pmat.gravity = Vector3.ZERO
	pmat.scale_min = 0.01
	pmat.scale_max = 0.025
	var grad := Gradient.new()
	grad.add_point(0.0, Color(0.8, 0.4, 1.0, 0.8))
	grad.add_point(1.0, Color(0.5, 0.1, 0.8, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	pmat.color_ramp = tex
	_particles.process_material = pmat
	_particles.draw_pass_1 = QuadMesh.new()
	add_child(_particles)

func _on_hit(body: Node3D) -> void:
	projectile_hit.emit(body, global_position)

	# Shrink the target — metamorphosis, not damage
	if body is Node3D:
		var tween := body.create_tween()
		var original_scale: Vector3 = body.scale
		var shrunken := original_scale * 0.5
		tween.tween_property(body, "scale", shrunken, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		# Recover slowly
		tween.tween_interval(1.5)
		tween.tween_property(body, "scale", original_scale, 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
