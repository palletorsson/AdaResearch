# SubstrateVector.gd - Describes an artifact's mathematical character
# as a weighted combination of terrain substrates.
#
# Every artifact in AdaResearch embodies mathematical concepts.
# A SubstrateVector captures WHICH mathematics and HOW MUCH of each.
#
# The wave_interference_tank artifact might be:
#   { sine: 0.3, wave_interference: 0.8, noise: 0.1 }
#
# The random_walk_terrarium:
#   { random: 0.7, noise: 0.3, fractal: 0.2 }
#
# This vector can:
# - Generate a blended walkable surface for the artifact to sit on
# - Classify artifacts by mathematical similarity
# - Create substrate "neighborhoods" in the lab
# - Drive visual theming (dominant substrate → material palette)
# - Suggest related artifacts (cosine similarity of vectors)
#
# "Every object carries the mathematics it embodies. The ground responds."

extends Resource
class_name SubstrateVector

# The substrate weights — which mathematical terrains compose this artifact
# Keys match TopologyManager.SPACE_REGISTRY keys
# Values are weights 0.0-1.0 (don't need to sum to 1)
@export var weights: Dictionary = {}

# Cached dominant substrate
var _dominant_key: String = ""
var _dominant_weight: float = 0.0

# ── All known substrate keys ─────────────────────────────────
const ALL_SUBSTRATES = [
	"sine", "noise", "voronoi", "random", "fractal",
	"worley", "cellular_automata", "reaction_diffusion",
	"mandelbrot", "lsystem", "wave_interference", "ridged_noise",
	"spherical_harmonics", "flow_field",
	"domain_warp", "erosion",
	"mobius", "torus", "hyperbolic",
]

# ── Construction ─────────────────────────────────────────────

static func create(w: Dictionary) -> SubstrateVector:
	var sv = SubstrateVector.new()
	sv.weights = w
	sv._compute_dominant()
	return sv

static func from_single(key: String, weight: float = 1.0) -> SubstrateVector:
	"""Create a vector dominated by a single substrate"""
	return create({key: weight})

static func from_artifact_tags(tags: Array) -> SubstrateVector:
	"""Infer substrate weights from artifact tags/themes.
	   Uses keyword matching to estimate mathematical composition."""
	var w: Dictionary = {}

	var tag_map = {
		# tag → [substrate_key, weight]
		"sine": ["sine", 0.6],
		"cosine": ["sine", 0.5],
		"wave": ["wave_interference", 0.6],
		"waves": ["wave_interference", 0.6],
		"oscillation": ["sine", 0.7],
		"harmonic": ["sine", 0.5],
		"frequency": ["sine", 0.4],
		"noise": ["noise", 0.7],
		"perlin": ["noise", 0.8],
		"simplex": ["noise", 0.8],
		"fractal": ["fractal", 0.7],
		"recursive": ["fractal", 0.5],
		"self_similar": ["fractal", 0.6],
		"mandelbrot": ["mandelbrot", 0.9],
		"julia": ["mandelbrot", 0.8],
		"iteration": ["mandelbrot", 0.4],
		"voronoi": ["voronoi", 0.8],
		"cellular": ["cellular_automata", 0.7],
		"automata": ["cellular_automata", 0.8],
		"game_of_life": ["cellular_automata", 0.9],
		"turing_pattern": ["reaction_diffusion", 0.9],
		"reaction_diffusion": ["reaction_diffusion", 0.9],
		"diffusion": ["reaction_diffusion", 0.6],
		"morphogenesis": ["reaction_diffusion", 0.7],
		"random": ["random", 0.6],
		"random_walk": ["random", 0.8],
		"stochastic": ["random", 0.5],
		"entropy": ["random", 0.5],
		"erosion": ["erosion", 0.7],
		"terrain": ["ridged_noise", 0.5],
		"mountain": ["ridged_noise", 0.7],
		"ridge": ["ridged_noise", 0.6],
		"lsystem": ["lsystem", 0.8],
		"l_system": ["lsystem", 0.8],
		"branching": ["lsystem", 0.6],
		"grammar": ["lsystem", 0.5],
		"tree": ["lsystem", 0.4],
		"vectors": ["flow_field", 0.5],
		"field": ["flow_field", 0.6],
		"force": ["flow_field", 0.5],
		"potential": ["flow_field", 0.6],
		"vortex": ["flow_field", 0.7],
		"interference": ["wave_interference", 0.8],
		"superposition": ["wave_interference", 0.7],
		"topology": ["torus", 0.5],
		"torus": ["torus", 0.8],
		"mobius": ["mobius", 0.8],
		"hyperbolic": ["hyperbolic", 0.8],
		"non_euclidean": ["hyperbolic", 0.6],
		"curvature": ["hyperbolic", 0.5],
		"orbital": ["spherical_harmonics", 0.7],
		"spherical": ["spherical_harmonics", 0.6],
		"quantum": ["spherical_harmonics", 0.5],
		"warp": ["domain_warp", 0.7],
		"marble": ["domain_warp", 0.5],
		"organic": ["domain_warp", 0.4],
		"worley": ["worley", 0.8],
		"cell": ["worley", 0.4],
	}

	for tag in tags:
		var t = str(tag).to_lower().replace(" ", "_")
		if tag_map.has(t):
			var entry = tag_map[t]
			var key: String = entry[0]
			var val: float = entry[1]
			w[key] = maxf(w.get(key, 0.0), val)

	return create(w)

