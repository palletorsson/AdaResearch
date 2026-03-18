@tool
extends Node3D

@export var grid_size_x: int = 15
@export var grid_size_y: int = 15
@export var grid_size_z: int = 15
@export var spacing: float = 1.0
@export var arrow_length: float = 0.4
@export var arrow_thickness: float = 0.05

@export_group("Field Type")
@export_enum("Vortex", "Saddle", "Source", "Sink", "Tornado", "Wave", "Circular") var field_type: int = 0
@export var field_strength: float = 1.0
@export var rotation_speed: float = 0.5
@export var time_variation_strength: float = 1.0
@export var direction_change_speed: float = 0.3
@export_group("Noise Modulation")
@export var noise_enabled: bool = true
@export var noise_strength: float = 0.5
@export var noise_scale: float = 0.3
@export var noise_speed: float = 0.2
@export var turbulence_octaves: int = 3

@export_group("Particles")
@export var particle_count: int = 500
@export var particle_speed: float = 2.0
@export var particle_size: float = 0.1
@export var spawn_from_outside: bool = true
@export var spawn_distance_multiplier: float = 1.2
@export var use_rk4_integration: bool = true
@export_group("Debug & Trails")
@export var show_particle_direction: bool = false
@export var direction_line_length: float = 0.5
@export var trail_enabled: bool = true
@export var trail_length: int = 50
@export var trail_fade: bool = true
@export var trail_width: float = 0.05

@export_group("Visualization")
@export var show_vectors: bool = true
@export var vector_color: Color = Color(0.3, 0.7, 1.0, 0.6)
@export var particle_color_start: Color = Color(1.0, 0.2, 0.2, 1.0)
@export var particle_color_end: Color = Color(0.2, 1.0, 0.2, 1.0)

@export var regenerate: bool = false: set = _set_regenerate

@onready var vector_mm_inst: MultiMeshInstance3D = MultiMeshInstance3D.new()
@onready var particle_mm_inst: MultiMeshInstance3D = MultiMeshInstance3D.new()

var _time: float = 0.0
var _particles: Array[Dictionary] = []
var _trail_meshes: Array[MeshInstance3D] = []

func _ready() -> void:
	generate_field()
	set_process(true)
	print("VectorField ready - Particles: ", particle_count, " Trail enabled: ", trail_enabled)

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		_time += delta
		_update_vector_field()
		_update_particles(delta)
		if show_particle_direction:
			_update_debug_lines()

func _set_regenerate(value: bool) -> void:
	if value:
		generate_field()
		regenerate = false

func generate_field() -> void:
	# Clear existing
	if vector_mm_inst.get_parent():
		vector_mm_inst.get_parent().remove_child(vector_mm_inst)
	if particle_mm_inst.get_parent():
		particle_mm_inst.get_parent().remove_child(particle_mm_inst)

	add_child(vector_mm_inst)
	add_child(particle_mm_inst)

	if Engine.is_editor_hint():
		vector_mm_inst.owner = get_tree().edited_scene_root
		particle_mm_inst.owner = get_tree().edited_scene_root

	_clear_trails()
	_setup_vector_field()
	_setup_particles()
	_spawn_particles()

func _setup_vector_field() -> void:
	var mm := MultiMesh.new()
	vector_mm_inst.multimesh = mm
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true

	# Create arrow mesh (cylinder + cone)
	var arrow_mesh := CylinderMesh.new()
	arrow_mesh.top_radius = arrow_thickness
	arrow_mesh.bottom_radius = arrow_thickness
	arrow_mesh.height = arrow_length
	arrow_mesh.radial_segments = 6

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arrow_mesh.material = mat

	mm.mesh = arrow_mesh
	mm.instance_count = grid_size_x * grid_size_y * grid_size_z

	vector_mm_inst.visible = show_vectors
	_update_vector_field()

