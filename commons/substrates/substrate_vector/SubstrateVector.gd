# SubstrateVector.gd — 8-dimensional substrate coordinate for any artifact
#
# Every artifact in AdaResearch occupies a point in an 8-dimensional
# "substrate space" describing HOW it is implemented:
#   Geometry, Material, Physics, Time, Algorithm, Interaction, Containment, Information
#
# Each dimension holds a sparse dictionary of {value_name: weight} pairs.
# A jelly_cube might be: {physics: {soft_body: 1.0}, material: {transparent: 0.7, emissive: 0.3}}
#
# Supports: dot product, cosine similarity, distance, blend, add, scale,
#           per-dimension similarity, serialization, readable printing.
#
# "Every object carries the substrates it embodies. The space responds."

extends Resource
class_name SubstrateVector

# ── Dimension Definitions ────────────────────────────────────

const DIMENSIONS := [
	"geometry", "material", "physics", "time",
	"algorithm", "interaction", "containment", "information"
]

const DIMENSION_VALUES := {
	"geometry": [
		"none", "primitive_mesh", "csg", "procedural_mesh", "multimesh",
		"immediate_mesh", "parametric_surface", "curve_extrusion", "voxel_grid"
	],
	"material": [
		"opaque_standard", "transparent", "emissive", "shader_driven",
		"vertex_color", "cull_disabled"
	],
	"physics": [
		"none", "rigid_body", "soft_body", "custom_integration",
		"particle_system", "collision_only"
	],
	"time": [
		"static", "continuous", "discrete_step", "event_driven",
		"simulation", "accumulative"
	],
	"algorithm": [
		"none", "trig_functions", "noise_sampling", "cellular_automata",
		"flocking_rules", "fractal_iteration", "physics_equations",
		"vector_arithmetic", "reaction_diffusion", "lsystem_expansion",
		"probability", "topology", "state_machine"
	],
	"interaction": [
		"none", "grab", "slider", "button", "touch_surface", "spatial_presence"
	],
	"containment": [
		"none", "glass_jar", "glass_tank", "petri_dish", "table",
		"pedestal", "frame", "box"
	],
	"information": [
		"none", "label_3d", "formula_display", "data_visualization",
		"color_encoding", "spatial_encoding"
	],
}

# ── Data ─────────────────────────────────────────────────────

# Core storage: { "geometry": {"procedural_mesh": 1.0}, "physics": {"soft_body": 0.8} }
@export var dimensions: Dictionary = {}

# ── Construction ─────────────────────────────────────────────

static func create(dim_dict: Dictionary = {}) -> SubstrateVector:
	var sv := SubstrateVector.new()
	for dim_name in dim_dict:
		if dim_name in DIMENSIONS:
			var values: Dictionary = dim_dict[dim_name]
			var clean := {}
			for val_name in values:
				var w: float = float(values[val_name])
				if absf(w) > 0.001:
					clean[val_name] = w
			if not clean.is_empty():
				sv.dimensions[dim_name] = clean
	return sv


static func from_dict(d: Dictionary) -> SubstrateVector:
	return create(d)


static func zero() -> SubstrateVector:
	return SubstrateVector.new()


# ── Accessors ────────────────────────────────────────────────

func get_dimension(dim_name: String) -> Dictionary:
	return dimensions.get(dim_name, {})


func get_weight(dim_name: String, value_name: String) -> float:
	var dim: Dictionary = dimensions.get(dim_name, {})
	return dim.get(value_name, 0.0)


func set_weight(dim_name: String, value_name: String, weight: float) -> void:
	if dim_name not in DIMENSIONS:
		return
	if absf(weight) < 0.001:
		if dimensions.has(dim_name):
			dimensions[dim_name].erase(value_name)
			if dimensions[dim_name].is_empty():
				dimensions.erase(dim_name)
		return
	if not dimensions.has(dim_name):
		dimensions[dim_name] = {}
	dimensions[dim_name][value_name] = weight


