# ChaosProjectile.gd
# verb: arc
# Tesla coil spark — branching electric arcs that crackle and fork.
# Unpredictable paths, random impulses, flickering lightning.
extends CatalystProjectile

var _impulse_timer: float = 0.0
var _arc_timer: float = 0.0
var _arc_meshes: Array[MeshInstance3D] = []
var _core_light: OmniLight3D = null
const IMPULSE_INTERVAL := 0.25
const IMPULSE_STRENGTH := 3.5
const ARC_REBUILD_INTERVAL := 0.08  # Rebuild arcs rapidly for crackle effect
const NUM_ARCS := 4
const ARC_LENGTH := 0.25
const ARC_SEGMENTS := 5

func _build_visual() -> void:
	# Central glowing core — small bright sphere
	_mesh_instance = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.03 * projectile_scale
	sphere.height = 0.06 * projectile_scale
	sphere.radial_segments = 8
	sphere.rings = 4
	_mesh_instance.mesh = sphere
	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = Color.WHITE
	core_mat.emission_enabled = true
	core_mat.emission = Color(0.95, 0.3, 0.7)
	core_mat.emission_energy_multiplier = 4.0
	_mesh_instance.material_override = core_mat
	add_child(_mesh_instance)

	# Point light for electric glow
	_core_light = OmniLight3D.new()
	_core_light.light_color = color_primary
	_core_light.light_energy = 1.5
	_core_light.omni_range = 0.4
	_core_light.omni_attenuation = 2.0
	add_child(_core_light)

	# Build initial arc bolts
	_rebuild_arcs()

	# Spark particles
	_particles = GPUParticles3D.new()
	_particles.amount = 12
	_particles.lifetime = 0.15
	_particles.emitting = true
	var pmat := ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pmat.emission_sphere_radius = 0.04
	pmat.gravity = Vector3.ZERO
	pmat.initial_velocity_min = 2.0
	pmat.initial_velocity_max = 6.0
	pmat.direction = Vector3.ZERO
	pmat.spread = 180.0
	pmat.scale_min = 0.002
	pmat.scale_max = 0.008
	var grad := Gradient.new()
	grad.add_point(0.0, Color(1.0, 0.9, 1.0, 1.0))
	grad.add_point(0.3, Color(0.9, 0.2, 0.5, 0.8))
	grad.add_point(1.0, Color(0.5, 0.0, 0.4, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	pmat.color_ramp = tex
	_particles.process_material = pmat
	_particles.draw_pass_1 = QuadMesh.new()
	add_child(_particles)

func _rebuild_arcs() -> void:
	# Remove old arcs
	for arc in _arc_meshes:
		if is_instance_valid(arc):
			arc.queue_free()
	_arc_meshes.clear()

	# Create new random lightning arcs branching from center
	for i in NUM_ARCS:
		var arc := _create_arc_bolt()
		add_child(arc)
		_arc_meshes.append(arc)

func _create_arc_bolt() -> MeshInstance3D:
	# Generate a jagged lightning path using ImmediateMesh
	var mesh_inst := MeshInstance3D.new()
	var imesh := ImmediateMesh.new()

	# Random direction for this arc
	var arc_dir := Vector3(
		randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)
	).normalized()

	var arc_len := ARC_LENGTH * projectile_scale * randf_range(0.6, 1.2)
	var seg_len := arc_len / ARC_SEGMENTS

	# Build jagged line strip
	imesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var pos := Vector3.ZERO
	imesh.surface_add_vertex(pos)
	for seg in ARC_SEGMENTS:
		# Step along main direction with random jitter
		pos += arc_dir * seg_len
		pos += Vector3(
			randf_range(-0.03, 0.03),
			randf_range(-0.03, 0.03),
			randf_range(-0.03, 0.03)
		) * projectile_scale
		imesh.surface_add_vertex(pos)
	imesh.surface_end()
	mesh_inst.mesh = imesh

	# Bright emissive material
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.6, 0.9)
	mat.emission_enabled = true
	# Vary hue per arc for visual variety
	var hue := randf_range(0.85, 1.0)  # Pink-magenta range
	if randf() > 0.5:
		hue = randf_range(0.7, 0.8)  # Occasional purple
	mat.emission = Color.from_hsv(fmod(hue, 1.0), 0.7, 1.0)
	mat.emission_energy_multiplier = 3.0
	mesh_inst.material_override = mat

	return mesh_inst

func _update_trajectory(delta: float) -> void:
	if has_hit:
		return

	# Random impulses — erratic flight
	_impulse_timer += delta
	if _impulse_timer >= IMPULSE_INTERVAL:
		_impulse_timer = 0.0
		var impulse := Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-0.5, 0.5),
			randf_range(-1.0, 1.0)
		).normalized() * IMPULSE_STRENGTH
		apply_central_impulse(impulse)

	# Rapidly rebuild arcs for crackling effect
	_arc_timer += delta
	if _arc_timer >= ARC_REBUILD_INTERVAL:
		_arc_timer = 0.0
		_rebuild_arcs()

	# Flicker the core light
	if _core_light:
		_core_light.light_energy = randf_range(0.8, 2.5)

	# Flicker core color
	if _mesh_instance and _mesh_instance.material_override:
		var mat: StandardMaterial3D = _mesh_instance.material_override
		mat.emission_energy_multiplier = randf_range(2.0, 5.0)

func _on_hit(body: Node3D) -> void:
	projectile_hit.emit(body, global_position)
	# Electric shock — random effect
	var roll := randi() % 4
	match roll:
		0:  # Jolt/shake
			if body is Node3D:
				var tw := body.create_tween()
				var base_pos: Vector3 = body.position
				for i in 6:
					var offset := Vector3(randf_range(-0.04, 0.04), randf_range(-0.02, 0.02), randf_range(-0.04, 0.04))
					tw.tween_property(body, "position", base_pos + offset, 0.03)
				tw.tween_property(body, "position", base_pos, 0.1)
		1:  # Repel
			if body is RigidBody3D:
				body.apply_central_impulse(direction.normalized() * 5.0)
		2:  # Tint electric
			_tint(body)
		3:  # Spin
			if body is RigidBody3D:
				body.apply_torque_impulse(Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3)))

func _tint(body: Node3D) -> void:
	for child in body.get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = child.material_override
			var original := mat.emission
			mat.emission = color_primary
			var tw := child.create_tween()
			tw.tween_property(mat, "emission", original, 2.0)
			break