func _update_vector_field() -> void:
	if not vector_mm_inst.multimesh:
		return

	var mm := vector_mm_inst.multimesh
	var k := 0

	for iy in range(grid_size_y):
		for iz in range(grid_size_z):
			for ix in range(grid_size_x):
				var x: float = (ix - grid_size_x / 2.0) * spacing
				var y: float = (iy - grid_size_y / 2.0) * spacing
				var z: float = (iz - grid_size_z / 2.0) * spacing
				var pos := Vector3(x, y, z)

				var field_vector := _get_field_at(pos)
				var field_magnitude: float = field_vector.length()

				if field_magnitude < 0.001:
					# Hide very small vectors
					var transform := Transform3D.IDENTITY
					transform.origin = Vector3(0, -1000, 0)
					mm.set_instance_transform(k, transform)
				else:
					# Orient arrow along field direction
					var direction := field_vector.normalized()
					var transform := Transform3D.IDENTITY
					transform = transform.looking_at(direction, Vector3.UP)
					transform = transform.rotated_local(Vector3.RIGHT, PI / 2.0)  # Align with cylinder

					# Scale by magnitude
					var scale: float = min(field_magnitude * arrow_length, arrow_length * 2.0)
					transform.basis = transform.basis.scaled(Vector3(1, scale / arrow_length, 1))
					transform.origin = pos

					mm.set_instance_transform(k, transform)

					# Color by magnitude
					var color_t: float = clamp(field_magnitude / field_strength, 0.0, 1.0)
					var color := vector_color
					color.a = 0.3 + color_t * 0.5
					mm.set_instance_color(k, color)

				k += 1

func _setup_particles() -> void:
	var mm := MultiMesh.new()
	particle_mm_inst.multimesh = mm
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true

	var sphere := SphereMesh.new()
	sphere.radius = particle_size
	sphere.height = particle_size * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 1.0
	sphere.material = mat

	mm.mesh = sphere
	mm.instance_count = particle_count

func _spawn_particles() -> void:
	_particles.clear()

	for i in range(particle_count):
		var pos := _get_spawn_position()

		_particles.append({
			"position": pos,
			"velocity": Vector3.ZERO,
			"age": 0.0,
			"lifetime": randf_range(5.0, 15.0),
			"trail": []
		})

func _get_spawn_position() -> Vector3:
	if spawn_from_outside:
		# Spawn on the faces of the bounding box
		var half_x: float = grid_size_x * spacing * 0.5 * spawn_distance_multiplier
		var half_y: float = grid_size_y * spacing * 0.5 * spawn_distance_multiplier
		var half_z: float = grid_size_z * spacing * 0.5 * spawn_distance_multiplier

		# Choose random face (0-5: -X, +X, -Y, +Y, -Z, +Z)
		var face := randi() % 6
		var pos := Vector3.ZERO

		match face:
			0:  # -X face
				pos = Vector3(-half_x, randf_range(-half_y, half_y), randf_range(-half_z, half_z))
			1:  # +X face
				pos = Vector3(half_x, randf_range(-half_y, half_y), randf_range(-half_z, half_z))
			2:  # -Y face
				pos = Vector3(randf_range(-half_x, half_x), -half_y, randf_range(-half_z, half_z))
			3:  # +Y face
				pos = Vector3(randf_range(-half_x, half_x), half_y, randf_range(-half_z, half_z))
			4:  # -Z face
				pos = Vector3(randf_range(-half_x, half_x), randf_range(-half_y, half_y), -half_z)
			5:  # +Z face
				pos = Vector3(randf_range(-half_x, half_x), randf_range(-half_y, half_y), half_z)

		return pos
	else:
		# Original spherical spawn
		var angle1: float = randf() * TAU
		var angle2: float = randf() * PI
		var radius: float = randf() * grid_size_x * spacing * 0.5

		return Vector3(
			cos(angle1) * sin(angle2) * radius,
			cos(angle2) * radius,
			sin(angle1) * sin(angle2) * radius
		)