func get_dominant(dim_name: String) -> String:
	var dim: Dictionary = dimensions.get(dim_name, {})
	var best_key := ""
	var best_val := 0.0
	for key in dim:
		if dim[key] > best_val:
			best_key = key
			best_val = dim[key]
	return best_key


func get_dominant_weight(dim_name: String) -> float:
	var dim: Dictionary = dimensions.get(dim_name, {})
	var best := 0.0
	for key in dim:
		if dim[key] > best:
			best = dim[key]
	return best


func get_active_dimensions() -> Array[String]:
	var result: Array[String] = []
	for dim_name in DIMENSIONS:
		if dimensions.has(dim_name) and not dimensions[dim_name].is_empty():
			result.append(dim_name)
	return result


func is_empty() -> bool:
	for dim_name in dimensions:
		if not dimensions[dim_name].is_empty():
			return false
	return true


# ── Per-Dimension Vector Math ────────────────────────────────

## Flat weight array for one dimension (treating each possible value as an axis).
func _dim_weights(dim_name: String) -> Array[float]:
	var vals: Array = DIMENSION_VALUES.get(dim_name, [])
	var dim: Dictionary = dimensions.get(dim_name, {})
	var result: Array[float] = []
	for v in vals:
		result.append(dim.get(v, 0.0))
	return result


## Dot product of a single dimension between two vectors.
func dimension_dot(other: SubstrateVector, dim_name: String) -> float:
	var a := _dim_weights(dim_name)
	var b := other._dim_weights(dim_name)
	var s := 0.0
	for i in a.size():
		s += a[i] * b[i]
	return s


## Cosine similarity on a single dimension.
func dimension_similarity(other: SubstrateVector, dim_name: String) -> float:
	var a := _dim_weights(dim_name)
	var b := other._dim_weights(dim_name)
	var dot_val := 0.0
	var mag_a := 0.0
	var mag_b := 0.0
	for i in a.size():
		dot_val += a[i] * b[i]
		mag_a += a[i] * a[i]
		mag_b += b[i] * b[i]
	mag_a = sqrt(mag_a)
	mag_b = sqrt(mag_b)
	if mag_a < 0.0001 or mag_b < 0.0001:
		# If both are zero-vectors on this dim, they're "identical" (both absent)
		if mag_a < 0.0001 and mag_b < 0.0001:
			return 1.0
		return 0.0
	return dot_val / (mag_a * mag_b)


# ── Full Vector Math ────────────────────────────────────────

## Flatten all dimensions into a single float array for vector ops.
func _flatten() -> Array[float]:
	var result: Array[float] = []
	for dim_name in DIMENSIONS:
		var vals: Array = DIMENSION_VALUES.get(dim_name, [])
		var dim: Dictionary = dimensions.get(dim_name, {})
		for v in vals:
			result.append(dim.get(v, 0.0))
	return result


func magnitude() -> float:
	var flat := _flatten()
	var s := 0.0
	for v in flat:
		s += v * v
	return sqrt(s)


func dot(other: SubstrateVector) -> float:
	var a := _flatten()
	var b := other._flatten()
	var s := 0.0
	for i in a.size():
		s += a[i] * b[i]
	return s


func cosine_similarity(other: SubstrateVector) -> float:
	var a := _flatten()
	var b := other._flatten()
	var dot_val := 0.0
	var mag_a := 0.0
	var mag_b := 0.0
	for i in a.size():
		dot_val += a[i] * b[i]
		mag_a += a[i] * a[i]
		mag_b += b[i] * b[i]
	mag_a = sqrt(mag_a)
	mag_b = sqrt(mag_b)
	if mag_a < 0.0001 or mag_b < 0.0001:
		if mag_a < 0.0001 and mag_b < 0.0001:
			return 1.0
		return 0.0
	return dot_val / (mag_a * mag_b)


