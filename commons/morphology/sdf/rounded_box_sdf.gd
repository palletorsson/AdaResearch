# rounded_box_sdf.gd
# Box with corner-radius chamfer — gives solid objects a soft silhouette.
# Distance from p to nearest edge, minus radius. Classic IQ formulation.
# Used for seat cushions, soap bars, rounded signs, barrels, books.

extends "res://commons/morphology/sdf/form_sdf.gd"

@export var center: Vector3 = Vector3.ZERO
@export var half_extents: Vector3 = Vector3(0.5, 0.5, 0.5)
@export var corner_radius: float = 0.08
@export var basis: Basis = Basis.IDENTITY


static func make(c: Vector3, half_ext: Vector3, r: float, b: Basis = Basis.IDENTITY) -> Resource:
	var script: GDScript = load("res://commons/morphology/sdf/rounded_box_sdf.gd")
	var rb: Resource = script.new()
	rb.center = c
	rb.half_extents = half_ext
	rb.corner_radius = r
	rb.basis = b
	return rb


func signed_distance(p: Vector3) -> float:
	var local: Vector3 = basis.inverse() * (p - center)
	# Shrink box by radius, then add radius to the distance — produces the
	# rounded silhouette. Box extents must shrink at least by corner_radius
	# on each axis, otherwise we'd get a negative-extent box.
	var shrunk: Vector3 = Vector3(
		maxf(half_extents.x - corner_radius, 0.001),
		maxf(half_extents.y - corner_radius, 0.001),
		maxf(half_extents.z - corner_radius, 0.001),
	)
	var q: Vector3 = Vector3(absf(local.x), absf(local.y), absf(local.z)) - shrunk
	var outside: float = Vector3(maxf(q.x, 0.0), maxf(q.y, 0.0), maxf(q.z, 0.0)).length()
	var inside: float = minf(maxf(q.x, maxf(q.y, q.z)), 0.0)
	return (outside + inside) - corner_radius


func get_aabb() -> AABB:
	var r_max: float = maxf(maxf(half_extents.x, half_extents.y), half_extents.z) * 1.2
	return AABB(center - Vector3(r_max, r_max, r_max), Vector3(r_max, r_max, r_max) * 2.0)


func build_mesh_parts() -> Array:
	# Approximate with a BoxMesh for now — a proper rounded mesh would need
	# either edge beveling or marching cubes. BoxMesh reads close enough at
	# low poly counts; swap to bevel when production quality matters.
	var mesh := BoxMesh.new()
	mesh.size = half_extents * 2.0
	return [{"mesh": mesh, "transform": Transform3D(basis, center), "slot": "self"}]