# ── Vector Operations ────────────────────────────────────────

func get_dominant() -> String:
	"""Return the substrate with highest weight"""
	if _dominant_key == "":
		_compute_dominant()
	return _dominant_key

func get_dominant_weight() -> float:
	if _dominant_key == "":
		_compute_dominant()
	return _dominant_weight

func get_weight(key: String) -> float:
	return weights.get(key, 0.0)

func set_weight(key: String, value: float):
	weights[key] = value
	_compute_dominant()

func get_nonzero_substrates() -> Array[String]:
	"""Return all substrates with weight > 0"""
	var result: Array[String] = []
	for key in weights:
		if weights[key] > 0.0:
			result.append(key)
	return result

func get_sorted_substrates() -> Array[Dictionary]:
	"""Return substrates sorted by weight descending"""
	var entries: Array[Dictionary] = []
	for key in weights:
		if weights[key] > 0.0:
			entries.append({"key": key, "weight": weights[key]})
	entries.sort_custom(func(a, b): return a["weight"] > b["weight"])
	return entries

func magnitude() -> float:
	"""L2 norm of the vector"""
	var sum = 0.0
	for key in weights:
		sum += weights[key] * weights[key]
	return sqrt(sum)

func normalized() -> SubstrateVector:
	"""Return unit vector (weights sum of squares = 1)"""
	var mag = magnitude()
	if mag < 0.0001:
		return SubstrateVector.create({})
	var new_weights: Dictionary = {}
	for key in weights:
		new_weights[key] = weights[key] / mag
	return SubstrateVector.create(new_weights)

func dot(other: SubstrateVector) -> float:
	"""Dot product — measures similarity"""
	var sum = 0.0
	for key in weights:
		sum += weights[key] * other.get_weight(key)
	return sum

func cosine_similarity(other: SubstrateVector) -> float:
	"""Cosine similarity (0-1) — how similar two artifacts' substrates are"""
	var mag_a = magnitude()
	var mag_b = other.magnitude()
	if mag_a < 0.0001 or mag_b < 0.0001:
		return 0.0
	return dot(other) / (mag_a * mag_b)

func distance(other: SubstrateVector) -> float:
	"""Euclidean distance between two substrate vectors"""
	var sum = 0.0
	var all_keys: Dictionary = {}
	for key in weights:
		all_keys[key] = true
	for key in other.weights:
		all_keys[key] = true

	for key in all_keys:
		var diff = get_weight(key) - other.get_weight(key)
		sum += diff * diff
	return sqrt(sum)

func blend(other: SubstrateVector, t: float = 0.5) -> SubstrateVector:
	"""Blend two substrate vectors (lerp)"""
	var all_keys: Dictionary = {}
	for key in weights:
		all_keys[key] = true
	for key in other.weights:
		all_keys[key] = true

	var new_weights: Dictionary = {}
	for key in all_keys:
		var a = get_weight(key)
		var b = other.get_weight(key)
		var blended = lerpf(a, b, t)
		if blended > 0.001:
			new_weights[key] = blended
	return SubstrateVector.create(new_weights)

func add(other: SubstrateVector) -> SubstrateVector:
	"""Add two substrate vectors"""
	var new_weights = weights.duplicate()
	for key in other.weights:
		new_weights[key] = new_weights.get(key, 0.0) + other.weights[key]
	return SubstrateVector.create(new_weights)

func scale(factor: float) -> SubstrateVector:
	"""Scale all weights by a factor"""
	var new_weights: Dictionary = {}
	for key in weights:
		new_weights[key] = weights[key] * factor
	return SubstrateVector.create(new_weights)

# ── Terrain Generation ───────────────────────────────────────

func generate_blended_terrain(parent: Node3D, size: Vector2 = Vector2(10, 10), res: int = 60) -> TopologySpace:
	"""Generate a walkable surface that blends all substrates in this vector.
	   The dominant substrate provides the base, others modulate it."""
	var sorted = get_sorted_substrates()
	if sorted.is_empty():
		return null

	# Use dominant substrate as the base terrain
	var dominant = sorted[0]
	var base_script = _load_space_script(dominant["key"])
	if base_script == null:
		return null

	var space: TopologySpace = base_script.new()
	space.space_size = size
	space.resolution = res
	space.name = "BlendedSubstrate"
	parent.add_child(space)

	return space

func _load_space_script(key: String) -> Script:
	if TopologyManager.SPACE_REGISTRY.has(key):
		return load(TopologyManager.SPACE_REGISTRY[key][0])
	return null

# ── Serialization ────────────────────────────────────────────

func to_dict() -> Dictionary:
	return weights.duplicate()

static func from_dict(d: Dictionary) -> SubstrateVector:
	return create(d)

func to_string_readable() -> String:
	var sorted = get_sorted_substrates()
	var parts: Array[String] = []
	for entry in sorted:
		parts.append("%s: %.2f" % [entry["key"], entry["weight"]])
	return "{ " + ", ".join(parts) + " }"

# ── Internal ─────────────────────────────────────────────────

func _compute_dominant():
	_dominant_key = ""
	_dominant_weight = 0.0
	for key in weights:
		if weights[key] > _dominant_weight:
			_dominant_key = key
			_dominant_weight = weights[key]
