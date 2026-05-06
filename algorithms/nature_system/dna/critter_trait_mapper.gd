# CritterTraitMapper.gd — Bridge between CritterDNA and shader materials
#
# Maps DNA genes to shader parameters with per-part interpretation.
# Different body parts (trunk, leaves, limbs, petals, caps) get different
# pattern remapping and surface types from the same DNA, creating visual
# diversity within a single organism.

class_name CritterTraitMapper
extends RefCounted

var _shader: Shader = null

const DEFAULT_SHADER_PATH := "res://algorithms/nature_system/shaders/critter_dna.gdshader"

## Part types — each interprets DNA genes differently
enum PartType {
	GENERIC,     ## Default — standard DNA mapping
	TRUNK,       ## Tree trunk, flower stem, fungus stem — bark-like
	FOLIAGE,     ## Tree leaves, flower petals — organic, iridescent
	LIMB,        ## Creature legs, branches — scale-like
	HEAD,        ## Creature head, fungus cap — cellular
	ROOT,        ## Tree roots, creature feet — cracked
	DECORATION,  ## Hybrid decoration — membrane
}

## Surface type indices matching shader: 0=bark, 1=scales, 2=petal, 3=membrane, 4=fur
const SURFACE_BARK: float = 0.0
const SURFACE_SCALES: float = 1.0
const SURFACE_PETAL: float = 2.0
const SURFACE_MEMBRANE: float = 3.0
const SURFACE_FUR: float = 4.0

## Pattern offset per part type — shifts pattern_type to a different region
## so trunk gets crystal/edges while leaves get dots/waves from the same DNA
const PART_PATTERN_OFFSETS: Dictionary = {
	PartType.GENERIC: 0.0,
	PartType.TRUNK: 0.85,     # Crystal + edges region (patterns 16-19)
	PartType.FOLIAGE: 0.0,    # Dots + waves region (patterns 0-5)
	PartType.LIMB: 0.6,       # Hexagons + fragments region (patterns 11-13)
	PartType.HEAD: 0.25,      # Voronoi + blobs region (patterns 5-7)
	PartType.ROOT: 0.7,       # Stitching + tartan region (patterns 13-15)
	PartType.DECORATION: 0.4, # Fractal + noise region (patterns 7-9)
}

## Surface type per part + kingdom
## kingdom_int → { PartType → surface_type_float }
const KINGDOM_SURFACE_MAP: Dictionary = {
	0: {  # Tree
		PartType.GENERIC: SURFACE_BARK,
		PartType.TRUNK: SURFACE_BARK,
		PartType.FOLIAGE: SURFACE_PETAL,
		PartType.LIMB: SURFACE_BARK,
		PartType.ROOT: SURFACE_BARK,
	},
	1: {  # Creature
		PartType.GENERIC: SURFACE_SCALES,
		PartType.TRUNK: SURFACE_SCALES,
		PartType.LIMB: SURFACE_SCALES,
		PartType.HEAD: SURFACE_FUR,
		PartType.ROOT: SURFACE_SCALES,
	},
	2: {  # Flower
		PartType.GENERIC: SURFACE_PETAL,
		PartType.TRUNK: SURFACE_BARK,
		PartType.FOLIAGE: SURFACE_PETAL,
		PartType.HEAD: SURFACE_PETAL,
	},
	3: {  # Fungus
		PartType.GENERIC: SURFACE_MEMBRANE,
		PartType.TRUNK: SURFACE_BARK,
		PartType.HEAD: SURFACE_MEMBRANE,
		PartType.FOLIAGE: SURFACE_MEMBRANE,
	},
	4: {  # Hybrid
		PartType.GENERIC: SURFACE_MEMBRANE,
		PartType.DECORATION: SURFACE_MEMBRANE,
	},
}


func _init(shader_path: String = DEFAULT_SHADER_PATH) -> void:
	if ResourceLoader.exists(shader_path):
		_shader = load(shader_path)
		if not _shader is Shader:
			push_error("[CritterTraitMapper] Loaded resource is not a Shader: ", shader_path)
			_shader = null
	else:
		push_warning("[CritterTraitMapper] Shader not found at: %s" % shader_path)


func create_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	if _shader:
		mat.shader = _shader
	return mat


## Create a material with standard DNA mapping (no part specialization).
func create_material_from_dna(dna: CritterDNA, instance_seed: int = 0) -> ShaderMaterial:
	var mat := create_material()
	apply_dna(mat, dna, instance_seed)
	return mat


