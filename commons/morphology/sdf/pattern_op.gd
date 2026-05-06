# pattern_op.gd
# FormSDF wrapper that displaces a base SDF by a surface pattern. Reads
# dna.pattern_type, pattern_density, pattern_scale genes.
#
# Modes:
#   "noise"   — simplex bumpiness (bark, rock, skin)
#   "stripes" — bands along an axis (gills, ridges)
#   "dots"    — sinusoidal polka-dot pattern (Kusama on a skin)
#   "scales"  — overlapping scale-like displacement (reptile, fish)
#
# The displacement amplitude is tiny compared to the base form — this is
# about ornament, not about reshaping.

extends "res://commons/morphology/sdf/form_sdf.gd"

@export var base: Resource  # FormSDF
@export_enum("noise", "stripes", "dots", "scales") var mode: String = "noise"
@export_range(0.0, 1.0) var density: float = 0.5
@export_range(0.1, 5.0) var scale: float = 1.0
@export_range(0.0, 0.3) var amplitude: float = 0.05
@export var axis: Vector3 = Vector3.UP

var _noise: FastNoiseLite = null


static func make(base_sdf: Resource, m: String, d: float, s: float, amp: float = 0.05) -> Resource:
	var script: GDScript = load("res://commons/morphology/sdf/pattern_op.gd")
	var op: Resource = script.new()
	op.base = base_sdf
	op.mode = m
	op.density = d
	op.scale = s
	op.amplitude = amp
	return op


func _ensure_noise() -> void:
	if _noise == null:
		_noise = FastNoiseLite.new()
		_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
		_noise.frequency = scale


func signed_distance(p: Vector3) -> float:
	if base == null:
		return INF
	var d: float = base.signed_distance(p)
	var disp: float = 0.0
	match mode:
		"noise":
			_ensure_noise()
			disp = _noise.get_noise_3d(p.x * scale, p.y * scale, p.z * scale) * amplitude
		"stripes":
			var proj: float = p.dot(axis.normalized())
			disp = sin(proj * scale * TAU) * amplitude * density
		"dots":
			var dx: float = sin(p.x * scale * TAU) * sin(p.y * scale * TAU) * sin(p.z * scale * TAU)
			disp = (1.0 if dx > lerp(1.0, -1.0, density) else -1.0) * amplitude * 0.5
		"scales":
			var u: float = sin(p.y * scale * TAU)
			var v: float = cos(p.x * scale * TAU + p.z * scale * TAU + p.y * scale * PI)
			disp = (u * v) * amplitude * density
	# Subtracting disp from d pushes the surface outward where disp > 0.
	return d - disp


func get_aabb() -> AABB:
	if base == null:
		return AABB()
	# Pattern adds at most `amplitude` to the surface extent.
	return base.get_aabb().grow(amplitude + 0.05)
