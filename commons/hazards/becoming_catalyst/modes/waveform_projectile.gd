# WaveformProjectile.gd
# Teal torus that follows a sinusoidal/helix path.
# Wave-particle duality as identity — always oscillating, never fixed.
extends CatalystProjectile

var _wave_freq: float = 8.0
var _wave_amp: float = 0.4
var _local_right: Vector3 = Vector3.RIGHT
var _local_up: Vector3 = Vector3.UP
var _helix: bool = false

func _build_visual() -> void:
	_mesh_instance = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.02 * projectile_scale
	torus.outer_radius = 0.06 * projectile_scale
	torus.rings = 12
	torus.ring_segments = 8
	_mesh_instance.mesh = torus
	_mesh_instance.material_override = _make_material(color_primary, emission_energy)
	add_child(_mesh_instance)

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

	# Randomly decide helix vs planar
	_helix = randf() > 0.5

	linear_velocity = forward * speed

func _update_trajectory(delta: float) -> void:
	if has_hit:
		return
	# Sinusoidal displacement perpendicular to travel
	var wave_offset := sin(time_alive * _wave_freq) * _wave_amp * delta
	global_position += _local_right * wave_offset

	# Helix: also oscillate vertically
	if _helix:
		var vert_offset := cos(time_alive * _wave_freq) * _wave_amp * 0.6 * delta
		global_position += _local_up * vert_offset

	# Spin the torus
	if _mesh_instance:
		_mesh_instance.rotate_z(delta * 6.0)

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
