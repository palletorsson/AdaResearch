extends RefCounted
## Native meshes for the resolution film. These are independent specimens;
## changing one never changes a mesh owned by a museum artifact.
const Inspection = preload("res://commons/primitives/shared/mesh_inspection.gd")
const MIN_SEGMENTS := 4
const MAX_SEGMENTS := 64
const MAX_RINGS := 32
const HEIGHT := 2.4
const RADIUS := 0.82
const SPHERE_RADIUS := 1.2

static func make(kind: int, segments: int, rings: int) -> PrimitiveMesh:
	var around := clampi(segments, MIN_SEGMENTS, MAX_SEGMENTS)
	var levels := clampi(rings, 1 if kind == 2 else 0, MAX_RINGS)
	var mesh: PrimitiveMesh
	match kind:
		0:
			var cylinder := CylinderMesh.new()
			cylinder.height = HEIGHT
			cylinder.top_radius = RADIUS
			cylinder.bottom_radius = RADIUS
			cylinder.radial_segments = around
			cylinder.rings = levels
			cylinder.cap_top = true
			cylinder.cap_bottom = true
			mesh = cylinder
		1:
			var capsule := CapsuleMesh.new()
			# Set height before radius so their linked setters retain both sizes.
			capsule.height = HEIGHT
			capsule.radius = RADIUS
			capsule.radial_segments = around
			capsule.rings = levels
			mesh = capsule
		2:
			var sphere := SphereMesh.new()
			sphere.radius = SPHERE_RADIUS
			sphere.height = HEIGHT
			sphere.radial_segments = around
			sphere.rings = levels
			mesh = sphere
		_:
			push_error("Resolution film expects cylinder (0), capsule (1), or sphere (2).")
			return null
	return mesh

static func measure(mesh: PrimitiveMesh) -> Dictionary:
	var measured: Dictionary = Inspection.inspect(mesh)
	var count := 0
	for surface in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(surface)
		count += (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	measured["segments"] = int(mesh.get("radial_segments"))
	measured["radial_segments"] = int(mesh.get("radial_segments"))
	measured["rings"] = int(mesh.get("rings"))
	measured["vertex_count"] = count
	measured["triangles"] = int(measured["surface_triangles"])
	measured["degenerate_triangles"] = int(measured["submitted"]) - int(measured["surface_triangles"])
	measured["bounds"] = mesh.get_aabb()
	return measured
