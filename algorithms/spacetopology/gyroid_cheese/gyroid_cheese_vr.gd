extends Node3D

# Gyroid Cheese VR - Marching Cubes Edition
# Creates actual mesh geometry using marching cubes algorithm
# Much more reliable and debuggable than ray marching!

# ---------------- Parameters ----------------
@export_group("Field (gyroid)")
@export var frequency: float = 1.2
@export var threshold: float = 0.0
@export var noise_amp: float = 0.15
@export var noise_freq: float = 0.7

@export_group("Volume")
@export var box_size: Vector3 = Vector3(8, 8, 8)
@export var voxel_resolution: Vector3i = Vector3i(40, 40, 40)

@export_group("Visual")
@export var albedo_color: Color = Color(0.85, 0.93, 1.0, 1.0)
@export var rim_color: Color = Color(0.2, 0.6, 1.0, 1.0)
@export var metallic: float = 0.0
@export var roughness: float = 1.0

@export_group("Options")
@export var generate_collision: bool = true
@export var show_wireframe: bool = false
@export var regenerate_mesh: bool = false:
	set(value):
		if value and is_inside_tree() and gyroid_generator != null:
			_regenerate()
			regenerate_mesh = false

# ---------------- Internals ----------------
var gyroid_generator: GyroidFieldGenerator
var gyroid_mesh: MeshInstance3D
var collision_body: StaticBody3D

func _ready() -> void:
	print("=== GYROID CHEESE VR (Marching Cubes) ===")
	_setup_generator()
	_generate_gyroid()
	print("=== INITIALIZATION COMPLETE ===")

func _setup_generator() -> void:
	"""Initialize the gyroid field generator"""
	gyroid_generator = GyroidFieldGenerator.new()

	# Configure parameters
	gyroid_generator.frequency = frequency
	gyroid_generator.threshold = threshold
	gyroid_generator.noise_amp = noise_amp
	gyroid_generator.noise_freq = noise_freq
	gyroid_generator.box_size = box_size
	gyroid_generator.voxel_resolution = voxel_resolution

	print("✓ Gyroid generator configured")
	print("  Frequency: %.2f, Resolution: %s" % [frequency, voxel_resolution])

func _generate_gyroid() -> void:
	"""Generate the gyroid mesh and collision"""
	# Generate mesh using marching cubes
	gyroid_mesh = gyroid_generator.generate_gyroid_mesh(self)

	if gyroid_mesh == null:
		print("✗ Failed to generate gyroid mesh!")
		return

	# Apply visual parameters
	_apply_material()

	# Generate collision if enabled
	if generate_collision:
		collision_body = gyroid_generator.generate_collision(self)

	print("✓ Gyroid mesh generated successfully")

func _apply_material() -> void:
	"""Apply shader material to the gyroid mesh"""
	if gyroid_mesh == null or gyroid_mesh.material_override == null:
		return

	# The shader is already applied by GyroidFieldGenerator
	# We just update the parameters here
	var material := gyroid_mesh.material_override as ShaderMaterial
	if material != null:
		material.set_shader_parameter("base_color", albedo_color)
		material.set_shader_parameter("rim_color", rim_color)
		material.set_shader_parameter("metallic", metallic)
		material.set_shader_parameter("roughness", roughness)

	print("✓ Shader parameters applied")

func _regenerate() -> void:
	"""Regenerate mesh with current parameters"""
	print("Regenerating gyroid mesh...")

	# Update generator parameters
	gyroid_generator.frequency = frequency
	gyroid_generator.threshold = threshold
	gyroid_generator.noise_amp = noise_amp
	gyroid_generator.noise_freq = noise_freq
	gyroid_generator.box_size = box_size
	gyroid_generator.voxel_resolution = voxel_resolution

	# Regenerate
	gyroid_generator.regenerate(self)

	# Get new references
	gyroid_mesh = gyroid_generator.gyroid_mesh
	collision_body = gyroid_generator.collision_body

	# Apply material
	_apply_material()

	print("✓ Regeneration complete")

# ---------------- Public API ----------------
func set_box_size(new_size: Vector3) -> void:
	"""Set the size of the gyroid volume"""
	box_size = new_size
	if gyroid_generator != null:
		gyroid_generator.box_size = new_size

func set_frequency(f: float) -> void:
	frequency = f
	if gyroid_generator != null:
		gyroid_generator.frequency = f

func set_threshold(t: float) -> void:
	threshold = t
	if gyroid_generator != null:
		gyroid_generator.threshold = t

func set_noise_amplitude(a: float) -> void:
	noise_amp = a
	if gyroid_generator != null:
		gyroid_generator.noise_amp = a
