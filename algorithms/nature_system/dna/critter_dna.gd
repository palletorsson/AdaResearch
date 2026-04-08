# CritterDNA.gd — The genome of every living thing in the Nature System
#
# A single Resource shared by all five kingdoms (Tree, Creature, Flower, Fungus, Cave).
# Every gene is a typed @export field — directly visible in the Godot inspector,
# serializable to .tres, and participating in crossover/mutation without encoding.
#
# Philosophical grounding: Donna Haraway's critter discourse + Q-FEP.
# Nothing is purely one thing. body_type is a float, not an enum.
# A value of 1.7 is a creature-flower hybrid. The boundaries are soft.

class_name CritterDNA
extends Resource

# ── PHENOTYPE (visual expression) ──────────────────────────────
@export var primary_color: Color = Color.WHITE       ## Body/bark/petal base color
@export var secondary_color: Color = Color.GRAY      ## Detail/vein/stem color
@export var tertiary_color: Color = Color.YELLOW     ## Wing/leaf/cap accent

# ── MORPHOLOGY (body form) ─────────────────────────────────────
@export_range(0.0, 4.0) var body_type: float = 0.0  ## 0=tree 1=walker 2=flower 3=fungus 4=hybrid
@export_range(2.0, 12.0) var segments: float = 4.0  ## Body complexity / ring count / branch depth
@export_range(1.0, 8.0) var symmetry: float = 4.0   ## Radial symmetry order
@export_range(0.3, 3.0) var scale: float = 1.0      ## Overall size multiplier
@export_range(0.0, 1.0) var pattern_type: float = 0.5    ## Surface pattern (20 types, interpolated)
@export_range(0.0, 1.0) var pattern_density: float = 0.5 ## Pattern frequency
@export_range(0.3, 3.0) var pattern_scale: float = 1.0   ## Pattern UV scale

# ── MATERIAL (surface quality) ─────────────────────────────────
@export_range(0.05, 1.0) var roughness: float = 0.7
@export_range(0.0, 0.5) var metallic: float = 0.0
@export_range(0.0, 1.0) var iridescence: float = 0.0
@export_range(0.0, 0.9) var transparency: float = 0.0
@export_range(0.0, 1.0) var cracking: float = 0.0   ## Age / metamorphosis cracks

# ── BEHAVIOR (how it acts → how it moves → how it looks) ──────
@export_range(0.0, 1.0) var mobility: float = 0.0   ## Rooted → fast runner
@export_range(0.0, 1.0) var aggression: float = 0.0 ## Passive → predator
@export_range(0.0, 1.0) var sociality: float = 0.5  ## Solitary → swarm
@export_range(0.0, 1.0) var curiosity: float = 0.5  ## Avoidant → seeks novelty

# ── METABOLISM (energy dynamics) ───────────────────────────────
@export_range(0.0, 3.0) var energy_source: float = 0.0  ## 0=light 1=organic 2=mineral 3=player
@export_range(0.5, 2.0) var efficiency: float = 1.0
@export_range(0.5, 2.0) var growth_speed: float = 1.0
@export_range(0.0, 1.0) var fertility: float = 0.5

# ── KINGDOM-SPECIFIC (interpreted differently per body_type) ──
@export_range(15.0, 90.0) var branch_angle: float = 25.0  ## Tree: L-system angle / Creature: leg splay / Flower: ring opening
@export_range(0.3, 0.9) var branch_decay: float = 0.7     ## Tree: taper / Creature: segment taper / Flower: ring size falloff
@export_range(0.0, 1.0) var leaf_density: float = 0.5     ## Tree: foliage / Flower: stamen density / Fungi: spore density

# ── GEOMETRY DETAIL (petal/branch/limb shape) ──────────────────
@export_range(0.1, 2.0) var part_length: float = 0.6      ## Petal length / branch segment / limb length
@export_range(0.05, 1.0) var part_width: float = 0.3      ## Petal width / branch thickness / limb girth
@export_range(0.0, 1.0) var part_curve: float = 0.35      ## Petal curvature / branch droop / limb arc
@export_range(0.0, 1.0) var part_taper: float = 0.8       ## Tip pointiness / branch tip / claw sharpness
@export_range(-45.0, 45.0) var part_twist: float = 0.0    ## Petal twist / branch spiral / limb rotation
@export_range(0.0, 45.0) var part_tilt: float = 15.0      ## Petal tilt per ring / branch gravity / limb rest angle

