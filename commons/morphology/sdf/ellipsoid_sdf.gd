# ellipsoid_sdf.gd
# Ellipsoid primitive. Used for petals, leaves, heads, caps. SDF is
# approximate (not exact) — the IQ formulation, good enough for our
# voxel-preview and marching-cubes resolutions.

extends "res://commons/morphology/sdf/form_sdf.gd"

@export var center: Vector3 = Vector3.ZERO
@export var radii: Vector3 = Vector3(1, 1, 1)
@export var basis: Basis = Basis.IDENTITY


static func make(c: Vector3, r: Vector3, b: Basis = Basis.IDENTITY) -> Resource:
	var script: GDScript = load("res://commons/morphology/sdf/ellipsoid_sdf.gd")
	var e: Resource = script.new()
	e.center = c
	e.radii = r
	e.basis = b
	return e


func signed_distance(p: Vector3) -> float:
	# Transform p into local ellipsoid frame
	var local: Vector3 = basis.inverse() * (p - center)
	# IQ approximate ellipsoid SDF
	var k0: float = Vector3(local.x / radii.x, local.y / radii.y, local.z / radii.z).length()
	var k1: float = Vector3(local.x / (radii.x * radii.x), local.y / (radii.y * radii.y), local.z / (radii.z * radii.z)).length()
	if k1 <= 0.0:
		return -radii.x  # inside at center
	return k0 * (k0 - 1.0) / k1


func get_aabb() -> AABB:
	var r_max: float = maxf(maxf(radii.x, radii.y), radii.z)
	var pad := Vector3(r_max, r_max, r_max) * 1.3
	return AABB(center - pad, pad * 2.0)


func build_mesh_parts() -> Array:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 20
	mesh.rings = 10
	# Transform = translate(center) * rotate(basis) * scale(radii)
	var scaled_basis: Basis = basis * Basis.from_scale(radii)
	return [{"mesh": mesh, "transform": Transform3D(scaled_basis, center), "slot": "self"}]