## Create a material with per-part interpretation.
## Different part types get different pattern offsets and surface types.
func create_part_material(dna: CritterDNA, part_type: int, instance_seed: int = 0) -> ShaderMaterial:
	var mat := create_material()
	apply_dna_for_part(mat, dna, part_type, instance_seed)
	return mat


# ═══════════════════════════════════════════════════════════════
# MAIN PIPELINE: CritterDNA → ShaderMaterial
# ═══════════════════════════════════════════════════════════════

## Apply all genes with standard mapping (backward compatible).
func apply_dna(material: ShaderMaterial, dna: CritterDNA, instance_seed: int = 0) -> void:
	if not material:
		return
	_apply_colors(material, dna, instance_seed)
	_apply_pattern(material, dna, instance_seed, PartType.GENERIC)
	_apply_surface(material, dna, PartType.GENERIC)
	_apply_animation(material, dna)
	_apply_effects(material, dna)


## Apply genes with per-part interpretation.
func apply_dna_for_part(material: ShaderMaterial, dna: CritterDNA, part_type: int, instance_seed: int = 0) -> void:
	if not material:
		return
	_apply_colors(material, dna, instance_seed)
	_apply_pattern(material, dna, instance_seed, part_type)
	_apply_surface(material, dna, part_type)
	_apply_animation(material, dna)
	_apply_effects(material, dna)


## Apply bond-level visual overlay.
func apply_bond_overlay(material: ShaderMaterial, dna: CritterDNA, bond_level: float) -> void:
	if not material:
		return
	material.set_shader_parameter("emission_energy", bond_level * 0.5)
	material.set_shader_parameter("rim_light", bond_level * bond_level)
	var crack_boost := maxf(bond_level - 0.6, 0.0) * 2.5
	material.set_shader_parameter("cracking", minf(dna.cracking + crack_boost, 1.0))
	material.set_shader_parameter("iridescence", minf(dna.iridescence + bond_level * 0.4, 1.0))


## Per-instance variation (color drift, pattern rotation).
func apply_variation(material: ShaderMaterial, variation_seed: int) -> void:
	if not material:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = variation_seed

	var color = material.get_shader_parameter("primary_color")
	if color is Color:
		material.set_shader_parameter("primary_color", Color(
			clampf(color.r + rng.randf_range(-0.06, 0.06), 0.0, 1.0),
			clampf(color.g + rng.randf_range(-0.06, 0.06), 0.0, 1.0),
			clampf(color.b + rng.randf_range(-0.06, 0.06), 0.0, 1.0),
			color.a
		))

	material.set_shader_parameter("pattern_rotation", rng.randf_range(0.0, TAU))

	var base_scale = material.get_shader_parameter("pattern_scale")
	if base_scale is float:
		material.set_shader_parameter("pattern_scale",
			clampf(base_scale + rng.randf_range(-0.15, 0.15), 0.3, 3.0))


# ═══════════════════════════════════════════════════════════════
# INTERNAL — Per-domain shader parameter application
# ═══════════════════════════════════════════════════════════════

func _apply_colors(material: ShaderMaterial, dna: CritterDNA, instance_seed: int) -> void:
	material.set_shader_parameter("primary_color", dna.primary_color)
	material.set_shader_parameter("secondary_color", dna.secondary_color)
	material.set_shader_parameter("wing_color", dna.tertiary_color)

	if dna.primary_color.get_luminance() < 0.05:
		var rng := RandomNumberGenerator.new()
		rng.seed = instance_seed if instance_seed > 0 else randi()
		material.set_shader_parameter("primary_color", Color(
			rng.randf_range(0.3, 1.0), rng.randf_range(0.3, 1.0), rng.randf_range(0.3, 1.0)
		))


func _apply_pattern(material: ShaderMaterial, dna: CritterDNA, instance_seed: int, part_type: int) -> void:
	# Remap pattern_type based on part — different parts get different patterns
	var base_pattern: float = dna.pattern_type
	var offset: float = PART_PATTERN_OFFSETS.get(part_type, 0.0)
	var remapped: float = fmod(base_pattern + offset, 1.0)  # wrap around 0-1

	material.set_shader_parameter("pattern_type", remapped)
	material.set_shader_parameter("pattern_density", dna.pattern_density)
	material.set_shader_parameter("pattern_scale", dna.pattern_scale)

	# Pattern intensity varies by part — foliage gets stronger patterns
	match part_type:
		PartType.FOLIAGE:
			material.set_shader_parameter("pattern_intensity", 0.9)
		PartType.TRUNK, PartType.ROOT:
			material.set_shader_parameter("pattern_intensity", 0.6)
		PartType.HEAD:
			material.set_shader_parameter("pattern_intensity", 0.85)
		_:
			material.set_shader_parameter("pattern_intensity", 0.8)

	var rng := RandomNumberGenerator.new()
	rng.seed = instance_seed if instance_seed > 0 else randi()
	material.set_shader_parameter("pattern_rotation", rng.randf_range(0.0, TAU))