func _update_particles(delta: float) -> void:
	if not particle_mm_inst.multimesh:
		return

	var mm := particle_mm_inst.multimesh

	for i in range(_particles.size()):
		var particle := _particles[i]

		# Store old position for trail
		if trail_enabled:
			particle.trail.push_front(particle.position)
			if particle.trail.size() > trail_length:
				particle.trail.pop_back()

		# Get field at particle position and integrate
		if use_rk4_integration:
			particle.position = _rk4_step(particle.position, delta)
		else:
			var field := _get_field_at(particle.position)
			particle.velocity = field * particle_speed
			particle.position += particle.velocity * delta

		# Age particle
		particle.age += delta

		# Respawn if too old or out of bounds
		var bounds: float = max(grid_size_x, max(grid_size_y, grid_size_z)) * spacing * 0.7
		if particle.age > particle.lifetime or particle.position.length() > bounds:
			# Respawn at edge
			particle.position = _get_spawn_position()
			particle.velocity = Vector3.ZERO
			particle.age = 0.0
			particle.trail.clear()

		# Update instance
		var transform := Transform3D.IDENTITY
		transform.origin = particle.position
		mm.set_instance_transform(i, transform)

		# Color by age
		var age_t: float = particle.age / particle.lifetime
		var color: Color = particle_color_start.lerp(particle_color_end, age_t)
		mm.set_instance_color(i, color)

	# Draw trails in real-time
	if trail_enabled:
		_update_trails()

	# Debug: Print first particle trail size occasionally
	if int(_time * 2.0) % 10 == 0 and fmod(_time, 0.5) < 0.02 and _particles.size() > 0:
		print("Time: %.1f, Particle 0 trail: %d points, Total trail meshes: %d" % [_time, _particles[0].trail.size(), _trail_meshes.size()])

func _get_field_at(pos: Vector3) -> Vector3:
	var field := Vector3.ZERO
	var time_factor: float = _time * rotation_speed

	match field_type:
		0:  # Vortex
			field = Vector3(-pos.z, pos.y * 0.3, pos.x) * field_strength
		1:  # Saddle
			field = Vector3(pos.x, -pos.y, pos.z) * field_strength
		2:  # Source
			field = pos.normalized() * field_strength
		3:  # Sink
			field = -pos.normalized() * field_strength
		4:  # Tornado
			var r: float = Vector2(pos.x, pos.z).length()
			var tangent := Vector3(-pos.z, 0, pos.x).normalized()
			field = tangent * field_strength / max(r, 0.5) + Vector3.UP * field_strength * 0.5
		5:  # Wave
			field = Vector3(
				sin(pos.y * 0.5 + time_factor) * field_strength,
				cos(pos.x * 0.5 + time_factor) * field_strength,
				sin(pos.z * 0.5 + time_factor) * field_strength
			)
		6:  # Circular
			var axis := Vector3(0, 1, 0)
			field = pos.cross(axis).normalized() * field_strength

	# Apply time-based rotation to the field
	if time_variation_strength > 0.0:
		field = _rotate_field(field, pos, _time * direction_change_speed)

	# Apply noise modulation
	if noise_enabled:
		field = _apply_noise_to_field(field, pos, _time)

	return field

func _rotate_field(field: Vector3, pos: Vector3, time: float) -> Vector3:
	# Create a rotation that varies over time and space
	var rotation_axis := Vector3(
		sin(time * 0.7 + pos.x * 0.1),
		cos(time * 0.5 + pos.y * 0.1),
		sin(time * 0.9 + pos.z * 0.1)
	).normalized()

	var rotation_angle: float = sin(time) * time_variation_strength * 0.5

	# Rotate the field vector around the time-varying axis
	var rotated_field := field.rotated(rotation_axis, rotation_angle)

	return rotated_field

func _rk4_step(pos: Vector3, dt: float) -> Vector3:
	# Runge-Kutta 4th order integration for more accurate field following
	var k1 := _get_field_at(pos) * particle_speed
	var k2 := _get_field_at(pos + k1 * dt * 0.5) * particle_speed
	var k3 := _get_field_at(pos + k2 * dt * 0.5) * particle_speed
	var k4 := _get_field_at(pos + k3 * dt) * particle_speed

	return pos + (k1 + k2 * 2.0 + k3 * 2.0 + k4) * dt / 6.0

