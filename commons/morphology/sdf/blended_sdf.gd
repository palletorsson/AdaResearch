# blended_sdf.gd
# Two SDFs blended by a morph parameter t ∈ [0, 1]. Composes.
#
# This is the FormSDF that embodies "transition between principals" — the
# whole reason the SDF bus exists.

extends "res://commons/morphology/sdf/form_sdf.gd"

const SdfOps = preload("res://commons/morphology/sdf/sdf_ops.gd")

@export var a: Resource  # FormSDF
@export var b: Resource  # FormSDF
@export_range(0.0, 1.0) var t: float = 0.5
@export_enum("weighted", "linear", "smooth", "smooth_union", "union", "intersect", "subtract") var mode: String = "weighted"
## Smoothness radius for smooth modes. Ignored for linear/union/intersect/subtract.
@export_range(0.0, 2.0) var smoothness: float = 0.3
## For weighted mode: max surface inflation at full visibility. Higher values
## make each form bulkier when present; lower values keep it gaunt.
@export_range(0.0, 2.0) var weighted_inflation: float = 0.5


static func new_blend(a_sdf: Resource, b_sdf: Resource, t: float, mode: String = "linear") -> Resource:
	var script: GDScript = load("res://commons/morphology/sdf/blended_sdf.gd")
	var instance: Resource = script.new()
	instance.a = a_sdf
	instance.b = b_sdf
	instance.t = t
	instance.mode = mode
	return instance


func signed_distance(p: Vector3) -> float:
	if a == null and b == null:
		return INF
	if a == null:
		return b.signed_distance(p)
	if b == null:
		return a.signed_distance(p)
	var da: float = a.signed_distance(p)
	var db: float = b.signed_distance(p)
	match mode:
		"weighted":
			# "Principle transition" — the operator we actually want for
			# blending different form-generators. Both forms are always
			# present; their visibility is controlled by t. Weight goes
			# from 1→0 for a, 0→1 for b. Each form is "inflated" by its
			# weight (subtract from d = push surface outward = make visible).
			# When a form's weight is 0, its surface is pushed infinitely
			# inward so it contributes nothing. Smooth union binds the two
			# present forms into one manifold surface without gaps.
			var wa: float = 1.0 - t
			var wb: float = t
			var inflated_a: float = da - wa * weighted_inflation
			var inflated_b: float = db - wb * weighted_inflation
			# When weight is 0, push SDF far positive (surface vanishes).
			if wa < 0.01: inflated_a = 1e6
			if wb < 0.01: inflated_b = 1e6
			return SdfOps.smooth_union(inflated_a, inflated_b, smoothness)
		"linear":
			return SdfOps.morph(da, db, t)
		"smooth":
			return SdfOps.morph_smooth(da, db, t)
		"smooth_union":
			return SdfOps.smooth_union(da, db, smoothness)
		"union":
			return SdfOps.union(da, db)
		"intersect":
			return SdfOps.intersect(da, db)
		"subtract":
			return SdfOps.subtract(da, db)
		_:
			return SdfOps.morph(da, db, t)


func get_aabb() -> AABB:
	if a == null and b == null:
		return AABB()
	if a == null:
		return b.get_aabb()
	if b == null:
		return a.get_aabb()
	return a.get_aabb().merge(b.get_aabb())
