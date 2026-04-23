# fold_chain.gd
# A sequence of articulated capsule-links, each one a φ-fold of the
# previous. This is the Modulor made SDF-shaped: instead of a flat chain
# of identical segments, every next link is 1/φ the length of its parent,
# and the hinge between them is a FoldOp-style rotation.
#
# `segments` is an Array of Dictionary entries. Two build modes:
#
# 1. Absolute: each entry has {length, radius, angle_degrees, axis}
# 2. Ladder:   each entry has {ladder_level, angle_degrees, axis} and the
#              length/radius are looked up from ModulorScale.
#
# Usage — an arm from shoulder to finger in one chain:
#   chain.segments = [
#       {ladder_level=2, angle_degrees=0,   axis=Vector3.FORWARD},  # upper arm
#       {ladder_level=3, angle_degrees=-25, axis=Vector3.FORWARD},  # forearm (elbow)
#       {ladder_level=4, angle_degrees=10,  axis=Vector3.FORWARD},  # hand (wrist)
#       {ladder_level=6, angle_degrees=-15, axis=Vector3.FORWARD},  # finger (knuckle)
#   ]

extends "res://commons/morphology/sdf/form_sdf.gd"

const SdfOps = preload("res://commons/morphology/sdf/sdf_ops.gd")
const ModulorScale = preload("res://commons/morphology/sdf/modulor_scale.gd")

@export var origin: Vector3 = Vector3.ZERO
@export var initial_direction: Vector3 = Vector3.UP
## See module docstring for entry schema.
@export var segments: Array = []
## Thickness factor applied to ladder-level radii (blends stocky vs lean).
@export_range(0.05, 0.4) var radius_ratio: float = 0.13

var _capsules: Array = []  # each: [from: Vector3, to: Vector3, radius: float]
var _dirty: bool = true
var _cached_aabb: AABB = AABB()


func build() -> void:
	_capsules.clear()
	if segments.is_empty():
		_dirty = false
		return

	var pos: Vector3 = origin
	var dir: Vector3 = initial_direction.normalized()

	var minp: Vector3 = pos
	var maxp: Vector3 = pos

	for seg in segments:
		# Resolve length + radius (ladder lookup or explicit)
		var length: float = 0.3
		var radius: float = 0.04
		if seg.has("ladder_level"):
			length = ModulorScale.red(int(seg.get("ladder_level", 3)))
			radius = ModulorScale.link_radius(length, radius_ratio)
		else:
			length = float(seg.get("length", 0.3))
			radius = float(seg.get("radius", length * radius_ratio))

		# Apply hinge rotation BEFORE extending — the fold happens at the joint
		var angle_deg: float = float(seg.get("angle_degrees", 0.0))
		var axis: Vector3 = (seg.get("axis", Vector3.FORWARD) as Vector3).normalized()
		if absf(angle_deg) > 0.01 and axis.length_squared() > 0.0:
			dir = dir.rotated(axis, deg_to_rad(angle_deg))

		var next_pos: Vector3 = pos + dir * length
		_capsules.append([pos, next_pos, radius])

		# Track AABB
		var cap_pad := Vector3.ONE * (radius + 0.02)
		var segmin := Vector3(minf(pos.x, next_pos.x), minf(pos.y, next_pos.y), minf(pos.z, next_pos.z)) - cap_pad
		var segmax := Vector3(maxf(pos.x, next_pos.x), maxf(pos.y, next_pos.y), maxf(pos.z, next_pos.z)) + cap_pad
		minp = Vector3(minf(minp.x, segmin.x), minf(minp.y, segmin.y), minf(minp.z, segmin.z))
		maxp = Vector3(maxf(maxp.x, segmax.x), maxf(maxp.y, segmax.y), maxf(maxp.z, segmax.z))

		pos = next_pos

	_cached_aabb = AABB(minp, maxp - minp)
	_dirty = false


func signed_distance(p: Vector3) -> float:
	if _dirty:
		build()
	if _capsules.is_empty():
		return INF
	# Smooth union between adjacent capsules so joints read as organic
	# welds, not hard cylinder intersections. Small k for crisp shapes.
	var d: float = SdfOps.sdf_capsule(p, _capsules[0][0], _capsules[0][1], _capsules[0][2])
	for i in range(1, _capsules.size()):
		var c = _capsules[i]
		d = SdfOps.smooth_union(d, SdfOps.sdf_capsule(p, c[0], c[1], c[2]), 0.03)
	return d


func get_aabb() -> AABB:
	if _dirty:
		build()
	return _cached_aabb.grow(0.05)


# ─── Static helpers for common fold chains ───────────────────────

## Human arm — shoulder → upper arm → forearm → hand → finger.
## Anchored at `shoulder_pos`, initial direction `init_dir` (usually down
## and slightly forward). Angles create a typical resting pose.
static func arm(shoulder_pos: Vector3, init_dir: Vector3 = Vector3(0.3, -1, 0.1)) -> Resource:
	var script: GDScript = load("res://commons/morphology/sdf/fold_chain.gd")
	var chain: Resource = script.new()
	chain.origin = shoulder_pos
	chain.initial_direction = init_dir.normalized()
	chain.segments = [
		{ladder_level = 2, angle_degrees =   0.0, axis = Vector3.FORWARD},  # upper arm
		{ladder_level = 3, angle_degrees = -25.0, axis = Vector3.FORWARD},  # forearm
		{ladder_level = 4, angle_degrees =  15.0, axis = Vector3.FORWARD},  # hand
		{ladder_level = 6, angle_degrees = -20.0, axis = Vector3.FORWARD},  # finger
	]
	return chain


## Human leg — hip → thigh → shin → foot.
static func leg(hip_pos: Vector3, side: float = 1.0) -> Resource:
	var script: GDScript = load("res://commons/morphology/sdf/fold_chain.gd")
	var chain: Resource = script.new()
	chain.origin = hip_pos
	chain.initial_direction = Vector3(side * 0.08, -1, 0.0).normalized()
	chain.segments = [
		{ladder_level = 2, angle_degrees =  0.0, axis = Vector3.FORWARD}, # thigh
		{ladder_level = 3, angle_degrees = 12.0, axis = Vector3.FORWARD}, # shin
		{ladder_level = 4, angle_degrees = 80.0, axis = Vector3.FORWARD}, # foot (bent sharply forward)
	]
	return chain