func distance(other: SubstrateVector) -> float:
	var a := _flatten()
	var b := other._flatten()
	var s := 0.0
	for i in a.size():
		var diff := a[i] - b[i]
		s += diff * diff
	return sqrt(s)


## Weighted overall similarity: average of per-dimension cosine similarities.
## dimension_weights lets you emphasize certain dimensions (default: equal).
func overall_similarity(other: SubstrateVector, dimension_weights: Dictionary = {}) -> float:
	var total := 0.0
	var weight_sum := 0.0
	for dim_name in DIMENSIONS:
		var w: float = dimension_weights.get(dim_name, 1.0)
		total += dimension_similarity(other, dim_name) * w
		weight_sum += w
	if weight_sum < 0.0001:
		return 0.0
	return total / weight_sum


func blend(other: SubstrateVector, t: float = 0.5) -> SubstrateVector:
	var result := {}
	var all_dims := {}
	for d in dimensions:
		all_dims[d] = true
	for d in other.dimensions:
		all_dims[d] = true
	for dim_name in all_dims:
		var vals_a: Dictionary = dimensions.get(dim_name, {})
		var vals_b: Dictionary = other.dimensions.get(dim_name, {})
		var all_keys := {}
		for k in vals_a:
			all_keys[k] = true
		for k in vals_b:
			all_keys[k] = true
		var blended := {}
		for k in all_keys:
			var a_val: float = vals_a.get(k, 0.0)
			var b_val: float = vals_b.get(k, 0.0)
			var v: float = lerpf(a_val, b_val, t)
			if absf(v) > 0.001:
				blended[k] = v
		if not blended.is_empty():
			result[dim_name] = blended
	return SubstrateVector.create(result)


func add(other: SubstrateVector) -> SubstrateVector:
	var result := {}
	for dim_name in DIMENSIONS:
		var vals_a: Dictionary = dimensions.get(dim_name, {})
		var vals_b: Dictionary = other.dimensions.get(dim_name, {})
		var all_keys := {}
		for k in vals_a:
			all_keys[k] = true
		for k in vals_b:
			all_keys[k] = true
		var summed := {}
		for k in all_keys:
			var v: float = vals_a.get(k, 0.0) + vals_b.get(k, 0.0)
			if absf(v) > 0.001:
				summed[k] = v
		if not summed.is_empty():
			result[dim_name] = summed
	return SubstrateVector.create(result)


func scale(factor: float) -> SubstrateVector:
	var result := {}
	for dim_name in dimensions:
		var scaled := {}
		for k in dimensions[dim_name]:
			var v: float = dimensions[dim_name][k] * factor
			if absf(v) > 0.001:
				scaled[k] = v
		if not scaled.is_empty():
			result[dim_name] = scaled
	return SubstrateVector.create(result)


func normalized() -> SubstrateVector:
	var mag := magnitude()
	if mag < 0.0001:
		return SubstrateVector.zero()
	return scale(1.0 / mag)


# ── Serialization ────────────────────────────────────────────

func to_dict() -> Dictionary:
	var result := {}
	for dim_name in DIMENSIONS:
		if dimensions.has(dim_name) and not dimensions[dim_name].is_empty():
			result[dim_name] = dimensions[dim_name].duplicate()
	return result


func to_string_readable() -> String:
	var parts: Array[String] = []
	for dim_name in DIMENSIONS:
		if not dimensions.has(dim_name) or dimensions[dim_name].is_empty():
			continue
		var dim: Dictionary = dimensions[dim_name]
		var entries: Array[String] = []
		# Sort by weight descending
		var sorted_keys := dim.keys()
		sorted_keys.sort_custom(func(a, b): return dim[a] > dim[b])
		for k in sorted_keys:
			entries.append("%s:%.1f" % [k, dim[k]])
		parts.append("%s={%s}" % [dim_name, ", ".join(entries)])
	if parts.is_empty():
		return "SubstrateVector{empty}"
	return "SubstrateVector{%s}" % ", ".join(parts)


func _to_string() -> String:
	return to_string_readable()
