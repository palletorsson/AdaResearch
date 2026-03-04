# WaveformProjectile.gd
# Teal double helix — two torus rings spiraling around each other.
# Wave-particle duality as identity — always oscillating, never fixed.
extends CatalystProjectile

var _wave_freq: float = 6.0
var _wave_amp: float = 0.6
var _local_right: Vector3 = Vector3.RIGHT
var _local_up: Vector3 = Vector3.UP
var _mesh_strand_b: MeshInstance3D = null  # Second helix strand

func _build_visual() -> void:
	# Strand A — primary color
	_mesh_instance = MeshInstance3D.new()
	var torus_a := TorusMesh.new()
	torus_a.inner_radius = 0.02 * projectile_scale
	torus_a.outer_radius = 0.06 * projectile_scale
	torus_a.rings = 12
	torus_a.ring_segments = 8
	_mesh_instance.mesh = torus_a
	_mesh_instance.material_override = _make_material(color_primary, emission_energy)
	add_child(_mesh_instance)

	# Strand B — secondary color, 180° phase offset
	_mesh_strand_b = MeshInstance3D.new()
	var torus_b := TorusMesh.new()
	torus_b.inner_radius = 0.02 * projectile_scale
	torus_b.outer_radius = 0.06 * projectile_scale
	torus_b.rings = 12
	torus_b.ring_segments = 8
	_mesh_strand_b.mesh = torus_b
	_mesh_strand_b.material_override = _make_material(color_secondary, emission_energy * 0.8)
	add_child(_mesh_strand_b)

	# Trail
	_particles = GPUParticles3D.new()
	_particles.amount = 16
	_particles.lifetime = 0.5
	_particles.emitting = true
	var pmat := ParticleProcessMaterial.new()
	pmat.gravity = Vector3.ZERO
	pmat.scale_min = 0.005
	pmat.scale_max = 0.015
	var grad := Gradient.new()
	grad.add_point(0.0, Color(color_primary, 0.8))
	grad.add_point(1.0, Color(color_secondary, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	pmat.color_ramp = tex
	_particles.process_material = pmat
	_particles.draw_pass_1 = QuadMesh.new()
	add_child(_particles)

func _apply_initial_velocity() -> void:
	# Calculate local axes perpendicular to travel direction
	var forward := direction.normalized()
	if abs(forward.dot(Vector3.UP)) < 0.99:
		_local_right = forward.cross(Vector3.UP).normalized()
	else:
		_local_right = forward.cross(Vector3.RIGHT).normalized()
	_local_up = _local_right.cross(forward).normalized()

	linear_velocity = forward * speed

func _update_trajectory(delta: float) -> void:
	if has_hit:
		return

	# Double helix: strand A at phase 0, strand B at phase PI
	var t := time_alive * _wave_freq
	var amp := _wave_amp * delta

	# Strand A displacement (applied to main body position)
	var offset_right_a := sin(t) * amp
	var offset_up_a := cos(t) * amp * 0.6
	global_position += _local_right * offset_right_a + _local_up * offset_up_a

	# Strand B offset relative to strand A (180° phase = opposite position)
	if _mesh_strand_b:
		var strand_sep := _wave_amp * 0.15  # Visual separation between strands
		var phase_diff_right := (sin(t + PI) - sin(t)) * strand_sep
		var phase_diff_up := (cos(t + PI) - cos(t)) * strand_sep * 0.6
		_mesh_strand_b.position = _local_right * phase_diff_right + _local_up * phase_diff_up

	# Counter-spin the two tori
	if _mesh_instance:
		_mesh_instance.rotate_z(delta * 6.0)
	if _mesh_strand_b:
		_mesh_strand_b.rotate_z(-delta * 6.0)

func _on_hit(body: Node3D) -> void:
	projectile_hit.emit(body, global_position)
	# Brief oscillation on target
	if body is Node3D:
		var tween := body.create_tween()
		var base_pos: Vector3 = body.position
		for i in 5:
			var offset := sin(i * 1.5) * 0.03
			tween.tween_property(body, "position", base_pos + Vector3(offset, 0, 0), 0.06)
		tween.tween_property(body, "position", base_pos, 0.1)