# ── PART DETAIL (fine structure — botanical reference) ─────────
@export_range(0.0, 1.0) var phyllotaxis: float = 0.0      ## Arrangement (spiral→opposite→whorled)
@export_range(0.0, 1.0) var edge_type: float = 0.0        ## Edge profile (smooth→serrated)
@export_range(0.0, 1.0) var base_shape: float = 0.0       ## Base form (rounded→arrow→spear)

# ── INFLORESCENCE (multi-flower / colony structure) ────────────
@export_range(0.0, 1.0) var inflorescence: float = 0.0    ## Solitary→raceme→umbel→head→panicle
@export_range(0.0, 1.0) var root_type: float = 0.0        ## Bulb→rhizome→tuber→rootstock→fibrous

# ── ECOLOGY (interaction with other critters) ──────────────────
@export_range(0.0, 1.0) var scent_strength: float = 0.3   ## Flower: attract radius / Fungi: spore range
@export_range(0.0, 1.0) var nectar_quality: float = 0.5   ## Flower: reward / Fungi: potency

# ── POTENTIAL (Haraway — what it CAN become) ───────────────────
@export_range(0.0, 1.0) var affinity: float = 0.5     ## How easily player bonds
@export_range(0.0, 1.0) var volatility: float = 0.3   ## How unstable current form is
@export_range(0.0, 5.0) var latent_ability: float = 0.0  ## Which transmutation it carries

# ── LINEAGE (not inherited — accumulated) ──────────────────────
@export var generation: int = 0
@export var parent_a_id: String = ""
@export var parent_b_id: String = ""
@export var mutations: Array[String] = []  ## Which fields changed from parents


# ═══════════════════════════════════════════════════════════════
# GENETICS — Crossover, Mutation, Random Generation
# ═══════════════════════════════════════════════════════════════

## The properties we iterate over for genetics operations.
## Cached once, used by crossover/mutate/randomize.
static var _gene_properties: Array[Dictionary] = []


static func _get_gene_properties() -> Array[Dictionary]:
	if not _gene_properties.is_empty():
		return _gene_properties

	# Build the list from a temporary instance
	var temp := CritterDNA.new()
	for prop in temp.get_property_list():
		# Only exported storage properties, skip lineage metadata
		if prop.usage & PROPERTY_USAGE_STORAGE == 0:
			continue
		if prop.name in ["generation", "parent_a_id", "parent_b_id",
						 "mutations", "resource_local_to_scene",
						 "resource_name", "resource_path", "script"]:
			continue
		_gene_properties.append(prop)
	return _gene_properties


## Create a child from two parents. Each gene is randomly inherited
## from parent A, parent B, or blended between them.
static func crossover(a: CritterDNA, b: CritterDNA) -> CritterDNA:
	var child := CritterDNA.new()
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for prop in _get_gene_properties():
		var gene_name: String = prop.name
		var va = a.get(gene_name)
		var vb = b.get(gene_name)

		match rng.randi() % 3:
			0:  # Inherit from parent A
				child.set(gene_name, va)
			1:  # Inherit from parent B
				child.set(gene_name, vb)
			2:  # Blend
				if va is float:
					child.set(gene_name, lerp(va, vb, rng.randf()))
				elif va is Color:
					child.set(gene_name, va.lerp(vb, rng.randf()))
				else:
					child.set(gene_name, va if rng.randf() < 0.5 else vb)

	# Lineage tracking
	child.generation = maxi(a.generation, b.generation) + 1
	child.parent_a_id = str(a.get_instance_id())
	child.parent_b_id = str(b.get_instance_id())

	return child