func _update_trails() -> void:
	_clear_trails()

	var trails_created := 0
	for particle in _particles:
		if particle.trail.size() < 2:
			continue

		trails_created += 1

		# Create tube mesh for thicker trails
		var immediate := ImmediateMesh.new()
		var mesh_inst := MeshInstance3D.new()
		mesh_inst.mesh = immediate

		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.albedo_color = Color.WHITE
		mat.emission_enabled = true
		mat.emission = particle_color_start
		mat.emission_energy_multiplier = 0.3
		mesh_inst.material_override = mat

		# Use triangles for thicker, more visible trails
		immediate.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

		for j in range(particle.trail.size() - 1):
			var p1: Vector3 = particle.trail[j]
			var p2: Vector3 = particle.trail[j + 1]

			var alpha1: float = 1.0
			var alpha2: float = 1.0
			if trail_fade:
				alpha1 = 1.0 - float(j) / float(particle.trail.size())
				alpha2 = 1.0 - float(j + 1) / float(particle.trail.size())

			# Create a ribbon facing camera (billboard)
			var direction := (p2 - p1).normalized()
			var perpendicular := direction.cross(Vector3.UP)
			if perpendicular.length() < 0.001:
				perpendicular = direction.cross(Vector3.RIGHT)
			perpendicular = perpendicular.normalized() * trail_width

			# Two triangles forming a quad
			var color1 := particle_color_start
			color1.a = alpha1 * 0.9

			var color2 := particle_color_start
			color2.a = alpha2 * 0.9

			# Triangle 1
			immediate.surface_set_color(color1)
			immediate.surface_add_vertex(p1 + perpendicular)
			immediate.surface_set_color(color1)
			immediate.surface_add_vertex(p1 - perpendicular)
			immediate.surface_set_color(color2)
			immediate.surface_add_vertex(p2 + perpendicular)

			# Triangle 2
			immediate.surface_set_color(color2)
			immediate.surface_add_vertex(p2 + perpendicular)
			immediate.surface_set_color(color1)
			immediate.surface_add_vertex(p1 - perpendicular)
			immediate.surface_set_color(color2)
			immediate.surface_add_vertex(p2 - perpendicular)

		immediate.surface_end()

		add_child(mesh_inst)
		if Engine.is_editor_hint():
			mesh_inst.owner = get_tree().edited_scene_root
		_trail_meshes.append(mesh_inst)

	if trails_created > 0 and _trail_meshes.size() == 0:
		print("WARNING: Trails created but no meshes added!")

func _clear_trails() -> void:
	for mesh in _trail_meshes:
		if is_instance_valid(mesh):
			mesh.queue_free()
	_trail_meshes.clear()

func _update_debug_lines() -> void:
	# Clear old debug visualization
	for child in get_children():
		if child.name.begins_with("DebugLine"):
			child.queue_free()

	# Draw lines from particles showing field direction
	for particle in _particles:
		var field := _get_field_at(particle.position)
		if field.length() < 0.001:
			continue

		var immediate := ImmediateMesh.new()
		var mesh_inst := MeshInstance3D.new()
		mesh_inst.name = "DebugLine"
		mesh_inst.mesh = immediate

		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color.YELLOW
		mesh_inst.material_override = mat

		immediate.surface_begin(Mesh.PRIMITIVE_LINES)
		immediate.surface_add_vertex(particle.position)
		immediate.surface_add_vertex(particle.position + field.normalized() * direction_line_length)
		immediate.surface_end()

		add_child(mesh_inst)

func _apply_noise_to_field(field: Vector3, pos: Vector3, time: float) -> Vector3:
	# Multi-octave noise for turbulent field distortion
	var noise_offset := Vector3.ZERO

	for octave in range(turbulence_octaves):
		var freq: float = pow(2.0, float(octave)) * noise_scale
		var amp: float = pow(0.5, float(octave))

		var noise_pos := pos * freq + Vector3.ONE * time * noise_speed

		# 3D Perlin-like noise using sine waves
		var nx: float = _noise_3d(noise_pos.x, noise_pos.y, noise_pos.z)
		var ny: float = _noise_3d(noise_pos.x + 100.0, noise_pos.y + 100.0, noise_pos.z + 100.0)
		var nz: float = _noise_3d(noise_pos.x + 200.0, noise_pos.y + 200.0, noise_pos.z + 200.0)

		noise_offset += Vector3(nx, ny, nz) * amp * noise_strength

	return field + noise_offset

func _noise_3d(x: float, y: float, z: float) -> float:
	# Simple 3D noise function using sine waves
	var n: float = sin(x * 1.2 + sin(y * 1.7)) * cos(y * 1.5 + sin(z * 1.3))
	n += sin(z * 1.9 + sin(x * 0.8)) * 0.5
	n += cos(x * 2.3 + y * 0.7 + z * 1.1) * 0.25
	return n / 1.75

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
