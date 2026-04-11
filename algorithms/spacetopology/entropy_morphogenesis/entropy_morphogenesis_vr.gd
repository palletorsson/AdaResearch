extends Node3D

# @identity
# essence: entropy parameter S in [0,1] maps to gyroid field parameters — frequency = lerp(0.9, 1.6, S), noise_amp = lerp(0.05, 0.20, S), threshold = center + wobble*(S-0.5)*2 — then marching cubes generates the mesh
# desire: to turn a single entropy slider and watch a gyroid surface crumple from smooth order into noisy complexity — morphogenesis as a function of one number
# critical_parameter: S (entropy) — at S=0 the gyroid is smooth and periodic, at S=1 noise disrupts the field and the surface fragments into chaotic topology
# triggers: setting S (via set_entropy or export) recomputes frequency, noise_amp, and threshold; regenerate_at_entropy triggers marching cubes mesh rebuild
# emerges: the gyroid's triply-periodic minimal surface creates passages and chambers that open and close as entropy changes, producing architecture from pure mathematics
# needs: slider_horizontal [missing]; push_button [missing]; Label3D [missing]
# relationships: synthesis of softbodies sequence — entropy becoming form; depends on GyroidFieldGenerator for marching cubes mesh generation
# truth: morphogenesis is not construction — it is what happens when entropy finds a threshold where disorder crystallizes into structure

# Entropy Morphogenesis VR - Marching Cubes Edition
# Entropy S(t) drives the morphological parameters of the gyroid
# Creates actual mesh geometry at a specific entropy state

# ---------------- Parameters (Entropy Engine) ----------------
@export_group("Entropy (S) & Morphology")
@export var S: float = 0.3:
	set(value):
		S = clamp(value, 0.0, 1.0)
		if is_inside_tree() and gyroid_generator != null:
			_update_from_entropy()

@export_subgroup("Field Mapping from Entropy")
@export var base_frequency: float = 0.9
@export var high_frequency: float = 1.6
@export var base_noise_amp: float = 0.05
@export var high_noise_amp: float = 0.20
@export var threshold_center: float = 0.0
@export var threshold_wobble: float = 0.15

@export_group("Volume")
@export var box_size: Vector3 = Vector3(8, 8, 8)
@export var voxel_resolution: Vector3i = Vector3i(40, 40, 40)

@export_group("Visual")
@export var base_color: Color = Color(0.85, 0.93, 1.0, 1.0)
@export var rim_color: Color = Color(0.2, 0.6, 1.0, 1.0)
@export var metallic: float = 0.0
@export var roughness: float = 1.0

@export_group("Options")
@export var generate_collision: bool = true
@export var show_wireframe: bool = false
@export var regenerate_at_entropy: bool = false:
	set(value):
		if value and is_inside_tree() and gyroid_generator != null:
			_regenerate()
			regenerate_at_entropy = false

# ---------------- Internals ----------------
var gyroid_generator: GyroidFieldGenerator
var gyroid_mesh: MeshInstance3D
var collision_body: StaticBody3D

# Entropy-mapped parameters (computed from S)
var current_frequency: float
var current_noise_amp: float
var current_threshold: float

func _ready() -> void:
	print("=== ENTROPY MORPHOGENESIS VR (Marching Cubes) ===")
	print("  Entropy S = %.3f" % S)
	_update_from_entropy()
	_setup_generator()
	_generate_gyroid()
	print("=== INITIALIZATION COMPLETE ===")

func _update_from_entropy() -> void:
	"""Map entropy S to field parameters"""
	current_frequency = lerpf(base_frequency, high_frequency, S)
	current_noise_amp = lerpf(base_noise_amp, high_noise_amp, S)
	current_threshold = threshold_center + threshold_wobble * (S - 0.5) * 2.0

func _setup_generator() -> void:
	"""Initialize the gyroid field generator with entropy-mapped parameters"""
	gyroid_generator = GyroidFieldGenerator.new()

	# Configure with entropy-driven parameters
	gyroid_generator.frequency = current_frequency
	gyroid_generator.threshold = current_threshold
	gyroid_generator.noise_amp = current_noise_amp
	gyroid_generator.noise_freq = 0.7
	gyroid_generator.box_size = box_size
	gyroid_generator.voxel_resolution = voxel_resolution

	print("✓ Gyroid generator configured")
	print("  S=%.2f → Freq:%.2f, Noise:%.3f, Threshold:%.2f" % [S, current_frequency, current_noise_amp, current_threshold])

func _generate_gyroid() -> void:
	"""Generate the gyroid mesh at current entropy state"""
	print("Generating gyroid at entropy S=%.3f..." % S)

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

	print("✓ Entropy morphology generated successfully")
	print("  This is the structure's form at S=%.3f" % S)
	print("  Adjust S and regenerate to see different morphological states")

func _apply_material() -> void:
	"""Apply shader material with entropy-influenced colors"""
	if gyroid_mesh == null or gyroid_mesh.material_override == null:
		return

	# The shader is already applied by GyroidFieldGenerator
	# We just update the parameters here
	var material := gyroid_mesh.material_override as ShaderMaterial
	if material != null:
		material.set_shader_parameter("base_color", base_color)
		material.set_shader_parameter("rim_color", rim_color)
		material.set_shader_parameter("metallic", metallic)
		material.set_shader_parameter("roughness", roughness)

	print("✓ Shader parameters applied")

func _regenerate() -> void:
	"""Regenerate mesh with new entropy state"""
	print("=== REGENERATING AT NEW ENTROPY STATE ===")
	print("  S = %.3f" % S)

	_update_from_entropy()

	# Update generator parameters
	gyroid_generator.frequency = current_frequency
	gyroid_generator.threshold = current_threshold
	gyroid_generator.noise_amp = current_noise_amp
	gyroid_generator.box_size = box_size
	gyroid_generator.voxel_resolution = voxel_resolution

	# Regenerate
	gyroid_generator.regenerate(self)

	# Get new references
	gyroid_mesh = gyroid_generator.gyroid_mesh
	collision_body = gyroid_generator.collision_body

	# Apply material
	_apply_material()

	print("✓ Morphological transformation complete")
	print("  New state: Freq:%.2f, Noise:%.3f, Threshold:%.2f" % [current_frequency, current_noise_amp, current_threshold])

# ---------------- Public API ----------------
func set_box_size(new_size: Vector3) -> void:
	"""Set the size of the gyroid volume"""
	box_size = new_size
	if gyroid_generator != null:
		gyroid_generator.box_size = new_size

func set_entropy(new_S: float) -> void:
	"""Set entropy and update parameters (call regenerate_at_entropy to rebuild mesh)"""
	S = clamp(new_S, 0.0, 1.0)

func get_entropy() -> float:
	return S

func regenerate_now() -> void:
	"""Manually trigger regeneration at current entropy"""
	_regenerate()

func apply_grid_config(config: Dictionary) -> void:
	pass
