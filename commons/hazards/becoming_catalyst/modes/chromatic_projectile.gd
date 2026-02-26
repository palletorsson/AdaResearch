# ChromaticProjectile.gd
# Fast small rainbow sphere with particle trail.
# Each shot picks a random hue — chromatic expression.
extends CatalystProjectile

var _hue_offset: float = 0.0

func _build_visual() -> void:
	_mesh_instance = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.06 * projectile_scale
	sphere.height = 0.12 * projectile_scale
	_mesh_instance.mesh = sphere
	_mesh_instance.material_override = _make_material(color_primary, emission_energy)
	add_child(_mesh_instance)

	# Rainbow trail particles
	_particles = GPUParticles3D.new()
	_particles.amount = 20
	_particles.lifetime = 0.4
	_particles.emitting = true

	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 0, 1)  # Trail behind
	pmat.initial_velocity_min = 0.5
	pmat.initial_velocity_max = 1.5
	pmat.gravity = Vector3.ZERO
	pmat.scale_min = 0.01
	pmat.scale_max = 0.03

	var grad := Gradient.new()
	grad.add_point(0.0, Color(color_primary, 0.9))
	grad.add_point(0.5, Color(color_secondary, 0.5))
	grad.add_point(1.0, Color(color_secondary, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	pmat.color_ramp = tex

	_particles.process_material = pmat
	_particles.draw_pass_1 = QuadMesh.new()
	add_child(_particles)

func _update_trajectory(_delta: float) -> void:
	# Subtle hue cycling on the mesh material
	if _mesh_instance and _mesh_instance.material_override and not has_hit:
		_hue_offset += _delta * 0.5
		var mat: StandardMaterial3D = _mesh_instance.material_override
		var new_color := Color.from_hsv(fmod(color_primary.h + _hue_offset, 1.0), 0.85, 1.0)
		mat.emission = new_color

func _on_hit(body: Node3D) -> void:
	projectile_hit.emit(body, global_position)
	# Brief color tint on target
	if body is MeshInstance3D or (body.get_child_count() > 0):
		_tint_target(body)

func _tint_target(body: Node3D) -> void:
	# Find first MeshInstance3D child and tint it briefly
	var mesh: MeshInstance3D = null
	if body is MeshInstance3D:
		mesh = body
	else:
		for child in body.get_children():
			if child is MeshInstance3D:
				mesh = child
				break
	if mesh and mesh.material_override is StandardMaterial3D:
		var mat: StandardMaterial3D = mesh.material_override
		var original_emission := mat.emission
		mat.emission = color_primary
		# Restore after delay
		var tween := mesh.create_tween()
		tween.tween_property(mat, "emission", original_emission, 1.5)
