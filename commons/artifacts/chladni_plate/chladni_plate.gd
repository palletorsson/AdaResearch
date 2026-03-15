# chladni_plate.gd
# Chladni plate - vibrating plate with particles showing nodal patterns
# Sand/particles migrate to nodal lines where the plate doesn't vibrate
# Classic demonstration of standing wave modes
extends Node3D

class_name ChladniPlate

## Plate parameters
@export var plate_size: float = 0.3  # Square plate side length
@export var plate_thickness: float = 0.005

## Particle parameters
@export var num_particles: int = 400
@export var particle_size: float = 0.003
@export var particle_speed: float = 0.5
@export var particle_color: Color = Color(0.9, 0.85, 0.7)  # Sand color

## Vibration parameters
@export var mode_n: int = 2  # Mode number (horizontal)
@export var mode_m: int = 3  # Mode number (vertical)
@export var vibration_frequency: float = 1.0
@export var vibration_amplitude: float = 0.002
@export var auto_cycle_modes: bool = true
@export var mode_cycle_time: float = 8.0

## Visual
@export var base_color: Color = Color(0.15, 0.15, 0.18)
@export var plate_color: Color = Color(0.7, 0.7, 0.75)

## Internal
var particles: Array[Dictionary] = []
var _multimesh_instance: MultiMeshInstance3D
var _multimesh: MultiMesh
var time: float = 0.0
var mode_timer: float = 0.0
var current_mode_index: int = 0

# Classic Chladni mode pairs that produce nice patterns
var mode_pairs: Array = [
	[2, 3], [3, 4], [4, 5], [2, 5], [3, 5],
	[1, 2], [2, 4], [3, 3], [4, 4], [5, 5]
]

@onready var plate: MeshInstance3D = $Plate
@onready var base: MeshInstance3D = $Base
@onready var particle_container: Node3D = $ParticleContainer
@onready var label: Label3D = $Label

func _ready() -> void:
	_setup_materials()
	_spawn_particles()
	_update_label()

func _setup_materials() -> void:
	# Plate material (metal)
	if plate:
		var plate_mat = StandardMaterial3D.new()
		plate_mat.albedo_color = plate_color
		plate_mat.metallic = 0.8
		plate_mat.roughness = 0.3
		plate.material_override = plate_mat
	
	# Base material
	if base:
		var base_mat = StandardMaterial3D.new()
		base_mat.albedo_color = base_color
		base_mat.metallic = 0.6
		base_mat.roughness = 0.4
		base.material_override = base_mat

func _spawn_particles() -> void:
	if not particle_container:
		particle_container = Node3D.new()
		particle_container.name = "ParticleContainer"
		add_child(particle_container)
	
	var particle_mat = StandardMaterial3D.new()
	particle_mat.albedo_color = particle_color
	particle_mat.roughness = 0.9
	
	var particle_mesh = SphereMesh.new()
	particle_mesh.radius = particle_size
	particle_mesh.height = particle_size * 2
	particle_mesh.radial_segments = 6
	particle_mesh.rings = 3
	
	# Create MultiMesh
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.instance_count = num_particles
	_multimesh.mesh = particle_mesh
	
	# Create MultiMeshInstance3D
	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.multimesh = _multimesh
	_multimesh_instance.material_override = particle_mat
	particle_container.add_child(_multimesh_instance)
	
	for i in range(num_particles):
		# Random starting position on plate
		var x = randf_range(-plate_size/2, plate_size/2)
		var z = randf_range(-plate_size/2, plate_size/2)
		
		var particle_data = {
			"position": Vector3(x, plate_thickness/2 + particle_size, z),
			"velocity": Vector3.ZERO
		}
		particles.append(particle_data)
		
		_multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, particle_data.position))

func _process(delta: float) -> void:
	time += delta
	
	# Auto-cycle through modes
	if auto_cycle_modes:
		mode_timer += delta
		if mode_timer > mode_cycle_time:
			mode_timer = 0.0
			current_mode_index = (current_mode_index + 1) % mode_pairs.size()
			var new_mode = mode_pairs[current_mode_index]
			mode_n = new_mode[0]
			mode_m = new_mode[1]
			_update_label()
	
	# Update all particles
	for i in range(particles.size()):
		_update_particle(i, delta)
		_multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, particles[i].position))
	
	# Vibrate the plate visually
	if plate:
		plate.position.y = sin(time * vibration_frequency * TAU * 10) * vibration_amplitude

func _update_particle(index: int, delta: float) -> void:
	var p = particles[index]
	var pos = p.position
	
	# Normalize position to -1 to 1 range for Chladni calculation
	var nx = pos.x / (plate_size / 2)
	var nz = pos.z / (plate_size / 2)
	
	# Chladni pattern: amplitude at this point
	# Classic formula: cos(n*pi*x)*cos(m*pi*y) - cos(m*pi*x)*cos(n*pi*y)
	var amplitude = _chladni_amplitude(nx, nz)
	
	# Gradient of the Chladni function (particles move toward nodal lines where amplitude = 0)
	var grad = _chladni_gradient(nx, nz)
	
	# Move toward nodal lines (where amplitude is zero)
	# The force is proportional to amplitude and points toward zero
	var force = -grad * abs(amplitude) * particle_speed
	
	# Add some random jitter (vibration)
	var jitter = Vector3(
		randf_range(-1, 1),
		0,
		randf_range(-1, 1)
	) * 0.02 * abs(_chladni_amplitude(nx, nz))
	
	# Update velocity with damping
	p.velocity = p.velocity * 0.9 + (force + jitter) * delta
	
	# Update position
	p.position += p.velocity * delta
	
	# Keep on plate
	p.position.x = clamp(p.position.x, -plate_size/2 + particle_size, plate_size/2 - particle_size)
	p.position.z = clamp(p.position.z, -plate_size/2 + particle_size, plate_size/2 - particle_size)
	p.position.y = plate_thickness/2 + particle_size

func _chladni_amplitude(x: float, y: float) -> float:
	# Chladni pattern equation
	var n = mode_n * PI
	var m = mode_m * PI
	return cos(n * x) * cos(m * y) - cos(m * x) * cos(n * y)

func _chladni_gradient(x: float, y: float) -> Vector3:
	# Numerical gradient of Chladni function
	var eps = 0.01
	var dx = (_chladni_amplitude(x + eps, y) - _chladni_amplitude(x - eps, y)) / (2 * eps)
	var dy = (_chladni_amplitude(x, y + eps) - _chladni_amplitude(x, y - eps)) / (2 * eps)
	
	# Convert back to world scale
	return Vector3(dx, 0, dy) * (2.0 / plate_size)

func _update_label() -> void:
	if label:
		label.text = "CHLADNI PLATE\nMode (%d, %d)" % [mode_n, mode_m]

func set_mode(n: int, m: int) -> void:
	mode_n = n
	mode_m = m
	_update_label()

# Config parsing for map placement
func apply_config(config: Dictionary) -> void:
	if config.has("mode_n"):
		mode_n = int(config.mode_n)
	if config.has("mode_m"):
		mode_m = int(config.mode_m)
	if config.has("auto_cycle"):
		auto_cycle_modes = config.auto_cycle == "true" or config.auto_cycle == "1"
	if config.has("particles"):
		num_particles = int(config.particles)
	_update_label()

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