## Mutate a DNA in-place. Each gene has a `rate` probability of being
## perturbed. Colors shift per-channel; floats nudge within their range.
static func mutate(dna: CritterDNA, rate: float = 0.05, strength: float = 0.1) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for prop in _get_gene_properties():
		if rng.randf() > rate:
			continue

		var gene_name: String = prop.name
		var val = dna.get(gene_name)

		if val is float:
			# Get hint range from property metadata
			var range_min: float = _get_hint_range_min(prop)
			var range_max: float = _get_hint_range_max(prop)
			var range_span: float = range_max - range_min
			var nudge: float = rng.randf_range(-strength, strength) * range_span
			dna.set(gene_name, clampf(val + nudge, range_min, range_max))
			dna.mutations.append(gene_name)

		elif val is Color:
			dna.set(gene_name, Color(
				clampf(val.r + rng.randf_range(-strength, strength), 0.0, 1.0),
				clampf(val.g + rng.randf_range(-strength, strength), 0.0, 1.0),
				clampf(val.b + rng.randf_range(-strength, strength), 0.0, 1.0),
				val.a
			))
			dna.mutations.append(gene_name)


## Generate a fully random DNA, respecting all @export_range bounds.
static func random(rng_seed: int = -1) -> CritterDNA:
	var dna := CritterDNA.new()
	var rng := RandomNumberGenerator.new()
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()

	for prop in _get_gene_properties():
		var gene_name: String = prop.name
		var val = dna.get(gene_name)

		if val is float:
			var range_min: float = _get_hint_range_min(prop)
			var range_max: float = _get_hint_range_max(prop)
			dna.set(gene_name, rng.randf_range(range_min, range_max))

		elif val is Color:
			dna.set(gene_name, Color(rng.randf(), rng.randf(), rng.randf()))

	dna.generation = 0
	return dna


## Generate random DNA biased toward a specific kingdom.
## body_type is set to the kingdom value; related genes are weighted
## toward plausible values for that kingdom.
static func random_kingdom(kingdom: int, rng_seed: int = -1) -> CritterDNA:
	var dna := random(rng_seed)
	var rng := RandomNumberGenerator.new()
	if rng_seed >= 0:
		rng.seed = rng_seed + 999
	else:
		rng.randomize()

	dna.body_type = float(clampi(kingdom, 0, 4))

	match kingdom:
		0:  # Tree — rooted, branching, photosynthetic
			dna.mobility = rng.randf_range(0.0, 0.05)
			dna.energy_source = rng.randf_range(0.0, 0.3)
			dna.branch_angle = rng.randf_range(15.0, 55.0)
			dna.branch_decay = rng.randf_range(0.5, 0.85)
			dna.leaf_density = rng.randf_range(0.3, 0.9)
			dna.aggression = rng.randf_range(0.0, 0.1)
			dna.roughness = rng.randf_range(0.5, 1.0)  # Bark
			dna.inflorescence = rng.randf_range(0.0, 0.3)
			dna.root_type = rng.randf_range(0.5, 1.0)  # Deep roots

		1:  # Creature — mobile, segments, legs
			dna.mobility = rng.randf_range(0.3, 1.0)
			dna.energy_source = rng.randf_range(0.5, 2.0)
			dna.segments = rng.randf_range(2.0, 8.0)
			dna.symmetry = float(rng.randi_range(1, 4))  # Leg pairs
			dna.part_length = rng.randf_range(0.3, 1.5)  # Leg length
			dna.aggression = rng.randf_range(0.1, 0.8)
			dna.curiosity = rng.randf_range(0.3, 0.9)

		2:  # Flower — rooted, petals, scent
			dna.mobility = rng.randf_range(0.0, 0.02)
			dna.energy_source = rng.randf_range(0.0, 0.5)
			dna.symmetry = float(rng.randi_range(3, 8))  # Petal count
			dna.segments = rng.randf_range(2.0, 4.0)     # Ring count
			dna.scent_strength = rng.randf_range(0.2, 0.9)
			dna.nectar_quality = rng.randf_range(0.3, 0.9)
			dna.branch_angle = rng.randf_range(30.0, 85.0)  # Open flower
			dna.roughness = rng.randf_range(0.05, 0.4)  # Smooth petals
			dna.inflorescence = rng.randf_range(0.0, 1.0)
			dna.root_type = rng.randf_range(0.0, 0.5)  # Bulb/rhizome

		3:  # Fungus — decomposer, cap, spores
			dna.mobility = rng.randf_range(0.0, 0.01)
			dna.energy_source = rng.randf_range(1.0, 2.5)  # Organic/mineral
			dna.leaf_density = rng.randf_range(0.3, 1.0)   # Spore density
			dna.transparency = rng.randf_range(0.0, 0.5)
			dna.roughness = rng.randf_range(0.2, 0.8)
			dna.part_curve = rng.randf_range(0.3, 1.0)  # Cap dome
			dna.sociality = rng.randf_range(0.4, 0.9)   # Colony forming
			dna.inflorescence = rng.randf_range(0.0, 0.8)  # Cluster pattern
			dna.root_type = rng.randf_range(0.2, 0.7)  # Mycelium

		4:  # Hybrid — truly random, the whole space is open
			pass  # Already fully random from random()

	return dna


