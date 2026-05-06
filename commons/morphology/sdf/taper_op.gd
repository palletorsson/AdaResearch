# taper_op.gd
# FormSDF wrapper that scales a base SDF along an axis, narrowing it from
# bottom to top (or any direction). Reads like "this stem is fat at the
# base, thin at the tip".
#
# The trick: scale p's perpendicular components based on its projection
# along the taper axis. Where the axis projection is at `from_t`, scale
# is 1.0 (full radius). Where it's `to_t`, scale is `top_ratio`.

extends "res://commons/morphology/sdf/form_sdf.gd"

@export var base: Resource  # FormSDF
@export var axis: Vector3 = Vector3.UP
@export var from_t: float = 0.0   # axis parameter where full radius starts
@export var to_t: float = 1.0     # axis parameter where tip is
## Radius multiplier at the tip. 0.0 = pinched to point, 1.0 = no taper.
@export_range(0.05, 1.0) var top_ratio: float = 0.4


static func make(base_sdf: Resource, axis_dir: Vector3, start_t: float, end_t: float, tip_ratio: float) -> Resource:
	var script: GDScript = load("res://commons/morphology/sdf/taper_op.gd")
	var op: Resource = script.new()
	op.base = base_sdf
	op.axis = axis_dir.normalized()
	op.from_t = start_t
	op.to_t = end_t
	op.top_ratio = tip_ratio
	return op


func signed_distance(p: Vector3) -> float:
	if base == null:
		return INF
	# Project p onto axis
	var axis_n: Vector3 = axis.normalized()
	var proj: float = p.dot(axis_n)
	# Normalize projection into [0,1] over [from_t, to_t]
	var t: float = clampf((proj - from_t) / maxf(to_t - from_t, 0.0001), 0.0, 1.0)
	# Radius factor at this axis position — 1 at base, top_ratio at tip
	var r: float = lerpf(1.0, top_ratio, t)
	# Perpendicular component scaled inversely (to inflate SDF when r < 1,
	# the cross-section looks thinner).
	var along: Vector3 = axis_n * proj
	var perp: Vector3 = p - along
	# Inverse-scale the perpendicular component so the base SDF sees a
	# thicker shape relative to itself — this is the taper.
	var p_scaled: Vector3 = along + perp / maxf(r, 0.05)
	# Compensate for the scale to keep SDF Lipschitz: multiply back by r.
	return base.signed_distance(p_scaled) * r


func get_aabb() -> AABB:
	if base == null:
		return AABB()
	return base.get_aabb().grow(0.1)
