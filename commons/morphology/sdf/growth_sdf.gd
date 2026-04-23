# growth_sdf.gd
# SDF subclass for seq 11 — L-systems. Grammar rewriting produces a branch
# graph; SDF is the union of capsules along each branch. Canonical L-system
# SDF: exact, manifold at the zero-isosurface, always valid for morphing.

extends "res://commons/morphology/sdf/form_sdf.gd"

const SdfOps = preload("res://commons/morphology/sdf/sdf_ops.gd")

@export var axiom: String = "F"
@export var rules: Dictionary = {"F": "F[+F]F[-F]F"}
@export var iterations: int = 3
@export var step_length: float = 0.4
@export var angle_degrees: float = 25.0
@export var branch_radius: float = 0.05
@export var origin: Vector3 = Vector3.ZERO

## Cached branch segments as (from, to) capsule endpoints.
## Built lazily via rebuild().
var _segments: Array = []  # Array of [Vector3, Vector3]
var _dirty: bool = true
var _aabb: AABB = AABB()


func rebuild() -> void:
	# Rewrite the axiom
	var current: String = axiom
	for _it in iterations:
		var next: String = ""
		for ch in current:
			next += str(rules.get(ch, ch))
		current = next

	# Turtle-graphics walk to build capsule segments
	_segments.clear()
	var pos: Vector3 = origin
	var dir: Vector3 = Vector3.UP
	var angle_step: float = deg_to_rad(angle_degrees)
	var stack: Array = []

	var minp: Vector3 = origin
	var maxp: Vector3 = origin

	for ch in current:
		match ch:
			"F":
				var new_pos: Vector3 = pos + dir * step_length
				_segments.append([pos, new_pos])
				pos = new_pos
				# Track bounds
				minp = Vector3(minf(minp.x, pos.x), minf(minp.y, pos.y), minf(minp.z, pos.z))
				maxp = Vector3(maxf(maxp.x, pos.x), maxf(maxp.y, pos.y), maxf(maxp.z, pos.z))
			"+":
				dir = dir.rotated(Vector3.FORWARD, angle_step)
			"-":
				dir = dir.rotated(Vector3.FORWARD, -angle_step)
			"[":
				stack.append([pos, dir])
			"]":
				if stack.size() > 0:
					var s = stack.pop_back()
					pos = s[0]
					dir = s[1]

	var pad := Vector3.ONE * (branch_radius + 0.1)
	_aabb = AABB(minp - pad, (maxp - minp) + pad * 2.0)
	_dirty = false


func signed_distance(p: Vector3) -> float:
	if _dirty:
		rebuild()
	if _segments.is_empty():
		return INF
	# SDF = smooth-min over all branch capsules. Using hard union (min) for
	# exact reads; switch to smooth_union with k>0 for organic blobby branches.
	var best: float = INF
	for seg in _segments:
		var d: float = SdfOps.sdf_capsule(p, seg[0], seg[1], branch_radius)
		if d < best:
			best = d
	return best


func get_aabb() -> AABB:
	if _dirty:
		rebuild()
	return _aabb