## Get a gene value by name, normalized to 0-1 range.
## Useful for shader parameter mapping.
func get_normalized(gene_name: String) -> float:
	var val = get(gene_name)
	if val == null or not val is float:
		return 0.0

	for prop in _get_gene_properties():
		if prop.name == gene_name:
			var range_min := _get_hint_range_min(prop)
			var range_max := _get_hint_range_max(prop)
			if range_max - range_min < 0.001:
				return 0.0
			return (val - range_min) / (range_max - range_min)
	return 0.0


## Get all genes as a flat dictionary (for shader binding / serialization).
func to_dict() -> Dictionary:
	var result := {}
	for prop in _get_gene_properties():
		result[prop.name] = get(prop.name)
	return result


## Load genes from a flat dictionary.
func from_dict(data: Dictionary) -> void:
	for key in data:
		if key in ["generation", "parent_a_id", "parent_b_id", "mutations"]:
			continue
		set(key, data[key])


## How different two DNAs are, as a float 0-1.
## Used for speciation distance, visual similarity checks.
static func distance(a: CritterDNA, b: CritterDNA) -> float:
	var total_diff := 0.0
	var gene_count := 0

	for prop in _get_gene_properties():
		var va = a.get(prop.name)
		var vb = b.get(prop.name)

		if va is float and vb is float:
			var range_min := _get_hint_range_min(prop)
			var range_max := _get_hint_range_max(prop)
			var span := range_max - range_min
			if span > 0.001:
				total_diff += absf(va - vb) / span
				gene_count += 1
		elif va is Color and vb is Color:
			total_diff += (absf(va.r - vb.r) + absf(va.g - vb.g) + absf(va.b - vb.b)) / 3.0
			gene_count += 1

	return total_diff / maxf(gene_count, 1.0)


## Which kingdom this DNA is closest to (rounds body_type).
func get_kingdom() -> int:
	return clampi(roundi(body_type), 0, 4)


## Human-readable kingdom name.
func get_kingdom_name() -> String:
	match get_kingdom():
		0: return "tree"
		1: return "creature"
		2: return "flower"
		3: return "fungus"
		4: return "hybrid"
		_: return "unknown"


## How hybrid this DNA is (0 = pure kingdom, 0.5 = maximally hybrid).
func get_hybridity() -> float:
	return absf(body_type - float(get_kingdom()))


# ═══════════════════════════════════════════════════════════════
# SERIALIZATION HELPERS (for Pokemon Studio / web editor)
# ═══════════════════════════════════════════════════════════════

## Serialize entire DNA (including lineage) to a JSON string.
func to_json() -> String:
	var data: Dictionary = to_dict()
	# Convert Colors to hex strings for JSON compatibility
	for key in data:
		if data[key] is Color:
			data[key] = (data[key] as Color).to_html(false)
	data["generation"] = generation
	data["parent_a_id"] = parent_a_id
	data["parent_b_id"] = parent_b_id
	data["mutations"] = mutations.duplicate()
	return JSON.stringify(data, "\t")


