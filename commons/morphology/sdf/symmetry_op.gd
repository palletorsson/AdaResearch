# symmetry_op.gd
# FormSDF wrapper that radially replicates a base SDF `count` times around
# `axis`, with optional tilt. Reads like "this petal, seven times around
# the stem". Reads dna.symmetry in recipes.

extends "res://commons/morphology/sdf/form_sdf.gd"

@export var base: Resource  # FormSDF — the one sub-unit to replicate
@export var count: int = 5
@export var axis: Vector3 = Vector3.UP
@export var origin: Vector3 = Vector3.ZERO


static func make(base_sdf: Resource, n: int, ax: Vector3 = Vector3.UP, org: Vector3 = Vector3.ZERO) -> Resource:
	var script: GDScript = load("res://commons/morphology/sdf/symmetry_op.gd")
	var op: Resource = script.new()
	op.base = base_sdf
	op.count = max(1, n)
	op.axis = ax
	op.origin = org
	return op


func signed_distance(p: Vector3) -> float:
	if base == null or count <= 0:
		return INF
	# Rotate p back by -theta for each symmetric copy and take the min.
	var best: float = INF
	var local: Vector3 = p - origin
	for i in count:
		var theta: float = float(i) / float(count) * TAU
		var rp: Vector3 = local.rotated(axis.normalized(), -theta) + origin
		var d: float = base.signed_distance(rp)
		if d < best:
			best = d
	return best


func get_aabb() -> AABB:
	if base == null:
		return AABB()
	# Conservative: take base AABB and expand by its diagonal around origin.
	var base_aabb: AABB = base.get_aabb()
	var r: float = (base_aabb.position - origin).length()
	r = maxf(r, (base_aabb.position + base_aabb.size - origin).length())
	var pad := Vector3(r, 0, r)
	return AABB(origin - pad - Vector3(0, base_aabb.size.y * 0.5, 0),
		pad * 2.0 + Vector3(0, base_aabb.size.y * 2.0, 0))


func build_mesh_parts() -> Array:
	if base == null:
		return []
	var base_parts: Array = base.build_mesh_parts()
	if base_parts.is_empty():
		return []
	var out: Array = []
	var ax: Vector3 = axis.normalized()
	for i in count:
		var theta: float = float(i) / float(count) * TAU
		var rot := Basis(ax, theta)
		for spec in base_parts:
			var base_xf: Transform3D = spec["transform"]
			# Rotate the part's placement around the symmetry origin by theta
			var new_origin: Vector3 = origin + rot * (base_xf.origin - origin)
			var new_basis: Basis = rot * base_xf.basis
			out.append({
				"mesh": spec["mesh"],
				"transform": Transform3D(new_basis, new_origin),
				"slot": spec.get("slot", "self"),
			})
	return out
