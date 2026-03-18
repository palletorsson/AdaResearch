@tool
extends Node3D

@export var grid_size_x: int = 50
@export var grid_size_z: int = 50
@export var spacing: float = 0.3
@export var particle_size: float = 0.08

@export_group("Field Dynamics")
@export var vacuum_fluctuation_strength: float = 0.15
@export var wave_speed: float = 2.0
@export var wave_amplitude: float = 1.5
@export var field_decay: float = 0.3
@export var time_scale: float = 1.0

@export_group("Virtual Particles")
@export var enable_virtual_particles: bool = true
@export var virtual_particle_density: float = 0.02
@export var virtual_particle_lifetime: float = 0.3

@export_group("Wave Sources")
@export var num_wave_sources: int = 3
@export var source_frequency: float = 1.5

@export_group("Visualization")
@export var color_low: Color = Color(0.1, 0.0, 0.5, 1.0)  # Dark blue
@export var color_mid: Color = Color(0.0, 1.0, 0.5, 1.0)  # Cyan
@export var color_high: Color = Color(1.0, 0.3, 0.0, 1.0) # Orange
@export var height_scale: float = 2.0

@export var regenerate: bool = false: set = _set_regenerate

@onready var field_mm_inst: MultiMeshInstance3D = MultiMeshInstance3D.new()
@onready var virtual_mm_inst: MultiMeshInstance3D = MultiMeshInstance3D.new()

var _time: float = 0.0
var _wave_sources: Array[Dictionary] = []
var _virtual_particles: Array[Dictionary] = []
var _field_values: Array[float] = []

func _ready() -> void:
	generate_field()
	set_process(true)

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		_time += delta * time_scale
		_update_wave_sources(delta)
		_update_virtual_particles(delta)
		_update_field()

func _set_regenerate(value: bool) -> void:
	if value:
		generate_field()
		regenerate = false

func generate_field() -> void:
	# Clear existing
	if field_mm_inst.get_parent():
		field_mm_inst.get_parent().remove_child(field_mm_inst)
	if virtual_mm_inst.get_parent():
		virtual_mm_inst.get_parent().remove_child(virtual_mm_inst)

	add_child(field_mm_inst)
	add_child(virtual_mm_inst)

	if Engine.is_editor_hint():
		field_mm_inst.owner = get_tree().edited_scene_root
		virtual_mm_inst.owner = get_tree().edited_scene_root

	_setup_field_mesh()
	_setup_virtual_particle_mesh()
	_initialize_wave_sources()
	_initialize_field_values()

func _setup_field_mesh() -> void:
	var mm := MultiMesh.new()
	field_mm_inst.multimesh = mm
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true

	# Create sphere mesh for field points
	var sphere := SphereMesh.new()
	sphere.radius = particle_size
	sphere.height = particle_size * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.5
	sphere.material = mat

	mm.mesh = sphere
	mm.instance_count = grid_size_x * grid_size_z

	# Initialize positions
	var k := 0
	for iz in range(grid_size_z):
		for ix in range(grid_size_x):
			var x := (ix - grid_size_x / 2.0) * spacing
			var z := (iz - grid_size_z / 2.0) * spacing

			var transform := Transform3D.IDENTITY
			transform.origin = Vector3(x, 0, z)
			mm.set_instance_transform(k, transform)
			mm.set_instance_color(k, color_low)
			k += 1

func _setup_virtual_particle_mesh() -> void:
	var mm := MultiMesh.new()
	virtual_mm_inst.multimesh = mm
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true

	var sphere := SphereMesh.new()
	sphere.radius = particle_size * 1.5
	sphere.height = particle_size * 3.0

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere.material = mat

	mm.mesh = sphere
	mm.instance_count = int(grid_size_x * grid_size_z * virtual_particle_density)

func _initialize_wave_sources() -> void:
	_wave_sources.clear()
	for i in range(num_wave_sources):
		var angle := TAU * float(i) / float(num_wave_sources)
		var radius: float = float(min(grid_size_x, grid_size_z)) * spacing * 0.3
		_wave_sources.append({
			"position": Vector2(cos(angle) * radius, sin(angle) * radius),
			"phase": randf() * TAU,
			"frequency": source_frequency + randf_range(-0.3, 0.3)
		})

func _initialize_field_values() -> void:
	_field_values.clear()
	_field_values.resize(grid_size_x * grid_size_z)
	for i in range(_field_values.size()):
		_field_values[i] = 0.0

func _update_wave_sources(delta: float) -> void:
	for source in _wave_sources:
		source.phase += delta * source.frequency * TAU

