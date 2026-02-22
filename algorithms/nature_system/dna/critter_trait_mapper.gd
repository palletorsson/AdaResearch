# CritterTraitMapper.gd — Bridge between CritterDNA and shader materials
#
# Takes a CritterDNA Resource and applies its genes as shader parameters
# to a ShaderMaterial. Handles kingdom-specific interpretation, per-instance
# variation, and bond/transmutation overlays.
#
# Adapted from queerbreader's DNATraitMapper.gd but works directly with
# typed CritterDNA Resources instead of gene dictionaries.

class_name CritterTraitMapper
extends RefCounted

var _shader: Shader = null

## Standard shader path — will evolve into critter_dna.gdshader
const DEFAULT_SHADER_PATH := "res://algorithms/nature_system/shaders/critter_dna.gdshader"


func _init(shader_path: String = DEFAULT_SHADER_PATH) -> void:
	if ResourceLoader.exists(shader_path):
		_shader = load(shader_path)
		if not _shader is Shader:
			push_error("[CritterTraitMapper] Loaded resource is not a Shader: ", shader_path)
			_shader = null
	else:
		push_warning("[CritterTraitMapper] Shader not found at: %s — materials will be created without shader" % shader_path)


## Create a new ShaderMaterial bound to the DNA shader.
func create_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	if _shader:
		mat.shader = _shader
	return mat


## Create a material and immediately apply a CritterDNA to it.
func create_material_from_dna(dna: CritterDNA, instance_seed: int = 0) -> ShaderMaterial:
	var mat := create_material()
	apply_dna(mat, dna, instance_seed)
	return mat


# ═══════════════════════════════════════════════════════════════
# MAIN PIPELINE: CritterDNA → ShaderMaterial
# ═══════════════════════════════════════════════════════════════

## Apply all genes from a CritterDNA to a ShaderMaterial.
## instance_seed provides per-mesh variation (pass mesh index or instance ID).
func apply_dna(material: ShaderMaterial, dna: CritterDNA, instance_seed: int = 0) -> void:
	if not material:
		push_error("[CritterTraitMapper] Null material")
		return

	_apply_colors(material, dna, instance_seed)
	_apply_pattern(material, dna, instance_seed)
	_apply_surface(material, dna)
	_apply_animation(material, dna)
	_apply_effects(material, dna)


## Apply bond-level visual overlay (transmutation progression).
func apply_bond_overlay(material: ShaderMaterial, dna: CritterDNA, bond_level: float) -> void:
	if not material:
		return

	# Bond glow — subtle at low levels, dramatic near transmutation
	var emission_boost := bond_level * 0.5
	var rim_strength := bond_level * bond_level  # Quadratic — ramps up fast near 1.0
	var crack_boost := maxf(bond_level - 0.6, 0.0) * 2.5  # Only at high bond

	material.set_shader_parameter("emission_energy", emission_boost)
	material.set_shader_parameter("rim_light", rim_strength)

	# Metamorphosis cracking at high bond
	var base_cracking: float = dna.cracking
	material.set_shader_parameter("cracking", minf(base_cracking + crack_boost, 1.0))

	# Iridescence increases with bond — the creature "shimmers" as it changes
	var base_iridescence: float = dna.iridescence
	material.set_shader_parameter("iridescence", minf(base_iridescence + bond_level * 0.4, 1.0))


## Apply per-instance biological variation (color drift, pattern rotation).
## Call this AFTER apply_dna() to add uniqueness between meshes/petals/branches.
func apply_variation(material: ShaderMaterial, variation_seed: int) -> void:
	if not material:
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = variation_seed

	# Slight color drift
	var color = material.get_shader_parameter("primary_color")
	if color is Color:
		material.set_shader_parameter("primary_color", Color(
			clampf(color.r + rng.randf_range(-0.04, 0.04), 0.0, 1.0),
			clampf(color.g + rng.randf_range(-0.04, 0.04), 0.0, 1.0),
			clampf(color.b + rng.randf_range(-0.04, 0.04), 0.0, 1.0),
			color.a
		))

	# Random pattern rotation per instance
	material.set_shader_parameter("pattern_rotation", rng.randf_range(0.0, TAU))

	# Slight pattern scale jitter
	var base_scale = material.get_shader_parameter("pattern_scale")
	if base_scale is float:
		material.set_shader_parameter("pattern_scale",
			clampf(base_scale + rng.randf_range(-0.08, 0.08), 0.3, 3.0))


# ═══════════════════════════════════════════════════════════════
# INTERNAL — Per-domain shader parameter application
# ═══════════════════════════════════════════════════════════════

