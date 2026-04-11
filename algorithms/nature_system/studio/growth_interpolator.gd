# GrowthInterpolator.gd — Maps growth factor t (0-1) to intermediate DNA expression
#
# Takes a target CritterDNA and a growth factor and produces a new DNA
# representing the organism at that developmental stage. Seeds start small,
# pale, simple. Maturity reveals the full gene expression.
#
# Used by GrowthChamber to animate real-time growth from seed to adult.
#
# Usage:
#   var baby_dna: CritterDNA = GrowthInterpolator.interpolate(adult_dna, 0.3)

class_name GrowthInterpolator
extends RefCounted


## Growth stage names for UI display.
const STAGES: Array[Dictionary] = [
	{"name": "seed", "range": [0.0, 0.15], "label": "Seed"},
	{"name": "sprout", "range": [0.15, 0.35], "label": "Sprout"},
	{"name": "juvenile", "range": [0.35, 0.6], "label": "Juvenile"},
	{"name": "mature", "range": [0.6, 0.85], "label": "Mature"},
	{"name": "prime", "range": [0.85, 1.0], "label": "Prime"},
]


## Produce a DNA snapshot at growth factor t (0 = seed, 1 = fully grown).
## Returns a NEW CritterDNA — does not modify the target.
static func interpolate(target: CritterDNA, t: float) -> CritterDNA:
	var growth := clampf(t, 0.0, 1.0)
	var result := CritterDNA.new()

	# Copy lineage metadata unchanged
	result.generation = target.generation
	result.parent_a_id = target.parent_a_id
	result.parent_b_id = target.parent_b_id
	result.mutations = target.mutations.duplicate()

	# ── Scale: tiny seed → full size ──
	result.scale = lerpf(0.1, target.scale, _ease_out(growth))

	# ── Morphology: simple → complex ──
	result.body_type = target.body_type  # Kingdom doesn't change during growth
	result.segments = lerpf(2.0, target.segments, _ease_in(growth))
	result.symmetry = lerpf(1.0, target.symmetry, growth)
	result.pattern_type = lerpf(0.0, target.pattern_type, growth)
	result.pattern_density = lerpf(0.0, target.pattern_density, growth)
	result.pattern_scale = lerpf(0.5, target.pattern_scale, growth)

	# ── Colors: pale/desaturated → full expression ──
	var pale := Color(0.85, 0.82, 0.78)  # Seed beige
	result.primary_color = pale.lerp(target.primary_color, _ease_in(growth))
	result.secondary_color = pale.lerp(target.secondary_color, _ease_in(growth * 0.8))
	result.tertiary_color = pale.lerp(target.tertiary_color, _ease_in(growth * 0.6))

	# ── Material: soft → final texture ──
	result.roughness = lerpf(0.9, target.roughness, growth)
	result.metallic = lerpf(0.0, target.metallic, _late_bloom(growth, 0.5))
	result.iridescence = lerpf(0.0, target.iridescence, _late_bloom(growth, 0.6))
	result.transparency = lerpf(0.0, target.transparency, _late_bloom(growth, 0.4))
	result.cracking = lerpf(0.0, target.cracking, _late_bloom(growth, 0.8))

	# ── Behavior: dormant → active ──
	result.mobility = lerpf(0.0, target.mobility, _ease_in(growth))
	result.aggression = lerpf(0.0, target.aggression, _late_bloom(growth, 0.4))
	result.sociality = lerpf(0.1, target.sociality, growth)
	result.curiosity = lerpf(0.1, target.curiosity, growth)

	# ── Metabolism: slow → full ──
	result.energy_source = target.energy_source  # Fixed from birth
	result.efficiency = lerpf(0.5, target.efficiency, growth)
	result.growth_speed = target.growth_speed  # Controls rate, not expression
	result.fertility = lerpf(0.0, target.fertility, _late_bloom(growth, 0.8))

	# ── Kingdom-specific: undeveloped → full branching/petals/caps ──
	result.branch_angle = lerpf(5.0, target.branch_angle, _ease_out(growth))
	result.branch_decay = lerpf(0.9, target.branch_decay, growth)
	result.leaf_density = lerpf(0.0, target.leaf_density, _late_bloom(growth, 0.3))

	# ── Geometry: stubby → full form ──
	result.part_length = lerpf(0.1, target.part_length, _ease_out(growth))
	result.part_width = lerpf(0.05, target.part_width, growth)
	result.part_curve = lerpf(0.0, target.part_curve, growth)
	result.part_taper = lerpf(0.5, target.part_taper, growth)
	result.part_twist = lerpf(0.0, target.part_twist, _late_bloom(growth, 0.5))
	result.part_tilt = lerpf(0.0, target.part_tilt, growth)

	# ── Detail: absent → full ──
	result.phyllotaxis = lerpf(0.0, target.phyllotaxis, _late_bloom(growth, 0.4))
	result.edge_type = lerpf(0.0, target.edge_type, _late_bloom(growth, 0.5))
	result.base_shape = lerpf(0.0, target.base_shape, growth)
	result.inflorescence = lerpf(0.0, target.inflorescence, _late_bloom(growth, 0.6))
	result.root_type = lerpf(0.0, target.root_type, _ease_in(growth))

	# ── Ecology: dormant → active ──
	result.scent_strength = lerpf(0.0, target.scent_strength, _late_bloom(growth, 0.5))
	result.nectar_quality = lerpf(0.0, target.nectar_quality, _late_bloom(growth, 0.6))

	# ── Potential: always present ──
	result.affinity = target.affinity
	result.volatility = target.volatility
	result.latent_ability = target.latent_ability

	return result


## Get the stage name for a given growth factor.
static func get_stage_name(t: float) -> String:
	var growth := clampf(t, 0.0, 1.0)
	for stage in STAGES:
		var r: Array = stage["range"] as Array
		if growth >= (r[0] as float) and growth < (r[1] as float):
			return stage["label"] as String
	return "Prime"


## Get the stage index (0-4) for a given growth factor.
static func get_stage_index(t: float) -> int:
	var growth := clampf(t, 0.0, 1.0)
	for i in STAGES.size():
		var r: Array = STAGES[i]["range"] as Array
		if growth >= (r[0] as float) and growth < (r[1] as float):
			return i
	return STAGES.size() - 1


# ═══════════════════════════════════════════════════════════════
# EASING CURVES — Shape the growth trajectory
# ═══════════════════════════════════════════════════════════════

## Ease-out: fast start, slow finish (roots, branches extend early)
static func _ease_out(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)

## Ease-in: slow start, fast finish (complexity comes later)
static func _ease_in(t: float) -> float:
	return t * t

## Late bloom: stays near zero until threshold, then ramps quickly.
## Used for features that only appear in later growth stages.
static func _late_bloom(t: float, threshold: float) -> float:
	if t < threshold:
		return 0.0
	var local_t: float = (t - threshold) / (1.0 - threshold)
	return local_t * local_t
