# capsule_sdf.gd
# Capsule primitive as a FormSDF. Exact distance, the fundamental building
# block for stems, spines, limbs, branches.

extends "res://commons/morphology/sdf/form_sdf.gd"

const SdfOps = preload("res://commons/morphology/sdf/sdf_ops.gd")

@export var a: Vector3 = Vector3.ZERO
@export var b: Vector3 = Vector3.UP
@export var radius: float = 0.1


static func make(from: Vector3, to: Vector3, r: float) -> Resource:
	var script: GDScript = load("res://commons/morphology/sdf/capsule_sdf.gd")
	var c: Resource = script.new()
	c.a = from
	c.b = to
	c.radius = r
	return c


func signed_distance(p: Vector3) -> float:
	return SdfOps.sdf_capsule(p, a, b, radius)


func get_aabb() -> AABB:
	var pad := Vector3.ONE * (radius + 0.05)
	var minp := Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z)) - pad
	var maxp := Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z)) + pad
	return AABB(minp, maxp - minp)


func build_mesh_parts() -> Array:
	var mid: Vector3 = (a + b) * 0.5
	var dir: Vector3 = b - a
	var segment_length: float = dir.length()
	# Godot CapsuleMesh.height includes both hemispheres (total end-to-end).
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(segment_length + radius * 2.0, radius * 2.001)
	mesh.radial_segments = 16
	mesh.rings = 4

	# Default CapsuleMesh is oriented along +Y. Rotate so +Y aligns with dir.
	var basis := Basis.IDENTITY
	if segment_length > 0.0001:
		var dir_n: Vector3 = dir / segment_length
		if not dir_n.is_equal_approx(Vector3.UP) and not dir_n.is_equal_approx(-Vector3.UP):
			var axis: Vector3 = Vector3.UP.cross(dir_n).normalized()
			basis = Basis(axis, Vector3.UP.angle_to(dir_n))
		elif dir_n.is_equal_approx(-Vector3.UP):
			basis = Basis(Vector3.FORWARD, PI)
	return [{"mesh": mesh, "transform": Transform3D(basis, mid), "slot": "self"}]
