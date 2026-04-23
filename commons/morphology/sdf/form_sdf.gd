# form_sdf.gd
# Abstract base. Every form generator that wants to participate in the SDF bus
# extends this and overrides signed_distance(). See doc/SDF_BUS.md for the
# architectural rationale.

extends Resource


## Signed distance from world-space point p to the nearest surface of the form.
## Negative inside the form, positive outside, zero on the surface.
func signed_distance(_p: Vector3) -> float:
	push_error("FormSDF subclasses must override signed_distance()")
	return INF


## Bounding box of the form's defined region. SDFs are infinite functions;
## this is only a hint for voxel-grid sizing during mesh extraction or preview.
func get_aabb() -> AABB:
	return AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))


## Emit a list of mesh parts representing this SDF as actual geometry.
## Each entry is a Dictionary {mesh: Mesh, transform: Transform3D, slot: String}.
## Used for production rendering when we don't need voxel/marching-cubes
## extraction — primitive SDFs (capsules, ellipsoids) can mesh themselves
## exactly, while a BlendedSDF or other compound SDF should fall back to
## voxel/marching-cubes since its geometry isn't a union of known primitives.
##
## Default: empty. Override in subclasses that have a direct mesh form.
func build_mesh_parts() -> Array:
	return []


## Batch evaluation on a voxel grid. Default implementation is per-point and
## slow; override in subclasses when the principle admits vectorization
## (e.g. noise fields, lattice SDFs).
func sample_grid(origin: Vector3, size: Vector3, res: Vector3i) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(res.x * res.y * res.z)
	var step := size / Vector3(res)
	var idx := 0
	for z in res.z:
		for y in res.y:
			for x in res.x:
				var p := origin + Vector3(x, y, z) * step
				out[idx] = signed_distance(p)
				idx += 1
	return out