func _apply_colors(material: ShaderMaterial, dna: CritterDNA, instance_seed: int) -> void:
	# Direct color mapping — no encoding step
	material.set_shader_parameter("primary_color", dna.primary_color)
	material.set_shader_parameter("secondary_color", dna.secondary_color)
	material.set_shader_parameter("wing_color", dna.tertiary_color)

	# If colors are near-black (uninitialized), generate from seed
	if dna.primary_color.get_luminance() < 0.05:
		var rng := RandomNumberGenerator.new()
		rng.seed = instance_seed if instance_seed > 0 else randi()
		material.set_shader_parameter("primary_color", Color(
			rng.randf_range(0.3, 1.0),
			rng.randf_range(0.3, 1.0),
			rng.randf_range(0.3, 1.0)
		))


func _apply_pattern(material: ShaderMaterial, dna: CritterDNA, instance_seed: int) -> void:
	# pattern_type is already 0-1, maps directly to shader's 20-type interpolation
	material.set_shader_parameter("pattern_type", dna.pattern_type)
	material.set_shader_parameter("pattern_density", dna.pattern_density)
	material.set_shader_parameter("pattern_scale", dna.pattern_scale)
	material.set_shader_parameter("pattern_intensity", 0.8)  # Sane default

	# Per-instance pattern rotation
	var rng := RandomNumberGenerator.new()
	rng.seed = instance_seed if instance_seed > 0 else randi()
	material.set_shader_parameter("pattern_rotation", rng.randf_range(0.0, TAU))


func _apply_surface(material: ShaderMaterial, dna: CritterDNA) -> void:
	material.set_shader_parameter("roughness", dna.roughness)
	material.set_shader_parameter("metallic", dna.metallic)
	material.set_shader_parameter("iridescence", dna.iridescence)
	material.set_shader_parameter("transparency", dna.transparency)
	material.set_shader_parameter("cracking", dna.cracking)


func _apply_animation(material: ShaderMaterial, dna: CritterDNA) -> void:
	# Animation parameters are driven by behavior genes, interpreted per kingdom
	var kingdom := dna.get_kingdom()
	var wave_intensity := 0.0
	var wave_amplitude := 0.0
	var wave_frequency := 0.0
	var wave_speed := 0.0

	match kingdom:
		0:  # Tree — wind sway from leaf_density (more leaves = more sway)
			wave_intensity = dna.leaf_density * 0.15
			wave_amplitude = 0.08
			wave_frequency = 1.5
			wave_speed = 0.8

		1:  # Creature — body undulation from mobility
			wave_intensity = dna.mobility * 0.2
			wave_amplitude = 0.05
			wave_frequency = 8.0 + dna.mobility * 8.0
			wave_speed = 2.0 + dna.mobility * 3.0

		2:  # Flower — gentle sway from scent_strength
			wave_intensity = dna.scent_strength * 0.25
			wave_amplitude = 0.04
			wave_frequency = 1.2
			wave_speed = 0.6

		3:  # Fungus — subtle pulse from sociality (spore release)
			wave_intensity = dna.sociality * 0.1
			wave_amplitude = 0.02
			wave_frequency = 2.0
			wave_speed = 0.4

		_:  # Hybrid — blend
			wave_intensity = (dna.mobility + dna.scent_strength) * 0.1
			wave_amplitude = 0.04
			wave_frequency = 3.0
			wave_speed = 1.0

	material.set_shader_parameter("wave_intensity", wave_intensity)
	material.set_shader_parameter("wave_amplitude", wave_amplitude)
	material.set_shader_parameter("wave_frequency", wave_frequency)
	material.set_shader_parameter("wave_speed", wave_speed)


func _apply_effects(material: ShaderMaterial, dna: CritterDNA) -> void:
	# Effect flags packed as Vector4:
	# x = edge_detection   — driven by pattern_density
	# y = cellular_influence — driven by pattern_type (voronoi emphasis)
	# z = darkness          — driven by energy_source (deep cave = dark)
	# w = color_mixing      — driven by sociality (social = more color blend)

	var edge_detect := clampf(dna.pattern_density, 0.1, 0.8)
	var cellular := clampf(dna.pattern_type * 0.5, 0.1, 0.7)
	var darkness := clampf(0.35 + (dna.energy_source - 1.5) * 0.2, 0.1, 0.7)
	var color_mix := clampf(dna.sociality, 0.2, 0.8)

	material.set_shader_parameter("effect_flags", Vector4(
		edge_detect, cellular, darkness, color_mix
	))

	# Detail/LOD level — can be driven externally by distance to player
	material.set_shader_parameter("detail_level", 1.0)
