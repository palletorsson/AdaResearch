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

# --- DNA (stage 2 - variation), promoted 2026-08-03 -------------------------
#
# WHAT WAS ALREADY HERE AND WHAT NOBODY COULD REACH. This artifact has had a
# clean parameter space since the day it was written — S in [0,1] driving
# frequency, noise amplitude and threshold, and a `set_entropy()` that says so
# in its own docstring. And `apply_grid_config()` was `pass`. Every knob was
# exported to the inspector and NONE of them was reachable from a map token, so
# all 7 placements (Topology_Entropy_Morphogenesis and its _p1.._p3,
# Corridor_Topology_..., Morphogenesis_Intro, Curation_Bay_softbodies_4) render
# the same gyroid at the same S. The promotion is mostly a matter of opening
# the door that was already built.
#
# AXIS 1 - FOUND_STATE: which state of the second law you are standing in front
# of. Borrowed word for word from [[entropy_jar]] in this same curriculum,
# which asks exactly this question of a mixture instead of a form. Three of its
# four values mean the same thing here and are taken unchanged:
#
#   sorted   S = 0.0. The crystal. Frequency at its floor, noise at 0.05, the
#            triply-periodic surface legible cell by cell. Nothing has happened.
#   stirred  SHIPPED (S = 0.3, whatever the scene loads). Noise is present and
#            the periodicity still reads through it. Mid-sentence.
#   mixed    S = 1.0. Frequency 1.6, noise 0.20, the sheets crumple and the
#            passages stop lining up. You arrived after the arrow ran.
#
# entropy_jar's fourth value, `shelled`, is NOT taken. There it is a joke about
# the jar's own instrument — order that is real and that the vertical binning
# cannot see. This artifact has no instrument to fool: it reports nothing, it
# only IS a shape. Borrowing the word would claim a comparability that does not
# exist, so the list is an honest subset and the three shared values measure the
# same question.
#
# AXIS 2 - LEVEL: where the surface is cut through the field. The truth line at
# the top of this file says morphogenesis is what happens "when entropy finds a
# THRESHOLD where disorder crystallizes into structure" — and that threshold has
# been nailed to 0.0 in every placement, the one level at which a gyroid is a
# minimal surface and its two labyrinths are congruent. Move it and the claim
# changes: the same field, the same entropy, a different structure.
#
#   minimal    0.00  SHIPPED. Balanced. Half solid, half void, both labyrinths
#                    connected. The triply-periodic MINIMAL surface proper.
#   thickened -0.60  The solid phase swells to roughly three quarters. What was
#                    a membrane becomes a block pierced by narrow tunnels.
#   pinched   +0.60  The solid retreats to about a quarter: thin struts, wide
#                    channels, still one connected labyrinth.
#   broken    +0.95  Past the percolation point. The labyrinth is no longer a
#                    labyrinth — it is isolated pockets. The topology breaks
#                    without the entropy changing at all, which is the whole
#                    argument: structure is a fact about where you cut.
#
# BOTH DEFAULTS ARE NO-OPS. `stirred` and `minimal` assign nothing whatsoever;
# they fall through to `_:` and leave S and threshold_center exactly as the
# scene loaded them. The 7 existing placements are byte-identical to before.
#
# NOT declared, deliberately: box_size and voxel_resolution are size and budget,
# not argument; base_color/rim_color/metallic/roughness are livery; and
# `regenerate_at_entropy` is an inspector button, not a state.
#
# FIELD_SEED is a fixture knob, not an axis. GyroidFieldGenerator does
# `noise.seed = randi()`, so every gyroid in the corpus is genuinely a different
# gyroid — correct in a map, fatal on the bench, where five variants would be
# five different objects. 0 keeps the shipped randi(); any non-zero pins it.

const FOUND_STATES: PackedStringArray = ["sorted", "stirred", "mixed"]
const LEVELS: PackedStringArray = ["minimal", "thickened", "pinched", "broken"]

@export_enum("sorted", "stirred", "mixed") var found_state: String = "stirred"
@export_enum("minimal", "thickened", "pinched", "broken") var level: String = "minimal"
@export var field_seed: int = 0

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

# True once _ready has built a gyroid once. apply_grid_config must never
# regenerate before there is something to regenerate.
var _built: bool = false


## AXIS 1. Writes S, and only for a value that is not the shipped one. The `_:`
## branch is `stirred` and it assigns NOTHING — the scene's own S survives.
func _apply_found_state() -> void:
	match found_state:
		"sorted":
			S = 0.0
		"mixed":
			S = 1.0
		_:
			pass


## AXIS 2. Where the field is cut. Same rule: `minimal` writes nothing, so a
## placement that never hears about this axis keeps threshold_center at 0.0.
func _apply_level() -> void:
	match level:
		"thickened":
			threshold_center = -0.60
		"pinched":
			threshold_center = 0.60
		"broken":
			threshold_center = 0.95
		_:
			pass


func _ready() -> void:
	print("=== ENTROPY MORPHOGENESIS VR (Marching Cubes) ===")
	_apply_found_state()
	_apply_level()
	print("  Entropy S = %.3f" % S)
	_update_from_entropy()
	_setup_generator()
	_generate_gyroid()
	_built = true
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

	# 0 leaves the generator's own `noise.seed = randi()` alone — the shipped
	# behaviour, one unrepeatable gyroid per placement.
	if field_seed != 0 and gyroid_generator.noise != null:
		gyroid_generator.noise.seed = field_seed

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

## Map/bench entry point. Until 2026-08-03 this was `pass`, so no map token had
## ever reached a single one of the exports above.
##
## THE GUARD THAT MATTERS. Regenerating unconditionally here would rebuild a
## 40x40x40 marching-cubes volume in all 7 shipped placements — and, because the
## generator reseeds its noise on nothing, would hand them a DIFFERENT gyroid
## than the one they had. Act only when a declared value actually moved, and
## only once _ready has built a mesh to replace.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return

	var restate: bool = false

	if config.has("found_state"):
		var v: String = str(config["found_state"]).strip_edges().to_lower()
		if FOUND_STATES.has(v) and v != found_state:
			found_state = v
			restate = true

	if config.has("level"):
		var l: String = str(config["level"]).strip_edges().to_lower()
		if LEVELS.has(l) and l != level:
			level = l
			restate = true

	if config.has("field_seed"):
		var sd: int = int(config["field_seed"])
		if sd != field_seed:
			field_seed = sd
			restate = true

	if not restate or not _built:
		return

	_apply_found_state()
	_apply_level()
	if field_seed != 0 and gyroid_generator != null and gyroid_generator.noise != null:
		gyroid_generator.noise.seed = field_seed
	_regenerate()