## Load entire DNA (including lineage) from a JSON string.
static func from_json(json_str: String) -> CritterDNA:
	var parsed = JSON.parse_string(json_str)
	if not parsed is Dictionary:
		push_error("[CritterDNA] from_json: invalid JSON")
		return CritterDNA.new()

	var data: Dictionary = parsed as Dictionary
	var dna := CritterDNA.new()
	var color_keys: Array[String] = ["primary_color", "secondary_color", "tertiary_color"]

	for key in data:
		if key in ["generation", "parent_a_id", "parent_b_id", "mutations"]:
			continue
		var val = data[key]
		if key in color_keys and val is String:
			dna.set(key, Color.html(val as String))
		elif val is float or val is int:
			dna.set(key, float(val))

	dna.generation = int(data.get("generation", 0))
	dna.parent_a_id = str(data.get("parent_a_id", ""))
	dna.parent_b_id = str(data.get("parent_b_id", ""))
	if "mutations" in data and data["mutations"] is Array:
		for m in data["mutations"]:
			dna.mutations.append(str(m))

	return dna


## Get names of all heritable gene properties (excludes lineage metadata).
static func get_gene_names() -> Array[String]:
	var names: Array[String] = []
	for prop in _get_gene_properties():
		names.append(prop.name as String)
	return names


## Get display info for a gene: { name, min, max, current, normalized, category, type }.
## Useful for UI sliders and inspector panels.
func get_gene_display_info(gene_name: String) -> Dictionary:
	var val = get(gene_name)
	if val == null:
		return {}

	for prop in _get_gene_properties():
		if prop.name != gene_name:
			continue

		var info: Dictionary = {"name": gene_name}

		if val is float:
			var range_min := _get_hint_range_min(prop)
			var range_max := _get_hint_range_max(prop)
			info["min"] = range_min
			info["max"] = range_max
			info["current"] = val
			info["normalized"] = get_normalized(gene_name)
			info["type"] = "float"
		elif val is Color:
			info["current"] = (val as Color).to_html(false)
			info["min"] = 0.0
			info["max"] = 1.0
			info["normalized"] = 0.5
			info["type"] = "color"

		# Categorize
		info["category"] = _categorize_gene(gene_name)
		return info

	return {}


## Get display info for ALL genes at once (for building a full inspector).
func get_all_gene_info() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for prop in _get_gene_properties():
		var info: Dictionary = get_gene_display_info(prop.name as String)
		if not info.is_empty():
			result.append(info)
	return result


## Categorize a gene name into its group.
static func _categorize_gene(gene_name: String) -> String:
	match gene_name:
		"primary_color", "secondary_color", "tertiary_color":
			return "phenotype"
		"body_type", "segments", "symmetry", "scale", "pattern_type", "pattern_density", "pattern_scale":
			return "morphology"
		"roughness", "metallic", "iridescence", "transparency", "cracking":
			return "material"
		"mobility", "aggression", "sociality", "curiosity":
			return "behavior"
		"energy_source", "efficiency", "growth_speed", "fertility":
			return "metabolism"
		"branch_angle", "branch_decay", "leaf_density":
			return "kingdom"
		"part_length", "part_width", "part_curve", "part_taper", "part_twist", "part_tilt":
			return "geometry"
		"phyllotaxis", "edge_type", "base_shape", "inflorescence", "root_type":
			return "detail"
		"scent_strength", "nectar_quality":
			return "ecology"
		"affinity", "volatility", "latent_ability":
			return "potential"
		_:
			return "other"


# ═══════════════════════════════════════════════════════════════
# INTERNAL — Property range extraction
# ═══════════════════════════════════════════════════════════════

static func _get_hint_range_min(prop: Dictionary) -> float:
	if prop.hint != PROPERTY_HINT_RANGE:
		return 0.0
	var parts: PackedStringArray = str(prop.hint_string).split(",")
	if parts.size() >= 1:
		return parts[0].strip_edges().to_float()
	return 0.0


static func _get_hint_range_max(prop: Dictionary) -> float:
	if prop.hint != PROPERTY_HINT_RANGE:
		return 1.0
	var parts: PackedStringArray = str(prop.hint_string).split(",")
	if parts.size() >= 2:
		return parts[1].strip_edges().to_float()
	return 1.0