func _update_virtual_particles(delta: float) -> void:
	if not enable_virtual_particles:
		return

	# Update existing particles
	for i in range(_virtual_particles.size() - 1, -1, -1):
		var particle := _virtual_particles[i]
		particle.lifetime -= delta
		if particle.lifetime <= 0:
			_virtual_particles.remove_at(i)

	# Spawn new virtual particle pairs
	var max_particles := int(grid_size_x * grid_size_z * virtual_particle_density)
	while _virtual_particles.size() < max_particles and randf() < virtual_particle_density * delta * 10:
		var x := randf_range(-grid_size_x / 2.0, grid_size_x / 2.0) * spacing
		var z := randf_range(-grid_size_z / 2.0, grid_size_z / 2.0) * spacing

		_virtual_particles.append({
			"position": Vector3(x, 0, z),
			"lifetime": virtual_particle_lifetime,
			"is_antiparticle": false
		})
		_virtual_particles.append({
			"position": Vector3(x, 0, z) + Vector3(randf_range(-0.2, 0.2), 0, randf_range(-0.2, 0.2)),
			"lifetime": virtual_particle_lifetime,
			"is_antiparticle": true
		})

func _update_field() -> void:
	if not field_mm_inst.multimesh:
		return

	var mm := field_mm_inst.multimesh
	var k := 0

	for iz in range(grid_size_z):
		for ix in range(grid_size_x):
			var x := (ix - grid_size_x / 2.0) * spacing
			var z := (iz - grid_size_z / 2.0) * spacing
			var pos := Vector2(x, z)

			# Quantum vacuum fluctuations (noise)
			var noise_value := _get_noise_3d(x, z, _time)
			var field_value := noise_value * vacuum_fluctuation_strength

			# Add wave contributions from sources
			for source in _wave_sources:
				var dist := pos.distance_to(source.position)
				var wave_phase: float = source.phase - dist / wave_speed
				var wave := sin(wave_phase) * wave_amplitude
				wave *= exp(-dist * field_decay / (grid_size_x * spacing))
				field_value += wave

			# Interference and standing waves
			field_value *= 0.5 + 0.5 * sin(_time * 0.5 + pos.length() * 0.3)

			_field_values[k] = field_value

			# Update transform (height displacement)
			var transform := Transform3D.IDENTITY
			transform.origin = Vector3(x, field_value * height_scale, z)

			# Color based on field strength
			var normalized: float = clamp((field_value + wave_amplitude) / (wave_amplitude * 2.0), 0.0, 1.0)
			var color: Color = _get_field_color(normalized)

			mm.set_instance_transform(k, transform)
			mm.set_instance_color(k, color)
			k += 1

	# Update virtual particles
	if enable_virtual_particles:
		_update_virtual_particle_instances()

func _update_virtual_particle_instances() -> void:
	if not virtual_mm_inst.multimesh:
		return

	var mm := virtual_mm_inst.multimesh
	var max_instances := mm.instance_count

	for i in range(min(_virtual_particles.size(), max_instances)):
		var particle := _virtual_particles[i]
		var alpha: float = clamp(particle.lifetime / virtual_particle_lifetime, 0.0, 1.0)

		var transform := Transform3D.IDENTITY
		transform.origin = particle.position
		transform.origin.y = randf_range(-0.3, 0.3)

		var color := Color.WHITE if not particle.is_antiparticle else Color(1, 0.5, 0)
		color.a = alpha * 0.7

		mm.set_instance_transform(i, transform)
		mm.set_instance_color(i, color)

	# Hide unused instances
	for i in range(_virtual_particles.size(), max_instances):
		var transform := Transform3D.IDENTITY
		transform.origin = Vector3(0, -1000, 0)  # Hide far away
		mm.set_instance_transform(i, transform)

func _get_field_color(t: float) -> Color:
	if t < 0.5:
		return color_low.lerp(color_mid, t * 2.0)
	else:
		return color_mid.lerp(color_high, (t - 0.5) * 2.0)

func _get_noise_3d(x: float, z: float, t: float) -> float:
	# Simple pseudo-noise using sine waves
	var freq1 := 0.5
	var freq2 := 1.3
	var freq3 := 2.7

	var n := sin(x * freq1 + t * 0.5) * cos(z * freq1 - t * 0.3)
	n += sin(x * freq2 - t * 0.7) * sin(z * freq2 + t * 0.4) * 0.5
	n += cos(x * freq3 + t * 0.9) * cos(z * freq3 - t * 0.6) * 0.25

	return n / 1.75

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
