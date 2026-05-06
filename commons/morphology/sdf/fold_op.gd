# fold_op.gd
# FormSDF wrapper that folds a base SDF around an axis by a given angle.
# Connects CritterDNA fold_* genes (fold_axis, fold_material, fold_speed,
# fold_memory, fold_risk, fold_depth) to actual form articulation — a
# creature in a DEFENSIVE fold-state closes up; CURIOUS unfolds.
#
# Implementation: reflect points on one side of the fold plane across it
# at a non-linear angle. When fold_angle=0, passes through unchanged;
# at PI/2 the upper half is bent 90° from the lower.

extends "res://commons/morphology/sdf/form_sdf.gd"

@export var base: Resource  # FormSDF
@export var fold_point: Vector3 = Vector3.ZERO
@export var fold_axis: Vector3 = Vector3.UP      # hinge axis
@export var fold_normal: Vector3 = Vector3.RIGHT # which side gets folded (perpendicular to axis)
@export_range(0.0, 3.14159) var fold_angle: float = 0.0


static func make(base_sdf: Resource, point: Vector3, axis: Vector3, normal: Vector3, angle: float) -> Resource:
	var script: GDScript = load("res://commons/morphology/sdf/fold_op.gd")
	var op: Resource = script.new()
	op.base = base_sdf
	op.fold_point = point
	op.fold_axis = axis.normalized()
	op.fold_normal = normal.normalized()
	op.fold_angle = angle
	return op


func signed_distance(p: Vector3) -> float:
	if base == null:
		return INF
	var local: Vector3 = p - fold_point
	# Classify: is this point on the side of fold_normal that gets folded?
	var side: float = local.dot(fold_normal)
	if side > 0.0:
		# Rotate this side around fold_axis by -fold_angle. The hinge passes
		# through fold_point. This bends the "upper" half toward the base.
		local = local.rotated(fold_axis, -fold_angle)
	return base.signed_distance(local + fold_point)


func get_aabb() -> AABB:
	if base == null:
		return AABB()
	# Folding can bring distant points closer OR push them out; grow
	# conservatively.
	return base.get_aabb().grow(0.5)