func _apply_surface(material: ShaderMaterial, dna: CritterDNA, part_type: int) -> void:
	material.set_shader_parameter("roughness", dna.roughness)
	material.set_shader_parameter("metallic", dna.metallic)
	material.set_shader_parameter("iridescence", dna.iridescence)
	material.set_shader_parameter("transparency", dna.transparency)
	material.set_shader_parameter("cracking", dna.cracking)

	# Surface type from kingdom + part
	var kingdom: int = dna.get_kingdom()
	var surface: float = SURFACE_SCALES  # default
	var kingdom_map: Dictionary = KINGDOM_SURFACE_MAP.get(kingdom, {})
	if kingdom_map.has(part_type):
		surface = kingdom_map[part_type]
	elif kingdom_map.has(PartType.GENERIC):
		surface = kingdom_map[PartType.GENERIC]

	material.set_shader_parameter("surface_type", surface)


func _apply_animation(material: ShaderMaterial, dna: CritterDNA) -> void:
	var kingdom := dna.get_kingdom()
	var wave_intensity := 0.0
	var wave_amplitude := 0.0
	var wave_frequency := 0.0
	var wave_speed := 0.0
	var breath_speed := 1.5
	var breath_amplitude := 0.015
	var anim_tension := 0.0

	match kingdom:
		0:  # Tree — wind sway
			wave_intensity = dna.leaf_density * 0.15
			wave_amplitude = 0.08
			wave_frequency = 1.5
			wave_speed = 0.8
			breath_speed = 0.5
			breath_amplitude = 0.005

		1:  # Creature — body undulation + breathing + tension from volatility
			wave_intensity = dna.mobility * 0.2
			wave_amplitude = 0.05
			wave_frequency = 8.0 + dna.mobility * 8.0
			wave_speed = 2.0 + dna.mobility * 3.0
			breath_speed = 1.5 + dna.mobility
			breath_amplitude = 0.02
			anim_tension = dna.volatility * 0.5

		2:  # Flower — gentle sway
			wave_intensity = dna.scent_strength * 0.25
			wave_amplitude = 0.04
			wave_frequency = 1.2
			wave_speed = 0.6
			breath_speed = 0.8
			breath_amplitude = 0.01

		3:  # Fungus — subtle pulse
			wave_intensity = dna.sociality * 0.1
			wave_amplitude = 0.02
			wave_frequency = 2.0
			wave_speed = 0.4
			breath_speed = 0.6
			breath_amplitude = 0.012

		_:  # Hybrid
			wave_intensity = (dna.mobility + dna.scent_strength) * 0.1
			wave_amplitude = 0.04
			wave_frequency = 3.0
			wave_speed = 1.0
			breath_speed = 1.2
			breath_amplitude = 0.015
			anim_tension = dna.volatility * 0.3

	material.set_shader_parameter("wave_intensity", wave_intensity)
	material.set_shader_parameter("wave_amplitude", wave_amplitude)
	material.set_shader_parameter("wave_frequency", wave_frequency)
	material.set_shader_parameter("wave_speed", wave_speed)
	material.set_shader_parameter("breath_speed", breath_speed)
	material.set_shader_parameter("breath_amplitude", breath_amplitude)
	material.set_shader_parameter("tension", anim_tension)


func _apply_effects(material: ShaderMaterial, dna: CritterDNA) -> void:
	# Decouple effect flags from single genes — use combinations
	var edge_detect := clampf(dna.pattern_density * 0.6 + dna.edge_type * 0.4, 0.1, 0.8)
	var cellular := clampf(dna.pattern_type * 0.3 + dna.sociality * 0.3, 0.1, 0.7)
	var darkness := clampf(0.35 + (dna.energy_source - 1.5) * 0.15 + dna.aggression * 0.1, 0.1, 0.7)
	var color_mix := clampf(dna.sociality * 0.5 + dna.curiosity * 0.3, 0.2, 0.8)

	material.set_shader_parameter("effect_flags", Vector4(
		edge_detect, cellular, darkness, color_mix
	))
	material.set_shader_parameter("detail_level", 1.0)
