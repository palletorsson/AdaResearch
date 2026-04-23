# box_sdf.gd
# Axis-aligned box primitive (rotatable via basis). The bread-and-butter
# primitive for walls, crates, signs, blocks, panels. Exact SDF.

extends "res://commons/morphology/sdf/form_sdf.gd"

const SdfOps = preload("res://commons/morphology/sdf/sdf_ops.gd")

@export var center: Vector3 = Vector3.ZERO
@export var half_extents: Vector3 = Vector3(0.5, 0.5, 0.5)
@export var basis: Basis = Basis.IDENTITY


static func make(c: Vector3, half_ext: Vector3, b: Basis = Basis.IDENTITY) -> Resource:
	var script: GDScript = load("res://commons/morphology/sdf/box_sdf.gd")
	var box: Resource = script.new()
	box.center = c
	box.half_extents = half_ext
	box.basis = b
	return box


func signed_distance(p: Vector3) -> float:
	var local: Vector3 = basis.inverse() * (p - center)
	return SdfOps.sdf_box(local, half_extents)


func get_aabb() -> AABB:
	var r_max: float = maxf(maxf(half_extents.x, half_extents.y), half_extents.z) * 1.2
	return AABB(center - Vector3(r_max, r_max, r_max), Vector3(r_max, r_max, r_max) * 2.0)


func build_mesh_parts() -> Array:
	var mesh := BoxMesh.new()
	mesh.size = half_extents * 2.0
	return [{"mesh": mesh, "transform": Transform3D(basis, center), "slot": "self"}]
